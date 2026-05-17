# BENCHMARKS — TRI-1 Euler

**Last updated:** 2026-05-17
**Rule:** every number on this page is one of `MEASURED`, `SIMULATED`,
`SYNTHESIS-REPORTED`, or `PROJECTED`. No bare number stands alone.

If a benchmark question is asked of TRI-1 Euler in customer-facing material
(slides, papers, proposals), the answer has to reduce to a row on this
page — otherwise it does not exist.

---

## 1. The 4-tier disclosure

| Tier | What it means | What you can say from this tier |
|---|---|---|
| `MEASURED` | Number came out of physical hardware (silicon or FPGA) inside this repo's evidence path. | "On chip / FPGA we observed …" |
| `SIMULATED` | Number came out of an RTL simulation (Icarus / Verilator / Cocotb) checked into this repo. | "Our RTL simulation reports …" |
| `SYNTHESIS-REPORTED` | Number came out of an OpenLane2 / synthesis run, reported by the toolchain on SKY130A. | "OpenLane2 reports …" |
| `PROJECTED` | Number is an extrapolation (different node, different density, BitNet-class workload assumption, etc.). | "Projected at <node> under <stated assumptions> …" — and only with those qualifications. |

> A `PROJECTED` number quoted without its qualifying clause is, for the
> purposes of this repository, **wrong**.

---

## 2. What we currently have

| Quantity | Value | Tier | Source / evidence |
|---|---|---|---|
| GF16 dot4 canonical anchor result | `0x47C0` | `SIMULATED` | [`sim/tb_gf16_dot8.v`](sim/tb_gf16_dot8.v) test `dot4_canonical` — runs locally with `iverilog 12.0`, prints `PASS dot4_canonical` |
| GF16 dot8 randomised vectors | 16/16 pass against golden model | `SIMULATED` | same testbench, `dot8_tv0..tv15` |
| Total testbench pass/fail | `TOTAL PASS=17  FAIL=0  ALL PASS` | `SIMULATED` | same testbench, run on this branch on 2026-05-17 |
| Top-level boot value after reset | `{uio_out, uo_out} == 16'h47C0` | `SIMULATED` | [`.github/workflows/test.yaml`](.github/workflows/test.yaml) inline `tb_canonical` |
| R-SI-1 audit (zero new `*` in synth RTL) | green | `LINT` (CI workflow) | [`.github/workflows/no_star.yaml`](.github/workflows/no_star.yaml) |
| Tile budget | 8×2 = 16 tiles on SKY130A | `SPEC` | [`info.yaml`](info.yaml) `tiles: "8x2"` |
| Target clock | 50 MHz | `SPEC` (not yet `SYNTHESIS-REPORTED` on this branch) | [`info.yaml`](info.yaml) `clock_hz: 50000000` |
| Module count under `src/` | 86 `.v` files | `MEASURED` (repo) | `ls src/*.v \| wc -l` |
| SUPER-CROWN module count | 18 (per `source_files`) | `SPEC` | [`info.yaml`](info.yaml) |
| CLARA gap module count | 10/10 present as RTL | `SPEC` + `RTL` | [`info.yaml`](info.yaml) + per-row [CLARA_TRACEABILITY.md](CLARA_TRACEABILITY.md) |

---

## 3. What we do **not** have yet — honest disclosure

The following are *not* measured for TRI-1 Euler today. They are tracked
here so that no one quotes them as if they were.

| Quantity | Why we don't have it (yet) | What would close it |
|---|---|---|
| Silicon TOPS / TOPS-per-watt | TTSKY26b silicon has not returned | Post-bring-up power+throughput log under `boards/` |
| Silicon power at canonical workload | same | Same as above |
| Silicon WNS / measured Fmax | same | JTAG / scan-chain Fmax sweep on returned die |
| SKY130A synthesis WNS / TNS / DRC count / LVS for this branch | OpenLane2 run for `docs/improvement-package-2026-05-17` has not been recorded into the repo | Capture the run as `docs/SIGN_OFF_TTSKY26b.md` (tracked in [STATUS.md §5](STATUS.md)) |
| FPGA Fmax | The line cites "323 MHz on XC7A100T" in `info.yaml` and `CHANGELOG.md`; this branch has *not* re-verified it | Add an FPGA bitstream + post-route log under `boards/` or `sim/g1_loopback/` |
| MLPerf / MobileNet / ResNet style numbers | Out of scope for a SKY130A research die at this stage | Not planned for tape-out 0; meaningful at a later silicon revision on a production node |

---

## 4. README claims that must be read as `PROJECTED`

The current [README.md](README.md) cites three figures that **must** be
read under the `PROJECTED` tier — they are not measured on SKY130A silicon,
and they are not measured at all on the silicon Euler is targeting:

1. **"75 TOPS/W baseline, 405 TOPS/W with AVS-96 (5.4× boost)."** This is
   a projection at an advanced node (22 FDX-class) under stated power-
   gating / voltage-scaling assumptions. The SKY130A demonstrator does
   *not* run at that envelope. README §"Green AI Manifesto" already states
   "SKY130A = proof-of-concept; advanced node = competitive vs Hailo /
   Mythic" — this BENCHMARKS.md is the authoritative caveat: numbers in
   that table are `PROJECTED`, not `MEASURED`.
2. **"~20 TOPS ML capacity."** `PROJECTED` under SUPER-CROWN module-mix
   assumptions; not a silicon measurement.
3. **"<1 W TDP."** Target / `PROJECTED`. No post-silicon power table
   yet.

When TTSKY26b silicon returns, the corresponding rows here should be
upgraded from `PROJECTED` to `MEASURED` and the README updated to match.
Until then the README's competitive table should be read in the spirit of
[COMPETITORS.md §2](COMPETITORS.md) — the differentiation axis is open
RTL / open PDK / ternary / audit, **not** a TOPS race.

---

## 5. How to reproduce the SIMULATED row

From a clean checkout on Ubuntu 24.04:

```bash
sudo apt-get install -y iverilog
iverilog -I src -o /tmp/sim_dot8 \
    src/gf16_mul.v src/gf16_add.v src/gf16_dot4.v src/gf16_dot8.v \
    sim/tb_gf16_dot8.v
vvp /tmp/sim_dot8
# expected tail:
#   dot8 vectors : 16/16 PASS
#   TOTAL PASS=17  FAIL=0
#   ALL PASS
```

The top-level canonical test runs in CI via [`.github/workflows/test.yaml`](.github/workflows/test.yaml)
on every push and PR.

---

## 6. Adding a new benchmark

1. Decide the tier (`MEASURED` / `SIMULATED` / `SYNTHESIS-REPORTED` /
   `PROJECTED`).
2. Add a row to §2 with a path to the evidence (testbench file, CI run
   URL, log under `boards/`, OpenLane2 run ID — *something* a third party
   can re-run).
3. If the number is `PROJECTED`, state every assumption inline. No
   "single-number" projections.
4. Open a PR. A reviewer must check the evidence column points at
   something real before merging.

---

## 7. External anchors used elsewhere

- BitNet b1.58 (research anchor for the ternary numeric regime) — <https://arxiv.org/abs/2402.17764>
- Tiny Tapeout shuttle index (where the line's tape-outs live) — <https://tinytapeout.com/chips/>
- DARPA CLARA programme — <https://www.darpa.mil/research/programs/clara>
- Google Coral Edge TPU benchmarks (reference axis for "INT8 edge inference at known measured throughput") — <https://www.coral.ai/docs/edgetpu/benchmarks/>
