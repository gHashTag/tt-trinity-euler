# CL-02: CLARA traceability proof-status sweep

**Local plan ID:** `#2`  (placeholder)
**Track:** CLARA alignment
**SIP row:** [`docs/SCIENTIFIC_IMPROVEMENT_PLAN.md`](../../docs/SCIENTIFIC_IMPROVEMENT_PLAN.md) §2 CL-02
**Label:** `target`

## Context

[STATUS.md §5](../../STATUS.md) calls for a CLARA traceability
proof-status sweep. Today [`CLARA_TRACEABILITY.md`](../../CLARA_TRACEABILITY.md)
maps each CLARA gap to its RTL module; the per-row Coq status column is
uneven.

## Scope

- For every row in `CLARA_TRACEABILITY.md`, set the proof column to one
  of `Qed`, `Admitted`, or `not started`, citing the specific Coq file.
- Conservative bias: prefer `Admitted` or `not started` over `Qed` if
  evidence is ambiguous.

## Out of scope

- Writing new proofs. This row is documentation / annotation only.
- Re-counting `Qed` / `Admitted` totals (the existing note in
  `STATUS.md §4` already covers this).

## Acceptance criteria

- [ ] `CLARA_TRACEABILITY.md` proof column populated for every row.
- [ ] Every cited Coq file path resolves.
- [ ] `STATUS.md §5` checklist item marked complete with a back-link.

## Non-claims

- Does not claim every CLARA gap is `Qed`-closed.
- Does not change `STATUS.md §1` ladder for any row.
