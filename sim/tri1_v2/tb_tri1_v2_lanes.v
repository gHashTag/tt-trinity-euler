`default_nettype none
`timescale 1ns/1ps
// tb_tri1_v2_lanes.v — Testbench for 6 LOW-complexity TRI-1 v2 lanes
// Apache-2.0
//
// Tests L-S22 plrm_counter, L-S23 cassini_post, L-S24 nca_entropy_monitor,
//       L-S28 strobe_seed_guard, L-S32 phi_distance_oracle, L-S33 bpb_lower_bound_guard.

module tb_tri1_v2_lanes;

    reg clk, rst_n;
    initial clk = 0;
    always #5 clk = ~clk;  // 100 MHz sim clock

    integer pass, fail;
    initial begin pass = 0; fail = 0; end

    // ============================================================
    // L-S22 PLRM COUNTER — mutual exclusion
    // ============================================================
    reg  plrm_req_arith, plrm_req_orch;
    wire plrm_grant_arith, plrm_grant_orch, plrm_error;
    plrm_counter u_plrm (
        .clk(clk), .rst_n(rst_n),
        .req_arith(plrm_req_arith), .req_orch(plrm_req_orch),
        .grant_arith(plrm_grant_arith), .grant_orch(plrm_grant_orch),
        .plrm_error(plrm_error)
    );

    // ============================================================
    // L-S23 CASSINI POST
    // ============================================================
    wire cassini_ok, cassini_done;
    cassini_post u_cassini (.clk(clk), .rst_n(rst_n),
        .cassini_ok(cassini_ok), .post_done(cassini_done));

    // ============================================================
    // L-S24 NCA ENTROPY MONITOR
    // ============================================================
    reg  [161:0] nca_trits;
    reg          nca_sample;
    wire         nca_violation, nca_in_band;
    wire [6:0]   nca_popcount;
    nca_entropy_monitor u_nca (
        .clk(clk), .rst_n(rst_n),
        .trits_in(nca_trits), .sample(nca_sample),
        .entropy_violation(nca_violation), .in_band(nca_in_band),
        .last_popcount(nca_popcount)
    );

    // ============================================================
    // L-S28 STROBE SEED GUARD
    // ============================================================
    reg  [31:0] seed_in;
    reg         seed_write;
    wire [31:0] seed_out;
    wire        seed_forbidden, seed_replaced;
    strobe_seed_guard u_seed (
        .clk(clk), .rst_n(rst_n),
        .seed_in(seed_in), .seed_write(seed_write),
        .seed_out(seed_out),
        .seed_forbidden(seed_forbidden), .seed_replaced(seed_replaced)
    );

    // ============================================================
    // L-S32 PHI DISTANCE ORACLE
    // ============================================================
    reg  [8:0]  phi_angle;
    reg         phi_valid_in;
    wire [15:0] phi_dist;
    wire        phi_valid_out;
    phi_distance_oracle u_phi (
        .clk(clk), .rst_n(rst_n),
        .angle_deg(phi_angle), .valid_in(phi_valid_in),
        .dist_out(phi_dist), .valid_out(phi_valid_out)
    );

    // ============================================================
    // L-S33 BPB LOWER BOUND GUARD
    // ============================================================
    reg signed [31:0] bpb_q24, floor_q24;
    reg               bpb_sample;
    wire              bpb_violation_pulse, bpb_sticky;
    wire [1:0]        bpb_fault;
    bpb_lower_bound_guard u_bpb (
        .clk(clk), .rst_n(rst_n),
        .bpb_q24(bpb_q24), .floor_q24(floor_q24),
        .sample(bpb_sample),
        .bpb_violation(bpb_violation_pulse),
        .sticky_violation(bpb_sticky),
        .fault_code(bpb_fault)
    );

    // ============================================================
    // CHECK macro
    // ============================================================
    task automatic check(input integer cond, input [255:0] name);
        begin
            if (cond) begin
                $display("[PASS] %0s", name);
                pass = pass + 1;
            end else begin
                $display("[FAIL] %0s", name);
                fail = fail + 1;
            end
        end
    endtask

    // ============================================================
    // MAIN TEST SEQUENCE
    // ============================================================
    integer i;
    initial begin
        // Init
        rst_n = 0;
        plrm_req_arith = 0; plrm_req_orch = 0;
        nca_trits = 162'd0; nca_sample = 0;
        seed_in = 0; seed_write = 0;
        phi_angle = 0; phi_valid_in = 0;
        bpb_q24 = 32'sd0; floor_q24 = 32'sd0; bpb_sample = 0;
        #20 rst_n = 1;
        #10;

        // ---------------- L-S22 PLRM ----------------
        $display("=== L-S22 PLRM ===");
        // Wait for both unflag
        @(posedge clk); #1;
        check(plrm_error === 1'b0, "L-S22.1 no spurious error at reset");

        // Arith requests alone -> grant_arith, not orch
        plrm_req_arith = 1; plrm_req_orch = 0;
        @(posedge clk); #1;
        @(posedge clk); #1;
        check(plrm_grant_arith === 1'b1, "L-S22.2 arith granted alone");
        check(plrm_grant_orch === 1'b0, "L-S22.3 orch not granted when arith holds");
        check(plrm_error === 1'b0, "L-S22.4 no error single grant");

        // Try to break mutual exclusion: both request mid-arith
        plrm_req_orch = 1;
        @(posedge clk); #1;
        // Per phi-priority arith wins (req_arith bit already grants); orch must NOT
        check(!(plrm_grant_arith && plrm_grant_orch), "L-S22.5 mutual exclusion holds");
        check(plrm_error === 1'b0, "L-S22.6 no error after collision attempt");
        plrm_req_arith = 0; plrm_req_orch = 0;
        // wait arith counter expire (29 cycles)
        for (i = 0; i < 35; i = i + 1) @(posedge clk);
        check(plrm_grant_arith === 1'b0, "L-S22.7 arith released after L_7=29 cycles");

        // ---------------- L-S23 CASSINI ----------------
        $display("=== L-S23 CASSINI ===");
        // POST runs from reset. Wait for done.
        for (i = 0; i < 20; i = i + 1) @(posedge clk);
        check(cassini_done === 1'b1, "L-S23.1 cassini_post completed");
        check(cassini_ok === 1'b1, "L-S23.2 Cassini identity verified");

        // ---------------- L-S24 NCA ----------------
        $display("=== L-S24 NCA ENTROPY ===");
        // entropy_violation is a 1-cycle pulse: check IMMEDIATELY after the
        // posedge that latches sample=1.
        // All zeros: popcount=0, below threshold (31)
        nca_trits = 162'd0; nca_sample = 1;
        @(posedge clk); #1;
        // posedge happened -> entropy_violation now valid for this sample
        check(nca_violation === 1'b1, "L-S24.1 all-zero -> entropy_violation");
        check(nca_in_band === 1'b0, "L-S24.2 all-zero out of band");
        nca_sample = 0;
        @(posedge clk); #1;

        // Pattern: 50/81 cells nonzero (in band)
        nca_trits = {{50{2'b01}}, {31{2'b00}}};
        nca_sample = 1;
        @(posedge clk); #1;
        check(nca_violation === 1'b0, "L-S24.3 mid-band -> no violation");
        check(nca_in_band === 1'b1, "L-S24.4 mid-band in_band high");
        nca_sample = 0;
        @(posedge clk); #1;

        // All nonzero (popcount=81 > 80) — violation
        nca_trits = {81{2'b10}};
        nca_sample = 1;
        @(posedge clk); #1;
        check(nca_violation === 1'b1, "L-S24.5 saturated -> entropy_violation");
        nca_sample = 0;
        @(posedge clk); #1;

        // ---------------- L-S28 STROBE SEED ----------------
        $display("=== L-S28 STROBE SEED ===");
        // Good seed: 100 mod 34 = 32, not forbidden
        seed_in = 32'd100; seed_write = 1;
        @(posedge clk); #1; seed_write = 0;
        @(posedge clk); #1;
        check(seed_forbidden === 1'b0, "L-S28.1 good seed accepted");
        check(seed_out === 32'd100, "L-S28.2 good seed passed through");

        // Bad seed: 42 mod 34 = 8, forbidden
        seed_in = 32'd42; seed_write = 1;
        @(posedge clk); #1; seed_write = 0;
        @(posedge clk); #1;
        check(seed_forbidden === 1'b1, "L-S28.3 forbidden seed flagged");
        check(seed_replaced === 1'b0, "L-S28.4 seed_replaced pulse cleared next cycle");
        check(seed_out === 32'd34, "L-S28.5 sanitised to residue 0 (=34)");

        // Sticky check: next good seed still leaves forbidden flag
        seed_in = 32'd100; seed_write = 1;
        @(posedge clk); #1; seed_write = 0;
        @(posedge clk); #1;
        check(seed_forbidden === 1'b1, "L-S28.6 sticky forbidden flag retained");

        // ---------------- L-S32 PHI DISTANCE ----------------
        $display("=== L-S32 PHI DISTANCE ===");
        // 1-cycle pipeline: assert valid_in for 1 cycle, then valid_out is high
        // on the SAME cycle (registered output).
        phi_angle = 9'd0; phi_valid_in = 1;
        @(posedge clk); #1;
        check(phi_valid_out === 1'b1, "L-S32.1 valid_out pipelined 1 cycle");
        check(phi_dist === 16'd0, "L-S32.2 d_phi(0)=0");
        phi_valid_in = 0;

        phi_angle = 9'd180; phi_valid_in = 1;
        @(posedge clk); #1;
        check(phi_dist === 16'd25066, "L-S32.3 d_phi(180)=2·phi^-2");
        phi_valid_in = 0;

        phi_angle = 9'd90; phi_valid_in = 1;
        @(posedge clk); #1;
        check(phi_dist === 16'd12533, "L-S32.4 d_phi(90)=phi^-2");
        phi_valid_in = 0;
        @(posedge clk); #1;

        // ---------------- L-S33 BPB ----------------
        $display("=== L-S33 BPB GUARD ===");
        // BPB = 2.5 in Q8.24 = 2.5 * 2^24 = 41943040
        bpb_q24    = 32'sd41943040;
        floor_q24  = 32'sd16777216;  // 1.0
        bpb_sample = 1;
        @(posedge clk); #1;
        check(bpb_violation_pulse === 1'b0, "L-S33.1 BPB above floor OK");
        check(bpb_sticky === 1'b0, "L-S33.2 sticky clean");
        bpb_sample = 0;
        @(posedge clk); #1;

        // Negative BPB -> THM-25-3 violation (pulse on the cycle after sample latch)
        bpb_q24 = -32'sd1; bpb_sample = 1;
        @(posedge clk); #1;
        check(bpb_violation_pulse === 1'b1, "L-S33.3 negative BPB -> violation");
        check(bpb_sticky === 1'b1, "L-S33.4 sticky set");
        check(bpb_fault === 2'b10, "L-S33.5 fault_code=negative");
        bpb_sample = 0;
        @(posedge clk); #1;

        // Below floor (positive but small)
        bpb_q24 = 32'sd8388608;  // 0.5
        bpb_sample = 1;
        @(posedge clk); #1;
        check(bpb_fault === 2'b01, "L-S33.6 fault_code=below_floor");
        bpb_sample = 0;
        @(posedge clk); #1;

        // ============================================================
        // SUMMARY
        // ============================================================
        $display("");
        $display("============================================");
        $display("TRI-1 V2 LANES: %0d/%0d PASS", pass, pass + fail);
        $display("============================================");
        if (fail == 0)
            $display("TRI1_V2_LANES_GREEN: %0d/%0d", pass, pass + fail);
        else
            $display("TRI1_V2_LANES_FAIL: %0d failures", fail);
        $finish;
    end

    // Safety timeout
    initial begin
        #20000 $display("TIMEOUT"); $finish;
    end

endmodule

`default_nettype wire
