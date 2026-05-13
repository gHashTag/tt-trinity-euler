`default_nettype none
`timescale 1ns / 1ps

module tb ();

  initial begin
    $dumpfile("tb.fst");
    $dumpvars(0, tb);
    #1;
  end

  reg clk;
  reg rst_n;
  reg ena;
  reg [7:0] ui_in;
  reg [7:0] uio_in;
  wire [7:0] uo_out;
  wire [7:0] uio_out;
  wire [7:0] uio_oe;

  tt_um_ghtag_trinity_gf16 user_project (
      .ui_in  (ui_in),
      .uo_out (uo_out),
      .uio_in (uio_in),
      .uio_out(uio_out),
      .uio_oe (uio_oe),
      .ena    (ena),
      .clk    (clk),
      .rst_n  (rst_n)
  );

  always #10 clk = ~clk;

  integer pass_count, fail_count, cycle_cnt;

  initial begin
    pass_count = 0;
    fail_count = 0;
    clk = 0;
    rst_n = 0;
    ena = 1;
    ui_in = 8'h00;
    uio_in = 8'h00;

    #50;
    rst_n = 1;
    @(posedge clk);
    #1;

    $display("=== TT Trinity GF16 Tests ===");

    // ---- T1: legacy combinational dot4 visible immediately after reset ----
    // dot4([1,2,3,4], [1,2,3,4]) = 1+4+9+16 = 30 = 0x47C0
    if ({uio_out, uo_out} === 16'h47C0) begin
      pass_count = pass_count + 1;
      $display("PASS legacy_dot4_result: 0x47C0 = 30.0");
    end else begin
      fail_count = fail_count + 1;
      $display("FAIL legacy_dot4_result: got 0x%h%h expected 0x47C0", uio_out, uo_out);
    end

    // ---- T2: uio_oe must be 0xFF ----
    if (uio_oe === 8'hFF) begin
      pass_count = pass_count + 1;
      $display("PASS uio_oe");
    end else begin
      fail_count = fail_count + 1;
      $display("FAIL uio_oe: 0x%h", uio_oe);
    end

    // ---- T3: Trinity v0 mesh fabric end-to-end ----
    // Master FSM drives 4xLOAD_A + 4xLOAD_B + COMPUTE + READ_RES packets to tile 0
    // and latches a RESULT packet with the dot product (== 30.0 == 0x47C0).
    // Generous cycle budget: 8 loads + 1 compute + 1 read + 1 result return ~= 12-16 cycles.
    for (cycle_cnt = 0; cycle_cnt < 64; cycle_cnt = cycle_cnt + 1)
      @(posedge clk);

`ifndef GL_TEST
    // Internal hierarchical peeks: only meaningful in RTL sim — gate-level
    // netlist has these signals flattened, so guard them out under GL_TEST.
    if (user_project.mesh_result_valid === 1'b1 &&
        user_project.mesh_result === 16'h47C0) begin
      pass_count = pass_count + 1;
      $display("PASS mesh_result: 0x47C0 from tile 0 via packet fabric");
    end else begin
      fail_count = fail_count + 1;
      $display("FAIL mesh_result: valid=%b value=0x%h",
               user_project.mesh_result_valid, user_project.mesh_result);
    end
`else
    pass_count = pass_count + 1;
    $display("SKIP mesh_result (GL_TEST — internal peek not available)");
`endif

    // ---- T4: outputs reflect mesh result after FSM completes ----
    if ({uio_out, uo_out} === 16'h47C0) begin
      pass_count = pass_count + 1;
      $display("PASS final_outputs_post_mesh: 0x47C0");
    end else begin
      fail_count = fail_count + 1;
      $display("FAIL final_outputs_post_mesh: 0x%h%h", uio_out, uo_out);
    end

    // ---- T5: G4 DePIN on-die receipt emission ----
    // The tile emits a paired RECEIPT after RESULT. The master FSM latches it.
    // Canned vectors: job_id=0x01, nonce=0x55, result=0x47C0
    //   expected checksum = (0x01 ^ 0xC0) & 0xFF = 0xC1
    //   expected tile_id  = 0 (tile 0)
    //   expected job_id   = 0x01
`ifndef GL_TEST
    // Internal hierarchical peeks: only meaningful in RTL sim — gate-level
    // netlist has these signals flattened, so guard them out under GL_TEST.
    if (user_project.mesh_rcpt_valid === 1'b1 &&
        user_project.mesh_rcpt_checksum === 8'hC1 &&
        user_project.mesh_rcpt_job_id === 8'h01 &&
        user_project.mesh_rcpt_tile_id === 2'd0) begin
      pass_count = pass_count + 1;
      $display("PASS dot4_with_receipt: checksum=0x%h job=0x%h tile=%0d (silicon-anchored DePIN G4)",
               user_project.mesh_rcpt_checksum,
               user_project.mesh_rcpt_job_id,
               user_project.mesh_rcpt_tile_id);
    end else begin
      fail_count = fail_count + 1;
      $display("FAIL dot4_with_receipt: valid=%b checksum=0x%h (want 0xC1) job=0x%h (want 0x01) tile=%0d (want 0)",
               user_project.mesh_rcpt_valid,
               user_project.mesh_rcpt_checksum,
               user_project.mesh_rcpt_job_id,
               user_project.mesh_rcpt_tile_id);
    end
`else
    pass_count = pass_count + 1;
    $display("SKIP dot4_with_receipt (GL_TEST — internal peek not available)");
`endif

    $display("Results: %0d pass, %0d fail", pass_count, fail_count);
    if (fail_count > 0) $display("SOME TESTS FAILED");
    else $display("ALL TESTS PASSED");
    $finish;
  end

  // Watchdog
  initial begin
    #100000;
    $display("WATCHDOG TIMEOUT");
    $finish;
  end

endmodule
