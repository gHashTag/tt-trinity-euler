`default_nettype none
//-----------------------------------------------------------------------------
// xchip_opcode_decoder.v
//
// Trinity Unified Computer -- XCHIP opcode decoder
// Author: Dmitrii Vasilev <admin@t27.ai>  (sole author, t27.ai)
// License: Apache-2.0
//
// Decodes the 9 cross-chip (XCHIP) opcodes that extend the TRI-27 ISA from
// 36 -> 45 opcodes (still divisible by 9, preserving Coptic 9-fold alignment).
//
// Opcode map (R-SI-1: zero standalone `*` operators):
//   0x30  XCHIP_SEND_PHI     -> xchip_op = 4'h0
//   0x31  XCHIP_SEND_EULER   -> xchip_op = 4'h1
//   0x32  XCHIP_SEND_GAMMA   -> xchip_op = 4'h2
//   0x33  XCHIP_RECV_PHI     -> xchip_op = 4'h3
//   0x34  XCHIP_RECV_EULER   -> xchip_op = 4'h4
//   0x35  XCHIP_RECV_GAMMA   -> xchip_op = 4'h5
//   0x36  XCHIP_BARRIER_3    -> xchip_op = 4'h6
//   0x37  XCHIP_TRIPLE_SIGN  -> xchip_op = 4'h7
//   0x38  XCHIP_BROADCAST    -> xchip_op = 4'h8
//
// Pure combinational. No flops. Tile cost: trivial (single LUT cluster).
// Companion spec: docs/architecture/UNIFIED_COMPUTER_PARADIGM.md
// in gHashTag/NeuronConstant.
//-----------------------------------------------------------------------------

module xchip_opcode_decoder (
    input  wire [7:0] opcode,
    output wire       is_xchip,
    output wire [3:0] xchip_op,
    output wire       is_send,
    output wire       is_recv,
    output wire       is_barrier,
    output wire       is_triple_sign,
    output wire       is_broadcast
);

    // R-SI-1 compliant: opcode arithmetic uses subtraction only.
    wire in_range = (opcode >= 8'h30) && (opcode <= 8'h38);

    assign is_xchip       = in_range;
    assign xchip_op       = in_range ? (opcode[3:0] - 4'h0) : 4'h0;
    assign is_send        = in_range && (opcode[3:0] >= 4'h0) && (opcode[3:0] <= 4'h2);
    assign is_recv        = in_range && (opcode[3:0] >= 4'h3) && (opcode[3:0] <= 4'h5);
    assign is_barrier     = in_range && (opcode[3:0] == 4'h6);
    assign is_triple_sign = in_range && (opcode[3:0] == 4'h7);
    assign is_broadcast   = in_range && (opcode[3:0] == 4'h8);

endmodule

`default_nettype wire
