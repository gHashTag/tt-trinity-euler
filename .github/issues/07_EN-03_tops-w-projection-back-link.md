# EN-03: TOPS/W projection back-link audit; refuse `1000×` / `4000 TOPS/W`

**Local plan ID:** `#7`  (placeholder)
**Track:** Energy efficiency
**SIP row:** [`docs/SCIENTIFIC_IMPROVEMENT_PLAN.md`](../../docs/SCIENTIFIC_IMPROVEMENT_PLAN.md) §3 EN-03
**Label:** `target` (maintenance)

## Context

The README cites "75 / 405 / 5.4× / ~20 TOPS / <1 W" figures.
[`BENCHMARKS.md §4`](../../BENCHMARKS.md) and
[`docs/PROJECTIONS_22FDX.md`](../../docs/PROJECTIONS_22FDX.md) state
these are `PROJECTED`. External press figures of `1000×` or
`4000 TOPS/W` are `VERIFY`-only and must not be restated as fact.

This row is an ongoing audit, not a one-shot delivery.

## Scope

- Periodic grep audit across markdown files for any TOPS/W or `×` number
  that lacks a tier label or assumption clause.
- Any failing line is either edited to add the qualifier or removed.

## Acceptance criteria (per audit)

- [ ] Grep across `**/*.md` for `TOPS/W`, `TOPS`, `×`, `1000x`, `4000`
      returns zero unqualified lines.
- [ ] No new measured-tier row added.

## Non-claims

- Does not introduce a new TOPS/W number.
- Does not weaken any existing `BENCHMARKS.md §2` row.
- Does not endorse external press figures.
