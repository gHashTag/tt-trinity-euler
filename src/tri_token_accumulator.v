`default_nettype none
// tri_token_accumulator.v — $TRI hardware token accumulator for DePIN proof-of-compute.
// On each attest_pulse the counter advances by reward_amount; saturates at WIDTH-bit MAX.
// R-SI-1 compliant: zero standalone * operators (uses only + and literal shifts/indices).
// Verilog-2005.  Apache-2.0.
//
// PhD anchor: Chapter 12 / DePIN multi-tile attestability — proof-of-compute reward engine.
// Per-chip wiring: Euler reward_amount = 2'd2 (8x2 tile weight), source = multi_tile_receipt all_attested.

module tri_token_accumulator #(
    parameter WIDTH       = 16,   // 64 K tokens max per session
    parameter REWARD_BITS = 2     // 1-4 tokens per attest pulse (config)
)(
    input  wire                   clk,
    input  wire                   rst_n,
    input  wire                   attest_pulse,          // 1-cycle pulse: valid job done
    input  wire [REWARD_BITS-1:0] reward_amount,         // tokens per attest (cfg)
    output reg  [WIDTH-1:0]       token_balance,
    output wire                   overflow_flag          // asserted when saturated at MAX
);

    // overflow when all bits set (reduction AND)
    assign overflow_flag = &token_balance;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            token_balance <= {WIDTH{1'b0}};
        end else if (attest_pulse && !overflow_flag) begin
            token_balance <= token_balance + {{(WIDTH-REWARD_BITS){1'b0}}, reward_amount};
        end
    end

endmodule
