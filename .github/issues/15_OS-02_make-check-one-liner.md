# OS-02: `make check` one-liner for new contributors

**Local plan ID:** `#15`  (placeholder)
**Track:** Open source
**SIP row:** [`docs/SCIENTIFIC_IMPROVEMENT_PLAN.md`](../../docs/SCIENTIFIC_IMPROVEMENT_PLAN.md) §6 OS-02
**Label:** `target`

## Context

[STATUS.md §2](../../STATUS.md) documents two reproducible local checks:
the `iverilog` GF16 dot4/dot8 testbench and the R-SI-1 audit. A new
contributor has to copy commands out of the doc.

## Scope

- Add a top-level `Makefile` target (or shell entry point) called
  `check` that runs both checks and exits non-zero on failure.
- Does **not** modify `.github/workflows/`.

## Out of scope

- Re-implementing the R-SI-1 filter inside the Makefile — call the
  workflow's logic out-of-line if needed.
- Adding new checks beyond the two already in `STATUS.md §2`.

## Acceptance criteria

- [ ] `make check` runs both checks from a clean checkout.
- [ ] `STATUS.md §2` updated to mention `make check`.

## Non-claims

- Does not change CI gating.
- Does not introduce new test surface.
