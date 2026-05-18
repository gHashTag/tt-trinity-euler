# CL-01: Promote D2D `RESTRAINT_HOLD` (KIND=0x4) from SPEC-DRAFT to RTL

**Local plan ID:** `#1`  (placeholder — not a GitHub issue number yet)
**Track:** CLARA alignment
**SIP row:** [`docs/SCIENTIFIC_IMPROVEMENT_PLAN.md`](../../docs/SCIENTIFIC_IMPROVEMENT_PLAN.md) §2 CL-01
**Label:** `target`

## Context

`docs/D2D_PROTOCOL.md` §4.3 defines a `KIND=0x4 RESTRAINT_HOLD` frame as
the cross-die signal that Euler has gated activity downstream. Today the
local restraint logic lives in `src/restraint_ctrl.v` but never reaches a
D2D-observable frame.

This row promotes one `SPEC-DRAFT` framing row to `RTL` — the one with
the cleanest composition path (`restraint_ctrl` already exists).

## Scope

- New (or extended) RTL that maps `restraint_ctrl.hold` to a
  D2D-observable signal on one TX port of `d2d_holo_mesh`.
- Pin contract is **unchanged**; the framing rides on existing TX wires.
- Audit-ring entry on each transition.

## Out of scope

- Full packet framer for all 8 `KIND` values — that stays `SPEC-DRAFT`.
- Multi-hop routing — `PLANNED` per `D2D_PROTOCOL.md` §7.
- Any silicon-side measurement.

## Acceptance criteria

- [ ] RTL change merged into `src/`.
- [ ] Testbench under `sim/` or `test/` asserts the frame on `hold = 1` and on `hold = 0`.
- [ ] `iverilog` GF16 dot4/dot8 testbench still reports `TOTAL PASS=17 FAIL=0`.
- [ ] R-SI-1 `no_star.yaml` still green.
- [ ] `docs/D2D_PROTOCOL.md` §4.3 row for `KIND=0x4` re-labelled from `SPEC-DRAFT` to `RTL`.
- [ ] `STATUS.md §3` Evidence table updated.

## Non-claims

- Does not assert the full D2D mesh is functional.
- Does not claim measured TOPS/W or silicon behaviour.
- Does not promote any other `SPEC-DRAFT` row.
