# Triple-Deck Status — e-engine RBB→FBB→CAP_BOOST

**Document ID:** TRINITY-TRIPLEDECK-V0.1
**Status:** SPEC + EVIDENCE — readiness label per row
**Last updated:** 2026-05-18
**Scope:** TRI-1 Euler (this repo). Cross-chip conformance contract is
described in §4 so that TRI-1 Phi and TRI-1 Gamma can match.
**Companion docs:** [BENCHMARKS.md](../BENCHMARKS.md), [STATUS.md](../STATUS.md),
[`docs/HARDWARE-IMPLEMENTATION.md`](HARDWARE-IMPLEMENTATION.md)

---

## 1. What "Triple-Deck" means in the e-engine

The Triple-Deck is the three-stage low-power composition specific to the
Euler e-engine: as a workload moves from idle through active to peak boost,
the chip transitions through three distinct biasing / voltage strategies.

```
    idle ──RBB──▶ active ──FBB──▶ peak ──CAP_BOOST──▶
                                              │
                                              └─▶ thermal/restraint envelope
```

| Deck | Role | Goal | Biasing strategy |
|---|---|---|---|
| **Deck 1 — RBB** | idle / standby PEs | minimise leakage | Reverse Body Bias raises Vth on idle paths |
| **Deck 2 — FBB** | active path | reduce delay at iso-voltage | Forward Body Bias lowers Vth where compute is happening |
| **Deck 3 — CAP_BOOST** (AVS-96) | peak / burst | maximise TOPS/W at a higher V-island | Adaptive Voltage Scaling lifts the active island to a higher rail temporarily |

The transitions are mutually exclusive at a given path: a path is either
RBB-biased, FBB-biased, or in CAP_BOOST — never two at once. This
exclusivity is part of the cross-chip conformance contract (§4).

---

## 2. Implemented evidence on Euler (per deck)

> **Readiness labels** match the convention used in
> [STATUS.md §1](../STATUS.md): `SPEC`, `RTL`, `SIM`, `SYNTH`, `GDS-SUBMIT`,
> `SILICON`. No row in this section is `SILICON`.

### Deck 1 — RBB (Reverse Body Bias)

| Item | Status | Evidence |
|---|---|---|
| RBB opcode in ISA (sacred bank, `0xF1 = OP_RBB`) | `SPEC` | [`trios-coq/Physics/RBB.v`](../trios-coq/Physics/RBB.v): `Definition OP_RBB := 241.` |
| RBB Coq lemmas (composite, distinctness, monotonicity) | `SPEC` (Coq `Qed` for stated lemmas; some `Admitted` per file) | [`trios-coq/Physics/RBB.v`](../trios-coq/Physics/RBB.v) |
| Standalone `rbb_*.v` RTL module | **NOT PRESENT in this branch** — `src/` contains no `rbb_*.v` file | `ls src/ \| grep -i rbb` → empty |
| RBB-equivalent leakage control via clock/retention path | `RTL` (related but not identical) | [`src/drowsy_ret.v`](../src/drowsy_ret.v) (drowsy retention), [`src/subth_clk.v`](../src/subth_clk.v) (sub-threshold clock) |

> **Honest disclosure:** Deck-1 RBB on Euler is **specified at the ISA /
> Coq level but is not yet a dedicated RTL module in this branch.** The
> leakage objective is partially covered by `drowsy_ret.v` and
> `subth_clk.v`. Promoting RBB to a dedicated `rbb_*.v` module is a
> `PLANNED` work item for a future wave.

### Deck 2 — FBB (Forward Body Bias)

| Item | Status | Evidence |
|---|---|---|
| FBB RTL module | `RTL` | [`src/fbb_active_path.v`](../src/fbb_active_path.v) — opcode `0xF2`, 5 FBB levels (`FBB_OFF/LOW/MED/HIGH/MAX`), leakage monitor input, status register |
| FBB Coq proofs | `SPEC` (`Qed` for several lemmas — count per file under `trios-coq/Physics/`) | [`trios-coq/Physics/FBBActive.v`](../trios-coq/Physics/FBBActive.v), [`trios-coq/Physics/FBBActive2.v`](../trios-coq/Physics/FBBActive2.v) |
| Tiny CapBoost (FBB) label in IGLA RACE wave table | `RTL` | [`docs/HARDWARE-IMPLEMENTATION.md`](HARDWARE-IMPLEMENTATION.md) §1.3 Wave W49 |
| Testbench for FBB path | `SIM` (lightweight) | [`test/tb_fbb_active_path.v`](../test/tb_fbb_active_path.v) |

> **Honest disclosure:** the doc string in `fbb_active_path.v` labels the
> module as the "CapBoost (FBB)" wave (W49). That naming reflects the wave
> history, not the Triple-Deck taxonomy: this module is **Deck 2 (FBB)**
> in the Triple-Deck sense, and Deck 3 (CAP_BOOST) is owned by AVS-96
> (next row). The dual naming is a historical artefact tracked here so
> future readers don't conflate them.

### Deck 3 — CAP_BOOST (AVS-96)

| Item | Status | Evidence |
|---|---|---|
| AVS-96 RTL module | `RTL` | [`src/avs_controller_96.v`](../src/avs_controller_96.v) — 96 islands, 4 voltage levels (0.75 / 0.85 / 0.95 / 1.05 V), thermal monitor, power gate output |
| AVS-96 Coq proofs | `SPEC` (`Qed` count per file) | [`trios-coq/Physics/CapBoost.v`](../trios-coq/Physics/CapBoost.v), [`trios-coq/Physics/PowerCapping.v`](../trios-coq/Physics/PowerCapping.v) |
| CAP_BOOST → TOPS/W contribution claim ("5.4× boost: 75 → 405 TOPS/W") | `PROJECTED` — not measured on silicon | [BENCHMARKS.md §4](../BENCHMARKS.md), README "Green AI Manifesto" — the 5.4× is a projection, not a measurement |
| AVS-48 (predecessor / lower-island variant) | `RTL` (referenced) | [`docs/HARDWARE-IMPLEMENTATION.md`](HARDWARE-IMPLEMENTATION.md) §1.3 Wave W36 |

> **Honest disclosure:** the "5.4× TOPS/W boost" headline associated with
> CAP_BOOST is a `PROJECTED` number on a 22 FDX-class node under stated
> assumptions, **not** a SKY130A measurement and **not** a measurement at
> all (TTSKY26b silicon has not returned). See
> [BENCHMARKS.md §4](../BENCHMARKS.md) for the authoritative caveat
> language.

### Cross-cutting power / restraint controls

These are not "decks" but they gate Triple-Deck transitions:

| Item | Status | Evidence |
|---|---|---|
| Purkinje thermal gate | `RTL` | [`src/purkinje_thermal_gate.v`](../src/purkinje_thermal_gate.v) |
| Restraint controller (control-engine) | `RTL` | [`src/restraint_ctrl.v`](../src/restraint_ctrl.v) |
| Sub-threshold clock | `RTL` | [`src/subth_clk.v`](../src/subth_clk.v) |
| Drowsy retention | `RTL` | [`src/drowsy_ret.v`](../src/drowsy_ret.v) |

---

## 3. Summary — what is real on Euler today

| Deck | Owned by | Readiness on Euler |
|---|---|---|
| **Deck 1 (RBB)** | ISA + Coq | `SPEC` only — no dedicated RTL module; leakage objective partially covered by `drowsy_ret.v` + `subth_clk.v` |
| **Deck 2 (FBB)** | `fbb_active_path.v` | `RTL` + lightweight `SIM` + `SPEC` (Coq) |
| **Deck 3 (CAP_BOOST / AVS-96)** | `avs_controller_96.v` | `RTL` + `SPEC` (Coq); TOPS/W claim is `PROJECTED` only |

> **Bottom line for marketing:** Euler can honestly claim "Deck 2 + Deck 3
> implemented in RTL with Coq spec; Deck 1 specified in ISA + Coq, RTL is a
> `PLANNED` add-on; full Triple-Deck silicon validation awaits TTSKY26b
> return."

---

## 4. Cross-chip conformance contract

This section defines the **minimum surface a sibling chip (Phi, Gamma)
must expose** to claim Triple-Deck conformance. The contract is
intentionally permissive about *internal implementation* and strict about
*observable behaviour*.

### 4.1 Conformance levels

| Level | Meaning |
|---|---|
| **C0 — Spec-only** | ISA opcode and Coq spec exist for all three decks; no RTL |
| **C1 — Partial RTL** | At least one deck has an RTL module in `src/` matching the opcode |
| **C2 — All three decks in RTL** | All three deck opcodes have a dedicated `src/*.v` module |
| **C3 — Cross-deck exclusivity proven** | RTL or formal evidence that a given path is never in two decks simultaneously |
| **C4 — Triple-Deck on silicon** | Measured transitions on returned silicon (per-deck power deltas captured in `boards/`) |

### 4.2 Where each chip sits in the line

> **Cross-chip rows below are inferred from public repository structure
> and the line's [LINEUP.md](../LINEUP.md). Sibling chips MUST publish
> their own `TRIPLE_DECK_STATUS.md` (or equivalent) before these rows can
> be cited normatively.**

| Chip | Conformance level (claim from this repo's perspective) | Notes |
|---|---|---|
| **TRI-1 Euler** (this repo) | **C1.5** — Deck-2 and Deck-3 RTL present; Deck-1 spec-only | See §3 |
| **TRI-1 Phi** | unknown to this repo | Phi's 1×1 tile budget likely makes a full Triple-Deck infeasible; a sibling-side doc is required |
| **TRI-1 Gamma** | unknown to this repo | Wider PE surface; the Triple-Deck should compose naturally but a sibling-side doc is required |
| **`t27` toolchain** | n/a — toolchain repo | Owns the opcode registry that all three chips lower against |

### 4.3 Required conformance evidence

A sibling repository that claims Triple-Deck conformance MUST publish, in
its own equivalent of this file:

1. The ISA opcode and Coq spec ID for each deck (or an explicit "not
   applicable — Deck-N is intentionally omitted on this SKU" row).
2. A path from each opcode to either an RTL module under `src/`, a
   testbench under `sim/` or `test/`, or both.
3. A readiness label for every row, drawn from the same ladder as
   [STATUS.md §1](../STATUS.md).
4. Either:
   - an RTL or formal argument for **cross-deck exclusivity** (a path is
     never RBB and FBB simultaneously, never FBB and CAP_BOOST
     simultaneously), or
   - an explicit row noting "exclusivity not yet proven" (this is
     acceptable at C1/C2 levels but blocks C3+).
5. Honest separation between `PROJECTED` and `MEASURED` TOPS/W numbers in
   the chip's `BENCHMARKS.md`.

### 4.4 What the contract does NOT require

- Sibling chips MAY omit a deck if their tile budget / role doesn't admit
  it. Phi at 1×1 is the obvious case for omitting Deck 3.
- Sibling chips MAY name their decks differently (e.g. "low / mid / high"
  instead of "RBB / FBB / CAP_BOOST") as long as the opcode mapping in
  §4.3.1 is explicit.
- Sibling chips MAY achieve a deck objective with a different RTL module
  name. Conformance is on *opcode and observable behaviour*, not on
  module filename.

---

## 5. Promotion rules

A row in §2 promotes from one readiness level to the next only when there
is a reproducible artefact in this repository (or a linked CI run). The
specific rules:

| From → To | Required artefact |
|---|---|
| `SPEC → RTL` | A `src/*.v` module exists that maps to the opcode |
| `RTL → SIM` | A testbench under `sim/` or `test/` exercises the module and is in CI |
| `SIM → SYNTH` | OpenLane2 run logs the module synthesised cleanly |
| `SYNTH → GDS-SUBMIT` | The module is in `info.yaml` `source_files:` for a submitted shuttle |
| `GDS-SUBMIT → SILICON` | Returned die exercises the deck and the bring-up data is under `boards/` |

This matches the global ladder in [STATUS.md](../STATUS.md) §1 — Triple-Deck
rows must not invent their own promotion criteria.

---

## 6. Open items (in priority order)

These are the items that, if completed, would let us move a row above
from PARTIAL to DONE:

1. **Add `src/rbb_active_path.v`** (or equivalent) — a dedicated RTL
   module for OP_RBB so Deck 1 leaves `SPEC` and enters `RTL`. Target a
   future wave; not in scope for this documentation pass.
2. **Cross-deck exclusivity assertion** — a small SystemVerilog assertion
   (or Coq lemma) showing that no path is RBB + FBB simultaneously. This
   is the C2 → C3 promotion gate.
3. **Per-deck power delta measurement plan** — required before TTSKY26b
   silicon returns, so the post-bring-up section in
   [STATUS.md §6](../STATUS.md) can be populated.

---

## 7. Links

- Wave / opcode table: [`docs/HARDWARE-IMPLEMENTATION.md`](HARDWARE-IMPLEMENTATION.md) §1.3
- Coq proofs: [`trios-coq/Physics/RBB.v`](../trios-coq/Physics/RBB.v),
  [`trios-coq/Physics/FBBActive.v`](../trios-coq/Physics/FBBActive.v),
  [`trios-coq/Physics/CapBoost.v`](../trios-coq/Physics/CapBoost.v)
- TOPS/W disclosure: [BENCHMARKS.md §4](../BENCHMARKS.md)
- Readiness ladder: [STATUS.md §1](../STATUS.md)
- Sibling line position: [LINEUP.md](../LINEUP.md)
- 2026 plan tracking Deck-1 promotion and cross-deck exclusivity: [`docs/SCIENTIFIC_IMPROVEMENT_PLAN.md`](SCIENTIFIC_IMPROVEMENT_PLAN.md) §3 EN-01 + EN-02 (both `target`; Deck-1 RBB remains `SPEC`-only until `src/rbb_active_path.v` lands).
