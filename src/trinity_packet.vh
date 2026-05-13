// Trinity packet format constants (v0, 2x2 mesh fabric)
// Apache-2.0
//
// 32-bit packet layout:
//   [31:28] op     - 4'h0 NOP, 4'h1 LOAD_A, 4'h2 LOAD_B, 4'h3 COMPUTE, 4'h4 RESULT, 4'h5 READ_RES
//   [27:26] dst_x  - 2 bits (column 0..1)
//   [27]    dst_y  - 1 bit  (row    0..1)  (we treat [27:26] as flat tile id 0..3)
//   [25:24] src_x  - 2 bits (column)
//   [23:20] lane   - which lane (0..3 for a/b operands; 0 for compute/result)
//   [19:16] reserved
//   [15:0]  payload (GF16 word or result)
//
// Tile id (flat) lives in [27:26] (dst) and [25:24] (src).
// This is a single-hop fabric; "x/y" naming kept for forward-compat with full 2x2 XY routing.

`define TRN_PKT_W            32
`define TRN_NUM_TILES        4
`define TRN_TILE_ID_W        2

`define TRN_OP_NOP           4'h0
`define TRN_OP_LOAD_A        4'h1
`define TRN_OP_LOAD_B        4'h2
`define TRN_OP_COMPUTE       4'h3
`define TRN_OP_RESULT        4'h4
`define TRN_OP_READ_RES      4'h5

// Field accessors
`define TRN_PKT_OP(p)        (p[31:28])
`define TRN_PKT_DST(p)       (p[27:26])
`define TRN_PKT_SRC(p)       (p[25:24])
`define TRN_PKT_LANE(p)      (p[23:20])
`define TRN_PKT_PAYLOAD(p)   (p[15:0])

`define TRN_MK_PKT(op,dst,src,lane,pl) {op, dst, src, lane, 4'h0, pl}

// -----------------------------------------------------------------------------
// Compute-receipt format (v0 placeholder, NOT yet emitted by tiles)
// -----------------------------------------------------------------------------
// The intent: every RESULT packet that the on-die tile produces is paired
// with a deterministic *receipt* that off-chip TRI settlement code can use
// to attribute work to this Trinity node. The full receipt is wider than
// one 32-bit packet, so v0 reserves an encoding that fits across two
// packets (a RESULT followed by a RECEIPT) once gate G4 lands.
//
// Field widths reserved here (constants are committed so G4 can light them
// up without renumbering anything; nothing in v0 RTL reads these yet):
//
//   compute_job_id : 16 bits   host-assigned id of the job being settled
//   tile_id        :  2 bits   which on-die tile produced the result
//   op_code        :  4 bits   echoes the packet op field (LOAD/COMPUTE/...)
//   result         : 16 bits   GF16 scalar (today) / ternary word (future)
//   nonce          : 16 bits   per-job freshness, supplied by host
//   checksum       :  8 bits   XOR-fold placeholder; real MAC is host-side
//
// TRI token settlement is OFF-CHIP. The FPGA's only contract is determinism:
// the same `(job_id, nonce, operands)` always yields the same
// `(result, tile_id, op_code)` from this node. That is what a future ZK or
// fraud-proof attestation will sign.

`define TRN_OP_RECEIPT       4'h6   // reserved; tiles do not emit this in v0

`define TRN_RCPT_JOB_ID_W    16
`define TRN_RCPT_TILE_ID_W   `TRN_TILE_ID_W
`define TRN_RCPT_OP_W        4
`define TRN_RCPT_RESULT_W    16
`define TRN_RCPT_NONCE_W     16
`define TRN_RCPT_CHECKSUM_W  8
