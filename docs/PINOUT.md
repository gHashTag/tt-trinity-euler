# PINOUT — TRI-1 Euler (tt_um_ghtag_trinity_gf16)

**Project:** TRI-1 Euler — Trinity e-engine 8×2 SUPER-CROWN + 10 CLARA Gaps  
**Tile:** 8×2 · Tiny Tapeout SKY130A (TTSKY26b, slot #4915)  
**Top module:** `tt_um_ghtag_trinity_gf16`  
**Clock:** 50 MHz · **Reset:** active-low `rst_n`  
**Canonical anchor:** `0x47C0` on `{uio_out[7:0], uo_out[7:0]}` after reset (Theorem 36.1, TG-TRIAD-X)

> Cross-tile interconnect details: see [`docs/CROSS_TILE_INTERCONNECT.md`](CROSS_TILE_INTERCONNECT.md)

---

## Pin Table

```
 ┌─────────────────────────────────────────────────────────────────────────────┐
 │              TRI-1 Euler (tt_um_ghtag_trinity_gf16) — 8×2 tiles            │
 │                                                                             │
 │  PIN       DIR    SIGNAL / FUNCTION                                         │
 │  ────────  ─────  ──────────────────────────────────────────────────────    │
 │  ui[0]     IN     load_mode                                                 │
 │                     0 = canonical mode: 0x47C0 on {uio_out,uo_out}          │
 │                         POST/anchor status visible to host                  │
 │                     1 = packet path: data_bit[6:0] carry token data         │
 │  ui[1]     IN     data_bit[0] — payload/token byte bit 0                   │
 │  ui[2]     IN     data_bit[1] — payload/token byte bit 1                   │
 │  ui[3]     IN     data_bit[2] — payload/token byte bit 2                   │
 │  ui[4]     IN     data_bit[3] — payload/token byte bit 3                   │
 │  ui[5]     IN     data_bit[4] — payload/token byte bit 4                   │
 │  ui[6]     IN     data_bit[5] — payload/token byte bit 5                   │
 │  ui[7]     IN     data_bit[6] — payload/token byte bit 6                   │
 │  ────────  ─────  ──────────────────────────────────────────────────────    │
 │  uo[0]     OUT    result_bit[0] — canonical 0x47C0[0]  (default = 0)       │
 │  uo[1]     OUT    result_bit[1] — canonical 0x47C0[1]  (default = 0)       │
 │  uo[2]     OUT    result_bit[2] — canonical 0x47C0[2]  (default = 0)       │
 │  uo[3]     OUT    result_bit[3] — canonical 0x47C0[3]  (default = 0)       │
 │  uo[4]     OUT    result_bit[4] — canonical 0x47C0[4]  (default = 0)       │
 │  uo[5]     OUT    result_bit[5] — canonical 0x47C0[5]  (default = 0)       │
 │  uo[6]     OUT    result_bit[6] — canonical 0x47C0[6]  (default = 1)       │
 │  uo[7]     OUT    result_bit[7] — canonical 0x47C0[7]  (default = 1)       │
 │  ────────  ─────  ──────────────────────────────────────────────────────    │
 │  uio[0]    OUT    result_high_bit[0] — canonical 0x47C0[8]  (default = 0)  │
 │  uio[1]    OUT    result_high_bit[1] — canonical 0x47C0[9]  (default = 0)  │
 │  uio[2]    OUT    result_high_bit[2] — canonical 0x47C0[10] (default = 0)  │
 │  uio[3]    OUT    result_high_bit[3] — canonical 0x47C0[11] (default = 0)  │
 │  uio[4]    OUT    result_high_bit[4] — canonical 0x47C0[12] (default = 0)  │
 │  uio[5]    OUT    result_high_bit[5] — canonical 0x47C0[13] (default = 1)  │
 │  uio[6]    OUT    result_high_bit[6] — canonical 0x47C0[14] (default = 0)  │
 │  uio[7]    OUT    result_high_bit[7] — canonical 0x47C0[15] (default = 0)  │
 └─────────────────────────────────────────────────────────────────────────────┘
```

### Canonical default: 0x47C0

```
  {uio_out[7:0], uo_out[7:0]} = 16'h47C0
  Binary: 0100_0111_1100_0000
  Meaning: dot4(1.0, 2.0, 3.0, 4.0) in GF16 ternary encoding
  Theorem 36.1 cross-die anchor: φ² + φ⁻² = 3 (Lucas identity)
  Shared by all three Triad chips: Phi (#4914), Euler (#4915), Gamma (#4913)
```

---

## Pin Function Details

| Pin | Signal | Direction | Notes |
|-----|--------|-----------|-------|
| ui[0] | `load_mode` | IN | Core mode select. Low = canonical/POST; high = packet path. Shared protocol with Phi and Gamma — Phi drives this line as master via cross-tile handshake. |
| ui[1] | `data_bit[0]` | IN | Token payload bit 0. In packet path mode (`load_mode=1`), ui[7:1] carry 7-bit token or embedding data forwarded from Phi POST gate. |
| ui[2] | `data_bit[1]` | IN | Token payload bit 1. |
| ui[3] | `data_bit[2]` | IN | Token payload bit 2. |
| ui[4] | `data_bit[3]` | IN | Token payload bit 3. |
| ui[5] | `data_bit[4]` | IN | Token payload bit 4. |
| ui[6] | `data_bit[5]` | IN | Token payload bit 5. |
| ui[7] | `data_bit[6]` | IN | Token payload bit 6 (MSB of 7-bit data field). |
| uo[7:0] | `result_bit[7:0]` | OUT | Low byte of 16-bit ternary MAC result. Canonical: `0xC0`. After FSM compute: GF16 dot product output or SUPER-CROWN module result. |
| uio[7:0] | `result_high_bit[7:0]` | OUT | High byte of 16-bit result. Canonical: `0x47`. |

### Embedded module mapping (packet path)

When `load_mode=1`, `ui[7:1]` select the active SUPER-CROWN module or CLARA Gap block via `trinity_master_fsm`:

| `ui[3:1]` (data_bit[2:0]) | Block |
|---------------------------|-------|
| 000 | gf16_dot4 (ternary MAC, 4-element) |
| 001 | gf16_dot8 (ternary MAC, 8-element) |
| 010 | vsa_matmul_8x8 (VSA binding) |
| 011 | bitnet_encoder (BitNet b1.58 MLP) |
| 100 | bpb_counter (cross-entropy / BPB) |
| 101 | alu9_decoder (t27 ISA, 9-instruction) |
| 110 | ring27_memory (RING27 3³ ternary mem) |
| 111 | CLARA Gap router (gap index in data_bit[6:3]) |

---

## Clock and Reset Specification

| Parameter | Value |
|-----------|-------|
| Clock frequency | 50 MHz (target) |
| Clock period | 20 ns |
| Reset polarity | Active-low (`rst_n`) |
| Reset minimum pulse | 2 clock cycles minimum |
| Reset release | Synchronous release recommended |
| Post-reset latency | ≤ 1 clock cycle to assert 0x47C0 |
| FPGA-validated frequency | 323 MHz (XC7A100T — headroom confirmed) |
| Cell budget | ~16 000 gates @ 60% density (SKY130A) |

---

## Bring-Up Sequence

```
Step 1 — RESET
  Assert rst_n=0 for ≥ 4 clock cycles (80 ns at 50 MHz).
  Hold ui[7:0] = 0x00 during reset.

Step 2 — CHECK CANONICAL ANCHOR (0x47C0)
  Release rst_n=1. Wait 1 clock cycle (20 ns).
  Read {uio_out[7:0], uo_out[7:0]}.
  Expected: 0x47C0
  If mismatch → FAULT. Euler chip not passing POST gate.

Step 3 — POST (Power-On Self-Test)
  Set load_mode=0 (ui[0]=0).
  Assert compute_strobe via cross-tile handshake from Phi master
    (or directly: ui[6] rising edge if probing standalone).
  Verify anchor 0x47C0 stable across ≥ 3 clock cycles.
  POST COMPLETE when anchor is stable.

Step 4 — OPERATIONAL MODE (compute slave)
  Phi (master) drives ui[0]=load_mode=1 via board mux.
  Phi presents token on ui[7:1] (7-bit data field).
  Euler trinity_master_fsm latches token, routes to selected MAC/module.
  Result appears on {uio_out, uo_out} within FSM pipeline latency.
  Result forwarded to Gamma via board mux (see CROSS_TILE_INTERCONNECT.md).

Step 5 — CROSS-TILE SYNC
  See CROSS_TILE_INTERCONNECT.md for full 3-wire handshake protocol.
  Euler role: COMPUTE SLAVE (receives from Phi, sends to Gamma).
```

---

## SUPER-CROWN Modules Summary

| Module | Function |
|--------|----------|
| `phi_anchor_post` | Lucas POST: proves φ² + φ⁻² = 3 |
| `lucas_rom` | Addressable Lucas number ROM (L₂..L₇) |
| `vsa_matmul_8x8` / `16x16` | Ternary VSA matrix multiply (JEPA-T tier) |
| `bitnet_encoder` | BitNet b1.58 ternary MLP encoder |
| `bpb_counter` | On-chip cross-entropy / bits-per-byte counter |
| `blake3_anchor` | BLAKE3 receipt signer (G4 DePIN) |
| `multi_tile_receipt` + `crc32_receipt` | Multi-tile receipt + CRC32 |
| `alu9_decoder` | 9-instruction Trinity ternary ALU (t27 ISA) |
| `ring27_memory` | 27-cell 3³ ternary memory (Coptic) |
| `hwrng_lfsr` | Die-unique nonce LFSR |
| `phi_pll_div` | φ-PLL fractional divider |
| `wishbone_full` + `wb_status_reg` | Wishbone host interface |
| `trinity_master_fsm` | Packet master FSM |
| `d2d_holo_mesh` | 4-port N/E/S/W D2D router |

## DARPA CLARA AI Safety Gaps

| Gap | Module | TA |
|-----|--------|----|
| Gap-1 | `redteam_filter` | Adversarial detection |
| Gap-2 | `k3_alu` | Kleene K3 ternary ALU (TA1.1) |
| Gap-3 | `datalog_engine_mini` | Forward-chain Datalog |
| Gap-4 | `restraint_ctrl` | Bounded rationality (TA1.4) |
| Gap-5 | `explainability_unit` | Proof-trace emitter (TA1.2) |
| Gap-6 | `asp_solver_mini` | ASP solver with NAF |
| Gap-7 | `composition_kernel` | Orchestrator for Gaps 3/4/5 |
| Gap-8 | `proof_trace_writer` | On-chip audit receipt |
| Gap-9 | `sat_solver_mini` | DPLL SAT solver |
| Gap-10 | `audit_log_ring_buffer` | 64-entry event log |

---

## Related Documents

- [`docs/CROSS_TILE_INTERCONNECT.md`](CROSS_TILE_INTERCONNECT.md) — Cross-tile interconnect spec for Phi/Euler/Gamma DevKit board
- DOI: [10.5281/zenodo.19227877](https://doi.org/10.5281/zenodo.19227877) — Trinity Stack provenance
- Sibling: [TRI-1 Phi (#4914)](https://tinytapeout.com/runs/ttsky26b/tt_um_trinity_nano) — φ-anchor 1×1 (master)
- Sibling: [TRI-1 Gamma (#4913)](https://tinytapeout.com/runs/ttsky26b/tt_um_trinity_max_true) — γ-surface 8×4
