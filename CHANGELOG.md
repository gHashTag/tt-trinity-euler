# Changelog — TRI-1 Euler (e-engine)

All notable changes to the **tt-trinity-euler** project are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

---

## [Unreleased]

### Added
- `docs/API.md` — Complete API documentation with module interfaces
- `docs/ARCHITECTURE.md` — ASCII architecture diagrams (system overview, 2×2 mesh, CLARA gaps)
- `docs/COMPARISON.md` — Cross-chip comparison matrix (phi/euler/gamma)
- Performance benchmarks section in README with throughput, latency, area, power tables
- Additional testbenches for quantization and compute modules
- `docs/D2D_PROTOCOL.md` — Holographic die-to-die packet protocol (SPEC-DRAFT). Builds on the frozen 3-wire TIP v1.0; positions Euler as the safety/control e-engine endpoint bridging Phi (φ-anchor) and Gamma (γ-surface).
- `docs/GF16_BFLOAT16_NMSE.md` — Standard NMSE comparison protocol between GF16 (HW-under-test via `sim/tb_gf16_dot8.v`) and bfloat16 (software reference). Until the harness lands, no NMSE number may be quoted.
- `docs/TRIPLE_DECK_STATUS.md` — RBB → FBB → CAP_BOOST (AVS-96) status on Euler with honest per-deck readiness; cross-chip conformance contract so Phi and Gamma can match.
- `docs/TRI_NET_API.md` — External-integration view: pinout, TIP v1.0, D2D — bring-up sequence and host driver shape.
- `docs/WHITEPAPER_LINKS.md` — Value proposition + external publication / DOI / programme link index.
- `docs/PROJECTIONS_22FDX.md` — 22FDX TOPS/W projection table (all rows `PROJECTED`) and Zenodo bundle readiness checklist (all rows `PLANNED`).
- `docs/SCIENTIFIC_IMPROVEMENT_PLAN.md` — TRI-NET 2026 Scientific Improvement Plan, e-engine view: CL-01..CL-04 (DARPA-CLARA alignment), EN-01..EN-03 (energy efficiency / Triple-Deck), SN-01..SN-03 (SNN-TRI fusion hooks), PUB-01..PUB-03 (publication path), OS-01..OS-03 (open-source community), timeline (Q2..Q4 2026 + "open" for silicon), success metrics (committed artefacts + CI-green workflows only), references, anti-claims. `target` / `projection` / `VERIFY` labels per row; no `MEASURED` row added; no DARPA funding / silicon date / paper acceptance / `1000×` / `4000 TOPS/W` claim.

### Changed
- Updated README with unified badge order and TRI-NET cross-references section
- Improved test coverage across all quantization modules

---

## [TTSKY26b-submit] — 2026-05-17

### Tape-out
- Submitted to Tiny Tapeout SKY 26b shuttle (close: 2026-05-18 UTC)
- Allocation: **8×2** tiles (16 tiles — expansion layer)
- Cross-die anchor: dot4(1,2,3,4) = 0x47C0 — TG-TRIAD-X ledger (Theorem 36.1)

### Fixed
- **`tb.v` cocotb guard** — standalone driver block gated behind `\`ifndef COCOTB_SIM` to prevent driver conflicts during cocotb simulation runs
- **cocotb `VERILOG_SOURCES`** — `test/Makefile` updated to include all non-tb source files from `src/`; previously missing modules caused elaboration failures

### Added
- `docs/info.md` — Tiny Tapeout submit requirement (project description, pin mapping, usage instructions)

### Verified
- All 5 CI workflows green: t27 Format, R-SI-1 no-star, RTL & Cocotb, FPGA Synthesis, GDS
- `tt_submission` artifact validated
- FPGA-validated at 323 MHz on XC7A100T; silicon target 50 MHz @ SKY130A
- 18 SUPER-CROWN modules synthesised cleanly (R-SI-1: zero `*` operators in new RTL)
- 10 DARPA CLARA AI Safety Gaps (Gap-1 … Gap-10) all present in source list
- D2D holo mesh 4-port N/E/S/W router verified (LAYER-FROZEN gate per PhD Thm 36.1 R18)
- Coq provenance: trios-coq 297 Qed + 141 Admitted at submission

---

<!-- DOI: 10.5281/zenodo.19227877 — previous version -->
<!-- Siblings: tt-trinity-phi (1×1, 1 tile) · tt-trinity-gamma (8×4, 32 tiles) -->