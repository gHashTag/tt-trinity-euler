// SPDX-License-Identifier: Apache-2.0
// B3 — BGP RPKI HW signer (shift-add stub)
// Author: Dmitrii Vasilev (sole author, admin@t27.ai)
// R-SI-1 compliant: only XOR, shift, byte swap

`default_nettype none

module depin_b3_rpki (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [15:0] route_prefix,
    input  wire [15:0] signing_key,
    output reg  [15:0] signature
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            signature <= 16'd0;
        else
            signature <= (route_prefix << 1) ^ signing_key ^ {route_prefix[7:0], route_prefix[15:8]};
    end
endmodule

`default_nettype wire
