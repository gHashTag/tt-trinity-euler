`default_nettype none
`timescale 1ns/1ps
// tb_gf16_mesh_2x2.v — L-S38 TTSKY26c 2×2 GF16 mesh testbench
// Apache-2.0
//
// GF16 = 16-bit mini-float: 1-sign, 6-exp (bias=31), 9-mant.
//
// Test plan (60 minimum, 100% PASS required):
//   T01..T04  : 4 tile-local smoke tests — each tile produces 0x47C0 from canonical vectors
//                 a={1.0,2.0,3.0,4.0} b={1.0,2.0,3.0,4.0} → dot4=30.0=0x47C0
//   T05..T54  : 50 LFSR-driven random mesh traffic tests, result vs SW reference model
//   T55..T60  : 6 deterministic NoC handshake patterns (N/S/E/W boundary req/ack)
//
// Token: GF16_MESH_2X2_GREEN printed on 100% PASS.
// Anchor: φ²+φ⁻²=3 DOI 10.5281/zenodo.19227877 TTSKY26c WAVE10A L-S38
// LFSR: 32-bit Galois poly 0x80000057 (shifts only, no `*`)

`include "trinity_packet.vh"

module tb_gf16_mesh_2x2;

    // =========================================================================
    // Clock + reset
    // =========================================================================
    reg clk, rst_n;
    initial clk = 1'b0;
    always #5 clk = ~clk;

    integer pass_cnt, fail_cnt, test_num;
    initial begin
        pass_cnt = 0;
        fail_cnt = 0;
        test_num = 0;
    end

    // =========================================================================
    // DUT
    // =========================================================================
    reg  [`TRN_PKT_W-1:0] host_in_pkt;
    reg                   host_in_valid;
    wire                  host_in_ready;
    wire [`TRN_PKT_W-1:0] host_out_pkt;
    wire                  host_out_valid;
    reg                   host_out_ready;

    reg  [3:0] noc_north_flit_in, noc_south_flit_in;
    reg  [3:0] noc_east_flit_in,  noc_west_flit_in;
    reg        noc_north_req_in,  noc_south_req_in;
    reg        noc_east_req_in,   noc_west_req_in;
    wire       noc_north_ack_out, noc_south_ack_out;
    wire       noc_east_ack_out,  noc_west_ack_out;
    wire [3:0] noc_north_flit_out, noc_south_flit_out;
    wire [3:0] noc_east_flit_out,  noc_west_flit_out;
    wire       noc_north_req_out,  noc_south_req_out;
    wire       noc_east_req_out,   noc_west_req_out;
    reg        noc_north_ack_in,  noc_south_ack_in;
    reg        noc_east_ack_in,   noc_west_ack_in;
    wire [15:0] dbg0, dbg1, dbg2, dbg3;

    gf16_mesh_2x2_top u_dut (
        .clk (clk), .rst_n (rst_n),
        .host_in_pkt (host_in_pkt), .host_in_valid (host_in_valid), .host_in_ready (host_in_ready),
        .host_out_pkt(host_out_pkt), .host_out_valid(host_out_valid), .host_out_ready(host_out_ready),
        .noc_north_flit_in(noc_north_flit_in), .noc_north_req_in(noc_north_req_in),
        .noc_north_ack_out(noc_north_ack_out),
        .noc_north_flit_out(noc_north_flit_out), .noc_north_req_out(noc_north_req_out),
        .noc_north_ack_in(noc_north_ack_in),
        .noc_south_flit_in(noc_south_flit_in), .noc_south_req_in(noc_south_req_in),
        .noc_south_ack_out(noc_south_ack_out),
        .noc_south_flit_out(noc_south_flit_out), .noc_south_req_out(noc_south_req_out),
        .noc_south_ack_in(noc_south_ack_in),
        .noc_east_flit_in(noc_east_flit_in), .noc_east_req_in(noc_east_req_in),
        .noc_east_ack_out(noc_east_ack_out),
        .noc_east_flit_out(noc_east_flit_out), .noc_east_req_out(noc_east_req_out),
        .noc_east_ack_in(noc_east_ack_in),
        .noc_west_flit_in(noc_west_flit_in), .noc_west_req_in(noc_west_req_in),
        .noc_west_ack_out(noc_west_ack_out),
        .noc_west_flit_out(noc_west_flit_out), .noc_west_req_out(noc_west_req_out),
        .noc_west_ack_in(noc_west_ack_in),
        .dbg_tile0_result(dbg0), .dbg_tile1_result(dbg1),
        .dbg_tile2_result(dbg2), .dbg_tile3_result(dbg3)
    );

    // Always-ready host: prevents back-pressure on returning tiles
    initial host_out_ready = 1'b1;

    // =========================================================================
    // Receive buffer — collects host_out packets as they arrive
    // =========================================================================
    reg [`TRN_PKT_W-1:0] rxbuf [0:255];
    reg [7:0] rxhead = 0, rxtail = 0;

    always @(posedge clk) begin
        if (host_out_valid && host_out_ready) begin
            rxbuf[rxhead] <= host_out_pkt;
            rxhead        <= rxhead + 8'h1;
        end
    end

    task rxbuf_get;
        output [`TRN_PKT_W-1:0] pkt;
        integer timeout;
        begin
            timeout = 0;
            while (rxtail == rxhead && timeout < 3000) begin
                @(posedge clk);
                timeout = timeout + 1;
            end
            pkt    = rxbuf[rxtail];
            rxtail = rxtail + 8'h1;
        end
    endtask

    // =========================================================================
    // LFSR — 32-bit Galois poly 0x80000057 (no `*`, shifts only)
    // =========================================================================
    reg [31:0] lfsr;

    task lfsr_tick;
        integer lsb;
        begin
            lsb  = lfsr[0];
            lfsr = lfsr >> 1;
            if (lsb) lfsr = lfsr ^ 32'h80000057;
        end
    endtask

    // =========================================================================
    // send_pkt: drive valid packet for one cycle, wait for host_in_ready
    // =========================================================================
    task send_pkt;
        input [`TRN_PKT_W-1:0] pkt;
        integer timeout;
        begin
            // Drive on negedge so values are stable well before the next posedge
            @(negedge clk);
            host_in_pkt   = pkt;
            host_in_valid = 1'b1;
            @(posedge clk);              // packet presented at this edge
            timeout = 0;
            while (!host_in_ready && timeout < 500) begin
                @(posedge clk);
                timeout = timeout + 1;
            end
            // Deassert after the accepting edge
            @(negedge clk);
            host_in_valid = 1'b0;
            host_in_pkt   = {`TRN_PKT_W{1'b0}};
        end
    endtask

    // Load 4 operand lanes into a tile
    task load_tile;
        input [1:0] tile;
        input [15:0] a0, a1, a2, a3, b0, b1, b2, b3;
        begin
            send_pkt(`TRN_MK_PKT(`TRN_OP_LOAD_A, tile, 2'b00, 4'd0, a0));
            send_pkt(`TRN_MK_PKT(`TRN_OP_LOAD_A, tile, 2'b00, 4'd1, a1));
            send_pkt(`TRN_MK_PKT(`TRN_OP_LOAD_A, tile, 2'b00, 4'd2, a2));
            send_pkt(`TRN_MK_PKT(`TRN_OP_LOAD_A, tile, 2'b00, 4'd3, a3));
            send_pkt(`TRN_MK_PKT(`TRN_OP_LOAD_B, tile, 2'b00, 4'd0, b0));
            send_pkt(`TRN_MK_PKT(`TRN_OP_LOAD_B, tile, 2'b00, 4'd1, b1));
            send_pkt(`TRN_MK_PKT(`TRN_OP_LOAD_B, tile, 2'b00, 4'd2, b2));
            send_pkt(`TRN_MK_PKT(`TRN_OP_LOAD_B, tile, 2'b00, 4'd3, b3));
        end
    endtask

    // COMPUTE + READ_RES: drain RESULT + RECEIPT packets, return RESULT payload
    task tile_run;
        input  [1:0]  tile;
        output [15:0] result;
        reg [`TRN_PKT_W-1:0] rpkt;
        begin
            send_pkt(`TRN_MK_PKT(`TRN_OP_COMPUTE,  tile, 2'b00, 4'd0, 16'h0));
            @(posedge clk); @(posedge clk);
            send_pkt(`TRN_MK_PKT(`TRN_OP_READ_RES, tile, 2'b00, 4'd0, 16'h0));
            rxbuf_get(rpkt);           // RESULT
            result = `TRN_PKT_PAYLOAD(rpkt);
            rxbuf_get(rpkt);           // RECEIPT (discard)
        end
    endtask

    // check helper
    task check;
        input        cond;
        input [63:0] tnum;
        input [255:0] label;
        begin
            if (cond) begin
                $display("PASS T%0d %s", tnum, label);
                pass_cnt = pass_cnt + 1;
            end else begin
                $display("FAIL T%0d %s", tnum, label);
                fail_cnt = fail_cnt + 1;
            end
        end
    endtask

    // =========================================================================
    // GF16 mini-float SW reference model
    // Format: [15]=sign, [14:9]=exp (bias=31), [8:0]=mant (implied 1. prefix)
    // =========================================================================
    localparam integer GF16_BIAS = 31;
    localparam integer GF16_EXP_MAX = 63;

    function [15:0] gf16_mul_ref;
        input [15:0] a, b;
        reg        sa, sb, sr;
        reg [5:0]  ea, eb;
        reg [8:0]  ma, mb;
        reg        za, zb, ia, ib, na_f, nb_f;
        reg [9:0]  fa, fb;
        reg [19:0] prod;
        reg [6:0]  raw_exp;
        reg [8:0]  mant_out;
        reg        g, r, s;
        reg [8:0]  mrnd;
        reg [6:0]  fexp;
        reg [8:0]  fmnt;
        begin
            sa = a[15]; ea = a[14:9]; ma = a[8:0];
            sb = b[15]; eb = b[14:9]; mb = b[8:0];
            sr = sa ^ sb;
            za = (ea == 0) && (ma == 0);
            zb = (eb == 0) && (mb == 0);
            ia = (ea == GF16_EXP_MAX) && (ma == 0);
            ib = (eb == GF16_EXP_MAX) && (mb == 0);
            na_f = (ea == GF16_EXP_MAX) && (ma != 0);
            nb_f = (eb == GF16_EXP_MAX) && (mb != 0);
            if (na_f || nb_f)
                gf16_mul_ref = 16'hFE01;
            else if ((za && ib) || (ia && zb))
                gf16_mul_ref = 16'hFE01;
            else if (za || zb)
                gf16_mul_ref = sr ? 16'h8000 : 16'h0000;
            else if (ia || ib)
                gf16_mul_ref = sr ? 16'hFE00 : 16'h7E00;
            else begin
                fa = {1'b1, ma};
                fb = {1'b1, mb};
                prod = fa * fb;
                raw_exp = {1'b0, ea} + {1'b0, eb} - GF16_BIAS;
                if (prod[19]) begin
                    raw_exp = raw_exp + 1;
                    mant_out = prod[18:10]; g = prod[9]; r = prod[8]; s = |prod[7:0];
                end else if (prod[18]) begin
                    mant_out = prod[17:9]; g = prod[8]; r = prod[7]; s = |prod[6:0];
                end else if (prod[17]) begin
                    raw_exp = raw_exp - 1;
                    mant_out = prod[16:8]; g = prod[7]; r = prod[6]; s = |prod[5:0];
                end else begin
                    raw_exp = raw_exp - 2;
                    mant_out = prod[15:7]; g = prod[6]; r = prod[5]; s = |prod[4:0];
                end
                mrnd = (g && (r || s)) ? mant_out + 1 : mant_out;
                if (mrnd[9]) begin fexp = raw_exp + 1; fmnt = 0; end
                else         begin fexp = raw_exp;     fmnt = mrnd; end
                if (fexp[6])
                    gf16_mul_ref = sr ? 16'h8000 : 16'h0000;
                else if (fexp[5:0] >= GF16_EXP_MAX)
                    gf16_mul_ref = sr ? 16'hFE00 : 16'h7E00;
                else
                    gf16_mul_ref = {sr, fexp[5:0], fmnt};
            end
        end
    endfunction

    function [15:0] gf16_add_ref;
        input [15:0] a, b;
        reg        sa, sb, sr, big_s, sm_s, cancel;
        reg [5:0]  ea, eb;
        reg [8:0]  ma, mb;
        reg        za, zb, ia, ib, na_f, nb_f, al;
        reg [6:0]  big_exp, shift, res_exp, fexp;
        reg [10:0] big_fm, sm_fm;
        reg [11:0] sum_m;
        reg [9:0]  norm, rnd;
        reg        g_b, r_b, s_b;
        reg [8:0]  fmnt;
        reg [15:0] fr;
        begin
            sa = a[15]; ea = a[14:9]; ma = a[8:0];
            sb = b[15]; eb = b[14:9]; mb = b[8:0];
            za = (ea == 0) && (ma == 0);
            zb = (eb == 0) && (mb == 0);
            ia = (ea == GF16_EXP_MAX) && (ma == 0);
            ib = (eb == GF16_EXP_MAX) && (mb == 0);
            na_f = (ea == GF16_EXP_MAX) && (ma != 0);
            nb_f = (eb == GF16_EXP_MAX) && (mb != 0);
            if (na_f || nb_f)
                gf16_add_ref = 16'hFE01;
            else if (ia && ib && (sa != sb))
                gf16_add_ref = 16'hFE01;
            else if (ia) gf16_add_ref = a;
            else if (ib) gf16_add_ref = b;
            else if (za && zb) gf16_add_ref = 16'h0000;
            else if (za) gf16_add_ref = b;
            else if (zb) gf16_add_ref = a;
            else begin
                al = (ea > eb) || ((ea == eb) && (ma >= mb));
                cancel = 0;
                if (al) begin
                    big_exp = {1'b0,ea}; big_fm = {1'b1,ma}; big_s = sa;
                    sm_fm   = {1'b1,mb}; sm_s  = sb;
                    shift   = {1'b0,ea} - {1'b0,eb};
                end else begin
                    big_exp = {1'b0,eb}; big_fm = {1'b1,mb}; big_s = sb;
                    sm_fm   = {1'b1,ma}; sm_s  = sa;
                    shift   = {1'b0,eb} - {1'b0,ea};
                end
                res_exp = big_exp;
                case (shift)
                    0:  ;
                    1:  sm_fm = {1'b0, sm_fm[10:1]};
                    2:  sm_fm = {2'b00, sm_fm[10:2]};
                    3:  sm_fm = {3'b000, sm_fm[10:3]};
                    4:  sm_fm = {4'b0000, sm_fm[10:4]};
                    5:  sm_fm = {5'b00000, sm_fm[10:5]};
                    6:  sm_fm = {6'b000000, sm_fm[10:6]};
                    7:  sm_fm = {7'b0000000, sm_fm[10:7]};
                    8:  sm_fm = {8'b00000000, sm_fm[10:8]};
                    9:  sm_fm = {9'b000000000, sm_fm[10:9]};
                    10: sm_fm = {10'b0000000000, sm_fm[10]};
                    default: sm_fm = 11'h0;
                endcase
                if (big_s == sm_s) begin
                    sum_m = {1'b0,big_fm} + {1'b0,sm_fm};
                    sr    = big_s;
                end else begin
                    sum_m = {1'b0,big_fm} - {1'b0,sm_fm};
                    sr    = big_s;
                    if (sum_m == 0) cancel = 1;
                end
                if (!cancel) begin
                    g_b = 0; r_b = 0; s_b = 0;
                    if (sum_m[11]) begin
                        res_exp = res_exp + 1; norm = sum_m[10:1]; g_b = sum_m[0];
                    end else if (sum_m[10]) begin
                        res_exp = res_exp + 1; norm = sum_m[10:1]; g_b = sum_m[0];
                    end else begin
                        if      (sum_m[9]) norm = sum_m[9:0];
                        else if (sum_m[8]) begin norm = {sum_m[8:0],1'b0}; res_exp=res_exp-1; end
                        else if (sum_m[7]) begin norm = {sum_m[7:0],2'b00}; res_exp=res_exp-2; end
                        else if (sum_m[6]) begin norm = {sum_m[6:0],3'b000}; res_exp=res_exp-3; end
                        else if (sum_m[5]) begin norm = {sum_m[5:0],4'b0000}; res_exp=res_exp-4; end
                        else if (sum_m[4]) begin norm = {sum_m[4:0],5'b00000}; res_exp=res_exp-5; end
                        else if (sum_m[3]) begin norm = {sum_m[3:0],6'b000000}; res_exp=res_exp-6; end
                        else if (sum_m[2]) begin norm = {sum_m[2:0],7'b0000000}; res_exp=res_exp-7; end
                        else if (sum_m[1]) begin norm = {sum_m[1:0],8'b00000000}; res_exp=res_exp-8; end
                        else               begin norm = {sum_m[0],9'b000000000}; res_exp=res_exp-9; end
                    end
                    rnd = (g_b && (r_b || s_b)) ? norm + 1 : norm;
                    if (rnd < norm) begin fexp = res_exp + 1; fmnt = 0; end
                    else            begin fexp = res_exp;     fmnt = norm[8:0]; end
                    if (fexp[6])              fr = sr ? 16'h8000 : 16'h0000;
                    else if (fexp[5:0] >= GF16_EXP_MAX) fr = sr ? 16'hFE00 : 16'h7E00;
                    else                      fr = {sr, fexp[5:0], fmnt};
                    gf16_add_ref = fr;
                end else
                    gf16_add_ref = 16'h0000;
            end
        end
    endfunction

    function [15:0] dot4_ref;
        input [15:0] a0, a1, a2, a3;
        input [15:0] b0, b1, b2, b3;
        reg [15:0] p0, p1, p2, p3, s01, s23;
        begin
            p0  = gf16_mul_ref(a0, b0);
            p1  = gf16_mul_ref(a1, b1);
            p2  = gf16_mul_ref(a2, b2);
            p3  = gf16_mul_ref(a3, b3);
            s01 = gf16_add_ref(p0, p1);
            s23 = gf16_add_ref(p2, p3);
            dot4_ref = gf16_add_ref(s01, s23);
        end
    endfunction

    // Helper: make a GF16 mini-float from a simple positive integer value [0..127]
    // value must be a power of 2 for exact representation with mant=0
    // For val >= 1: exp = bias + log2(val), mant based on fractional part
    // We use fixed vectors from the codebase for canonical test.

    // =========================================================================
    // GF16 constants
    // =========================================================================
    localparam [15:0] GF16_0 = 16'h0000;
    localparam [15:0] GF16_1 = 16'h3E00;  // 1.0: exp=31=bias+0, mant=0
    localparam [15:0] GF16_2 = 16'h4000;  // 2.0: exp=32=bias+1, mant=0
    localparam [15:0] GF16_3 = 16'h4100;  // 3.0: exp=32, mant=0x100 (1.5*2=3)
    localparam [15:0] GF16_4 = 16'h4200;  // 4.0: exp=33=bias+2, mant=0

    // LFSR-friendly mini-floats: 8 representative small values
    // These cover various exponent values to give diverse random dot4 results
    localparam [15:0] GF16_VEC0 = 16'h3E00; // 1.0
    localparam [15:0] GF16_VEC1 = 16'h4000; // 2.0
    localparam [15:0] GF16_VEC2 = 16'h4100; // 3.0
    localparam [15:0] GF16_VEC3 = 16'h4200; // 4.0
    localparam [15:0] GF16_VEC4 = 16'h4300; // 6.0
    localparam [15:0] GF16_VEC5 = 16'h4400; // 8.0
    localparam [15:0] GF16_VEC6 = 16'h4500; // 12.0
    localparam [15:0] GF16_VEC7 = 16'h4600; // 16.0

    // Lookup from 3-bit LFSR nibble to GF16 vector value
    function [15:0] lfsr_to_gf16;
        input [2:0] bits;
        begin
            case (bits)
                3'd0: lfsr_to_gf16 = GF16_VEC0;
                3'd1: lfsr_to_gf16 = GF16_VEC1;
                3'd2: lfsr_to_gf16 = GF16_VEC2;
                3'd3: lfsr_to_gf16 = GF16_VEC3;
                3'd4: lfsr_to_gf16 = GF16_VEC4;
                3'd5: lfsr_to_gf16 = GF16_VEC5;
                3'd6: lfsr_to_gf16 = GF16_VEC6;
                default: lfsr_to_gf16 = GF16_VEC7;
            endcase
        end
    endfunction

    // =========================================================================
    // MAIN TEST SEQUENCE
    // =========================================================================
    integer ti;
    reg [15:0] got_result, exp_result;
    reg [15:0] ra0, ra1, ra2, ra3, rb0, rb1, rb2, rb3;
    reg [`TRN_PKT_W-1:0] rr_pkt;

    initial begin
        host_in_pkt       = {`TRN_PKT_W{1'b0}};
        host_in_valid     = 1'b0;
        noc_north_flit_in = 4'h0; noc_north_req_in = 1'b0; noc_north_ack_in = 1'b0;
        noc_south_flit_in = 4'h0; noc_south_req_in = 1'b0; noc_south_ack_in = 1'b0;
        noc_east_flit_in  = 4'h0; noc_east_req_in  = 1'b0; noc_east_ack_in  = 1'b0;
        noc_west_flit_in  = 4'h0; noc_west_req_in  = 1'b0; noc_west_ack_in  = 1'b0;
        lfsr = 32'hACE1_CAFE;

        rst_n = 1'b0;
        repeat(8) @(posedge clk);
        rst_n = 1'b1;
        repeat(4) @(posedge clk);

        // ==============================================================
        // SECTION 1: Tile-local smoke tests T01..T04
        // Canonical vectors: a=b={1.0,2.0,3.0,4.0} → dot4=30.0=0x47C0
        // ==============================================================
        $display("=== SECTION 1: Tile-local dot4 smoke tests ===");
        for (ti = 0; ti < 4; ti = ti + 1) begin
            test_num = ti + 1;
            load_tile(ti[1:0], GF16_1, GF16_2, GF16_3, GF16_4,
                               GF16_1, GF16_2, GF16_3, GF16_4);
            tile_run(ti[1:0], got_result);
            check(got_result == 16'h47C0, test_num, "tile dot4(1,2,3,4)^2 == 0x47C0");
        end

        // ==============================================================
        // SECTION 2: 50 LFSR random mesh traffic tests T05..T54
        // Use mini-float vectors chosen from GF16_VEC table to ensure
        // meaningful non-special results.
        // ==============================================================
        $display("=== SECTION 2: LFSR random mesh traffic (50 tests) ===");
        for (ti = 0; ti < 50; ti = ti + 1) begin : blk_lfsr
            reg [1:0] tile_sel;
            test_num = ti + 5;
            // Advance LFSR and pick vectors from table
            lfsr_tick; ra0 = lfsr_to_gf16(lfsr[2:0]);
            lfsr_tick; ra1 = lfsr_to_gf16(lfsr[2:0]);
            lfsr_tick; ra2 = lfsr_to_gf16(lfsr[2:0]);
            lfsr_tick; ra3 = lfsr_to_gf16(lfsr[2:0]);
            lfsr_tick; rb0 = lfsr_to_gf16(lfsr[2:0]);
            lfsr_tick; rb1 = lfsr_to_gf16(lfsr[2:0]);
            lfsr_tick; rb2 = lfsr_to_gf16(lfsr[2:0]);
            lfsr_tick; rb3 = lfsr_to_gf16(lfsr[2:0]);
            lfsr_tick; tile_sel = lfsr[1:0];

            load_tile(tile_sel, ra0, ra1, ra2, ra3, rb0, rb1, rb2, rb3);
            tile_run(tile_sel, got_result);

            exp_result = dot4_ref(ra0, ra1, ra2, ra3, rb0, rb1, rb2, rb3);
            check(got_result == exp_result, test_num, "LFSR dot4 == SW ref");
        end

        // ==============================================================
        // SECTION 3: 6 NoC handshake tests T55..T60
        // ==============================================================
        $display("=== SECTION 3: NoC handshake patterns (6 tests) ===");

        // T55: North req → ack (combinational)
        test_num = 55;
        @(negedge clk);
        noc_north_flit_in = 4'hA; noc_north_req_in = 1'b1;
        #1;
        check(noc_north_ack_out === 1'b1, test_num, "NoC North req->ack");
        @(posedge clk); @(negedge clk);
        noc_north_req_in = 1'b0;
        @(posedge clk);

        // T56: South req → ack
        test_num = 56;
        @(negedge clk);
        noc_south_flit_in = 4'hB; noc_south_req_in = 1'b1;
        #1;
        check(noc_south_ack_out === 1'b1, test_num, "NoC South req->ack");
        @(posedge clk); @(negedge clk);
        noc_south_req_in = 1'b0;
        @(posedge clk);

        // T57: East req → ack
        test_num = 57;
        @(negedge clk);
        noc_east_flit_in = 4'hC; noc_east_req_in = 1'b1;
        #1;
        check(noc_east_ack_out === 1'b1, test_num, "NoC East req->ack");
        @(posedge clk); @(negedge clk);
        noc_east_req_in = 1'b0;
        @(posedge clk);

        // T58: West req → ack
        test_num = 58;
        @(negedge clk);
        noc_west_flit_in = 4'hD; noc_west_req_in = 1'b1;
        #1;
        check(noc_west_ack_out === 1'b1, test_num, "NoC West req->ack");
        @(posedge clk); @(negedge clk);
        noc_west_req_in = 1'b0;
        @(posedge clk);

        // T59: Round-robin mutual exclusion — simultaneous N/S/E/W, at most 1 ack
        test_num = 59;
        begin
            reg [3:0] acks_sum;
            @(negedge clk);
            noc_north_flit_in=4'h1; noc_north_req_in=1'b1;
            noc_south_flit_in=4'h2; noc_south_req_in=1'b1;
            noc_east_flit_in =4'h3; noc_east_req_in =1'b1;
            noc_west_flit_in =4'h4; noc_west_req_in =1'b1;
            #1;
            acks_sum = {noc_north_ack_out, noc_south_ack_out,
                        noc_east_ack_out,  noc_west_ack_out};
            check((acks_sum==4'b1000)||(acks_sum==4'b0100)||
                  (acks_sum==4'b0010)||(acks_sum==4'b0001)||
                  (acks_sum==4'b0000), test_num, "NoC RR at-most-1-ack");
            @(posedge clk); @(negedge clk);
            noc_north_req_in=1'b0; noc_south_req_in=1'b0;
            noc_east_req_in =1'b0; noc_west_req_in =1'b0;
            @(posedge clk);
        end

        // T60: Flit passthrough integrity
        // Assert North req; RR will select it within 4 cycles.
        // The hold register captures flit_in=0xF and holds it on flit_out.
        // Check: flit_out == 0xF at some point during the request window.
        test_num = 60;
        begin : blk_t60
            integer t60_cy;
            reg     t60_pass;
            t60_pass = 1'b0;
            @(negedge clk);
            noc_north_flit_in = 4'hF;
            noc_north_req_in  = 1'b1;
            noc_north_ack_in  = 1'b0;
            // Keep req active for up to 8 cycles, sample flit_out each negedge
            for (t60_cy = 0; t60_cy < 8; t60_cy = t60_cy + 1) begin
                @(posedge clk); @(negedge clk);
                // flit_out = hold_q which is updated at posedge
                // After the posedge that selected North, hold_q=0xF
                if (noc_north_flit_out === 4'hF) t60_pass = 1'b1;
            end
            noc_north_req_in  = 1'b0;
            @(posedge clk);
            check(t60_pass, test_num, "NoC flit passthrough 0xF");
        end

        // ==============================================================
        // SUMMARY
        // ==============================================================
        $display("");
        $display("========================================");
        $display("MESH 2x2 SIM: %0d PASS / %0d FAIL (total %0d)", pass_cnt, fail_cnt, pass_cnt+fail_cnt);
        if (fail_cnt == 0 && pass_cnt >= 60) begin
            $display("GF16_MESH_2X2_GREEN");
            $display("sim_token: GF16_MESH_2X2_GREEN");
        end else begin
            $display("GF16_MESH_2X2_RED — %0d failure(s), %0d/%0d pass", fail_cnt, pass_cnt, pass_cnt+fail_cnt);
        end
        $display("========================================");
        $finish;
    end

    initial begin
        #10000000;
        $display("WATCHDOG TIMEOUT — GF16_MESH_2X2_RED");
        $finish;
    end

endmodule
