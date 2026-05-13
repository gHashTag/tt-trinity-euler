`default_nettype none
// trinity_gf16_tile.v - addressable GF16 dot4 tile wrapping the existing combinational gf16_dot4.
// Apache-2.0
//
// Packet-driven interface:
//   - Accepts LOAD_A / LOAD_B packets to fill 4 operand lanes (lane 0..3).
//   - On COMPUTE packet, latches result of gf16_dot4 into result register.
//   - On READ_RES packet, drives one outgoing RESULT packet on out_valid.
//
// The compute is combinational (existing dot4), but the tile latches inputs and result, so
// the tile behaves as a real synchronous packet-addressable compute element inside the mesh.

`include "trinity_packet.vh"

module trinity_gf16_tile #(
    parameter [1:0] TILE_ID = 2'b00
) (
    input  wire                    clk,
    input  wire                    rst_n,

    // Inbound packet (from router)
    input  wire [`TRN_PKT_W-1:0]   in_pkt,
    input  wire                    in_valid,
    output wire                    in_ready,

    // Outbound packet (to router) - only RESULT packets
    output reg  [`TRN_PKT_W-1:0]   out_pkt,
    output reg                     out_valid,
    input  wire                    out_ready,

    // Debug visibility
    output wire [15:0]             dbg_result
);

    // Operand registers
    reg [15:0] a0, a1, a2, a3;
    reg [15:0] b0, b1, b2, b3;
    reg [15:0] result_q;
    reg        result_valid;

    // Combinational dot4 over current latched operands
    wire [15:0] dot_out;
    gf16_dot4 u_dot (
        .a0(a0), .a1(a1), .a2(a2), .a3(a3),
        .b0(b0), .b1(b1), .b2(b2), .b3(b3),
        .result(dot_out)
    );

    // Accept any packet addressed to us when out FIFO slot is free or op isn't READ_RES
    assign in_ready = !out_valid || out_ready;

    wire pkt_for_me = (`TRN_PKT_DST(in_pkt) == TILE_ID);
    wire [3:0] op   = `TRN_PKT_OP(in_pkt);
    wire [3:0] lane = `TRN_PKT_LANE(in_pkt);
    wire [15:0] pl  = `TRN_PKT_PAYLOAD(in_pkt);

    assign dbg_result = result_q;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a0 <= 16'h0; a1 <= 16'h0; a2 <= 16'h0; a3 <= 16'h0;
            b0 <= 16'h0; b1 <= 16'h0; b2 <= 16'h0; b3 <= 16'h0;
            result_q <= 16'h0;
            result_valid <= 1'b0;
            out_pkt <= {`TRN_PKT_W{1'b0}};
            out_valid <= 1'b0;
        end else begin
            // Clear out_valid on handshake
            if (out_valid && out_ready)
                out_valid <= 1'b0;

            if (in_valid && in_ready && pkt_for_me) begin
                case (op)
                    `TRN_OP_LOAD_A: begin
                        case (lane[1:0])
                            2'd0: a0 <= pl;
                            2'd1: a1 <= pl;
                            2'd2: a2 <= pl;
                            2'd3: a3 <= pl;
                        endcase
                    end
                    `TRN_OP_LOAD_B: begin
                        case (lane[1:0])
                            2'd0: b0 <= pl;
                            2'd1: b1 <= pl;
                            2'd2: b2 <= pl;
                            2'd3: b3 <= pl;
                        endcase
                    end
                    `TRN_OP_COMPUTE: begin
                        result_q <= dot_out;
                        result_valid <= 1'b1;
                    end
                    `TRN_OP_READ_RES: begin
                        if (!out_valid || out_ready) begin
                            out_pkt   <= `TRN_MK_PKT(`TRN_OP_RESULT,
                                                    `TRN_PKT_SRC(in_pkt),
                                                    TILE_ID,
                                                    4'h0,
                                                    result_q);
                            out_valid <= 1'b1;
                        end
                    end
                    default: ; // NOP / unknown -> ignore
                endcase
            end
        end
    end

endmodule
