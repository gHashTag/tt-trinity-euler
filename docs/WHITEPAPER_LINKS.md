# Whitepaper Links and Value Proposition

**Document ID:** TRINITY-WHITEPAPER-V0.1
**Status:** DRAFT — link index for external readers
**Last updated:** 2026-05-18
**Audience:** evaluators, partners, researchers who want the "why" of
TRI-NET before reading any RTL or proofs.

> **Readiness:** every entry on this page links to a frozen artefact
> (markdown in this repo, Zenodo DOI, public programme page, or sibling
> repo). Forward-looking claims are labelled `PROJECTED` or `PLANNED` per
> [BENCHMARKS.md §1](../BENCHMARKS.md) and [STATUS.md §1](../STATUS.md).

---

## 1. Value proposition (one paragraph)

TRI-NET is an **open high-assurance ternary AI silicon substrate** — full
RTL, open PDK, ternary numeric format, and an on-chip audit / proof-trace
path. The wedge isn't "beat closed INT8 NPUs on raw TOPS"; it's that a
fully-auditable substrate is a more useful primitive for **safety-critical,
formally-verifiable, DARPA-aligned AI compute**. TRI-1 Euler is the
balanced SKU in the line — 8×2 tiles, 18 SUPER-CROWN modules, 10/10 CLARA
gaps, on-chip BLAKE3 receipt, audit ring, and D2D mesh. It's the chip that
carries the safety story.

This is the same paragraph as the top of [LINEUP.md §1](../LINEUP.md). If
you read nothing else, read that file and [STATUS.md](../STATUS.md).

---

## 2. The four pillars

| Pillar | What it is | Where to read |
|---|---|---|
| **Open substrate** | Apache-2.0 RTL, open PDK (SKY130A), no NDA path needed to reproduce | [LICENSE](../LICENSE), [LINEUP.md](../LINEUP.md) |
| **Ternary numeric** | {−1, 0, +1} as canonical compute domain; GF16 inner-product as the core kernel | [`conformance/FORMAT-SPEC-001.json`](../conformance/FORMAT-SPEC-001.json), [BENCHMARKS.md](../BENCHMARKS.md) |
| **On-chip evidence** | BLAKE3 receipt signer, audit ring buffer, proof-trace writer, restraint controller | [`src/blake3_anchor.v`](../src/blake3_anchor.v), [`src/audit_log_ring_buffer.v`](../src/audit_log_ring_buffer.v), [`src/proof_trace_writer.v`](../src/proof_trace_writer.v), [`src/restraint_ctrl.v`](../src/restraint_ctrl.v) |
| **Formal anchor** | φ² + φ⁻² = 3 identity verified at boot, Lucas chain, Coq/Rocq proof tree | [`trios-coq/`](../trios-coq/), [`docs/CLARA_PROOF_MANIFEST.md`](CLARA_PROOF_MANIFEST.md), Zenodo DOI [10.5281/zenodo.19227877](https://doi.org/10.5281/zenodo.19227877) |

---

## 3. Whitepaper / publication links

### 3.1 Anchored publications (Zenodo / DOI)

| Title / role | DOI / URL | Status |
|---|---|---|
| Trinity Stack provenance (line-wide anchor; cited from every chip in TRI-NET) | <https://doi.org/10.5281/zenodo.19227877> | Published |
| Per-shuttle bundle (TTSKY26b) | see [`docs/PROJECTIONS_22FDX.md`](PROJECTIONS_22FDX.md) §3 — `PLANNED` | Not yet uploaded |

### 3.2 Programme alignments

| Programme | URL | Role of this repo |
|---|---|---|
| DARPA CLARA | <https://www.darpa.mil/research/programs/clara> | TRI-1 Euler aligns module set to TA1 / TA1.1 / TA1.2 / TA1.4 buckets per [`CLARA_TRACEABILITY.md`](../CLARA_TRACEABILITY.md). **This is an alignment, not an award.** See [STATUS.md §4](../STATUS.md) for the explicit non-claim. |
| Tiny Tapeout shuttle index | <https://tinytapeout.com/chips/> | TTSKY26b submission registered |

### 3.3 External numeric / ML anchors

| Reference | URL | Why it's cited |
|---|---|---|
| BitNet b1.58 | <https://arxiv.org/abs/2402.17764> | Research anchor for the ternary numeric regime |
| Google Coral Edge TPU benchmarks | <https://www.coral.ai/docs/edgetpu/benchmarks/> | Reference axis for "INT8 edge inference at known measured throughput" |
| bfloat16 (Google Brain Float) | <https://en.wikipedia.org/wiki/Bfloat16_floating-point_format> | Used as the comparison axis in [`docs/GF16_BFLOAT16_NMSE.md`](GF16_BFLOAT16_NMSE.md) |

---

## 4. In-repo reading order

For someone evaluating TRI-1 Euler for the first time, the recommended
reading order is:

1. [STATUS.md](../STATUS.md) — what's real today (readiness ladder)
2. [LINEUP.md](../LINEUP.md) — where Euler sits in the TRI-NET line
3. [BENCHMARKS.md](../BENCHMARKS.md) — what numbers can be quoted at which tier
4. [COMPETITORS.md](../COMPETITORS.md) — differentiation axis
5. [`docs/D2D_PROTOCOL.md`](D2D_PROTOCOL.md) — die-to-die protocol (draft)
6. [`docs/INTERCONNECT_PROTOCOL_V1.md`](INTERCONNECT_PROTOCOL_V1.md) — board protocol (frozen)
7. [`docs/TRIPLE_DECK_STATUS.md`](TRIPLE_DECK_STATUS.md) — power composition
8. [`docs/GF16_BFLOAT16_NMSE.md`](GF16_BFLOAT16_NMSE.md) — accuracy protocol
9. [`docs/TRI_NET_API.md`](TRI_NET_API.md) — external integration view
10. [`docs/PROJECTIONS_22FDX.md`](PROJECTIONS_22FDX.md) — labelled projections only
11. [`docs/SCIENTIFIC_IMPROVEMENT_PLAN.md`](SCIENTIFIC_IMPROVEMENT_PLAN.md) — TRI-NET 2026 plan (e-engine view; `target` / `projection` / `VERIFY` labels)

---

## 5. What this isn't

A whitepaper-grade narrative document is **not** in this repo today.
Pull-request material and customer-facing slides that need a single-PDF
"whitepaper" should be assembled from the files in §4 plus the
[`docs/TRI_NET_DARPA_CLARA_PROPOSAL.md`](TRI_NET_DARPA_CLARA_PROPOSAL.md)
and [`docs/TRI_NET_G1_NASA_REPORT.md`](TRI_NET_G1_NASA_REPORT.md) reports.
Any standalone "TRI-NET whitepaper PDF" is `PLANNED` and not part of the
TTSKY26b submission bundle.

---

## 6. Caveat block (required when citing any forward-looking claim)

Any external use of TRI-NET material that quotes the "75 TOPS/W baseline /
405 TOPS/W with AVS-96 (5.4× boost)" or "~20 TOPS / <1 W TDP" lines MUST
include the caveat block from [BENCHMARKS.md §4](../BENCHMARKS.md):

> *Numbers are `PROJECTED` at an advanced node (22 FDX-class) under
> SUPER-CROWN module-mix assumptions and stated power-gating / voltage-
> scaling assumptions. SKY130A is the proof-of-concept demonstrator;
> advanced node is competitive vs. Hailo / Mythic per the projection. No
> silicon TOPS/W has been `MEASURED`.*

The caveat is non-negotiable. See [BENCHMARKS.md](../BENCHMARKS.md) for
the authoritative wording.
