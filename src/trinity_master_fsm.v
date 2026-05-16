`default_nettype none
// trinity_master_fsm.v - 4-state host FSM (RESET, COMPUTE, EMIT, IDLE)
// Apache-2.0
//
// Trimmed for 2x2 tile budget. Sends canned LOAD_A x4, LOAD_B x4, COMPUTE,
// READ_RES to tile 0, latches RESULT (0x47C0) and RECEIPT.
//
// State map:
//   RESET   -> COMPUTE on ena
//   COMPUTE -> EMIT    after all load+compute packets accepted
//   EMIT    -> IDLE    after READ_RES accepted
//   IDLE    stays

`include "trinity_packet.vh"

module trinity_master_fsm (
    input  wire                    clk,
    input  wire                    rst_n,
    input  wire                    ena,
    input  wire                    load_mode,  // reserved

    output reg  [`TRN_PKT_W-1:0]   host_in_pkt,
    output reg                     host_in_valid,
    input  wire                    host_in_ready,

    input  wire [`TRN_PKT_W-1:0]   host_out_pkt,
    input  wire                    host_out_valid,
    output wire                    host_out_ready,

    output reg  [15:0]             result_reg,
    output reg                     result_valid_q,

    output reg  [7:0]              rcpt_checksum_q,
    output reg  [7:0]              rcpt_job_id_q,
    output reg  [1:0]              rcpt_tile_id_q,
    output reg                     rcpt_valid_q
);

    // Canned GF16 operands: 1.0, 2.0, 3.0, 4.0
    function [15:0] gf16_const;
        input [1:0] sel;
        begin
            case (sel)
                2'd0: gf16_const = 16'h3E00;
                2'd1: gf16_const = 16'h4000;
                2'd2: gf16_const = 16'h4100;
                2'd3: gf16_const = 16'h4200;
            endcase
        end
    endfunction

    localparam [7:0] CANNED_JOB_ID = 8'h01;

    localparam [1:0]
        S_RESET   = 2'd0,
        S_COMPUTE = 2'd1,
        S_EMIT    = 2'd2,
        S_IDLE    = 2'd3;

    reg [1:0] state;
    // step encoding in S_COMPUTE:
    //   0..3  => LOAD_A lane 0..3
    //   4..7  => LOAD_B lane 0..3
    //   8     => COMPUTE packet
    // step in S_EMIT:
    //   0 => READ_RES packet, then -> IDLE
    reg [3:0] step;

    assign host_out_ready = 1'b1;

    // Latch RESULT and RECEIPT
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            result_reg      <= 16'h0;
            result_valid_q  <= 1'b0;
            rcpt_checksum_q <= 8'h00;
            rcpt_job_id_q   <= 8'h00;
            rcpt_tile_id_q  <= 2'h0;
            rcpt_valid_q    <= 1'b0;
        end else if (host_out_valid && host_out_ready) begin
            case (`TRN_PKT_OP(host_out_pkt))
                `TRN_OP_RESULT: begin
                    result_reg     <= `TRN_PKT_PAYLOAD(host_out_pkt);
                    result_valid_q <= 1'b1;
                end
                `TRN_OP_RECEIPT: begin
                    rcpt_checksum_q <= `TRN_RCPT_PKT_CHECKSUM(host_out_pkt);
                    rcpt_job_id_q   <= `TRN_RCPT_PKT_JOB_LO(host_out_pkt);
                    rcpt_tile_id_q  <= `TRN_RCPT_PKT_TILE(host_out_pkt);
                    rcpt_valid_q    <= 1'b1;
                end
                default: ;
            endcase
        end
    end

    // Main sequencer
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state         <= S_RESET;
            step          <= 4'd0;
            host_in_pkt   <= {`TRN_PKT_W{1'b0}};
            host_in_valid <= 1'b0;
        end else begin
            if (host_in_valid && host_in_ready)
                host_in_valid <= 1'b0;

            case (state)
                S_RESET: begin
                    if (ena) begin
                        step  <= 4'd0;
                        state <= S_COMPUTE;
                    end
                end

                S_COMPUTE: begin
                    if (!host_in_valid || host_in_ready) begin
                        if (step <= 4'd3) begin
                            host_in_pkt   <= `TRN_MK_PKT(`TRN_OP_LOAD_A, 2'd0, 2'd0,
                                                         {2'd0, step[1:0]}, gf16_const(step[1:0]));
                            host_in_valid <= 1'b1;
                            step          <= step + 4'd1;
                        end else if (step <= 4'd7) begin
                            host_in_pkt   <= `TRN_MK_PKT(`TRN_OP_LOAD_B, 2'd0, 2'd0,
                                                         {2'd0, step[1:0]}, gf16_const(step[1:0]));
                            host_in_valid <= 1'b1;
                            step          <= step + 4'd1;
                        end else begin
                            // step==8: send COMPUTE
                            host_in_pkt   <= `TRN_MK_PKT(`TRN_OP_COMPUTE, 2'd0, 2'd0,
                                                         4'd0, 16'h0);
                            host_in_valid <= 1'b1;
                            state         <= S_EMIT;
                        end
                    end
                end

                S_EMIT: begin
                    if (!host_in_valid || host_in_ready) begin
                        host_in_pkt   <= `TRN_MK_PKT(`TRN_OP_READ_RES, 2'd0, 2'd0,
                                                     4'd0, {8'd0, CANNED_JOB_ID});
                        host_in_valid <= 1'b1;
                        state         <= S_IDLE;
                    end
                end

                S_IDLE: begin
                    state <= S_IDLE;
                end

                default: state <= S_RESET;
            endcase
        end
    end

endmodule
