# OS-03: Author short `CONTRIBUTING.md`

**Local plan ID:** `#16`  (placeholder)
**Track:** Open source
**SIP row:** [`docs/SCIENTIFIC_IMPROVEMENT_PLAN.md`](../../docs/SCIENTIFIC_IMPROVEMENT_PLAN.md) §6 OS-03
**Label:** `target`

## Context

There is no `CONTRIBUTING.md` in the repo. First-PR contributors have to
piece together the workflow from `STATUS.md`, `BENCHMARKS.md`, and the
CI files.

## Scope

- A short `CONTRIBUTING.md` covering:
  - How to run the local checks (OS-02 `make check` if it has landed,
    otherwise the commands from `STATUS.md §2`).
  - The readiness ladder ([STATUS.md §1](../../STATUS.md)).
  - The tier rule from [BENCHMARKS.md §1](../../BENCHMARKS.md) (every
    number is `MEASURED` / `SIMULATED` / `SYNTHESIS-REPORTED` /
    `PROJECTED` — no bare numbers).
  - Pointer to [`docs/SCIENTIFIC_IMPROVEMENT_PLAN.md`](../../docs/SCIENTIFIC_IMPROVEMENT_PLAN.md)
    for the planned-work picture.

## Out of scope

- A code-of-conduct file (separate, not part of this row).
- Templated PR/issue forms.

## Acceptance criteria

- [ ] `CONTRIBUTING.md` exists at repo root.
- [ ] Linked from `README.md`.

## Non-claims

- Does not modify CI gating.
- Does not weaken any honesty rule.
