# SN-03: Restraint-driven back-pressure as D2D-observable frame

**Local plan ID:** `#10`  (placeholder)
**Track:** SNN-TRI fusion
**SIP row:** [`docs/SCIENTIFIC_IMPROVEMENT_PLAN.md`](../../docs/SCIENTIFIC_IMPROVEMENT_PLAN.md) §4 SN-03
**Label:** `target`

This row composes with **CL-01** (the same `KIND=0x4 RESTRAINT_HOLD`
frame), but viewed from the SNN-side as back-pressure. Implementations
may close both rows with one RTL change as long as both acceptance lists
are satisfied.

## Scope

- A SNN-TRI consumer must observe a stable, frame-aligned restraint
  signal — not an internal-only flag.
- Reuse the `RESTRAINT_HOLD` framing from `docs/D2D_PROTOCOL.md` §4.3
  (no new `KIND` value).

## Out of scope

- Adaptive / windowed back-pressure semantics — keep it binary first.

## Acceptance criteria

- [ ] Restraint state observable on a D2D RX face from at least one
      neighbour direction.
- [ ] Testbench shows downstream traffic ceasing within one local clock
      cycle of `hold = 1`.
- [ ] `iverilog` baseline `TOTAL PASS=17 FAIL=0` still passes.

## Non-claims

- Does not implement multi-level priority.
- Does not assert measured silicon back-pressure latency.
