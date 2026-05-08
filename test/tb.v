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

  integer pass_count, fail_count;

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

    // dot4([1,2,3,4], [1,2,3,4]) = 1+4+9+16 = 30 = 0x47C0
    if ({uio_out, uo_out} === 16'h47C0) begin
      pass_count = pass_count + 1;
      $display("PASS dot4_result: 0x47C0 = 30.0");
    end else begin
      fail_count = fail_count + 1;
      $display("FAIL dot4_result: got 0x%h%h expected 0x47C0", uio_out, uo_out);
    end

    // uio_oe must be 0xFF (all outputs enabled)
    if (uio_oe === 8'hFF) begin
      pass_count = pass_count + 1;
      $display("PASS uio_oe");
    end else begin
      fail_count = fail_count + 1;
      $display("FAIL uio_oe: 0x%h", uio_oe);
    end

    $display("Results: %0d pass, %0d fail", pass_count, fail_count);
    if (fail_count > 0) $display("SOME TESTS FAILED");
    else $display("ALL TESTS PASSED");
    $finish;
  end

endmodule
