`default_nettype none
`timescale 1ns / 1ps
// sim/g1_loopback/tb_g1_loopback.v
// Apache-2.0
//
// G1 acceptance test: simulate `top_usb3_loopback` 100 times back-to-back,
// each time driving a canonical job stream (LOAD_A x4 + LOAD_B x4 + COMPUTE +
// READ_RES) through the FT601 FIFO model and verifying the FPGA returns a
// RESULT packet whose payload == 0x47C0 (GF16(30.0) == 1+4+9+16).
//
// Falsification rules:
//   - Any wrong payload, dropped packet, or timeout fails the run.
//   - The testbench does not instantiate Linux, soft CPU, or AXI.
//   - The simulated FT601 is a pure FIFO model: rxf_n/txe_n/rd_n/wr_n only.
//
// Run with iverilog:
//   iverilog -g2012 -o tb_g1_loopback.vvp \
//       sim/g1_loopback/tb_g1_loopback.v \
//       sim/g1_loopback/ft601_fifo_model.v \
//       boards/qmtech_a100t/top_usb3_loopback.v \
//       boards/qmtech_a100t/sync_reset_n.v \
//       boards/qmtech_a100t/trinity_async_pkt_fifo.v \
//       src/trinity_usb3_fifo_bridge.v \
//       src/trinity_master_fsm.v \
//       src/trinity_mesh_2x2.v \
//       src/trinity_router_2x2.v \
//       src/trinity_gf16_tile.v \
//       src/gf16_dot4.v src/gf16_mul.v src/gf16_add.v
//   vvp tb_g1_loopback.vvp

`include "../../src/trinity_packet.vh"

module tb_g1_loopback;
    // ---- Clocks ----
    reg sys_clk_50 = 1'b0;
    reg ft_clk     = 1'b0;
    always #10  sys_clk_50 = ~sys_clk_50;   // 50 MHz
    always #5   ft_clk     = ~ft_clk;       // 100 MHz

    reg sys_rst_n = 1'b0;

    // ---- FT601 model wires ----
    wire ft_rxf_n;     // model -> DUT  (active-low data available)
    wire ft_txe_n;     // model -> DUT  (active-low space available)
    wire ft_rd_n;      // DUT  -> model
    wire ft_wr_n;      // DUT  -> model
    wire ft_oe_n;      // DUT  -> model
    wire [31:0] ft_data;

    wire [3:0] led_status;

    // ---- DUT ----
    top_usb3_loopback u_dut (
        .sys_clk_50 (sys_clk_50),
        .sys_rst_n  (sys_rst_n),
        .ft_clk     (ft_clk),
        .ft_rxf_n   (ft_rxf_n),
        .ft_txe_n   (ft_txe_n),
        .ft_rd_n    (ft_rd_n),
        .ft_wr_n    (ft_wr_n),
        .ft_oe_n    (ft_oe_n),
        .ft_data    (ft_data),
        .led_status (led_status)
    );

    // ---- FT601 model (drives rxf_n/txe_n, latches DUT writes) ----
    reg                 model_push;
    reg  [31:0]         model_push_word;
    wire                model_push_full;
    wire                model_pop_valid;
    wire [31:0]         model_pop_word;
    reg                 model_pop_ack;

    ft601_fifo_model u_ft_model (
        .clk        (ft_clk),
        .rst_n      (sys_rst_n),
        // PC injection / readback side
        .push       (model_push),
        .push_word  (model_push_word),
        .push_full  (model_push_full),
        .pop_valid  (model_pop_valid),
        .pop_word   (model_pop_word),
        .pop_ack    (model_pop_ack),
        // FT601 pins facing the DUT
        .ft_rxf_n   (ft_rxf_n),
        .ft_txe_n   (ft_txe_n),
        .ft_rd_n    (ft_rd_n),
        .ft_wr_n    (ft_wr_n),
        .ft_oe_n    (ft_oe_n),
        .ft_data    (ft_data)
    );

    // ---- Packet helpers ----
    function [31:0] mk_pkt;
        input [3:0]  op;
        input [1:0]  dst;
        input [1:0]  src;
        input [3:0]  lane;
        input [15:0] payload;
        mk_pkt = {op, dst, src, lane, 4'h0, payload};
    endfunction

    function [15:0] gf16c;
        input [1:0] sel;
        case (sel)
            2'd0: gf16c = 16'h3E00; // 1.0
            2'd1: gf16c = 16'h4000; // 2.0
            2'd2: gf16c = 16'h4100; // 3.0
            2'd3: gf16c = 16'h4200; // 4.0
        endcase
    endfunction

    // ---- Test sequencer ----
    integer i, loops, passes, fails;
    integer waits;
    reg got_result;
    reg [15:0] got_payload;

    task push_pkt(input [31:0] p);
        begin
            @(posedge ft_clk);
            while (model_push_full) @(posedge ft_clk);
            model_push      <= 1'b1;
            model_push_word <= p;
            @(posedge ft_clk);
            model_push      <= 1'b0;
        end
    endtask

    task drive_canonical_job(input [15:0] expected);
        integer lane;
        integer t;
        begin
            // LOAD_A lane 0..3
            for (lane = 0; lane < 4; lane = lane + 1)
                push_pkt(mk_pkt(`TRN_OP_LOAD_A, 2'd0, 2'd0, lane[3:0], gf16c(lane[1:0])));
            // LOAD_B lane 0..3
            for (lane = 0; lane < 4; lane = lane + 1)
                push_pkt(mk_pkt(`TRN_OP_LOAD_B, 2'd0, 2'd0, lane[3:0], gf16c(lane[1:0])));
            // COMPUTE
            push_pkt(mk_pkt(`TRN_OP_COMPUTE,  2'd0, 2'd0, 4'h0, 16'h0));
            // READ_RES
            push_pkt(mk_pkt(`TRN_OP_READ_RES, 2'd0, 2'd0, 4'h0, 16'h0));

            // Wait for a RESULT packet to pop out of the FT egress.
            got_result  = 1'b0;
            got_payload = 16'hDEAD;
            for (t = 0; t < 4000 && !got_result; t = t + 1) begin
                @(posedge ft_clk);
                if (model_pop_valid) begin
                    model_pop_ack <= 1'b1;
                    if (model_pop_word[31:28] == `TRN_OP_RESULT) begin
                        got_payload = model_pop_word[15:0];
                        got_result  = 1'b1;
                    end
                    @(posedge ft_clk);
                    model_pop_ack <= 1'b0;
                end
            end

            if (got_result && got_payload === expected) begin
                passes = passes + 1;
            end else begin
                fails = fails + 1;
                $display("FAIL loop=%0d got_result=%b got_payload=0x%h expected=0x%h",
                         loops, got_result, got_payload, expected);
            end
        end
    endtask

    initial begin
        $dumpfile("tb_g1_loopback.vcd");
        $dumpvars(0, tb_g1_loopback);
        model_push      = 1'b0;
        model_push_word = 32'h0;
        model_pop_ack   = 1'b0;
        passes = 0;
        fails  = 0;
        // ---- Reset ----
        repeat (10) @(posedge ft_clk);
        sys_rst_n = 1'b1;
        repeat (50) @(posedge ft_clk);

        $display("=== G1 USB-3 LOOPBACK ===");

        // The canned FSM will emit a RESULT shortly after reset; drain that first.
        // Then let the FSM fully reach S_DONE state and let CDC FIFOs drain before
        // pushing host-driven packets (otherwise the FSM's last packet still in
        // flight collides with the arbiter and the first host job's READ_RES is
        // observed before the host's COMPUTE has propagated).
        waits = 0;
        while (!model_pop_valid && waits < 2000) begin
            @(posedge ft_clk);
            waits = waits + 1;
        end
        if (model_pop_valid) begin
            @(posedge ft_clk);
            model_pop_ack <= 1'b1;
            @(posedge ft_clk);
            model_pop_ack <= 1'b0;
            $display("INFO drained canned-FSM RESULT 0x%h", model_pop_word);
        end
        // Quiesce: drain any stragglers from the FSM canned sequence (which holds
        // result_valid_q sticky and may have already pushed a second RESULT into
        // the CDC FIFO between the drain check and now). Loop until truly empty.
        repeat (2000) @(posedge ft_clk);
        while (model_pop_valid) begin
            @(posedge ft_clk);
            model_pop_ack <= 1'b1;
            $display("INFO secondary drain pop 0x%h", model_pop_word);
            @(posedge ft_clk);
            model_pop_ack <= 1'b0;
            repeat (100) @(posedge ft_clk);
        end
        repeat (500) @(posedge ft_clk);

        // Run 100 host-driven jobs.
        for (loops = 1; loops <= 100; loops = loops + 1) begin
            drive_canonical_job(16'h47C0);
        end

        $display("=== G1 RESULT: %0d/100 passes, %0d fails ===", passes, fails);
        if (fails == 0 && passes == 100) $display("G1_GATE_GREEN: 100/100 0x47C0 received");
        else                              $display("G1_GATE_RED: falsification witness hit");
        $finish;
    end

    // ---- Watchdog ----
    initial begin
        #20_000_000; // 20 ms sim time
        $display("WATCHDOG_TIMEOUT: G1 did not complete in 20 ms sim");
        $finish;
    end

endmodule
