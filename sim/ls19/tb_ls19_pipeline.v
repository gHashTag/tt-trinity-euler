`default_nettype none
`timescale 1ns / 1ps
// tb_ls19_pipeline.v — L-S19 pipeline popcount testbench
// Apache-2.0
//
// Tests gf16_popcount (8-elem), gf16_popcount16 (16-elem), and vsa_matmul_8x8.
//
// Canonical GF16 test: dot4([1,2,3,4],[1,2,3,4]) = 30.0 = 0x47C0 (unchanged)
//
// Pipeline latency: valid_out appears exactly 3 clock edges after valid_in.
//   Cycle T:   valid_in=1, s1 decode latched
//   Cycle T+1: s2 popcount latched
//   Cycle T+2: s3 result latched (valid_out=1 at posedge T+3)
// So: after asserting valid_in at posedge T, wait for posedge T+3 to sample valid_out.

module tb_ls19_pipeline;

    reg clk, rst_n;
    initial clk = 0;
    always #5 clk = ~clk; // 100 MHz sim clock

    integer pass_count, fail_count;
    initial begin
        pass_count = 0;
        fail_count = 0;
    end

    // ---- DUT: gf16_popcount (8-element) ----
    reg        pc8_valid_in;
    reg [15:0] pc8_a, pc8_b;
    wire       pc8_valid_out;
    wire [7:0] pc8_result;

    gf16_popcount #(.N_ELEMS(8), .LATENCY(3)) dut_pc8 (
        .clk      (clk),
        .rst_n    (rst_n),
        .valid_in (pc8_valid_in),
        .a_row    (pc8_a),
        .b_row    (pc8_b),
        .valid_out(pc8_valid_out),
        .result   (pc8_result)
    );

    // ---- DUT: gf16_popcount16 (16-element) ----
    reg        pc16_valid_in;
    reg [31:0] pc16_a, pc16_b;
    wire       pc16_valid_out;
    wire [7:0] pc16_result;

    gf16_popcount16 #(.N_ELEMS(16), .LATENCY(3)) dut_pc16 (
        .clk      (clk),
        .rst_n    (rst_n),
        .valid_in (pc16_valid_in),
        .a_row    (pc16_a),
        .b_row    (pc16_b),
        .valid_out(pc16_valid_out),
        .result   (pc16_result)
    );

    // ---- DUT: vsa_matmul_8x8 (pipelined) ----
    reg         mm8_start;
    reg [127:0] mm8_a, mm8_b;
    wire        mm8_done;
    wire [511:0] mm8_c;
    wire         mm8_ok;

    vsa_matmul_8x8 dut_mm8 (
        .clk      (clk),
        .rst_n    (rst_n),
        .start    (mm8_start),
        .a_flat   (mm8_a),
        .b_flat   (mm8_b),
        .done     (mm8_done),
        .c_flat   (mm8_c),
        .matmul_ok(mm8_ok)
    );

    // ---- DUT: gf16_dot4 (unchanged combinational — canonical 0x47C0 test) ----
    wire [15:0] dot4_result;
    gf16_dot4 dut_dot4 (
        .a0(16'h3E00), .a1(16'h4000), .a2(16'h4100), .a3(16'h4200),
        .b0(16'h3E00), .b1(16'h4000), .b2(16'h4100), .b3(16'h4200),
        .result(dot4_result)
    );

    // ---- Helper: send one vector pair to pc8, wait 3 cycles, check ----
    // Task sends valid_in for 1 cycle, then waits for valid_out at T+3
    task send_pc8_wait;
        input [15:0] a;
        input [15:0] b;
        begin
            @(posedge clk); #1;
            pc8_valid_in = 1;
            pc8_a = a;
            pc8_b = b;
            @(posedge clk); #1;   // T+1: s1 latched at T, now s2 combinational
            pc8_valid_in = 0;
            @(posedge clk); #1;   // T+2: s2 latched, s3 combinational
            @(posedge clk); #1;   // T+3: s3 latched → valid_out=1
        end
    endtask

    task check_pc8;
        input [63:0] name;
        input signed [7:0] expected;
        begin
            if (pc8_valid_out !== 1'b1) begin
                fail_count = fail_count + 1;
                $display("FAIL %0s: valid_out=0 (expected 1)", name);
            end else if ($signed(pc8_result) !== expected) begin
                fail_count = fail_count + 1;
                $display("FAIL %0s: got %0d expected %0d (valid_out=1)", name,
                         $signed(pc8_result), expected);
            end else begin
                pass_count = pass_count + 1;
                $display("PASS %0s: result=%0d valid_out=1", name, $signed(pc8_result));
            end
        end
    endtask

    task send_pc16_wait;
        input [31:0] a;
        input [31:0] b;
        begin
            @(posedge clk); #1;
            pc16_valid_in = 1;
            pc16_a = a;
            pc16_b = b;
            @(posedge clk); #1;
            pc16_valid_in = 0;
            @(posedge clk); #1;
            @(posedge clk); #1;
        end
    endtask

    task check_pc16;
        input [63:0] name;
        input signed [7:0] expected;
        begin
            if (pc16_valid_out !== 1'b1) begin
                fail_count = fail_count + 1;
                $display("FAIL %0s: valid_out=0 (expected 1)", name);
            end else if ($signed(pc16_result) !== expected) begin
                fail_count = fail_count + 1;
                $display("FAIL %0s: got %0d expected %0d", name,
                         $signed(pc16_result), expected);
            end else begin
                pass_count = pass_count + 1;
                $display("PASS %0s: result=%0d valid_out=1", name, $signed(pc16_result));
            end
        end
    endtask

    integer cycle, lat_cnt;
    reg lat_found;

    initial begin
        rst_n         = 0;
        pc8_valid_in  = 0;
        pc8_a         = 0;
        pc8_b         = 0;
        pc16_valid_in = 0;
        pc16_a        = 0;
        pc16_b        = 0;
        mm8_start     = 0;
        mm8_a         = 0;
        mm8_b         = 0;

        #25; @(posedge clk); rst_n = 1; #1;

        $display("=== L-S19 Pipeline Popcount Tests ===");

        // ---------------------------------------------------------------
        // T1: GF16 0x47C0 — canonical combinational dot4, unchanged path
        //     dot4([1,2,3,4],[1,2,3,4]) = 30.0 = 0x47C0
        //     Non-negotiable test vector.
        // ---------------------------------------------------------------
        if (dot4_result === 16'h47C0) begin
            pass_count = pass_count + 1;
            $display("PASS legacy_dot4_0x47C0: 0x47C0 = 30.0 UNCHANGED");
        end else begin
            fail_count = fail_count + 1;
            $display("FAIL legacy_dot4_0x47C0: got 0x%04h", dot4_result);
        end

        // ---------------------------------------------------------------
        // T2: pc8 — all +1 vs all +1 → result = +8
        //     Encoding 00 = +1. 8 elements × 00 → a_row = 16'h0000
        // ---------------------------------------------------------------
        send_pc8_wait(16'h0000, 16'h0000);
        check_pc8("pc8_all_pos", 8'sd8);

        // ---------------------------------------------------------------
        // T3: pc8 — all +1 vs all -1 → result = -8
        //     -1 encoding: 01. 8 × 01 → 16'h5555
        // ---------------------------------------------------------------
        send_pc8_wait(16'h0000, 16'h5555);
        check_pc8("pc8_pos_vs_neg", -8'sd8);

        // ---------------------------------------------------------------
        // T4: pc8 — all zero → result = 0
        //     0 encoding: 10. 8 × 10 → 16'hAAAA
        // ---------------------------------------------------------------
        send_pc8_wait(16'hAAAA, 16'hAAAA);
        check_pc8("pc8_all_zeros", 8'sd0);

        // ---------------------------------------------------------------
        // T5: pc8 — 4 same + 4 diff → result = 0
        //     a = all +1 (16'h0000)
        //     b = [+1,+1,+1,+1,-1,-1,-1,-1]:
        //       elem[0..3]=00, elem[4..7]=01
        //       b[7:0] = 00_00_00_00, b[15:8] = 01_01_01_01
        //       b = 16'b0101_0101_0000_0000 = 16'h5500
        // ---------------------------------------------------------------
        send_pc8_wait(16'h0000, 16'h5500);
        check_pc8("pc8_mixed_zero", 8'sd0);

        // ---------------------------------------------------------------
        // T6: pc8 — 6 same + 2 diff → result = +4
        //     a = all +1 (16'h0000)
        //     b = [+1,+1,+1,+1,+1,+1,-1,-1]:
        //       b[11:0]=00000000000, b[15:12]=01_01 = 0101
        //       b = 16'b0101_0000_0000_0000 = 16'h5000
        // ---------------------------------------------------------------
        send_pc8_wait(16'h0000, 16'h5000);
        check_pc8("pc8_6p2n", 8'sd4);

        // ---------------------------------------------------------------
        // T7: pc16 — all +1 vs all +1 → result = +16
        //     16 × 00 → a_row = 32'h00000000
        // ---------------------------------------------------------------
        send_pc16_wait(32'h00000000, 32'h00000000);
        check_pc16("pc16_all_pos", 8'sd16);

        // ---------------------------------------------------------------
        // T8: pc16 — all +1 vs all -1 → result = -16
        //     16 × 01 → 32'h55555555
        // ---------------------------------------------------------------
        send_pc16_wait(32'h00000000, 32'h55555555);
        check_pc16("pc16_pos_vs_neg", -8'sd16);

        // ---------------------------------------------------------------
        // T9: LATENCY verification — valid_out appears exactly 3 edges after valid_in
        // ---------------------------------------------------------------
        lat_found = 0;
        @(posedge clk); #1;
        pc8_valid_in = 1;
        pc8_a = 16'h0000;
        pc8_b = 16'h0000;
        @(posedge clk); #1;
        pc8_valid_in = 0;
        // Now count: at cycle 1 after de-assertion we are at T+2, T+3 is cycle 2
        for (lat_cnt = 1; lat_cnt <= 6; lat_cnt = lat_cnt + 1) begin
            @(posedge clk); #1;
            if (pc8_valid_out && !lat_found) begin
                if (lat_cnt == 2) begin
                    // valid_in was asserted at T, deasserted at T+1
                    // valid_out at T+3 = 2 cycles after deassertion
                    pass_count = pass_count + 1;
                    $display("PASS latency_3: valid_out at T+3 (LATENCY=3 cycles confirmed)");
                end else begin
                    fail_count = fail_count + 1;
                    $display("FAIL latency_3: valid_out appeared at unexpected offset %0d (want 2)", lat_cnt);
                end
                lat_found = 1;
            end
        end
        if (!lat_found) begin
            fail_count = fail_count + 1;
            $display("FAIL latency_3: valid_out never asserted");
        end

        // ---------------------------------------------------------------
        // T10: vsa_matmul_8x8 — all +1 input → all inner products = 8
        //      a_flat = b_flat = 0 (all 00 = +1 encoding)
        //      result[i][j] = sum_k +1*+1 = 8 for all (i,j)
        // ---------------------------------------------------------------
        @(posedge clk); #1;
        mm8_start = 1;
        mm8_a = 128'h0;
        mm8_b = 128'h0;
        @(posedge clk); #1;
        mm8_start = 0;
        // Wait for done — max 20 cycles
        begin
            reg mm8_got_done;
            mm8_got_done = 0;
            for (cycle = 0; cycle < 20; cycle = cycle + 1) begin
                @(posedge clk); #1;
                if (mm8_done && !mm8_got_done) begin
                    if ($signed(mm8_c[7:0]) === 8'sd8 && $signed(mm8_c[15:8]) === 8'sd8) begin
                        pass_count = pass_count + 1;
                        $display("PASS mm8_results: c[0][0]=%0d c[0][1]=%0d (all=8)",
                                 $signed(mm8_c[7:0]), $signed(mm8_c[15:8]));
                    end else begin
                        fail_count = fail_count + 1;
                        $display("FAIL mm8_results: c[0][0]=%0d c[0][1]=%0d (expected 8)",
                                 $signed(mm8_c[7:0]), $signed(mm8_c[15:8]));
                    end
                    if (mm8_ok) begin
                        pass_count = pass_count + 1;
                        $display("PASS mm8_ok: matmul_ok=1");
                    end else begin
                        fail_count = fail_count + 1;
                        $display("FAIL mm8_ok: matmul_ok=%0b", mm8_ok);
                    end
                    mm8_got_done = 1;
                    cycle = 999;
                end
            end
            if (!mm8_got_done) begin
                fail_count = fail_count + 1;
                $display("FAIL mm8_done: never asserted in 20 cycles");
            end
        end

        // ---------------------------------------------------------------
        // Summary
        // ---------------------------------------------------------------
        $display("=== Results: %0d pass, %0d fail ===", pass_count, fail_count);
        if (fail_count == 0)
            $display("ALL L-S19 PIPELINE TESTS PASSED");
        else
            $display("SOME L-S19 TESTS FAILED");
        $finish;
    end

    // Watchdog
    initial begin
        #100000;
        $display("WATCHDOG TIMEOUT");
        $finish;
    end

endmodule
