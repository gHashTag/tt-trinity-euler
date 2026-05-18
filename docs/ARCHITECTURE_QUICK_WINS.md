# Architecture Quick Wins — TRI-1 Euler (e-engine)

**Document ID:** TRINITY-EULER-QW-V0.1
**Status:** SPEC — recommendations grounded in repo state + competitive
read. Readiness label per row.
**Last updated:** 2026-05-18
**Scope:** TRI-1 Euler (this repo). Sibling chips have their own
quick-win docs.
**Companion docs:** [`docs/VERIFICATION_CLAIMS_MATRIX.md`](VERIFICATION_CLAIMS_MATRIX.md),
[`docs/D2D_PROTOCOL.md`](D2D_PROTOCOL.md),
[`docs/TRIPLE_DECK_STATE_MACHINE.md`](TRIPLE_DECK_STATE_MACHINE.md),
[`docs/GF16_BFLOAT16_NMSE.md`](GF16_BFLOAT16_NMSE.md),
[`docs/PROJECTIONS_22FDX.md`](PROJECTIONS_22FDX.md),
[`COMPETITORS.md`](../COMPETITORS.md)

> **R5-Honesty contract.** Every quick win below is either (a) already
> implementable from current repo state with no RTL semantic change, or
> (b) explicitly marked `PLANNED` with an estimated effort tier. Nothing
> here invents a number. Nothing here promotes a row out of `SPEC-DRAFT`.

---

## 0. Status legend

| Symbol | Meaning |
|---|---|
| ✓ | Silicon-measured (NOT used in this repo today) |
| ⊙ | RTL-simulation target (pre-silicon) |
| ◷ | Architectural projection (from first principles, not from simulation of this design) |
| `SPEC-DRAFT` | Specified, not yet implemented |
| `RTL` / `RTL-STUB` | RTL exists (`-STUB` = pin-correct but not full behaviour) |
| `PLANNED` | Scoped for a future wave |

Every numerical claim in customer-facing material MUST carry one of the
symbols above and MUST map to a row in
[`docs/VERIFICATION_CLAIMS_MATRIX.md`](VERIFICATION_CLAIMS_MATRIX.md).

---

## 1. Why this doc exists

The TRI-NET competitive landscape ([COMPETITORS.md](../COMPETITORS.md)) has
moved aggressively over the last 18 months: NVIDIA Blackwell ships
NVFP4/FP8/MX microscaling, IBM NorthPole sits at >1000 frames/joule on
silicon, Tenstorrent Blackhole publishes BFP2/4/8 datasheets, the MX
Alliance (AMD/ARM/Intel/Meta/Microsoft/NVIDIA/Qualcomm) standardised
block-floating-point. Euler's differentiation thesis — **open RTL + open
PDK + native ternary + on-chip audit/proof-trace** — is real, but the
*evidence* surface needs the same five hardenings the silicon-proven
competitors already publish: bandwidth/fJ-bit tables, UCIe-style
conformance, block-FP interoperability maps, conformance CI vectors, and
R5-honest status labels on every number. This document lists exactly the
quick wins that close that gap without changing RTL semantics.

---

## 2. Quick wins ranked by impact-to-effort

| ID | Title | Effort | Impact | Status |
|---|---|---|---|---|
| **QW-E-1** | D2D bandwidth / fJ-per-bit table | Low | Very High | `SPEC-DRAFT` (this doc §3) |
| **QW-E-2** | UCIe-style D2D conformance evidence block | Low | Very High | `SPEC-DRAFT` (this doc §4 + `conformance/D2D-CONFORMANCE-V0.json`) |
| **QW-E-3** | GF16 ↔ MX block-FP interoperability map | Low | High | `SPEC-DRAFT` (this doc §5) |
| **QW-E-4** | D2D conformance CI vectors wired into the spec gate | Low | High | **Done in this PR** (see `scripts/check_trinet_specs.sh` step 8 + 6 `conformance/d2d/d2d_tc_*.json`) |
| **QW-E-5** | R5 honest status legend on every TOPS / NMSE / fJ-bit row | Low | High | **Done in this PR** (matrix + this doc §0; legend reproduced in README) |
| **QW-E-6** | Triple-Decker FSM → MLCommons inference power-phase mapping | Low | Medium | This doc §6 |
| **QW-E-7** | Body-bias operating-point table (RBB / Nominal / FBB / CAP_BOOST) | Low | High | This doc §7 |
| **QW-E-8** | Block-FP ecosystem alignment statement in README | Low | Medium | `SPEC-DRAFT` (this doc §5 + README) |
| **QW-E-9** | NVDLA-class positioning paragraph in README | Low | Medium | This doc §8 |
| **QW-E-10** | Per-deck power-delta measurement plan stub | Medium | High (after silicon) | This doc §9; ties to `VCM-DECK3-001` |

QW-E-4 and QW-E-5 already landed in the verification PR; the others are
written below as ready-to-paste sections with named claim IDs and named
anti-claims.

---

## 3. QW-E-1 — D2D bandwidth / fJ-per-bit table

**Why:** UCIe 2.0 and NVLink 6 publish two numbers on every product page —
GT/s per lane and pJ/bit. Without those, Euler's `d2d_holo_mesh.v` looks
opaque to an integrator who is fluent in UCIe. The table below is what a
reader should see at the top of [`docs/D2D_PROTOCOL.md`](D2D_PROTOCOL.md)
once silicon characterisation lands; until then, every row is `⊙` or
`◷`.

> **Reference comparators**
> ([COMPETITORS.md](../COMPETITORS.md) / industry sources, silicon-tier
> for the comparators):
>
> - UCIe Standard-Package: ~4-12 GT/s, ~1 pJ/bit
> - UCIe Advanced-Package: 16-32 GT/s, ≤1 pJ/bit
> - NVLink 6: 3.6 TB/s/GPU bidirectional
> - PCIe Gen5 (for context): ~10 pJ/bit @ 32 GT/s

**Proposed Euler D2D row (all entries pre-silicon):**

| Parameter | Value | Tier | Witness |
|---|---|---|---|
| Symbol stream width | 1 bit / lane | `SPEC-FROZEN` | `src/d2d_holo_mesh.v` |
| Active TX lanes | 4 (`n_tx`, `e_tx`, `s_tx`, `w_tx`) | `SPEC-FROZEN` | `src/d2d_holo_mesh.v` + `uio[3:0]` |
| Active RX lanes | 4 (`n_rx`, `e_rx`, `s_rx`, `w_rx`) | `SPEC-FROZEN` | `src/d2d_holo_mesh.v` + `uio[7:4]` |
| Symbol clock | up to 50 MHz on SKY130A demonstrator | `⊙` (SKY130A) | matches `info.yaml` target Fmax |
| Peak per-lane GT/s | 0.05 GT/s on SKY130A demonstrator | `⊙` | derived from above |
| Peak per-lane GT/s | 0.4-1.0 GT/s on 22FDX projection | `◷` | derived from 22FDX Fmax envelope (no Fmax measured) |
| Aggregate D2D rate | 4 × per-lane | `⊙`/`◷` | per row above |
| fJ/bit | **TBD — not characterised** | n/a | populate after silicon returns; see §9 |

**Required README footnote (R5):**

> *Bandwidth and energy/bit figures are pre-silicon (SKY130A
> demonstrator) or analytical projections to 22FDX. No silicon
> measurement is available; the production `fJ/bit` cell is intentionally
> empty in this branch. See claim `VCM-D2D-001..004` in the
> [Verification Claims Matrix](VERIFICATION_CLAIMS_MATRIX.md).*

**New claim IDs to add when this table is populated:**
`VCM-D2D-BW-001` (per-lane GT/s) and `VCM-D2D-EN-001` (fJ/bit). The
matrix already reserves space for them in its claim-ID namespace.

---

## 4. QW-E-2 — UCIe-style D2D conformance evidence block

**Why:** UCIe's adoption story rests on a small, well-known set of
conformance assets — CRC polynomial, retry policy, BER target, Flit
format, conformance vectors. Euler can publish the analogous five-row
block today using artefacts already in this PR.

| UCIe axis | Euler equivalent | Witness |
|---|---|---|
| Frame format | `{SYNC(1), KIND(4), EPOCH(8), PAYLOAD, RECEIPT(32)}` | [`docs/D2D_PROTOCOL.md`](D2D_PROTOCOL.md) §4.2, [`conformance/D2D-CONFORMANCE-V0.json`](../conformance/D2D-CONFORMANCE-V0.json) |
| Integrity check | Truncated BLAKE3 over (`KIND`, `EPOCH`, `PAYLOAD`) | Same; backed by [`src/blake3_anchor.v`](../src/blake3_anchor.v) |
| BER target | TBD (`PLANNED` — no link characterisation) | n/a |
| Retry policy | Max 3, backoff `[16, 64, 256]` cycles | [`conformance/d2d/d2d_tc_003_bad_crc.json`](../conformance/d2d/d2d_tc_003_bad_crc.json) |
| Conformance vectors | TC-001..006 (valid IDLE, valid SPIKE_SUMMARY, bad receipt, unsupported opcode, timeout/retry, multi-chip ordering) | `conformance/d2d/d2d_tc_001..006.json` |

**Quick win action:** the table above is the section to paste into
[`docs/D2D_PROTOCOL.md`](D2D_PROTOCOL.md) §4.4 ("Conformance — minimal
stub behaviour") as soon as a sibling-side row is added for BER. No RTL
change required.

**Anti-claim:** "UCIe-style" does NOT mean "UCIe-compliant." Euler's D2D
uses BLAKE3 truncated to 32 bits as its integrity check, not UCIe's
16-bit CRC, and operates at a fraction of UCIe's GT/s targets. The
comparison is structural, not specification-level.

---

## 5. QW-E-3 — GF16 ↔ MX block-FP interoperability map

**Why:** The MX Alliance ([arXiv 2310.10537](https://arxiv.org/abs/2310.10537))
standardised MXFP4/6/8 + MXINT8 across AMD/ARM/Intel/Meta/Microsoft/NVIDIA/Qualcomm.
GF16 is conceptually adjacent to MXFP8 (same family of scaled element
formats) but is not MX. A reader cannot tell that from the existing docs.
The table below resolves the ambiguity without claiming interoperability.

| Property | Euler GF16 | MXFP8 (E4M3) | MXFP8 (E5M2) | bfloat16 | Conversion cost |
|---|---|---|---|---|---|
| Bits | 16 | 8 | 8 | 16 | n/a |
| Sign | 1 | 1 | 1 | 1 | n/a |
| Exponent | 6 (bias 31) | 4 (bias 7) | 5 (bias 15) | 8 (bias 127) | needs renormalise |
| Mantissa | 9 | 3 | 2 | 7 | needs round-nearest-even |
| Block exponent shared? | No (per-element) | Yes (per-32-element block) | Yes (per-32-element block) | No | adding/removing block scale |
| Bit-exact decode to FP64 | Yes (via `FORMAT-SPEC-001.json`) | Per MX spec | Per MX spec | IEEE 754 | n/a |
| Native RTL on Euler | Yes ([`src/gf16_*.v`](../src/)) | No (software-only here) | No | No (software reference only) | n/a |

**Transcoding policy across the D2D mesh** (`SPEC-DRAFT`):

| Direction | Native format on wire | Conversion needed |
|---|---|---|
| Phi → Euler | GF16 + GF_TAG | None — GF_TAG is already a kind in `D2D-CONFORMANCE-V0.json` |
| Euler → Gamma | GF16 + spike summary | None |
| Euler ↔ host | GF16 / Int8 / NF4 / FP8 (quantizer modules in this repo) | Quantizer module (`src/quant_*.v`) handles conversion at compile time, not on the D2D wire |
| Euler ↔ external bfloat16 NPU | n/a | Software round-trip only; see [`docs/GF16_BFLOAT16_NMSE.md`](GF16_BFLOAT16_NMSE.md) |

**Anti-claim:** GF16 is NOT an MX format. The shared exponent block size
is a defining MX property; GF16 carries a per-element exponent. The
comparison above is for *positioning* (so a reader fluent in MX can locate
GF16 in the design space), not for compliance.

**New claim IDs to add to the matrix when this table is published in the
README:** `VCM-FORMATS-MX-001` (GF16-to-MX adjacency statement),
`VCM-FORMATS-MX-002` (per-format transcoding policy across D2D).

---

## 6. QW-E-6 — Triple-Decker FSM → MLCommons inference power-phase mapping

**Why:** MLCommons measures average AC system power over the full
performance window per scenario and explicitly separates "System Power"
from "chip TDP." Today's Euler power numbers (75 / 405 TOPS/W) are
PROJECTIONS that have no defined measurement window. Mapping the
Triple-Decker FSM ([`docs/TRIPLE_DECK_STATE_MACHINE.md`](TRIPLE_DECK_STATE_MACHINE.md))
to MLCommons phases is the lowest-effort way to make a future post-silicon
TOPS/W directly comparable.

| MLCommons phase | Triple-Decker state | Time window for the average |
|---|---|---|
| Idle / warm-up | `IDLE` (with optional `RBB`) | ≥ `IDLE_DWELL_MAX` cycles |
| Single-stream | `FBB` at `FBB_LOW` | full stream window |
| Multi-stream | `FBB` at `FBB_MED` | full stream window |
| Server / offline | `FBB` at `FBB_HIGH` or `CAP_BOOST` (with explicit fallback) | full benchmark window |
| Drain / tail | `FBB` → `IDLE` (during `cooldown_ctr` decay) | `CD_NORMAL` cycles |
| Fault / brownout | `IDLE` after `T8/T9/T10` fallback | reported separately, not folded into TOPS/W |

**Quick win action:** add this five-row block to
[`docs/TRIPLE_DECK_STATE_MACHINE.md`](TRIPLE_DECK_STATE_MACHINE.md) §6 in
a future commit. Already cross-referenced from the matrix as
`VCM-DECK-FSM-001`.

**Anti-claim:** mapping a state to a phase is not the same as running an
MLPerf submission. No MLPerf number can be quoted for Euler until silicon
returns and a System-Power-measured run is logged.

---

## 7. QW-E-7 — Body-bias operating-point table

**Why:** GF publishes 22FDX body-bias characterisation (≈30-45% frequency
gain at iso-voltage or ≈45% power reduction at iso-frequency depending
on bias polarity). Euler today only names the bias states; it does not
quote operating points. The skeleton below names what *will* be filled in
when characterisation runs and explicitly leaves no cell at risk of being
filled in by guess.

| State | V<sub>DD</sub> (target) | V<sub>BB</sub> (target) | Freq (target) | Notes | Status |
|---|---|---|---|---|---|
| `IDLE` (no bias) | 0.95 V | 0.0 V | n/a | leakage-only | `SPEC` |
| `RBB`            | 0.95 V | < 0.0 V (RBB) | n/a | leakage minimised; no compute | `SPEC` (no RTL module) |
| `FBB_OFF`        | 0.95 V | 0.0 V | nominal | matches `fbb_active_path.v` `FBB_OFF` | `RTL` |
| `FBB_LOW`        | 0.95 V | small +V<sub>BB</sub> | + small Δf | per `fbb_active_path.v` level enum | `RTL` |
| `FBB_MED`        | 0.95 V | mid +V<sub>BB</sub> | + Δf | per `fbb_active_path.v` | `RTL` |
| `FBB_HIGH`       | 0.95 V | high +V<sub>BB</sub> | + larger Δf | per `fbb_active_path.v` | `RTL` |
| `FBB_MAX`        | 0.95 V | max +V<sub>BB</sub> | + max Δf | per `fbb_active_path.v` | `RTL` |
| `CAP_BOOST`      | 1.05 V (AVS-96 lift) | (FBB-stacked) | sustained burst | per `avs_controller_96.v` | `RTL` |

Every numeric cell here is **deliberately not filled in** in the open
RTL. The cells are populated by silicon characterisation under a stated
PVT corner. Until then, the README/whitepaper MUST quote the cell as
"TBD post-silicon" and not as a number.

**New claim IDs to reserve:** `VCM-BIAS-001..008` (one per row above).

---

## 8. QW-E-9 — NVDLA-class positioning paragraph

**Why:** NVDLA is the open-source synthesisable inference accelerator
that academic and startup adopters compare against. Euler's footprint
(8×2 tiles, GF16 inner-product engine, audit ring, BLAKE3 receipt) is in
the same conceptual neighbourhood. A one-paragraph "what NVDLA is, what
Euler is, what is different" line is the lowest-effort positioning
artefact.

**Paragraph to paste into README "Why this is different" block:**

> NVDLA is NVIDIA's open-source fixed-function inference accelerator (6
> specialised units, INT8 fixed-point) integrated in Jetson Xavier and
> SiFive FE310-based SoCs. NVDLA is the closest analog to Euler's
> compute role on the open-RTL axis. Euler differs in three dimensions:
> (i) numeric format — GF16 element format vs NVDLA's INT8 fixed; (ii)
> safety surface — Euler ships 10 CLARA-style safety gaps and an on-chip
> BLAKE3 audit-ring (`src/audit_log_ring_buffer.v`), NVDLA does not; (iii)
> low-power story — Euler targets a 22FDX FD-SOI Triple-Decker (RBB / FBB
> / CAP_BOOST) envelope, NVDLA is silicon-proven on bulk 12-16 nm FinFET.
> All three differences are pre-silicon for Euler today; the per-row
> readiness is in [`docs/VERIFICATION_CLAIMS_MATRIX.md`](VERIFICATION_CLAIMS_MATRIX.md).

**Anti-claim:** Euler is NOT NVDLA-compatible at the software-stack
level. The two share no common compiler IR today.

---

## 9. QW-E-10 — Per-deck power-delta measurement plan stub

**Why:** Today the Triple-Decker status doc states that the "5.4× TOPS/W
boost" is `PROJECTED`; once TTSKY26b silicon returns, the gap between
`PROJECTED` and `MEASURED` will require a defined measurement plan or it
will not happen. The skeleton below names the plan.

**Measurement objective:** per-state ΔP and ΔF on the same workload
(canonical anchor `0x47C0` + 16 dot8 vectors), at TT corner, 50 MHz.

| Quantity | Method | Where it lands |
|---|---|---|
| `P_IDLE` | Long-window rail-current average with workload OFF | `boards/measurements/euler_idle_*.csv` (planned) |
| `P_FBB_LOW` | Same harness, `fbb_level=LOW` | `boards/measurements/euler_fbb_low_*.csv` |
| `P_FBB_MED` | Same harness, `fbb_level=MED` | `boards/measurements/euler_fbb_med_*.csv` |
| `P_CAP_BOOST` | Same harness with AVS-96 lift active, burst-window aligned | `boards/measurements/euler_cap_boost_*.csv` |
| ΔP per deck | Pairwise difference | `boards/measurements/euler_deck_delta_*.csv` |
| TOPS/W per deck | ΔTOPS / ΔP | promotes `VCM-TOPS-001/002/003` from `PROJECTED` to `MEASURED` only after this run |

**Anti-claim:** No silicon has been characterised. Every cell above is a
plan, not a result. The corresponding rows in
[`docs/VERIFICATION_CLAIMS_MATRIX.md`](VERIFICATION_CLAIMS_MATRIX.md)
remain `PROJECTED` until `boards/measurements/` is non-empty.

---

## 10. What this doc explicitly does NOT propose

- **No new TOPS/W headline.** The repo already carries 75 / 405 / 5.4×
  as `PROJECTED`; this doc does not invent additional headline numbers.
- **No FPGA Fmax updates.** The 323 MHz XC7A100T figure remains
  `unverified-in-this-branch` per `VCM-FPGA-001`. Reattaching the log is
  a separate task and is NOT a quick win in this PR.
- **No DOI changes.** Zenodo metadata changes live in
  [`docs/RELEASE_MANIFEST_TRINET_V1.md`](RELEASE_MANIFEST_TRINET_V1.md)
  and `.zenodo.json` (this PR), not here.
- **No RTL semantic change.** Every section above adds documentation,
  conformance JSON, or planning skeleton — none touches synthesisable
  `src/*.v`.

---

## 11. Where each quick win shows up in the repo

| Quick win | Artefact in this PR |
|---|---|
| QW-E-1 | This doc §3 + reserved claim IDs `VCM-D2D-BW-001`, `VCM-D2D-EN-001` |
| QW-E-2 | [`conformance/D2D-CONFORMANCE-V0.json`](../conformance/D2D-CONFORMANCE-V0.json) + [`docs/D2D_PROTOCOL.md`](D2D_PROTOCOL.md) §4 |
| QW-E-3 | This doc §5 |
| QW-E-4 | `scripts/check_trinet_specs.sh` step 8 + `conformance/d2d/d2d_tc_001..006.json` |
| QW-E-5 | Status legend in this doc §0; mirrored in [`docs/VERIFICATION_CLAIMS_MATRIX.md`](VERIFICATION_CLAIMS_MATRIX.md) §1.2 + README "Verification surface" |
| QW-E-6 | This doc §6 (target: paste into [`docs/TRIPLE_DECK_STATE_MACHINE.md`](TRIPLE_DECK_STATE_MACHINE.md) §6) |
| QW-E-7 | This doc §7 (target: paste into [`docs/PROJECTIONS_22FDX.md`](PROJECTIONS_22FDX.md) §1.5) |
| QW-E-8 | This doc §5 + README block-FP paragraph |
| QW-E-9 | This doc §8 + README NVDLA paragraph |
| QW-E-10 | This doc §9 (post-silicon measurement plan skeleton) |

---

## 12. Links

- [`docs/VERIFICATION_CLAIMS_MATRIX.md`](VERIFICATION_CLAIMS_MATRIX.md)
- [`docs/D2D_PROTOCOL.md`](D2D_PROTOCOL.md)
- [`docs/TRIPLE_DECK_STATE_MACHINE.md`](TRIPLE_DECK_STATE_MACHINE.md)
- [`docs/GF16_BFLOAT16_NMSE.md`](GF16_BFLOAT16_NMSE.md)
- [`docs/PROJECTIONS_22FDX.md`](PROJECTIONS_22FDX.md)
- [`COMPETITORS.md`](../COMPETITORS.md)
- [`docs/RELEASE_MANIFEST_TRINET_V1.md`](RELEASE_MANIFEST_TRINET_V1.md)
