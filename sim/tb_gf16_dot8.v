// tb_gf16_dot8.v — iverilog testbench for L-S20 dot8 expansion
// Tests:
//   (A) 16 diverse vectors: gf16_dot8 == gf16_add(gf16_dot4(lo), gf16_dot4(hi))
//   (B) Canonical dot4 0x47C0 vector: dot4([1,2,3,4],[1,2,3,4]) == 0x47C0
//
// SPDX-License-Identifier: Apache-2.0
// EPIC: gHashTag/trinity-fpga#51 · DOI 10.5281/zenodo.19227877

`default_nettype none
`timescale 1ns/1ps

module tb_gf16_dot8;

    // -----------------------------------------------------------------------
    // Shared DUT wires
    // -----------------------------------------------------------------------
    reg  [15:0] a0, a1, a2, a3, a4, a5, a6, a7;
    reg  [15:0] b0, b1, b2, b3, b4, b5, b6, b7;

    // dot8 result
    wire [15:0] dot8_result;

    // Reference: two dot4s + one add (structural golden model)
    wire [15:0] ref_lo, ref_hi, ref_sum;

    // Canonical dot4 for 0x47C0 check
    wire [15:0] canon_result;

    // -----------------------------------------------------------------------
    // DUTs
    // -----------------------------------------------------------------------
    gf16_dot8 u_dut (
        .a0(a0), .a1(a1), .a2(a2), .a3(a3),
        .b0(b0), .b1(b1), .b2(b2), .b3(b3),
        .a4(a4), .a5(a5), .a6(a6), .a7(a7),
        .b4(b4), .b5(b5), .b6(b6), .b7(b7),
        .result(dot8_result)
    );

    // Reference lower half
    gf16_dot4 u_ref_lo (
        .a0(a0), .a1(a1), .a2(a2), .a3(a3),
        .b0(b0), .b1(b1), .b2(b2), .b3(b3),
        .result(ref_lo)
    );

    // Reference upper half
    gf16_dot4 u_ref_hi (
        .a0(a4), .a1(a5), .a2(a6), .a3(a7),
        .b0(b4), .b1(b5), .b2(b6), .b3(b7),
        .result(ref_hi)
    );

    // Reference accumulator
    gf16_add u_ref_acc (
        .a(ref_lo),
        .b(ref_hi),
        .result(ref_sum)
    );

    // Canonical dot4: dot4([1,2,3,4],[1,2,3,4]) = 30.0 = 0x47C0
    // Encoding: 1.0=0x3E00, 2.0=0x4000, 3.0=0x4100, 4.0=0x4200
    gf16_dot4 u_canon (
        .a0(16'h3E00), .a1(16'h4000), .a2(16'h4100), .a3(16'h4200),
        .b0(16'h3E00), .b1(16'h4000), .b2(16'h4100), .b3(16'h4200),
        .result(canon_result)
    );

    // -----------------------------------------------------------------------
    // Counters
    // -----------------------------------------------------------------------
    integer pass_cnt, fail_cnt;

    // -----------------------------------------------------------------------
    // Task: check one vector
    // -----------------------------------------------------------------------
    task check_vec;
        input integer tv;
        input [15:0] exp;
        begin
            #1; // let combinational settle
            if (dot8_result === exp) begin
                $display("PASS dot8_tv%0d: dot8=0x%04h ref=0x%04h", tv, dot8_result, exp);
                pass_cnt = pass_cnt + 1;
            end else begin
                $display("FAIL dot8_tv%0d: got=0x%04h expected=0x%04h (ref_lo=0x%04h ref_hi=0x%04h)",
                         tv, dot8_result, exp, ref_lo, ref_hi);
                fail_cnt = fail_cnt + 1;
            end
        end
    endtask

    initial begin
        pass_cnt = 0;
        fail_cnt = 0;

        $display("=== L-S20 dot8 expansion testbench ===");
        $display("--- Part B: canonical dot4 0x47C0 ---");

        // B: canonical dot4 unchanged
        #1;
        if (canon_result === 16'h47C0) begin
            $display("PASS dot4_canonical: 0x47C0 (30.0) [GF16 canonical preserved]");
            pass_cnt = pass_cnt + 1;
        end else begin
            $display("FAIL dot4_canonical: got=0x%04h expected=0x47C0", canon_result);
            fail_cnt = fail_cnt + 1;
        end

        $display("--- Part A: 16 dot8 vectors (golden = 2x dot4 + adder) ---");

        // ------------------------------------------------------------------
        // TV0
        // ------------------------------------------------------------------
        a0=16'h4000; a1=16'h3f00; a2=16'h4180; a3=16'h4080;
        a4=16'h4200; a5=16'h4380; a6=16'h4280; a7=16'h4100;
        b0=16'h4400; b1=16'h3a00; b2=16'h3d00; b3=16'h4300;
        b4=16'h3f80; b5=16'h3c00; b6=16'h3e00; b7=16'h3e80;
        #2; check_vec(0, ref_sum);

        // TV1
        a0=16'h4280; a1=16'h3f80; a2=16'h4380; a3=16'h4080;
        a4=16'h4200; a5=16'h3a00; a6=16'h3d00; a7=16'h4100;
        b0=16'h4400; b1=16'h4000; b2=16'h3c00; b3=16'h4300;
        b4=16'h3e80; b5=16'h3f00; b6=16'h4180; b7=16'h3e00;
        #2; check_vec(1, ref_sum);

        // TV2
        a0=16'h4000; a1=16'h4280; a2=16'h3d00; a3=16'h4080;
        a4=16'h3e80; a5=16'h4300; a6=16'h4380; a7=16'h3a00;
        b0=16'h4100; b1=16'h4180; b2=16'h3c00; b3=16'h3e00;
        b4=16'h4400; b5=16'h3f00; b6=16'h4200; b7=16'h3f80;
        #2; check_vec(2, ref_sum);

        // TV3
        a0=16'h3f00; a1=16'h4100; a2=16'h4180; a3=16'h4280;
        a4=16'h4080; a5=16'h3e80; a6=16'h3c00; a7=16'h4200;
        b0=16'h4400; b1=16'h4380; b2=16'h3a00; b3=16'h3e00;
        b4=16'h3f80; b5=16'h4300; b6=16'h4000; b7=16'h3d00;
        #2; check_vec(3, ref_sum);

        // TV4
        a0=16'h3a00; a1=16'h3e00; a2=16'h4300; a3=16'h3c00;
        a4=16'h4380; a5=16'h4280; a6=16'h4000; a7=16'h4200;
        b0=16'h3d00; b1=16'h4180; b2=16'h4400; b3=16'h4100;
        b4=16'h3f80; b5=16'h3e80; b6=16'h3f00; b7=16'h4080;
        #2; check_vec(4, ref_sum);

        // TV5
        a0=16'h4100; a1=16'h4400; a2=16'h3e00; a3=16'h3d00;
        a4=16'h3f00; a5=16'h3f80; a6=16'h3c00; a7=16'h4280;
        b0=16'h4000; b1=16'h4180; b2=16'h3a00; b3=16'h4200;
        b4=16'h4300; b5=16'h3e80; b6=16'h4080; b7=16'h4380;
        #2; check_vec(5, ref_sum);

        // TV6
        a0=16'h3c00; a1=16'h3f80; a2=16'h4300; a3=16'h3d00;
        a4=16'h4400; a5=16'h4100; a6=16'h4200; a7=16'h3f00;
        b0=16'h3a00; b1=16'h4000; b2=16'h4280; b3=16'h3e00;
        b4=16'h4180; b5=16'h4080; b6=16'h3e80; b7=16'h4380;
        #2; check_vec(6, ref_sum);

        // TV7
        a0=16'h3a00; a1=16'h4000; a2=16'h3e00; a3=16'h4300;
        a4=16'h3f80; a5=16'h4180; a6=16'h3c00; a7=16'h4100;
        b0=16'h4380; b1=16'h4400; b2=16'h4280; b3=16'h4200;
        b4=16'h3f00; b5=16'h3e80; b6=16'h4080; b7=16'h3d00;
        #2; check_vec(7, ref_sum);

        // TV8
        a0=16'h4180; a1=16'h4280; a2=16'h3d00; a3=16'h3e00;
        a4=16'h4100; a5=16'h4380; a6=16'h3f00; a7=16'h4400;
        b0=16'h3f80; b1=16'h3a00; b2=16'h4300; b3=16'h3c00;
        b4=16'h3e80; b5=16'h4000; b6=16'h4200; b7=16'h4080;
        #2; check_vec(8, ref_sum);

        // TV9
        a0=16'h4080; a1=16'h4180; a2=16'h4000; a3=16'h4400;
        a4=16'h4200; a5=16'h4380; a6=16'h3f80; a7=16'h4300;
        b0=16'h3e80; b1=16'h3e00; b2=16'h3f00; b3=16'h3c00;
        b4=16'h4280; b5=16'h4100; b6=16'h3a00; b7=16'h3d00;
        #2; check_vec(9, ref_sum);

        // TV10
        a0=16'h4180; a1=16'h3d00; a2=16'h3f00; a3=16'h4300;
        a4=16'h3f80; a5=16'h3c00; a6=16'h4280; a7=16'h3a00;
        b0=16'h3e80; b1=16'h4380; b2=16'h4080; b3=16'h4200;
        b4=16'h4400; b5=16'h3e00; b6=16'h4000; b7=16'h4100;
        #2; check_vec(10, ref_sum);

        // TV11
        a0=16'h4080; a1=16'h4200; a2=16'h4300; a3=16'h3f80;
        a4=16'h3a00; a5=16'h4280; a6=16'h4000; a7=16'h4180;
        b0=16'h4400; b1=16'h3c00; b2=16'h4100; b3=16'h3e80;
        b4=16'h3e00; b5=16'h3f00; b6=16'h4380; b7=16'h3d00;
        #2; check_vec(11, ref_sum);

        // TV12
        a0=16'h3c00; a1=16'h4080; a2=16'h3e00; a3=16'h3d00;
        a4=16'h4180; a5=16'h4300; a6=16'h4100; a7=16'h4400;
        b0=16'h3a00; b1=16'h3f00; b2=16'h3f80; b3=16'h4280;
        b4=16'h3e80; b5=16'h4380; b6=16'h4000; b7=16'h4200;
        #2; check_vec(12, ref_sum);

        // TV13
        a0=16'h3f80; a1=16'h4300; a2=16'h3c00; a3=16'h3d00;
        a4=16'h4400; a5=16'h4280; a6=16'h3e00; a7=16'h3e80;
        b0=16'h4080; b1=16'h4200; b2=16'h4000; b3=16'h3f00;
        b4=16'h4380; b5=16'h4100; b6=16'h4180; b7=16'h3a00;
        #2; check_vec(13, ref_sum);

        // TV14
        a0=16'h4080; a1=16'h4100; a2=16'h4200; a3=16'h4280;
        a4=16'h3f00; a5=16'h4000; a6=16'h3a00; a7=16'h4300;
        b0=16'h3f80; b1=16'h4400; b2=16'h3e00; b3=16'h3c00;
        b4=16'h3e80; b5=16'h4380; b6=16'h3d00; b7=16'h4180;
        #2; check_vec(14, ref_sum);

        // TV15
        a0=16'h4080; a1=16'h3e80; a2=16'h3c00; a3=16'h4280;
        a4=16'h4380; a5=16'h3d00; a6=16'h4100; a7=16'h3f80;
        b0=16'h4180; b1=16'h4400; b2=16'h3f00; b3=16'h4200;
        b4=16'h4300; b5=16'h3e00; b6=16'h3a00; b7=16'h4000;
        #2; check_vec(15, ref_sum);

        // ------------------------------------------------------------------
        // Summary
        // ------------------------------------------------------------------
        $display("===================================");
        $display("dot8 vectors : %0d/16 PASS", pass_cnt - (fail_cnt > 0 ? 0 : 1) + (canon_result === 16'h47C0 ? 0 : 0));
        $display("TOTAL PASS=%0d  FAIL=%0d", pass_cnt, fail_cnt);
        if (fail_cnt == 0)
            $display("ALL PASS");
        else
            $display("FAILURES DETECTED");
        $finish;
    end

endmodule
