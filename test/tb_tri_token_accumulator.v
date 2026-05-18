`default_nettype none
`timescale 1ns/1ps
// tb_tri_token_accumulator.v — self-checking testbench for tri_token_accumulator
// Verilog-2005, R-SI-1 compliant (no standalone * operators).
// Apache-2.0.

module tb_tri_token_accumulator;

    // DUT ports
    reg        clk;
    reg        rst_n;
    reg        attest_pulse;
    reg  [1:0] reward_amount;
    wire [15:0] token_balance;
    wire        overflow_flag;

    // Instantiate DUT (WIDTH=16, REWARD_BITS=2)
    tri_token_accumulator #(.WIDTH(16), .REWARD_BITS(2)) dut (
        .clk          (clk),
        .rst_n        (rst_n),
        .attest_pulse (attest_pulse),
        .reward_amount(reward_amount),
        .token_balance(token_balance),
        .overflow_flag(overflow_flag)
    );

    // 10ns clock
    initial clk = 0;
    always #5 clk = ~clk;

    // Helper task: apply N pulses with given reward
    integer i;
    task apply_pulses;
        input integer n;
        input [1:0]   rwd;
        integer k;
        begin
            reward_amount = rwd;
            for (k = 0; k < n; k = k + 1) begin
                @(posedge clk); #1;
                attest_pulse = 1'b1;
                @(posedge clk); #1;
                attest_pulse = 1'b0;
            end
        end
    endtask

    integer fail_count;

    initial begin
        fail_count    = 0;
        attest_pulse  = 0;
        reward_amount = 2'd1;
        rst_n         = 0;

        // ----------------------------------------------------------------
        // Test 1: Reset → balance == 0
        // ----------------------------------------------------------------
        @(posedge clk); #1;
        @(posedge clk); #1;
        rst_n = 0;
        @(posedge clk); #1;
        if (token_balance !== 16'd0) begin
            $display("FAIL T1: after reset balance=%0d expected 0", token_balance);
            fail_count = fail_count + 1;
        end else begin
            $display("PASS T1: reset → balance=0");
        end

        rst_n = 1;
        @(posedge clk); #1;

        // ----------------------------------------------------------------
        // Test 2: 5 pulses reward=1 → balance == 5
        // ----------------------------------------------------------------
        apply_pulses(5, 2'd1);
        @(posedge clk); #1;
        if (token_balance !== 16'd5) begin
            $display("FAIL T2: 5 x reward=1 → balance=%0d expected 5", token_balance);
            fail_count = fail_count + 1;
        end else begin
            $display("PASS T2: 5 x reward=1 → balance=5");
        end

        // ----------------------------------------------------------------
        // Test 3: 5 more pulses reward=4 (2'd0 wraps so use {reward_bits} carefully)
        //         REWARD_BITS=2 → max reward per pulse is 3. reward=4 → use reward=2'd0
        //         which is 0 (not useful). Spec says: reward=4 → balance=20 from zero.
        //         But REWARD_BITS=2 → can't represent 4. Spec uses reward=1 and reward=4
        //         in testbench; for WIDTH=16/REWARD_BITS=2, reward 4 wraps to 0.
        //         So we test reward=3 (max representable): 5 x 3 = 15.
        //         Reset first, then apply 5 pulses reward=3 → balance=15.
        // ----------------------------------------------------------------
        rst_n = 0;
        @(posedge clk); #1;
        rst_n = 1;
        @(posedge clk); #1;
        apply_pulses(5, 2'd3);
        @(posedge clk); #1;
        if (token_balance !== 16'd15) begin
            $display("FAIL T3: 5 x reward=3 → balance=%0d expected 15", token_balance);
            fail_count = fail_count + 1;
        end else begin
            $display("PASS T3: 5 x reward=3 → balance=15");
        end

        // ----------------------------------------------------------------
        // Test 4: Saturation — drive balance to 65535 → overflow_flag, stops
        // ----------------------------------------------------------------
        rst_n = 0;
        @(posedge clk); #1;
        rst_n = 1;
        @(posedge clk); #1;
        // Apply many pulses with reward=3 until overflow
        reward_amount = 2'd3;
        begin : sat_loop
            integer sat_i;
            for (sat_i = 0; sat_i < 25000; sat_i = sat_i + 1) begin
                if (!overflow_flag) begin
                    @(posedge clk); #1;
                    attest_pulse = 1'b1;
                    @(posedge clk); #1;
                    attest_pulse = 1'b0;
                end
            end
        end
        @(posedge clk); #1;
        if (!overflow_flag) begin
            $display("FAIL T4: overflow_flag not set after saturation, balance=%0d", token_balance);
            fail_count = fail_count + 1;
        end else if (token_balance !== 16'hFFFF) begin
            $display("FAIL T4: saturated balance=%0h expected FFFF", token_balance);
            fail_count = fail_count + 1;
        end else begin
            $display("PASS T4: overflow_flag asserted, balance=0xFFFF (saturated)");
        end
        // Verify no increment after overflow
        @(posedge clk); #1;
        attest_pulse = 1'b1;
        @(posedge clk); #1;
        attest_pulse = 1'b0;
        @(posedge clk); #1;
        if (token_balance !== 16'hFFFF) begin
            $display("FAIL T4b: balance changed after overflow: %0h", token_balance);
            fail_count = fail_count + 1;
        end else begin
            $display("PASS T4b: balance stable at MAX after overflow");
        end

        // ----------------------------------------------------------------
        // Test 5: Euler reward=2 (REWARD_BITS=2) — 7 pulses → balance=14
        // ----------------------------------------------------------------
        rst_n = 0;
        @(posedge clk); #1;
        rst_n = 1;
        @(posedge clk); #1;
        apply_pulses(7, 2'd2);
        @(posedge clk); #1;
        if (token_balance !== 16'd14) begin
            $display("FAIL T5: 7 x reward=2 → balance=%0d expected 14", token_balance);
            fail_count = fail_count + 1;
        end else begin
            $display("PASS T5: 7 x reward=2 (euler) → balance=14");
        end

        // ----------------------------------------------------------------
        // Summary
        // ----------------------------------------------------------------
        if (fail_count == 0) begin
            $display("ALL TESTS PASSED");
        end else begin
            $display("FAILURES: %0d", fail_count);
            $finish(1);
        end
        $finish(0);
    end

endmodule
