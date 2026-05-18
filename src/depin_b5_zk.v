// SPDX-License-Identifier: Apache-2.0
// B5 — ZK Groth16 verifier stub
// Author: Dmitrii Vasilev (sole author, admin@t27.ai)
// R-SI-1 compliant: only XOR, ==

`default_nettype none

module depin_b5_zk (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [15:0] job_input_hash,
    input  wire [15:0] job_output_hash,
    input  wire [15:0] proof_a,
    input  wire [15:0] proof_b,
    input  wire [15:0] proof_c,
    output reg         valid
);
    wire [15:0] expected = job_input_hash ^ job_output_hash;
    wire [15:0] computed = proof_a ^ proof_b ^ proof_c;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            valid <= 1'b0;
        else
            valid <= (computed == expected);
    end
endmodule

`default_nettype wire
