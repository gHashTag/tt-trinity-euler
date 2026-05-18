# STATUS — TRI-1 Euler (tt-trinity-euler)

**Last updated:** 2026-05-17
**Branch / commit at write time:** `docs/improvement-package-2026-05-17` on top of `94bbef2`
**Shuttle target:** Tiny Tapeout TTSKY26b (SKY130A), 8×2 tiles
**Role in TRI-NET:** balanced / DARPA-CLARA-facing SKU (e-engine — see [LINEUP.md](LINEUP.md))

This file is the single source of truth for "what is real today" in this
repository. Numbers and claims appearing elsewhere (README, slides, papers)
must reduce to evidence cited here.

---

## 1. Readiness ladder

The TRI-NET line uses six readiness levels. A level is **only** marked DONE
when there is a reproducible artefact in this repository (or a linked CI run)
that demonstrates it. "Planned" means the work item is scoped but not yet
realised. "Partial" means some sub-modules are at that level while others are
not.

| Level | Meaning | tt-trinity-euler status | Evidence |
|------:|---------|-------------------------|----------|
| **SPEC**     | Architecture, ISA, pinout, protocols frozen in markdown / YAML | **DONE (board-frozen) / PARTIAL (D2D packet layer = SPEC-DRAFT)** | [`info.yaml`](info.yaml), [`docs/EULER_ISA_V2.md`](docs/EULER_ISA_V2.md), [`docs/PINOUT.md`](docs/PINOUT.md), [`docs/INTERCONNECT_PROTOCOL_V1.md`](docs/INTERCONNECT_PROTOCOL_V1.md) (FROZEN), [`docs/D2D_PROTOCOL.md`](docs/D2D_PROTOCOL.md) (DRAFT — packet layer above the frozen 3-wire), [`docs/architecture/TRI_NET_SHUTTLE_TRIAD.md`](docs/architecture/TRI_NET_SHUTTLE_TRIAD.md) |
| **RTL**      | Synthesisable Verilog-2005 in `src/`, R-SI-1 compliant | **DONE** | 86 `.v` files under [`src/`](src/) (51 core e-engine modules + 35 v1.0.0 quantiser / power / format files merged in from main), R-SI-1 enforced by [`.github/workflows/no_star.yaml`](.github/workflows/no_star.yaml) |
| **SIM**      | Functional simulation passes locally and in CI | **DONE (core path)** | `iverilog` GF16 dot4/dot8 testbench → `TOTAL PASS=17 FAIL=0` (see §3); [`.github/workflows/test.yaml`](.github/workflows/test.yaml) canonical 0x47C0 check |
| **SYNTH**    | OpenLane2 logic synthesis on SKY130A clean (no errors) | **PARTIAL — pipeline configured, last successful run claimed in CHANGELOG; not re-verified locally in this branch** | [`.github/workflows/gds.yaml`](.github/workflows/gds.yaml) (uses `TinyTapeout/tt-gds-action@ttsky26b`); [`CHANGELOG.md`](CHANGELOG.md) "Verified — All 5 CI workflows green" |
| **GDS/TAPEOUT** | Submitted to a shuttle; signed-off GDSII produced | **SUBMITTED (TTSKY26b)** — not yet returned silicon | [`CHANGELOG.md`](CHANGELOG.md) §`[TTSKY26b-submit] 2026-05-17`; [`.gds_trigger`](.gds_trigger) |
| **SILICON** | Physical die in hand, bring-up data collected | **NOT YET** | No bring-up logs in this repo. Carrier-board / FPGA bring-up artefacts exist (see [`docs/boards/SILICON_G1_BRINGUP.md`](docs/boards/SILICON_G1_BRINGUP.md)) but they are not silicon-from-TTSKY26b results. |

> **Conservative reading:** TRI-1 Euler is at **GDS-SUBMIT** as of 2026-05-17.
> Treat everything downstream of "silicon returns from the foundry" — measured
> TOPS/W, measured WNS, measured power, post-silicon errata — as **projected
> or unverified** until a silicon bring-up section is added below.

---

## 2. What runs today

The following commands work from a clean checkout on Ubuntu 24.04 with
`iverilog 12.0+`:

```bash
# 1. Build & run the GF16 dot4/dot8 functional testbench
iverilog -I src -o /tmp/sim_dot8 \
    src/gf16_mul.v src/gf16_add.v src/gf16_dot4.v src/gf16_dot8.v \
    sim/tb_gf16_dot8.v
vvp /tmp/sim_dot8
# Expected last line: "ALL PASS"  (TOTAL PASS=17  FAIL=0)

# 2. R-SI-1 audit (zero new `*` in synthesisable RTL)
bash -c 'see .github/workflows/no_star.yaml for the exact filter'
```

CI workflows that gate `main`:

| Workflow file | What it enforces |
|---|---|
| [`.github/workflows/test.yaml`](.github/workflows/test.yaml) | Icarus build + canonical `0x47C0` top-level check + Cocotb suite |
| [`.github/workflows/no_star.yaml`](.github/workflows/no_star.yaml) | R-SI-1: zero new `*` operators in `src/*.v` (allow-list: legacy `gf16_mul.v`, testbenches) |
| [`.github/workflows/gds.yaml`](.github/workflows/gds.yaml) | OpenLane2 GDS build via `TinyTapeout/tt-gds-action@ttsky26b` + precheck + GL test + viewer |
| [`.github/workflows/fpga.yaml`](.github/workflows/fpga.yaml) | FPGA elaboration sanity |
| [`.github/workflows/tri-test.yml`](.github/workflows/tri-test.yml) | Trinity cross-tile/lane tests |

---

## 3. Evidence table

Every line below ties a *claim* to a *file* (or CI workflow). If a claim is
not in this table, it is **not** part of the supported status.

| Claim | Evidence | Status |
|---|---|---|
| 8×2 tile allocation on SKY130A | [`info.yaml`](info.yaml) `tiles: "8x2"` | SPEC |
| 86 RTL modules under `src/` (51 core e-engine + 35 v1.0.0 add-ons) | `ls src/*.v \| wc -l` = 86 | RTL |
| GF16 dot4 canonical anchor = `0x47C0` | [`sim/tb_gf16_dot8.v`](sim/tb_gf16_dot8.v) `dot4_canonical` test passes | SIM |
| GF16 dot8 16 randomised vectors match golden | `sim/tb_gf16_dot8.v` `dot8_tv0..tv15` pass locally | SIM |
| Top-level `tt_um_ghtag_trinity_gf16` boots to `0x47C0` post-reset | [`.github/workflows/test.yaml`](.github/workflows/test.yaml) inline `tb_canonical` | SIM (CI-only) |
| R-SI-1: zero new `*` operators in synthesisable RTL (allow-list: `gf16_mul.v`, `tb_*.v`) | [`.github/workflows/no_star.yaml`](.github/workflows/no_star.yaml) gating | RTL-LINT |
| 18 SUPER-CROWN modules present in `source_files` list | [`info.yaml`](info.yaml) `source_files:` block | SPEC + RTL |
| 10 CLARA gaps present as RTL modules | [`info.yaml`](info.yaml), [`CLARA_TRACEABILITY.md`](CLARA_TRACEABILITY.md) | RTL (functional verification level varies — see CLARA_TRACEABILITY.md) |
| D2D 4-port N/E/S/W mesh router | [`src/d2d_holo_mesh.v`](src/d2d_holo_mesh.v) + [`docs/CROSS_TILE_INTERCONNECT.md`](docs/CROSS_TILE_INTERCONNECT.md) | RTL |
| Trinity Interconnect Protocol v1.0 spec frozen | [`docs/INTERCONNECT_PROTOCOL_V1.md`](docs/INTERCONNECT_PROTOCOL_V1.md) (commit `507cdfc`) | SPEC |
| D2D holographic packet-layer protocol drafted (above the frozen 3-wire TIP v1.0) | [`docs/D2D_PROTOCOL.md`](docs/D2D_PROTOCOL.md) | SPEC-DRAFT |
| GF16 vs bfloat16 NMSE comparison protocol | [`docs/GF16_BFLOAT16_NMSE.md`](docs/GF16_BFLOAT16_NMSE.md) — protocol only; no NMSE numbers recorded yet | SPEC-DRAFT |
| Triple-Deck (RBB→FBB→CAP_BOOST) cross-chip conformance contract | [`docs/TRIPLE_DECK_STATUS.md`](docs/TRIPLE_DECK_STATUS.md) — Deck-2 + Deck-3 RTL on Euler; Deck-1 SPEC-only | SPEC + RTL (per deck) |
| TRI-NET external integration API notes | [`docs/TRI_NET_API.md`](docs/TRI_NET_API.md) | SPEC-DRAFT |
| Whitepaper / publication link index | [`docs/WHITEPAPER_LINKS.md`](docs/WHITEPAPER_LINKS.md) | INDEX |
| 22FDX TOPS/W projection and Zenodo bundle readiness | [`docs/PROJECTIONS_22FDX.md`](docs/PROJECTIONS_22FDX.md) — all rows PROJECTED / PLANNED | PROJECTED / PLANNED |
| TRI-NET 2026 Scientific Improvement Plan (e-engine view) | [`docs/SCIENTIFIC_IMPROVEMENT_PLAN.md`](docs/SCIENTIFIC_IMPROVEMENT_PLAN.md) — `target` / `projection` / `VERIFY` labelled; no `MEASURED` rows added | PLAN |
| 2026 SIP issue pack — EPIC + 16 draft child issues | [`.github/issues/ISSUES_SUMMARY.md`](.github/issues/ISSUES_SUMMARY.md) + 17 markdown files; numeric prefixes are **local plan IDs only** (not GitHub issue numbers); creation via [`create_issues.sh`](.github/issues/create_issues.sh) (dry-run default, idempotent) | PLAN |
| CLARA proof manifest (Coq/Rocq provenance) | [`docs/CLARA_PROOF_MANIFEST.md`](docs/CLARA_PROOF_MANIFEST.md) (commit `c3b80b1`) | SPEC + partial proof artefacts under [`trios-coq/`](trios-coq/) |
| TTSKY26b shuttle submission | [`CHANGELOG.md`](CHANGELOG.md) `[TTSKY26b-submit] — 2026-05-17` | GDS-SUBMIT |
| Apache-2.0 only | [`LICENSE`](LICENSE) + R-SI-6 grep guard | LICENSE |

---

## 4. Things explicitly NOT claimed in this repo

These are common questions; the answer here is "no measured evidence, do not
quote in customer-facing material until evidence lands":

- ❌ **Measured silicon TOPS/W.** The 75 / 405 TOPS/W numbers cited in the
  README are *projections* on an advanced node, not SKY130A demonstrator
  measurements. See [BENCHMARKS.md](BENCHMARKS.md) §"Honest disclosure"
  and [`docs/PROJECTIONS_22FDX.md`](docs/PROJECTIONS_22FDX.md) for the
  per-row assumption clauses (all rows there are `PROJECTED`).
- ❌ **Measured power on silicon.** No power table from returned silicon.
- ❌ **Measured WNS / clock headroom on silicon.** The 50 MHz target is the
  spec ceiling for SKY130A submission, not a measured Fmax.
- ❌ **FPGA "323 MHz on XC7A100T".** This is recorded in `info.yaml` and
  `CHANGELOG.md` as project history; this branch does not re-verify it. Treat
  as **unverified in this branch** — to be re-checked when an FPGA log is
  added under `boards/` or `sim/g1_loopback/`.
- ❌ **DARPA CLARA programme award / contract.** The repo aligns with the
  publicly described CLARA programme structure
  ([darpa.mil/research/programs/clara](https://www.darpa.mil/research/programs/clara))
  and tags modules to TA1 / TA1.1 / TA1.2 / TA1.4 buckets. It does **not**
  imply an award, sub-award, or selection.
- ❌ **Production-grade formal verification across all 86 modules.** The
  Coq/Rocq tree (`trios-coq/`, `coq/`) carries `Qed`-closed lemmas for a
  scoped subset (IGLA invariants, kernel LUT-NPU, several physics modules);
  the rest of the RTL is *not* fully formally verified. CLARA_TRACEABILITY.md
  marks per-gap proof status conservatively.

---

## 5. Immediate checklist (next 30 days)

In priority order — these are the items that, if completed, would let us
move a row in §1 from PARTIAL/SUBMITTED to DONE.

- [ ] **SYNTH re-verification on this branch.** Re-run `gds.yaml` on
      `docs/improvement-package-2026-05-17` and attach the OpenLane2 run URL
      / artefact ID to this file. Until then SYNTH stays PARTIAL.
- [ ] **STA / DRC / LVS summary captured into repo.** Add a one-page
      `docs/SIGN_OFF_TTSKY26b.md` containing the final WNS / TNS / DRC count
      / LVS clean status pulled from the OpenLane2 run logs.
- [ ] **Cocotb regression matrix.** [`test/test.py`](test/test.py) + the
      `test/Makefile` configure a Cocotb run; capture a CI badge and link it
      from the README "What runs today" section.
- [ ] **CLARA traceability proof status sweep.** For each row in
      [CLARA_TRACEABILITY.md](CLARA_TRACEABILITY.md), confirm whether the
      proof column should be `Qed`, `Admitted`, or `not started`.
- [ ] **R-SI-1 audit log archive.** Stash the `no_star.yaml` workflow output
      for the submission commit as a permanent artefact (currently it lives
      only in the transient GitHub Actions run).
- [ ] **Silicon bring-up section.** When TTSKY26b silicon returns, append a
      §6 `Silicon bring-up` with: die photo, JTAG ID, canonical 0x47C0 from
      pads, RECEIPT trace, power log.
- [ ] **FPGA evidence re-attach.** Add an FPGA bitstream + log link (or
      explicitly retire the "323 MHz on XC7A100T" line everywhere if no
      reproducer can be found).

---

## 6. Silicon bring-up

*Empty — TTSKY26b silicon has not returned. Do not add projected numbers
here; this section is reserved for measured data only.*

---

## 7. How to update this file

1. Land your change on a branch.
2. Update the relevant row(s) in §1 and §3.
3. Cite the file or CI run that justifies the new status.
4. Open the PR with the body referencing this file.
5. A reviewer must confirm the cited evidence exists before merging.

> **Rule of thumb:** if you can't paste a path or a CI run URL into the
> "Evidence" column, the row stays at its prior level. Marketing copy goes
> in the README, not here.
