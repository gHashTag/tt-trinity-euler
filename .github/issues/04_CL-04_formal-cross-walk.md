# CL-04: CLARA gap → RTL → Coq formal cross-walk annotation

**Local plan ID:** `#4`  (placeholder)
**Track:** CLARA alignment
**SIP row:** [`docs/SCIENTIFIC_IMPROVEMENT_PLAN.md`](../../docs/SCIENTIFIC_IMPROVEMENT_PLAN.md) §2 CL-04
**Label:** `target`

## Context

[`CLARA_TRACEABILITY.md`](../../CLARA_TRACEABILITY.md) has the gap→RTL
mapping. The Coq citation per row is uneven.

## Scope

- For each CLARA row, add an explicit `trios-coq` proof file reference
  with per-file `Qed` / `Admitted` notes (file-level, not as a total).
- Cross-link from the SIP §2 CL-04 line.

## Out of scope

- Writing new proofs.
- Modifying `trios-coq/` content.

## Acceptance criteria

- [ ] Every CLARA row in `CLARA_TRACEABILITY.md` cites at least one
      `trios-coq/Physics/*.v` or `trios-coq/<Domain>/*.v` file, or
      explicitly states "no proof tied to this row yet".
- [ ] Each cited path resolves.

## Non-claims

- Does not claim aggregate proof coverage.
- Does not alter the `STATUS.md §4` honest-disclosure block.
