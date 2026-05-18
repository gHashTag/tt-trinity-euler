# TRI-NET 2026 Scientific Improvement Plan — e-engine (Euler) view

**Document ID:** TRINITY-SIP-2026-EULER-V0.1
**Status:** PLAN — programmatic targets only; nothing here is `MEASURED`
**Last updated:** 2026-05-18
**Scope:** TRI-1 Euler (this repo) adaptation of the TRI-NET line-wide 2026
Scientific Improvement Plan.
**Companion docs:** [STATUS.md](../STATUS.md), [LINEUP.md](../LINEUP.md),
[BENCHMARKS.md](../BENCHMARKS.md),
[`docs/D2D_PROTOCOL.md`](D2D_PROTOCOL.md),
[`docs/GF16_BFLOAT16_NMSE.md`](GF16_BFLOAT16_NMSE.md),
[`docs/TRIPLE_DECK_STATUS.md`](TRIPLE_DECK_STATUS.md),
[`docs/TRI_NET_API.md`](TRI_NET_API.md),
[`docs/WHITEPAPER_LINKS.md`](WHITEPAPER_LINKS.md),
[`docs/PROJECTIONS_22FDX.md`](PROJECTIONS_22FDX.md).

---

## 1. Preamble — labels used in this document

Every quantitative or forward-looking claim in this plan carries one of
three labels. They sit **alongside** (not on top of) the readiness ladder
in [STATUS.md §1](../STATUS.md), and they do not override it.

| Label | Meaning | Example |
|---|---|---|
| `VERIFY` | A claim or number sourced from **outside this repo**. An integrator MUST verify the source before quoting it in customer-facing material. | "press figures of 1000× or 4000 TOPS/W referenced externally" |
| `projection` | An architecture-level estimate, derived from RTL module counts / advanced-node physics under stated assumptions; not silicon. | "28–120 TOPS/W on 22FDX under SUPER-CROWN mix" |
| `target` | A programmatic goal of this plan: not yet an achieved outcome. | "draft + submit one workshop paper" |

> **R5 honesty note.** No row in this plan promotes anything from `PROJECTED`
> to `MEASURED`, from `RTL-STUB` to `RTL`, or from `SPEC-DRAFT` to
> `SPEC-FROZEN`. Promotion happens elsewhere — in the file that owns the
> row — and only when reproducible artefacts land.

### Anti-claims (not asserted anywhere in this plan)

- **No DARPA / CLARA funding claim.** The repo's relationship to DARPA CLARA
  is alignment-only ([STATUS.md §4](../STATUS.md)); this plan does **not**
  claim funding, award, sub-award, contract, or selection. No programme
  date is named.
- **No new DOI minted.** Only the already-anchored Trinity Stack DOI
  [10.5281/zenodo.19227877](https://doi.org/10.5281/zenodo.19227877) is
  quoted. A per-shuttle TTSKY26b bundle is `PLANNED` per
  [`docs/PROJECTIONS_22FDX.md`](PROJECTIONS_22FDX.md) §3 and not minted in
  this plan.
- **No silicon-return date.** TTSKY26b silicon has not returned. §7 marks
  silicon arrival as "open" — undated.
- **No paper acceptance.** Publication items (§5) are framed as "draft and
  submit", not "accepted at venue X".
- **No `1000×` or `4000 TOPS/W` figure restated as fact.** Such press
  figures from outside this repo are flagged `VERIFY` in §3 EN-03 only;
  they are **not** used to set targets.

---

## 2. DARPA CLARA alignment (CL-01..CL-04)

> **Context.** Euler is the line's CLARA-facing SKU — 10/10 CLARA gaps as
> RTL, BLAKE3 receipt, audit ring, restraint controller, multi-tile
> receipt, D2D mesh stub. Per [LINEUP.md §6](../LINEUP.md), Euler is the
> chip the line puts forward in CLARA-style proposals. This section
> defines the **alignment work plan**, not a funded engagement.

| ID | Item | Today on Euler | Plan label | Plan action |
|---|---|---|---|---|
| **CL-01** | D2D safety/control bridge between φ-anchor (Phi) and γ-surface (Gamma) | `RTL-STUB` (`src/d2d_holo_mesh.v`) + `SPEC-DRAFT` ([`docs/D2D_PROTOCOL.md`](D2D_PROTOCOL.md)) | `target` | Promote one `SPEC-DRAFT` row from [`D2D_PROTOCOL.md`](D2D_PROTOCOL.md) §4.3 to `RTL` (candidate: `KIND=0x4 RESTRAINT_HOLD` — it composes directly with `src/restraint_ctrl.v`). |
| **CL-02** | 10/10 CLARA gaps present as RTL | `RTL` ([`CLARA_TRACEABILITY.md`](../CLARA_TRACEABILITY.md), [`info.yaml`](../info.yaml)) | `target` | Drive [STATUS.md §5](../STATUS.md) "CLARA traceability proof status sweep" to completion: confirm `Qed` / `Admitted` / `not started` for every row. |
| **CL-03** | Cross-chip CLARA evidence stream — receipt + audit-ring path observable from outside the die | `RTL` (BLAKE3 + ring buffer + proof-trace writer); host-side reader = `SPEC-DRAFT` ([`docs/TRI_NET_API.md`](TRI_NET_API.md) §5) | `target` | Land a minimal `host/` reader (`evidence` layer per [`TRI_NET_API.md`](TRI_NET_API.md) §5) that decodes the BLAKE3 receipt + last `N` audit-ring entries. No driver yet ships; this plan only commits to the spec promotion path. |
| **CL-04** | Formal cross-walk: CLARA gap → RTL module → Coq lemma | Partial — [`CLARA_TRACEABILITY.md`](../CLARA_TRACEABILITY.md) has the gap→RTL mapping; per-row Coq citation is uneven | `target` | Annotate each CLARA row with its `trios-coq` proof file (and `Qed` / `Admitted` per file, not as a total). |

> **No claim is made that CLARA has funded this work; no programme date is
> named.** All four items above are work this repo would do regardless of
> programme status.

---

## 3. Energy efficiency (EN-01..EN-03)

| ID | Item | Today on Euler | Plan label | Plan action |
|---|---|---|---|---|
| **EN-01** | Triple-Deck (RBB → FBB → CAP_BOOST) composition | Deck-2 (FBB) = `RTL` ([`src/fbb_active_path.v`](../src/fbb_active_path.v)); Deck-3 (CAP_BOOST / AVS-96) = `RTL` ([`src/avs_controller_96.v`](../src/avs_controller_96.v)); **Deck-1 (RBB) = `SPEC`-only** ([`docs/TRIPLE_DECK_STATUS.md`](TRIPLE_DECK_STATUS.md) §3) | `target` | Promote Deck-1 (RBB) from `SPEC` to `RTL` by adding a dedicated `src/rbb_active_path.v` module. **No claim** that this composes to a `MEASURED` TOPS/W until silicon returns. |
| **EN-02** | Triple-Deck cross-chip conformance contract | `SPEC` ([`docs/TRIPLE_DECK_STATUS.md`](TRIPLE_DECK_STATUS.md) §4) | `target` | Add a cross-deck exclusivity assertion (RTL assert or Coq lemma) — the C2 → C3 promotion gate. |
| **EN-03** | TOPS/W envelope on advanced node | `projection` only — "75 TOPS/W baseline / 405 TOPS/W with AVS-96 (5.4× boost)" per [`docs/PROJECTIONS_22FDX.md`](PROJECTIONS_22FDX.md); README rows match | `projection` (restated, not promoted) | **External press figures of 1000× or 4000 TOPS/W are `VERIFY` only — this repo does not restate them as fact.** The existing 22FDX projection in [`PROJECTIONS_22FDX.md`](PROJECTIONS_22FDX.md) §1.2 remains the authoritative line, with its per-row assumption clauses. No new numeric claim is introduced. |

> **The 28–120 TOPS/W range that appears in some line-level notes is
> `projection` only.** It must back-link to [BENCHMARKS.md](../BENCHMARKS.md)
> + [`docs/PROJECTIONS_22FDX.md`](PROJECTIONS_22FDX.md) §1 wherever it is
> quoted. This plan does not introduce a new TOPS/W number.

---

## 4. SNN-TRI fusion — e-engine-side hooks (SN-01..SN-03)

> **Why this is on Euler at all.** Euler is not the neuromorphic SKU
> (that's Gamma — [LINEUP.md §2](../LINEUP.md)). But the D2D bridge,
> restraint controller, and audit ring on Euler are the *evidence-bearing
> surface* a SNN-TRI workload would terminate against. This section is
> the Euler-side hook list, not a SNN implementation plan.

| ID | Item | Today on Euler | Plan label | Plan action |
|---|---|---|---|---|
| **SN-01** | GF16 inner-product correctness anchor for SNN-TRI workloads | `RTL` + `SIM` — `sim/tb_gf16_dot8.v` passes `TOTAL PASS=17 FAIL=0` (canonical `0x47C0` + 16 randomised dot8 vectors) | `target` | Land the NMSE harness sketched in [`docs/GF16_BFLOAT16_NMSE.md`](GF16_BFLOAT16_NMSE.md) §5 so a SNN-TRI consumer can read a `bench/nmse/euler_*.json` record. **No `Δ_dB` number is permitted in this repo until that JSON record lands.** |
| **SN-02** | D2D spike-summary path Gamma → Euler | `RTL-STUB` — `n_tx`/`e_tx` carry `spike_count` MSB/LSB per [`src/d2d_holo_mesh.v`](../src/d2d_holo_mesh.v) header | `target` | Pin the `SPIKE_SUMMARY` (`KIND=0x1`) framing from [`D2D_PROTOCOL.md`](D2D_PROTOCOL.md) §4.3 into RTL: at minimum a fixed-width counter on the RX path so an external SNN can read a frame-aligned spike count. |
| **SN-03** | Restraint-driven back-pressure into a SNN workload | `RTL` ([`src/restraint_ctrl.v`](../src/restraint_ctrl.v)) — internal; not yet a D2D-observable frame | `target` | Promote `KIND=0x4 RESTRAINT_HOLD` (see CL-01) — a SNN-TRI consumer needs an observable signal that Euler has gated activity, not just an internal flag. |

---

## 5. Publication path (PUB-01..PUB-03)

> **Framing.** All three items below are "draft + submit", never
> "accepted at venue X". An accepted-paper claim only lands after the
> acceptance email is in hand and a `docs/publications/<venue>.md` entry
> with the proof exists.

| ID | Item | Plan label | Plan action |
|---|---|---|---|
| **PUB-01** | Workshop / short-paper draft on the e-engine evidence path (BLAKE3 receipt + audit ring + restraint, viewed as an on-chip CLARA-evidence primitive) | `target` | Draft a short paper; cite [`docs/CLARA_PROOF_MANIFEST.md`](CLARA_PROOF_MANIFEST.md), [`STATUS.md`](../STATUS.md), and the relevant `trios-coq/Physics/*.v` files. **Submission only; no acceptance claim.** |
| **PUB-02** | NMSE comparison note (GF16 vs bfloat16 software reference) — once the harness from `GF16_BFLOAT16_NMSE.md` produces a JSON record | `target` | Publish the *protocol* note ahead of any numbers. **No `Δ_dB` number is included until a `bench/nmse/euler_*.json` (or `sim/nmse/euler_*.json`) record exists in this repo.** |
| **PUB-03** | TRI-NET line note (cross-repo) — Euler-side contribution: the safety/control bridge role described in [`docs/D2D_PROTOCOL.md`](D2D_PROTOCOL.md) §5 | `target` | Coordinate with sibling repos (Phi, Gamma, t27) for a single line note. Submission only. |

---

## 6. Open-source community (OS-01..OS-03)

| ID | Item | Today on Euler | Plan label | Plan action |
|---|---|---|---|---|
| **OS-01** | Apache-2.0 only, R-SI-6 grep guard | `LICENSE` row in [STATUS.md §3](../STATUS.md) | maintain | No action — preserve the existing guard. |
| **OS-02** | Reproducible local checks for a new contributor | `iverilog` GF16 dot4/dot8 testbench runs in seconds on Ubuntu 24.04 ([STATUS.md §2](../STATUS.md)); R-SI-1 audit filter runs locally | `target` | Add a one-liner `make check` (or equivalent) that runs both, so a new contributor doesn't need to copy commands out of `STATUS.md`. **Doc / Makefile only — no CI changes.** |
| **OS-03** | First-PR friendliness | `CONTRIBUTING.md` not yet present | `target` | Author a short `CONTRIBUTING.md` covering: how to run the local checks (OS-02), the readiness ladder ([STATUS.md §1](../STATUS.md)), and the "every number on this page is one of `MEASURED`, `SIMULATED`, `SYNTHESIS-REPORTED`, or `PROJECTED`" rule from [BENCHMARKS.md §1](../BENCHMARKS.md). |

> No CI workflow is modified by any item in this plan.
> `.github/workflows/` is untouched.

---

## 7. Timeline (Q2..Q4 2026; silicon = open)

> **Honest framing.** Every row below is a `target`. Silicon-dependent
> rows are explicitly `open` (undated) because TTSKY26b silicon has not
> returned ([STATUS.md §6](../STATUS.md)).

| Quarter | Targets | Silicon dependency |
|---|---|---|
| **Q2 2026 (now)** | This plan (docs only); OS-02 `make check`; CL-04 row-level Coq annotation in [`CLARA_TRACEABILITY.md`](../CLARA_TRACEABILITY.md) | none |
| **Q3 2026** | EN-01 (`src/rbb_active_path.v` RTL); SN-02 (RX frame-aligned spike counter); CL-01 (`KIND=0x4 RESTRAINT_HOLD` from `SPEC-DRAFT` to `RTL`); PUB-01 workshop draft; OS-03 `CONTRIBUTING.md` | none |
| **Q4 2026** | EN-02 (cross-deck exclusivity assertion); SN-01 NMSE harness landed + first `sim/nmse/euler_*.json`; PUB-02 protocol note submission; CL-03 minimal `host/` evidence reader | none |
| **open (silicon-dependent)** | `STATUS.md §6` silicon bring-up section populated; `BENCHMARKS.md §2` rows promoted from `PROJECTED` to `MEASURED` where applicable; per-shuttle Zenodo bundle uploaded per [`docs/PROJECTIONS_22FDX.md`](PROJECTIONS_22FDX.md) §3 | **TTSKY26b silicon return — date open, no commitment** |

---

## 8. Success metrics

> **R5-honest framing.** Success is measured by **committed artefacts and
> CI-green workflows**, not by aspirational outcomes. A metric must
> reduce to a row in [STATUS.md §3](../STATUS.md) or
> [BENCHMARKS.md §2](../BENCHMARKS.md) to count.

| Metric | What counts |
|---|---|
| Committed artefacts | Net-new files / module count under `src/`, `sim/`, `test/`, `host/`, `docs/`, `bench/` referenced from §2–§6 — visible via `git log` on this branch. |
| CI-green workflows | The five workflows listed in [STATUS.md §2](../STATUS.md): `test.yaml`, `no_star.yaml`, `gds.yaml`, `fpga.yaml`, `tri-test.yml`. Each remains green on `main` after each Q-target lands. |
| Readiness promotions | Any row that moves rung under the [STATUS.md §1](../STATUS.md) ladder. Promotions counted only when a reproducible artefact (path or CI URL) is added to [STATUS.md §3](../STATUS.md). |
| `BENCHMARKS.md` table integrity | No row added that is not labelled `MEASURED` / `SIMULATED` / `SYNTHESIS-REPORTED` / `PROJECTED`. The table from [BENCHMARKS.md §1](../BENCHMARKS.md) governs. |

A success metric is **not** "we published numbers", "we got attention",
"we got funded", or "we hit Y TOPS/W". Those would be outcomes; this
section is about repository state.

---

## 9. References

Only repo-internal artefacts or publicly verifiable URLs are cited. No
"private" references; the line-level TRI-NET 2026 plan that motivates
this Euler-side adaptation lives in coordinator notes outside this repo
and is `VERIFY`-only here.

### 9.1 Repo-internal (authoritative)

- [STATUS.md](../STATUS.md) — readiness ladder + evidence table.
- [LINEUP.md](../LINEUP.md) — Euler's role in the line.
- [BENCHMARKS.md](../BENCHMARKS.md) — what tier a number sits at.
- [`docs/D2D_PROTOCOL.md`](D2D_PROTOCOL.md) — D2D packet layer (SPEC-DRAFT).
- [`docs/GF16_BFLOAT16_NMSE.md`](GF16_BFLOAT16_NMSE.md) — NMSE protocol (SPEC-DRAFT).
- [`docs/TRIPLE_DECK_STATUS.md`](TRIPLE_DECK_STATUS.md) — Triple-Deck per-deck readiness.
- [`docs/TRI_NET_API.md`](TRI_NET_API.md) — external integration surfaces.
- [`docs/WHITEPAPER_LINKS.md`](WHITEPAPER_LINKS.md) — publication / DOI index.
- [`docs/PROJECTIONS_22FDX.md`](PROJECTIONS_22FDX.md) — projection-tier numbers.
- [`docs/CLARA_PROOF_MANIFEST.md`](CLARA_PROOF_MANIFEST.md) — CLARA proof provenance.
- [`CLARA_TRACEABILITY.md`](../CLARA_TRACEABILITY.md) — CLARA gap → RTL map.
- [`info.yaml`](../info.yaml) — tile budget + source files.

### 9.2 External (`VERIFY` before quoting)

- Trinity Stack provenance DOI: <https://doi.org/10.5281/zenodo.19227877>
  — already anchored; no new DOI minted by this plan.
- DARPA CLARA programme: <https://www.darpa.mil/research/programs/clara>
  — alignment only; no funding / award implied.
- Tiny Tapeout shuttle index: <https://tinytapeout.com/chips/>
- BitNet b1.58 (research anchor): <https://arxiv.org/abs/2402.17764>
- Line-level TRI-NET 2026 plan (coordinator notes): **`VERIFY` — outside this repo.**

---

## 9a. Issue pack

The 16 plan rows above have draft GitHub issue bodies under
[`.github/issues/`](../.github/issues/). The numeric prefix (`00_`, …,
`16_`) is a **local plan ID** — it is **not a GitHub issue number**.
Real issue numbers are assigned only after
[`.github/issues/create_issues.sh`](../.github/issues/create_issues.sh)
runs successfully with `--apply`. The script is read-only by default
(`--dry-run` implied), idempotent (skips titles that already exist as
open issues), and never modifies CI workflows.

See [`.github/issues/ISSUES_SUMMARY.md`](../.github/issues/ISSUES_SUMMARY.md)
for the index.

---

## 10. What this is NOT (explicit anti-claims)

This section restates §1's anti-claims as a checklist so a reader scanning
only this section gets the honesty contract.

- ❌ This plan is **not** a DARPA / CLARA award or contract announcement.
  No programme date is named.
- ❌ This plan **does not** restate `1000×` or `4000 TOPS/W` press figures
  as fact. They are `VERIFY`-only in §3 EN-03.
- ❌ This plan **does not** mint a new DOI. Only the existing Trinity Stack
  DOI [10.5281/zenodo.19227877](https://doi.org/10.5281/zenodo.19227877)
  is quoted. A per-shuttle TTSKY26b bundle is `PLANNED` per
  [`docs/PROJECTIONS_22FDX.md`](PROJECTIONS_22FDX.md) §3.
- ❌ This plan **does not** commit to a silicon-return date. §7 marks
  silicon arrival as "open".
- ❌ This plan **does not** assert paper acceptance. Publication items
  (§5) are "draft + submit" only.
- ❌ This plan **does not** add a row to any `MEASURED` table.
- ❌ This plan **does not** weaken any check. `.github/workflows/` is
  untouched.
- ❌ This plan **does not** speak for sibling chips (Phi, Gamma) or the
  toolchain (t27) — their own SIP files own their rows. Cross-chip
  Triple-Deck conformance is per [`docs/TRIPLE_DECK_STATUS.md`](TRIPLE_DECK_STATUS.md) §4.
- ❌ This plan **does not** claim any GitHub issue exists. The
  [`.github/issues/`](../.github/issues/) directory holds drafts whose
  numeric prefixes are local plan IDs only. Real issue numbers appear
  only after [`create_issues.sh`](../.github/issues/create_issues.sh) is
  run with `--apply`.
