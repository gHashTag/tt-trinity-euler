# SN-02: D2D `SPIKE_SUMMARY` (KIND=0x1) RX frame-aligned counter (RTL)

**Local plan ID:** `#9`  (placeholder)
**Track:** SNN-TRI fusion
**SIP row:** [`docs/SCIENTIFIC_IMPROVEMENT_PLAN.md`](../../docs/SCIENTIFIC_IMPROVEMENT_PLAN.md) §4 SN-02
**Label:** `target`

## Context

The current `src/d2d_holo_mesh` stub emits `spike_count` MSB on `n_tx`
and LSB on `e_tx`; on the RX path the data is latched but not
frame-aligned. A SNN-TRI consumer needs to read a frame-aligned count.

## Scope

- Extend the RX path of `src/d2d_holo_mesh.v` to accumulate a
  fixed-width spike counter aligned to the existing SYNC strobe
  (`w_tx` / `w_rx` direction).
- Pin contract unchanged.
- R-SI-1 compliant.

## Out of scope

- The full `SPIKE_SUMMARY` framing across all four directions — keep
  scope minimal.
- Cross-die back-pressure (that's SN-03).

## Acceptance criteria

- [ ] RTL change merged.
- [ ] Testbench exercises a known spike pattern and reads the
      frame-aligned count.
- [ ] `iverilog` baseline `TOTAL PASS=17 FAIL=0` still passes.
- [ ] R-SI-1 audit green.

## Non-claims

- Does not assert measured neural workload throughput.
- Does not change `d2d_holo_mesh`'s pin contract.
