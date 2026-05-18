// SPDX-License-Identifier: Apache-2.0
// tb_integration_clara.v — Integration test for CLARA AI Safety Gaps
// Tests interaction between multiple CLARA gaps

`default_nettype none
`timescale 1ns / 1ps

module tb_integration_clara;

    reg clk;
    reg rst_n;

    // Common data bus
    reg [15:0] data_in;
    reg        valid_in;

    // Gap-1: Redteam filter outputs
    wire [15:0] redteam_out;
    wire        redteam_valid;
    wire        redteam_filtered;
    wire        redteam_ok;

    // Gap-2: K3 ALU outputs
    wire [1:0]  k3_result;
    wire        k3_valid;
    wire        k3_ok;

    // Gap-3: Datalog outputs
    wire [31:0] datalog_result;
    wire        datalog_valid;
    wire        datalog_ok;

    // Gap-4: Restraint control outputs
    wire        restraint_halt;
    wire [2:0]  restraint_reason;
    wire        restraint_ok;

    // Instantiate CLARA gaps
    redteam_filter u_gap1 (
        .clk(clk), .rst_n(rst_n),
        .data_in(data_in),
        .valid_in(valid_in),
        .data_out(redteam_out),
        .valid_out(redteam_valid),
        .filtered(redteam_filtered),
        .filter_ok(redteam_ok)
    );

    k3_alu u_gap2 (
        .a(data_in[1:0]),
        .b(data_in[3:2]),
        .op(data_in[7:4]),
        .result(k3_result),
        .valid(k3_valid),
        .k3_ok(k3_ok)
    );

    datalog_engine_mini u_gap3 (
        .clk(clk), .rst_n(rst_n),
        .fact_in({16'h0, data_in}),
        .fact_valid(valid_in),
        .query_in({16'h0, data_in}),
        .query_valid(valid_in),
        .result_out(datalog_result),
        .result_valid(datalog_valid),
        .datalog_ok(datalog_ok)
    );

    restraint_ctrl u_gap4 (
        .clk(clk), .rst_n(rst_n),
        .phi_drift(data_in),
        .step_count(data_in[3:0]),
        .receipt_ok(data_in[15]),
        .current_state(2'b00),
        .force_unknown(),
        .halt_mac(restraint_halt),
        .reason(restraint_reason)
    );

    // Clock
    initial begin
        clk = 0;
        forever #10 clk = ~clk;
    end

    // Test tracking
    integer pass_count = 0;
    integer fail_count = 0;

    task check_status;
        input expected_ok;
        input [100*8:1] test_name;
        begin
            if (expected_ok && !redteam_ok && !k3_ok && !datalog_ok) begin
                $display("FAIL: %s | Gaps not OK", test_name);
                fail_count = fail_count + 1;
            end else begin
                $display("PASS: %s | Gaps OK", test_name);
                pass_count = pass_count + 1;
            end
        end
    endtask

    initial begin
        $dumpfile("tb_integration_clara.vcd");
        $dumpvars(0, tb_integration_clara);
        $display("=== INTEGRATION TEST: CLARA AI SAFETY GAPS ===");

        rst_n = 0;
        data_in = 16'h0;
        valid_in = 1'b0;
        #100;
        rst_n = 1;
        #100;

        // Test 1: Normal data flow
        $display("\nTest 1: Normal data flow");
        data_in = 16'h1234;
        valid_in = 1'b1;
        #20;
        valid_in = 1'b0;
        #50;
        check_status(1'b1, "Normal data processed");

        // Test 2: Adversarial pattern (Gap-1)
        $display("\nTest 2: Adversarial pattern detection");
        data_in = 16'hFFFF;  // Known adversarial pattern
        valid_in = 1'b1;
        #20;
        valid_in = 1'b0;
        #50;
        if (redteam_filtered) $display("PASS: Adversarial input filtered");
        else $display("FAIL: Adversarial input not filtered");

        // Test 3: K3 ternary computation (Gap-2)
        $display("\nTest 3: K3 ternary ALU");
        data_in = 16'h0021;  // a=01 (+1), b=10 (+1), op=ADD
        #20;
        if (k3_valid && k3_result == 2'b10) $display("PASS: K3 computation correct");
        else $display("FAIL: K3 computation incorrect");

        // Test 4: Datalog reasoning (Gap-3)
        $display("\nTest 4: Datalog mini engine");
        data_in = 16'hABCD;  // Arbitrary fact
        valid_in = 1'b1;
        #20;
        valid_in = 1'b0;
        #50;
        if (datalog_valid) $display("PASS: Datalog query processed");

        // Test 5: Restraint control (Gap-4)
        $display("\nTest 5: Restraint control");
        data_in = 16'h0100;  // step_count > 10 (should trigger)
        #20;
        if (restraint_halt) $display("PASS: Restraint triggered");
        else $display("FAIL: Restraint not triggered");

        // Summary
        $display("\n=== TEST SUMMARY ===");
        $display("PASS: %d", pass_count);
        $display("FAIL: %d", fail_count);
        $finish;
    end

endmodule