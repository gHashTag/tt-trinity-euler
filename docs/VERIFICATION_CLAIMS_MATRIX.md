# TRI-NET Verification Claims Matrix

**Document ID:** TRINITY-VCM-V0.1
**Status:** SPEC + EVIDENCE INDEX — readiness label per row
**Last updated:** 2026-05-18
**Scope:** TRI-1 Euler (this repo). Cross-chip rows (Phi, Gamma) are
inferred from the line's public structure and MUST be re-confirmed in the
sibling repo before being cited normatively.
**Companion docs:** [BENCHMARKS.md](../BENCHMARKS.md),
[STATUS.md](../STATUS.md),
[`docs/GF16_BFLOAT16_NMSE.md`](GF16_BFLOAT16_NMSE.md),
[`docs/PROJECTIONS_22FDX.md`](PROJECTIONS_22FDX.md),
[`docs/TRIPLE_DECK_STATUS.md`](TRIPLE_DECK_STATUS.md),
[`docs/D2D_PROTOCOL.md`](D2D_PROTOCOL.md)

---

## 1. Purpose

This matrix is the **single index of every numerical or quasi-numerical
claim** currently in the TRI-NET docs and specs in this repository. Each
row names:

- the claim ID (stable, used by the CI gate),
- the verbatim claim text or short paraphrase,
- the source location (file + section),
- the evidence / witness artefact that backs the claim (if any),
- the test or harness that re-checks the claim (if any),
- the readiness `Status` per [STATUS.md §1](../STATUS.md),
- the **Anti-claim** — the explicit assertion the row is *not* making, so a
  future reader cannot smuggle a larger claim into a narrower one.

The R5-Honesty contract requires that every quoted number in customer-
facing material map to a row here. If a number appears in a doc but is not
in this matrix, the [`scripts/check_trinet_specs.sh`](../scripts/check_trinet_specs.sh)
CI gate fails the build until the row is added (or the number removed).

### 1.1 What counts as a "claim"

A claim is any concrete, falsifiable statement that a reader could check.
Examples that belong here:

- "GF16 dot4 canonical anchor = `0x47C0` (bit-exact)"
- "75 TOPS/W baseline @ 22FDX, 400 MHz, GF16, AVS-96 = 96 islands"
- "5.4× AVS-96 boost ratio"
- "17/17 PASS on `tb_gf16_dot8.v`"
- "Trinity Stack DOI: 10.5281/zenodo.19227877"

What does NOT belong here (these go in [`docs/INDEX.md`](INDEX.md) or
other docs, not this matrix):

- Marketing prose without a number ("competitive vs. Hailo").
- Process / governance statements ("PRs require one approval").
- Pure module presence statements ("`src/fbb_active_path.v` exists") —
  unless the doc attaches a number to that module.

### 1.2 Readiness labels (re-used unchanged)

| Label | Meaning |
|---|---|
| `SPEC` | Specified in markdown / Coq only. No RTL, no sim, no measurement. |
| `RTL` | An `src/*.v` module implements the claim. |
| `SIM` | A testbench under `sim/` or `test/` exercises it (CI or local). |
| `SYNTH` | Synthesis run logs exist (OpenLane2 or similar). |
| `GDS-SUBMIT` | Part of a submitted shuttle (named in `info.yaml`). |
| `SILICON` | Measured on returned die. **No row in this file is `SILICON`.** |
| `PROJECTED` | Extrapolation under stated assumptions. Not measured. |
| `SPEC-DRAFT` | Drafted here for the first time; not yet implemented. |
| `SPEC-FROZEN` | Frozen for the named shuttle (e.g. TTSKY26b). |
| `RTL-STUB` | Pin-correct RTL stub, not the full behaviour. |
| `PLANNED` | Scoped for a future wave; no RTL or sim yet. |

---

## 2. Claims matrix

| Claim ID | Claim | Location | Evidence / Witness | Harness | Status | Anti-claim |
|---|---|---|---|---|---|---|
| `VCM-GF16-001` | GF16 dot4 canonical anchor produces `0x47C0` bit-exact under the FORMAT-SPEC-001 mapping for inputs `([1,2,3,4],[1,2,3,4])`. | [BENCHMARKS.md §2](../BENCHMARKS.md), [`docs/GF16_BFLOAT16_NMSE.md`](GF16_BFLOAT16_NMSE.md) §2.3 | [`sim/tb_gf16_dot8.v`](../sim/tb_gf16_dot8.v) anchor row | iverilog: `tb_gf16_dot8` | `SIM` | Does NOT claim `0x47C0` was observed on silicon; SKY130A demonstrator has not returned. |
| `VCM-GF16-002` | 17/17 PASS on the GF16 inner-product testbench (`TOTAL PASS=17 FAIL=0`) under iverilog. | [BENCHMARKS.md §2](../BENCHMARKS.md), [`docs/GF16_BFLOAT16_NMSE.md`](GF16_BFLOAT16_NMSE.md) §1 | [`sim/tb_gf16_dot8.v`](../sim/tb_gf16_dot8.v) PASS counter | iverilog: `tb_gf16_dot8` | `SIM` | "PASS" measures correctness vs. the structural golden model — NOT accuracy vs. bfloat16 or any other format. |
| `VCM-GF16-003` | GF16 element format = 16 bits = 1 sign / 6 exp / 9 mantissa, bias 31. | [`conformance/FORMAT-SPEC-001.json`](../conformance/FORMAT-SPEC-001.json) `formats.GF16`, [`specs/numeric/gf16.t27`](../specs/numeric/gf16.t27) | `FORMAT-SPEC-001.json` schema, `gf16.t27` constants | `scripts/check_trinet_specs.sh` (schema field check) | `SPEC-FROZEN` | Does NOT claim GF16 is IEEE-754 compliant. |
| `VCM-NMSE-001` | NMSE comparison protocol GF16 vs bfloat16 = 16 randomised vectors + 1 canonical anchor; reported as `nmse_mean`, `nmse_p99`, `nmse_db_mean`. | [`docs/GF16_BFLOAT16_NMSE.md`](GF16_BFLOAT16_NMSE.md) §3, §3.5 | Golden vector pack: [`tests/vectors/nmse/gf16_vs_bfloat16_v0.json`](../tests/vectors/nmse/gf16_vs_bfloat16_v0.json) | `scripts/check_trinet_specs.sh` (vector schema check) | `SPEC-DRAFT` | No NMSE number is quoted in this repo until a `sim/nmse/euler_*.json` record exists. |
| `VCM-NMSE-002` | Reference path = FP64; GF16 path = RTL via `tb_gf16_dot8.v`; bfloat16 path = software (rt-nearest-even, FP32 accumulator). | [`docs/GF16_BFLOAT16_NMSE.md`](GF16_BFLOAT16_NMSE.md) §3.1–3.3 | Same as above | n/a (protocol-level) | `SPEC-DRAFT` | The bfloat16 path is NOT a bfloat16 NPU measurement. It is a software round-trip reference. |
| `VCM-TOPS-001` | 75 TOPS/W **baseline projection**, 22FDX @ 400 MHz, GF16, AVS-96 = 96 islands, no FBB. | [`docs/PROJECTIONS_22FDX.md`](PROJECTIONS_22FDX.md) §1.2, [`docs/HARDWARE-IMPLEMENTATION.md`](HARDWARE-IMPLEMENTATION.md) §2.1 | Module count + published 22FDX physics; assumption clause | n/a (projection) | `PROJECTED` | NOT a measured number. NOT a SKY130A-synthesis-reported number. Not derivable from the TTSKY26b deliverable. |
| `VCM-TOPS-002` | 405 TOPS/W **boosted projection**, AVS-96 active + Purkinje-gated FBB credit, sustained burst window only. | [`docs/PROJECTIONS_22FDX.md`](PROJECTIONS_22FDX.md) §1.2 | Same — derived as baseline × 5.4× under stated stacking assumption | n/a (projection) | `PROJECTED` | Not a steady-state number. The HARDWARE-IMPLEMENTATION.md table reports 297 for AVS-96 alone; the 405 figure requires the FBB credit to stack — that stacking is itself a projection. |
| `VCM-TOPS-003` | 5.4× AVS-96 boost factor = ratio of `VCM-TOPS-002` / `VCM-TOPS-001`. | [`docs/PROJECTIONS_22FDX.md`](PROJECTIONS_22FDX.md) §1.2, [`docs/TRIPLE_DECK_STATUS.md`](TRIPLE_DECK_STATUS.md) §2 Deck 3 | Derived ratio | n/a (derived) | `PROJECTED` | Does NOT survive a change of assumption set (different module mix, different burst window). |
| `VCM-TOPS-004` | ~20 TOPS steady-state ML capacity, 22FDX, 16-tile 8×2, GF16 inner-product per tile, SUPER-CROWN mix. | [`docs/PROJECTIONS_22FDX.md`](PROJECTIONS_22FDX.md) §1.2, README "Green AI Manifesto" | Module-count projection | n/a (projection) | `PROJECTED` | NOT a measured number. |
| `VCM-TOPS-005` | <1 W TDP envelope, 22FDX, Triple-Deck active. | [`docs/PROJECTIONS_22FDX.md`](PROJECTIONS_22FDX.md) §1.2, README "Green AI Manifesto" | Module-count projection | n/a (projection) | `PROJECTED` | NOT a measured rail. |
| `VCM-TILES-001` | TRI-1 Euler tile geometry = 8×2 (= 16 tiles). | [`info.yaml`](../info.yaml) `tiles: 8x2`, [LINEUP.md §6](../LINEUP.md) | `info.yaml` field | `.github/workflows/tri-test.yml` (grep for `tiles.*8x2`) | `SPEC-FROZEN` | Does NOT imply tile-count parity with Phi (1×1) or Gamma (8×4). |
| `VCM-FORMATS-001` | TRI-NET extended format set = 17 formats total (10 GoldenFloat + 7 IEEE / quantization). | [`conformance/FORMAT-SPEC-001.json`](../conformance/FORMAT-SPEC-001.json) `total_tri_net_formats: 17` | `FORMAT-SPEC-001.json` schema | `scripts/check_trinet_specs.sh` (schema field check) | `SPEC-FROZEN` | Does NOT claim all 17 formats are synthesised in this repo. Only the GF16 path has RTL here. |
| `VCM-PHI-001` | φ² = φ + 1 exact in f64; residual = 0; Ring 45 proven in Coq. | [`conformance/FORMAT-SPEC-001.json`](../conformance/FORMAT-SPEC-001.json) `phi_identity`, [`trios-coq/Kernel/Phi.v`](../trios-coq/Kernel/Phi.v) | f64 hex literals match; Coq `Qed` | `scripts/check_trinet_specs.sh` (schema field check) | `SPEC` | Identity is f64-arithmetic-level. Does NOT imply any silicon behaviour. |
| `VCM-D2D-001` | TIP v1.0 board-level 3-wire handshake (LOAD_MODE, SYNC_STROBE, ACK) is frozen at TTSKY26b. | [`docs/INTERCONNECT_PROTOCOL_V1.md`](INTERCONNECT_PROTOCOL_V1.md) §3, [`docs/D2D_PROTOCOL.md`](D2D_PROTOCOL.md) §1.1 | RTL pin assignments in `info.yaml` + `src/tt_um_ghtag_trinity_gf16.v` | n/a (pin-level freeze) | `SPEC-FROZEN` | Does NOT cover what flows across the die after the handshake — that is the D2D packet layer (`SPEC-DRAFT`). |
| `VCM-D2D-002` | D2D packet framing v0.1 = `{SYNC(1), KIND(4), EPOCH(8), PAYLOAD, RECEIPT(32)}`; receipts are truncated BLAKE3 over (`KIND`, `EPOCH`, `PAYLOAD`). | [`docs/D2D_PROTOCOL.md`](D2D_PROTOCOL.md) §4.2 | Conformance assets: [`conformance/D2D-CONFORMANCE-V0.json`](../conformance/D2D-CONFORMANCE-V0.json) | `scripts/check_trinet_specs.sh` (conformance schema) | `SPEC-DRAFT` | No multi-hop routing, no congestion control, no per-frame back-pressure. |
| `VCM-D2D-003` | D2D frame kinds defined v0.1: `IDLE`, `SPIKE_SUMMARY`, `GF_TAG`, `RECEIPT_BEACON`, `RESTRAINT_HOLD`, `AUDIT_FLUSH`, `LAYER_FROZEN`. | [`docs/D2D_PROTOCOL.md`](D2D_PROTOCOL.md) §4.3 | Same as above; conformance opcodes list | `scripts/check_trinet_specs.sh` | `SPEC-DRAFT` | Only `SYNC`, `SPIKE_SUMMARY`, `GF_TAG` are emitted by the current `d2d_holo_mesh.v` stub. The other kinds are spec-only. |
| `VCM-D2D-004` | Bridge invariant Thm 36.1 R18: no SYNC strobe crosses to Gamma unless φ-anchor POST has succeeded AND restraint controller is not holding. | [`docs/D2D_PROTOCOL.md`](D2D_PROTOCOL.md) §5.2 | [`src/phi_anchor_post.v`](../src/phi_anchor_post.v), [`src/restraint_ctrl.v`](../src/restraint_ctrl.v), [`src/d2d_holo_mesh.v`](../src/d2d_holo_mesh.v) `layer_frozen` gate | iverilog smoke test on existing testbenches | `RTL-STUB` | Gating logic exists; it has NOT been measured on silicon. |
| `VCM-DECK1-001` | Deck 1 (RBB) opcode `0xF1 = OP_RBB` defined in ISA + Coq. | [`docs/TRIPLE_DECK_STATUS.md`](TRIPLE_DECK_STATUS.md) §2 Deck 1, [`trios-coq/Physics/RBB.v`](../trios-coq/Physics/RBB.v) | Coq `Definition OP_RBB := 241.` | n/a (ISA-level) | `SPEC` | No dedicated `rbb_*.v` RTL module exists in this branch. |
| `VCM-DECK2-001` | Deck 2 (FBB) RTL with 5 levels (`OFF/LOW/MED/HIGH/MAX`), opcode `0xF2`. | [`docs/TRIPLE_DECK_STATUS.md`](TRIPLE_DECK_STATUS.md) §2 Deck 2 | [`src/fbb_active_path.v`](../src/fbb_active_path.v), [`test/tb_fbb_active_path.v`](../test/tb_fbb_active_path.v) | iverilog: `tb_fbb_active_path` | `RTL` + `SIM` | Lightweight sim only; no power-delta measurement. |
| `VCM-DECK3-001` | Deck 3 (CAP_BOOST / AVS-96) RTL with 96 islands, 4 voltage rails (0.75 / 0.85 / 0.95 / 1.05 V), thermal monitor. | [`docs/TRIPLE_DECK_STATUS.md`](TRIPLE_DECK_STATUS.md) §2 Deck 3 | [`src/avs_controller_96.v`](../src/avs_controller_96.v) | n/a (RTL pin check) | `RTL` | Voltage rails are nominal targets. NOT measured on silicon. |
| `VCM-DECK-EXC-001` | Cross-deck exclusivity: a given path is never RBB+FBB or FBB+CAP_BOOST simultaneously. | [`docs/TRIPLE_DECK_STATUS.md`](TRIPLE_DECK_STATUS.md) §1, §4.3, [`docs/TRIPLE_DECK_STATE_MACHINE.md`](TRIPLE_DECK_STATE_MACHINE.md) | State-machine table + state encoding | `scripts/check_trinet_specs.sh` (state set check) | `SPEC` | RTL assertion or Coq lemma proving exclusivity is `PLANNED`. |
| `VCM-DECK-FSM-001` | Triple-Decker state machine over states `IDLE`, `RBB`, `FBB`, `CAP_BOOST` with transitions `IDLE → RBB → FBB → CAP_BOOST → IDLE`, cooldown timer, and brownout/overcurrent/thermal-red fallback to `IDLE`. | [`docs/TRIPLE_DECK_STATE_MACHINE.md`](TRIPLE_DECK_STATE_MACHINE.md) | Spec doc (this PR) | `scripts/check_trinet_specs.sh` (state set check) | `SPEC-DRAFT` | No RTL FSM module yet implements the named transitions; today the gates are independent (`fbb_active_path`, `avs_controller_96`). |
| `VCM-DOI-001` | Trinity Stack provenance DOI (line-wide): `10.5281/zenodo.19227877`. | [`docs/PROJECTIONS_22FDX.md`](PROJECTIONS_22FDX.md) §3.1, [`docs/WHITEPAPER_LINKS.md`](WHITEPAPER_LINKS.md) | Zenodo public record | n/a (external) | `PUBLISHED` (external) | Per-shuttle TTSKY26b Zenodo bundle is `PLANNED` — not yet uploaded. |
| `VCM-DOI-002` | No per-shuttle TTSKY26b Zenodo DOI exists yet. | [`docs/PROJECTIONS_22FDX.md`](PROJECTIONS_22FDX.md) §3.1 | Absence of DOI URL in this branch | n/a | `PLANNED` | Material that quotes a "TTSKY26b DOI" without a URL is using a fabricated DOI. |
| `VCM-FUND-001` | TRI-NET has no DARPA-CLARA award/contract. Alignment-only. | [STATUS.md §4](../STATUS.md), [`docs/PROJECTIONS_22FDX.md`](PROJECTIONS_22FDX.md) §3.3 | Absence of award row in `STATUS.md` | n/a | `SPEC` | NOT a denial of CLARA-aligned intent; only a denial of funded relationship. |
| `VCM-FPGA-001` | "323 MHz on XC7A100T" FPGA Fmax claim is currently `unverified-in-this-branch`. | [BENCHMARKS.md §3](../BENCHMARKS.md), [`docs/PROJECTIONS_22FDX.md`](PROJECTIONS_22FDX.md) §3.3 | No re-attached log under `boards/` in this branch | n/a | `unverified-in-this-branch` | Until a log is re-attached, the number must NOT be quoted as `MEASURED`. |
| `VCM-CLARA-001` | 10/10 CLARA gaps implemented as RTL on Euler. | [LINEUP.md §6](../LINEUP.md), [CLARA_TRACEABILITY.md](../CLARA_TRACEABILITY.md), [`docs/D2D_PROTOCOL.md`](D2D_PROTOCOL.md) §1.2 | Per-gap rows in `CLARA_TRACEABILITY.md`, modules under `src/` | `scripts/check_clara_traceability.sh` | `RTL` | "RTL" ≠ "measured on silicon". Cross-gap interaction proofs are `PLANNED`. |
| `VCM-RSI-001` | R-SI-1: zero standalone `*` operators in synthesisable RTL (grandfathering only `gf16_mul.v`). | [`.github/workflows/tri-test.yml`](../.github/workflows/tri-test.yml) `rtl-r-si-1-check`, [`.github/workflows/no_star.yaml`](../.github/workflows/no_star.yaml) | CI grep over `src/*.v` | CI: `R-SI-1 Compliance Check` | `SIM` | Does NOT claim Coq-level proof of multiplier equivalence; only that the lexical surface is clean. |

---

## 3. Anti-claims that apply repo-wide

These are NOT individual rows because they are negative-form blanket
statements. They must be enforceable by inspection of this repo at any
time:

| Anti-claim ID | Statement | Enforced by |
|---|---|---|
| `NO-SILICON` | No TRI-NET claim in this repo is `SILICON`-tier (no returned die). | Grep over `STATUS.md` and `BENCHMARKS.md` for `SILICON` rows. |
| `NO-FAKE-DOI` | The only DOI cited in this repo is `10.5281/zenodo.19227877`. Any other DOI URL in TRI-NET-tagged docs is a bug. | `scripts/check_trinet_specs.sh` greps for `doi.org/10.5281/zenodo.` and accepts only the canonical record. |
| `NO-FUNDING` | TRI-NET has no DARPA/NASA/DoE/ESA contract. Alignment / proposal-only. | Absence of award row in `STATUS.md`. |
| `NO-MEASURED-TOPS` | No TOPS/W number in this repo is in the `MEASURED` tier. | Grep over `BENCHMARKS.md` and `PROJECTIONS_22FDX.md`; every TOPS/W row carries the `PROJECTED` qualifier. |
| `NO-MEASURED-NMSE` | No NMSE number is quoted in this repo. The protocol exists; the result does not. | Grep over docs for `nmse` numeric literals outside the protocol's `null` examples. |
| `NO-RTL-SEMANTIC-CHANGE-IN-THIS-PR` | This PR's task description forbids changes to RTL semantics. | Diff against `main` touching `src/*.v` synthesisable lines (this PR adds only docs, conformance JSON, and scripts). |

---

## 4. Cross-references

- Numerical claims that appear in any new TRI-NET-tagged doc MUST add a
  row here OR cite an existing claim ID.
- [`scripts/check_trinet_specs.sh`](../scripts/check_trinet_specs.sh) is
  the CI gate that enforces (2) + (3).
- When promoting a row's `Status` (e.g. `SPEC-DRAFT → RTL-STUB`), update
  the row in this file **and** the corresponding row in the source doc
  (e.g. `docs/D2D_PROTOCOL.md` §4.3). The two MUST agree.

---

## 5. Update policy

1. Add a row before you publish the number anywhere external.
2. Never delete a row — set its `Status` to `RETIRED` and leave the row in
   place with a `Why retired:` annotation.
3. The `Anti-claim` column is mandatory and is reviewed for each row.
4. The matrix is a *living* document; the canonical version lives on
   `main`.
