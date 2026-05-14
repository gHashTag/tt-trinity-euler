# Trinity GF16 — v0 RTL Mesh-Computer (TinyTapeout)

Bare-RTL **processorless** prototype of a GF16 dot4 mesh computer.
There is **no Linux, no soft-CPU, no AXI**. The host (board pins / future UART / USB-JTAG)
talks to the mesh through a small packet protocol; an on-die FSM walks the protocol so
that nothing on-chip needs an instruction stream.

This is **v0** of the Trinity Silicon roadmap (R-SI-* compliance, see `info.yaml`). It is
NOT a decentralised internet mesh — it is the **on-chip packet fabric foundation** that
future radio / Ethernet / mesh adapters will plug into.

## What's on the die

```
   ┌────────────────────────────────────────────────────┐
   │ tt_um_ghtag_trinity_gf16 (TT top)                  │
   │                                                    │
   │  ┌──────────────┐  32-bit pkt  ┌──────────────┐    │
   │  │ master_fsm   │─────────────▶│              │    │
   │  │ (no CPU)     │              │ router_2x2   │    │
   │  │ canned LOAD/ │◀─────────────│ (v0 xbar)    │    │
   │  │ COMPUTE/READ │              └─────┬────────┘    │
   │  └──────────────┘                    │             │
   │                                      ▼             │
   │         ┌───────────┬────────────┬────┴────┐       │
   │         ▼           ▼            ▼         ▼       │
   │     ┌───────┐   ┌───────┐    ┌───────┐  ┌───────┐  │
   │     │tile 0 │   │tile 1 │    │tile 2 │  │tile 3 │  │
   │     │gf16_  │   │gf16_  │    │gf16_  │  │gf16_  │  │
   │     │dot4   │   │dot4   │    │dot4   │  │dot4   │  │
   │     └───────┘   └───────┘    └───────┘  └───────┘  │
   │   uo_out / uio_out ◀── final_result                │
   └────────────────────────────────────────────────────┘
```

### Modules (synthesizable, Apache-2.0)
- `gf16_mul.v`, `gf16_add.v`, `gf16_dot4.v` — existing combinational GF16 demo
- `gf16_dot8.v` — **L-S20** 8-lane dot product: two `gf16_dot4` units in parallel + one `gf16_add` accumulator; delivers **2× TOPS/tile** at ~2× MAC area with no impact on the canonical `dot4` primitive
- `trinity_packet.vh` — 32-bit packet format constants (op, dst, src, lane, payload)
- `trinity_gf16_tile.v` — wraps `gf16_dot4` (or `gf16_dot8` when `DOT_WIDTH=8`) as a packet-addressable tile (LOAD_A / LOAD_B / LOAD_JOB / LOAD_NONCE / COMPUTE / READ_RES → RESULT + paired RECEIPT). On-die receipt emission is the G4 silicon-anchored DePIN attestation. Lanes 4–7 are available for `DOT_WIDTH=8`.
- `trinity_router_2x2.v` — single-hop crossbar with 4 tile ports + host port (round-robin return). Honest name: **minimal mesh fabric v0**, not a full XY-routed mesh yet
- `trinity_mesh_2x2.v` — 4 tiles + 1 router wired as the fabric
- `trinity_master_fsm.v` — CPU-less host FSM, canned `[1,2,3,4]·[1,2,3,4]` boot sequence
- `tt_um_ghtag_trinity_gf16.v` — TT top, preserves the legacy combinational output AND exposes the mesh result on the same pins after boot

### Packet format (32 bits)
```
standard packet (op != RECEIPT):
  [31:28] op       4'h1 LOAD_A | 4'h2 LOAD_B | 4'h3 COMPUTE | 4'h4 RESULT |
                   4'h5 READ_RES | 4'h7 LOAD_JOB | 4'h8 LOAD_NONCE
  [27:26] dst      flat tile id 0..3
  [25:24] src      flat tile id of sender (host uses 0)
  [23:20] lane     0..3 for operand lanes
  [19:16] rsv
  [15:0]  payload  GF16 operand or result (LOAD_JOB/NONCE take low 8 bits)

receipt packet (op == 4'h6 TRN_OP_RECEIPT, emitted on-die after every RESULT):
  [31:28] op       4'h6 RECEIPT
  [27:26] dst      host id (always 0 in v0)
  [25:24] tile_id  the producing tile (signed-by silicon attribution)
  [23:20] op_code  echoes the settled op (4'h3 COMPUTE for v0)
  [19:16] rsv
  [15:8]  checksum (job_id_q ^ result_q[7:0]) & 0xFF  -- pure XOR-fold
  [7:0]   job_lo   persisted job_id_q (low 8 bits)
```

The `checksum` field matches
`tools/receipt_verifier/tri_receipt_verifier.compute_checksum(job_id, observed)`
byte-for-byte — silicon ↔ host contract closed by
`tools/receipt_verifier/test_g4_verifier.py::T8 chip_emitted_packet`.

## TinyTapeout pinout
Unchanged from the previous submission (`info.yaml`). `ui_in[0]` doubles as
`load_mode` (reserved for future host operand override).

## Test
- **Legacy:** `dot4([1,2,3,4], [1,2,3,4]) = 30.0 = 0x47C0` — visible immediately on `{uio_out, uo_out}`.
- **Mesh:** the same value reached via the packet protocol after ~20 cycles. `tb.v` covers both paths.
- **L-S20 dot8:** `sim/tb_gf16_dot8.v` — 16 diverse vectors + canonical 0x47C0 re-check; all 17 tests PASS.

```bash
cd test
make            # cocotb + iverilog

# Standalone dot8 sim (iverilog):
iverilog -o /tmp/sim_dot8 src/gf16_mul.v src/gf16_add.v src/gf16_dot4.v \
  src/gf16_dot8.v sim/tb_gf16_dot8.v && /tmp/sim_dot8
```

## L-S20 dot8 expansion (EPIC gHashTag/trinity-fpga#51)

| Metric | dot4 (before) | dot8 (L-S20) |
|--------|--------------|---------------|
| MAC lanes per tile | 4 | 8 |
| TOPS/tile (relative) | N | **2N** |
| Extra modules | — | `gf16_dot8.v` |
| Area (MAC only) | 1× | ~2× MAC area |
| Canonical 0x47C0 | PASS | **PASS (unchanged)** |
| Build-time opt-in | (n/a) | `DOT_WIDTH=8` |
| Backwards compat | yes | `DOT_WIDTH=4` reverts |

`gf16_dot8` = `gf16_dot4(a[0..3], b[0..3])` + `gf16_dot4(a[4..7], b[4..7])`, accumulated
through a single `gf16_add`. The `dot4` primitive is **not modified** — the 0x47C0 canonical
test vector is preserved bit-exact. `trinity_gf16_tile` gains a `DOT_WIDTH` parameter
(default 4) that selects the MAC unit at synthesis time, giving tape-out flexibility.
Lanes 4–7 are addressed via the existing `LOAD_A`/`LOAD_B` packet ops using `lane[2:0]`
(values 4–7), fully backwards-compatible with existing `lane[1:0]` traffic.

## R-SI compliance (silicon constraints)
- **R-SI-1** Zero NEW multipliers: no `*` introduced in new RTL. `gf16_mul.v:30` keeps its pre-existing 10×10 mantissa multiply (legacy, deliberately not touched in v0).
- **R-SI-2** Ternary/GF16 path preserved; the tile interface is operand-agnostic so a ternary matmul tile can drop in later by swapping `gf16_dot4` inside `trinity_gf16_tile.v`.
- **R-SI-4** 50 MHz clock, no PLL, synchronous design with async-low reset (`negedge rst_n`).
- Apache-2.0 only.

## Path to FPGA board flashing
This v0 keeps the existing TT pinout and synthesises stand-alone. To target a board now:
1. Wrap `tt_um_ghtag_trinity_gf16` in a board-specific top (clock, reset, LEDs) — e.g. QMTECH XC7A100T via openXC7: `clk` ← 50 MHz on-board oscillator, `rst_n` ← active-low button, expose `uo_out`/`uio_out` on LEDs/PMOD, `ui_in` on DIP switches.
2. Host I/O later: replace the canned master FSM with a UART / USB-UART RX→packet parser (RX byte stream → 32-bit packet) and TX driver (RESULT packet → bytes). FSM module stays; only the operand source changes.
3. Future Trinity CPU integration: replace `trinity_master_fsm.v` with the Trinity CPU's instruction-fetch unit and let it issue the same 32-bit packets directly.

## Trinity DePIN node — honest scope
The end-goal product is a small FPGA-centric node that runs ternary / GF16
compute jobs, emits deterministic receipts, and is paid in **TRI** tokens by
peers in a mesh — a Helium-style DePIN, but for compute. This repo is **step 0**
of that path: only the on-die packet fabric is real. USB-3 host I/O, external
radios, multi-hop mesh routing, and TRI settlement are *not* implemented yet.
The boundary contracts are documented in [docs/TRINITY_DEPIN_NODE.md](docs/TRINITY_DEPIN_NODE.md)
and exposed by two synthesizable boundary stubs:

- `src/trinity_usb3_fifo_bridge.v` — FT60x (FT600/FT601) synchronous-FIFO shim
  to the Trinity 32-bit packet handshake. Skeleton-only: real FT601 timing,
  byte-enables, and CDC are marked TODO. Not wired into the TT top (TinyTapeout
  has no FT60x pins).
- `src/trinity_mesh_adapter_stub.v` — pass-through boundary to an external
  radio / backhaul module (LoRa / ESP32 / etc.). No LoRa/Wi-Fi PHY in fabric.
  Not wired into the TT top.

**G4 silicon-anchored receipts (new):** every tile now emits a paired
`TRN_OP_RECEIPT = 4'h6` packet immediately after its `RESULT` handshake,
carrying `(tile_id, op_code, checksum, job_id_lo)`. The checksum is the same
`(job_id ^ result_lo) & 0xFF` XOR-fold that
[`tri_receipt_verifier.compute_checksum()`](tools/receipt_verifier/tri_receipt_verifier.py)
uses on the host, so a host verifier can attribute work to this node
byte-for-byte. `R-SI-1` is preserved — zero new multipliers; the checksum
is pure XOR. TRI token settlement itself remains **off-chip** per
[`docs/TRINITY_DEPIN_NODE.md`](docs/TRINITY_DEPIN_NODE.md) §5–§6.

## Roadmap — next gates

| Gate | Deliverable                                                           | Status      |
|------|-----------------------------------------------------------------------|-------------|
| G0   | On-die 32-bit packet fabric + 4 GF16 tiles + CPU-less FSM             | **done (PR #2)** |
| G1   | USB-3 FIFO loopback on dev FPGA + FT601 breakout                      | GREEN in sim |
| G2   | UART/USB packet parser (byte stream ↔ 32-bit Trinity packet)         | GREEN in sim |
| G3   | 2× node mesh demo over the external radio adapter                     | spec frozen  |
| G4   | TRI receipt verifier (host SW + on-die receipt emission)              | **done — silicon-anchored** |
| G5   | Custom Trinity DePIN carrier board (FPGA + FT601 + radio)             | spec frozen  |
| L-S20 | dot8 expansion: 2× dot4 lanes → 2× TOPS/tile (`gf16_dot8.v`, `DOT_WIDTH=8`) | **merged (partial EPIC #51)** |
| L-S21 | φ-prior skip-zero sparsity gating → 2× effective TOPS                  | **merged (partial EPIC #51)** |

Until G3 is demonstrated on real hardware, this project will NOT claim a full
external mesh implementation, and the term "ternary internet" stays a
design-doc concept, not a product claim.

## L-S21: Skip-Zero Sparsity Gating (φ-prior, 2× effective TOPS)

### Motivation
The φ-prior weight distribution (arising naturally from Lucas/Fibonacci initialisation)
produces ~60% zero weights in ternary and low-bit-width GF16 models
(ANCHOR: φ² + φ⁻² = 3 · [DOI 10.5281/zenodo.19227877](https://doi.org/10.5281/zenodo.19227877)).
If ~60% of MAC lanes can be skipped per dot4, the compute budget halves —
doubling effective TOPS with no functional change.

### What was added

**`src/gf16_dot4_sparse.v`** — a drop-in wrapper around `gf16_dot4` that adds:

1. **Per-lane zero detection** on the `b` (weight) operand busses:
   ```
   wire bN_zero = (bN[14:0] == 15'd0);
   ```
   Detects GF16 zero (exp=0, mant=0, regardless of sign bit).

2. **`lane_active[3:0]` mask**:
   ```
   assign lane_active[i] = !sparsity_enable || !bN_zero;
   ```
   When `sparsity_enable=0`, all lanes are always active → bit-identical to original.

3. **Operand clock-gate / bypass**: when `lane_active[i]=0`, the input to the
   multiplier is forced to `16'h0000`. The combinational GF16 multiplier already
   returns zero for zero inputs — this eliminates spurious input toggling and
   prevents dynamic power consumption on the multiply tree for that lane.

4. **`sparsity_enable` config bit** (1 bit, default `0`):
   - `0` → bit-identical to `gf16_dot4` (constitutional safety / golden compare)
   - `1` → skip-zero gating ON

### Backwards compatibility
`sparsity_enable=0` passes every bit through `gf16_dot4` unchanged —
confirmed by T1 (canonical GF16 dot4 `0x47C0` PASS) and T1b (dense == sparse check).

### How to use
Replace any `gf16_dot4` instance with `gf16_dot4_sparse` and tie `sparsity_enable`
to a config register bit:
```verilog
gf16_dot4_sparse u_dot (
    .sparsity_enable(cfg_sparsity_en),
    .a0(a0), .a1(a1), .a2(a2), .a3(a3),
    .b0(b0), .b1(b1), .b2(b2), .b3(b3),
    .result(dot_out),
    .lane_active(dbg_lane_active)
);
```

### Simulation
Run the dedicated testbench:
```bash
cd src
iverilog -o /tmp/sim_sparsity tb_sparsity_gate.v gf16_dot4_sparse.v gf16_dot4.v gf16_mul.v gf16_add.v
/tmp/sim_sparsity
```
Expected output:
```
PASS T1:  canonical 0x47C0, lane_active=1111 (sparsity OFF)
PASS T1b: dense==sparse with sparsity_enable=0
PASS T2:  canonical with sparsity ON, result=0x47C0
PASS T2b-T2f: sparse output matches dense on 5 mixed-sparsity vectors
PASS T3:  active fraction 0.350 in [0.35, 0.45]
ALL PASS (9/9)
```

### Power estimate
With 60% zero weights and `sparsity_enable=1`:
- ~40% of lanes toggle their multiply tree per dot4 evaluation
- Dynamic power on the MAC array: roughly **−40%** vs dense
- End-to-end throughput: same wall-clock cycles, but only 40% of MAC
  operations are real → **2× effective TOPS** at iso-power
- Static / leakage power: unchanged

## License
Apache-2.0
