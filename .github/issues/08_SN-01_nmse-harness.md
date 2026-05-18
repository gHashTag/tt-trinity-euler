# SN-01: Land NMSE harness; produce first `sim/nmse/euler_*.json`

**Local plan ID:** `#8`  (placeholder)
**Track:** SNN-TRI fusion / accuracy
**SIP row:** [`docs/SCIENTIFIC_IMPROVEMENT_PLAN.md`](../../docs/SCIENTIFIC_IMPROVEMENT_PLAN.md) §4 SN-01
**Label:** `target`

## Context

[`docs/GF16_BFLOAT16_NMSE.md`](../../docs/GF16_BFLOAT16_NMSE.md) defines
the standard NMSE comparison protocol over the existing
`sim/tb_gf16_dot8.v` testbench. The harness itself is `PLANNED`. **No
`Δ_dB` number may appear anywhere in this repo until this row lands.**

## Scope

- `sim/nmse/run_nmse.py` (or equivalent) — generates vectors,
  drives `tb_gf16_dot8.v`, computes NMSE for GF16 vs an FP64 reference
  and for a bfloat16 software path.
- Output: at least one `sim/nmse/results/euler_<date>.json` record
  matching the schema in `GF16_BFLOAT16_NMSE.md` §3.5.
- bfloat16 path is a software reference only (no hardware bfloat16).

## Out of scope

- A measured silicon NMSE. Tier is `SIMULATED` per
  `BENCHMARKS.md §1`.
- Workloads other than the dot-8 inner product.
- Cross-chip NMSE for Phi / Gamma — they own their own harnesses.

## Acceptance criteria

- [ ] Harness merged.
- [ ] One `euler_*.json` record committed.
- [ ] Caveat block from `GF16_BFLOAT16_NMSE.md` §6 added to any
      external quote.
- [ ] `BENCHMARKS.md §2` gains a `SIMULATED` NMSE row pointing at the
      JSON record.

## Non-claims

- Does not promote NMSE to `MEASURED`.
- Does not generalise to transformer / convolution workloads.
- Does not claim "GF16 beats bfloat16" — the harness reports numbers; the
  numbers are read with the protocol's caveat block.
