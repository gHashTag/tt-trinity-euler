# Changelog — TRI-1 Euler (e-engine)

All notable changes to the **tt-trinity-euler** project are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

---

## [Unreleased]

### Added
- `docs/API.md` — Complete API documentation with module interfaces
- `docs/ARCHITECTURE.md` — ASCII architecture diagrams (system overview, 2×2 mesh, CLARA gaps)
- `docs/COMPARISON.md` — Cross-chip comparison matrix (phi/euler/gamma)
- `docs/TEST_COVERAGE.md` — Test coverage report showing 56% coverage
- `docs/TROUBLESHOOTING.md` — Comprehensive troubleshooting guide
- `docs/INDEX.md` — Complete documentation index
- `docs/GDS.md` — GDS status badges and tracking
- `docs/HARDWARE_BRINGUP.md` — Hardware bring-up guide with cocotb examples
- `examples/README.md` — Code examples for common usage patterns
- `test/tb_integration_clara.v` — CLARA gaps integration test
- `test/sim.sh` — Unified simulation script with colorized output
- `.verible.lintr` — Verible linter configuration
- `.pre-commit-config.yaml` — Pre-commit hooks for code quality and CLARA traceability
- `scripts/check_clara_traceability.sh` — CLARA gap traceability checker
- `scripts/formal_verify.sh` — Formal verification script using SBY
- `scripts/perf_sim.sh` — Performance simulation with cycle counting
- `CONTRIBUTING.md` — Comprehensive contributing guidelines with CLARA gap requirements
- Performance benchmarks section in README with throughput, latency, area, power tables

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