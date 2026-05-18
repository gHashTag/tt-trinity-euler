# EN-02: Cross-deck exclusivity assertion (RBB / FBB / CAP_BOOST)

**Local plan ID:** `#6`  (placeholder)
**Track:** Energy efficiency / Triple-Deck
**SIP row:** [`docs/SCIENTIFIC_IMPROVEMENT_PLAN.md`](../../docs/SCIENTIFIC_IMPROVEMENT_PLAN.md) §3 EN-02
**Label:** `target`

## Context

[`docs/TRIPLE_DECK_STATUS.md`](../../docs/TRIPLE_DECK_STATUS.md) §1
states the three decks are mutually exclusive at any given path. This is
asserted in prose only — there is no RTL assertion and no Coq lemma
backing it. The C2 → C3 promotion gate in §4.1 of that doc requires
exclusivity proof.

## Scope

- One RTL assertion (`assert property` style if supported by the
  simulator, or a constant-folded check inside a testbench) confirming
  that no path is simultaneously RBB-biased and FBB-biased, and not
  simultaneously FBB-biased and in CAP_BOOST.
- OR one Coq lemma in `trios-coq/Physics/` proving the same invariant.

## Out of scope

- Adding RBB RTL (that's EN-01; this row depends on EN-01 once filed).
- Full per-island exclusivity if AVS-96 islands are independent — keep
  the assertion scoped to the path-level invariant first.

## Acceptance criteria

- [ ] At least one of the two evidence forms above merged.
- [ ] `docs/TRIPLE_DECK_STATUS.md` §4.1 conformance level updated from
      C1.5 to C2 (or C3 if Coq-backed) for Euler.

## Non-claims

- Does not assert silicon-level exclusivity.
- Does not change any `BENCHMARKS.md §2` row.
