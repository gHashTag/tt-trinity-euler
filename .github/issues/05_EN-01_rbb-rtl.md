# EN-01: Add `src/rbb_active_path.v` (Deck-1 RBB)

**Local plan ID:** `#5`  (placeholder)
**Track:** Energy efficiency / Triple-Deck
**SIP row:** [`docs/SCIENTIFIC_IMPROVEMENT_PLAN.md`](../../docs/SCIENTIFIC_IMPROVEMENT_PLAN.md) §3 EN-01
**Label:** `target`

## Context

[`docs/TRIPLE_DECK_STATUS.md`](../../docs/TRIPLE_DECK_STATUS.md) §3
records Deck-1 (RBB) as **`SPEC`-only** on Euler today: the ISA opcode
(`OP_RBB = 0xF1`) and `trios-coq/Physics/RBB.v` exist, but there is no
dedicated `rbb_*.v` module. Leakage objective today is partially covered
by `drowsy_ret.v` + `subth_clk.v`.

## Scope

- New `src/rbb_active_path.v` module mirroring the shape of
  `src/fbb_active_path.v` (opcode-decoded, status register, body-bias
  level register).
- R-SI-1 compliant (zero new `*` operators).
- Verilog-2005.

## Out of scope

- Cross-deck exclusivity assertion — that's EN-02.
- Any TOPS/W claim. RBB landing does **not** promote any
  `PROJECTED` row to `MEASURED`.

## Acceptance criteria

- [ ] `src/rbb_active_path.v` merged.
- [ ] Testbench under `test/` or `sim/`.
- [ ] R-SI-1 `no_star.yaml` green on the new file.
- [ ] `iverilog` baseline test still `TOTAL PASS=17 FAIL=0`.
- [ ] `docs/TRIPLE_DECK_STATUS.md` §3 Deck-1 row promoted from `SPEC` to
      `RTL`; `STATUS.md §3` evidence table updated.

## Non-claims

- Does not claim measured leakage reduction on silicon.
- Does not claim the 22FDX TOPS/W projection is now measured.
- Does not change the "1000× / 4000 TOPS/W stays `VERIFY`" rule.
