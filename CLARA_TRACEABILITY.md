# CLARA_TRACEABILITY — TRI-1 Euler

**Last updated:** 2026-05-17
**Programme reference:** DARPA CLARA — <https://www.darpa.mil/research/programs/clara>
**Scope:** maps each of the 10 CLARA-style AI-safety capability "gaps"
claimed by TRI-1 Euler to (a) the RTL module that implements it, (b) the
local simulation / lint / CI evidence inside *this* checkout, and (c) the
external proof artefact, if any, that closes the property.

> **Disclaimer.** This document does **not** claim a DARPA CLARA award,
> selection, or contractual relationship. The programme structure (TA1
> Composition, TA1.1 Symbolic Reasoning, TA1.2 Explainability, TA1.4
> Bounded Rationality) is taken from the public programme page above and
> used here as a taxonomy. Module mappings are the project's own design.

---

## 1. How to read this table

For each gap there are three evidence columns:

- **RTL** — file exists at the cited path inside this repo. `grep -l` will
  find it.
- **Local SIM / lint** — what we run inside the repo's CI today to keep
  this module honest. "—" means we have no per-module functional check
  *yet* beyond elaboration + the top-level canonical test.
- **External proof** — references to Coq/Rocq lemmas listed in
  [`docs/CLARA_PROOF_MANIFEST.md`](docs/CLARA_PROOF_MANIFEST.md). Those
  lemmas live in an **external** repository (`trinity-clara/theorems/`)
  that is **not vendored into this checkout**. We mark such rows
  `Qed (external)` and they should be re-checked against the external
  repo before being quoted.

---

## 2. Gap-by-gap traceability table

| Gap | CLARA TA bucket | Module (in `src/`) | RTL evidence | Local SIM / lint evidence | External proof (per [`docs/CLARA_PROOF_MANIFEST.md`](docs/CLARA_PROOF_MANIFEST.md)) |
|----:|:---:|---|---|---|---|
| **Gap-1** Adversarial detection | TA1 | [`redteam_filter.v`](src/redteam_filter.v) | present, ~250 cells | R-SI-1 lint via [`no_star.yaml`](.github/workflows/no_star.yaml); elaboration via top-level CI | `Qed (external)` — `trinity-clara/theorems/gap_1.v`. Invariant: `∀ x ∈ adversarial_class → filter_block(x)=1` |
| **Gap-2** Kleene K3 ternary ALU | TA1.1 | [`k3_alu.v`](src/k3_alu.v) | present, ~150 cells | R-SI-1 lint; elaboration | `Qed (external)` — `gap_2.v`. Invariant: K3 truth-tables for ∧/∨/¬ on `{0, K_UNKNOWN, 1}` |
| **Gap-3** Datalog engine | TA1 | [`datalog_engine_mini.v`](src/datalog_engine_mini.v) | present, ~500 cells, 16 clauses | R-SI-1 lint; elaboration | `Qed (external)` — `gap_3.v`. Invariant: `⊢_datalog F ↔ F ∈ lfp(T_P)` (termination O(\|EDB\|²)) |
| **Gap-4** Bounded rationality | TA1.4 | [`restraint_ctrl.v`](src/restraint_ctrl.v) | present, ~100 cells | R-SI-1 lint; elaboration. Cross-referenced with phi-anchor (`tt-trinity-phi`) which also implements Gap-4 | `Qed (external)` — `gap_4.v`. Invariant: `cost_exceeded → output = K_UNKNOWN` |
| **Gap-5** Explainability / proof trace | TA1.2 | [`explainability_unit.v`](src/explainability_unit.v) | present, ~200 cells, 5-tuple `(op, arg0, arg1, result, confidence)` | R-SI-1 lint; elaboration | `Qed (external)` — `gap_5.v`. Invariant: every emitted decision writes a trace entry |
| **Gap-6** ASP solver with NAF | TA1.1 | [`asp_solver_mini.v`](src/asp_solver_mini.v) | present, ~300 cells | R-SI-1 lint; elaboration | `Qed (external)` — `gap_6.v`. Invariant: `answer_set(P) ⊆ stable_models(P)` |
| **Gap-7** Composition kernel | (orchestration) | [`composition_kernel.v`](src/composition_kernel.v) | present, ~250 cells; sequences Gap-3 → Gap-4 → Gap-5 | R-SI-1 lint; elaboration | `Qed (external)` — `gap_7.v`. Invariant: dependency order preserved |
| **Gap-8** Audit receipt | (audit) | [`proof_trace_writer.v`](src/proof_trace_writer.v) | present, ~150 cells | R-SI-1 lint; elaboration. Pairs with [`blake3_anchor.v`](src/blake3_anchor.v) for cryptographic receipt | `Qed (external)` — `gap_8.v`. Invariant: receipt is deterministic given inputs (collision-resistance under fixed PRF) |
| **Gap-9** SAT solver (DPLL) | (symbolic) | [`sat_solver_mini.v`](src/sat_solver_mini.v) | present, ~500 cells; 8 vars × 16 clauses | R-SI-1 lint; elaboration | `Qed (external)` — `gap_9.v`. Invariant: `sat_solver(φ)=SAT ↔ ∃σ: σ⊨φ` |
| **Gap-10** Audit log ring buffer | (audit) | [`audit_log_ring_buffer.v`](src/audit_log_ring_buffer.v) | present, 64-entry circular log, ~300 cells | R-SI-1 lint; elaboration | `Qed (external)` — `gap_10.v`. Invariant: no committed event is overwritten until buffer is full |

---

## 3. Anchor invariant (cross-gap, cross-die)

Beyond the 10 gaps there is a line-wide *anchor invariant* the line uses
as a power-on self-test (POST):

> **TG-TRIAD-X 36.1.** After reset, before `load_mode = 1`, every TRI-NET
> die emits `{uio_out, uo_out} = 0x47C0` — the canonical `gf16_dot4(1, 2,
> 3, 4)` result — gated by the φ²+φ⁻²=3 Lucas chain.

| Component | Evidence in this repo |
|---|---|
| `gf16_dot4` canonical | [`src/gf16_dot4.v`](src/gf16_dot4.v), validated by [`sim/tb_gf16_dot8.v`](sim/tb_gf16_dot8.v) test `dot4_canonical` — **passes locally** (see [STATUS.md §2](STATUS.md)) |
| Lucas POST chain | [`src/phi_anchor_post.v`](src/phi_anchor_post.v) + [`src/lucas_rom.v`](src/lucas_rom.v) |
| Cross-die enforcement | [`docs/architecture/TRI_NET_SHUTTLE_TRIAD.md`](docs/architecture/TRI_NET_SHUTTLE_TRIAD.md), Theorem 36.1 |
| Top-level boot value | [`.github/workflows/test.yaml`](.github/workflows/test.yaml) inline `tb_canonical` asserts `result == 16'h47C0` after reset |

---

## 4. R-SI-1 line-wide invariant

R-SI-1 (zero new `*` operators in synthesisable RTL) is the line-wide
construction discipline that makes the CLARA proofs cheap: the absence of
DSP multiplier instances limits the proof obligation to logic / LUT /
shift-and-add structure.

| Item | Detail |
|---|---|
| Enforcement | [`.github/workflows/no_star.yaml`](.github/workflows/no_star.yaml) — fails CI on any new `*` in `src/*.v` (allow-list: `gf16_mul.v` grandfathered legacy Karatsuba, `tb_*.v` testbenches excluded) |
| Comment stripping | `sed 's|/\*[^*]*\*\+\([^/*][^*]*\*\+\)*/\|/\|g; s|//.*||'` before grep |
| Status at submission commit | Reported green in [`docs/CLARA_PROOF_MANIFEST.md`](docs/CLARA_PROOF_MANIFEST.md) §R-SI-1 Audit at `507cdfcb` |

---

## 5. Provenance of external proof artefacts

The Coq/Rocq theorem files referenced in column 4 above are **not in this
checkout**. They are reported by [`docs/CLARA_PROOF_MANIFEST.md`](docs/CLARA_PROOF_MANIFEST.md)
to live in `gHashTag/trinity-clara`, with the following provenance
statements:

- All 10 gap theorems carry `Qed` (admitted: 0) at the manifest's freeze
  commit (`507cdfcb`).
- Aggregate proof footprint cited elsewhere in the line (e.g. `info.yaml`
  description): **297 Qed + 141 Admitted** across `trios-coq` at
  submission. The 141 Admitted are in non-CLARA scaffolding (IGLA
  physics, kernel utilities); the 10 CLARA gap theorems themselves are
  reported `Qed`-closed.

**Before quoting a `Qed (external)` row to a customer or reviewer:**

1. Pull the cited `trinity-clara` commit.
2. Re-run `coqc -R . TrinityClara theorems/gap_N.v`.
3. Confirm no `Admitted.` was introduced upstream.
4. Update column 4 if the result drifts.

---

## 6. Open work tracked against CLARA

Items that would *strengthen* this table — none of them are blockers for
the TTSKY26b submission, but each closes a soft spot a reviewer is likely
to probe:

- [ ] Per-module Cocotb tests for Gaps 1, 3, 6, 9 (currently they rely on
      top-level elaboration + R-SI-1 lint). [`test/test.py`](test/test.py)
      is the natural home.
- [ ] Vendor the relevant `trinity-clara/theorems/gap_*.v` subset into
      `trios-coq/CLARA/` so the proofs build with the same `_CoqProject`
      that gates this repo.
- [ ] Replace "approx N cells" estimates with synthesis-reported cell
      counts per module after the next OpenLane2 run.
- [ ] Re-state Gap-7 (composition kernel) as a temporal-logic property
      (LTL/CTL over the orchestrator FSM) — currently the invariant is
      stated set-theoretically, which is harder to relate to the RTL.
- [ ] Add a coverage assertion in [`assertions/toolchain.json`](assertions/toolchain.json)
      that *every* CLARA-tagged module is referenced by exactly one row in
      this file.
