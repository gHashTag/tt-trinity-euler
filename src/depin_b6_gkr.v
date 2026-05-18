// SPDX-License-Identifier: Apache-2.0
// B6 — GKR sum-check accelerator round (stub: a + 2b + 4b)
// Author: Dmitrii Vasilev (sole author, admin@t27.ai)
// R-SI-1 compliant: only +, <<

`default_nettype none

module depin_b6_gkr (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [15:0] poly_coeff,
    input  wire [15:0] challenge,
    output reg  [15:0] sum_eval
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            sum_eval <= 16'd0;
        else
            sum_eval <= poly_coeff + (challenge << 1) + (challenge << 2);
    end
endmodule

`default_nettype wire
