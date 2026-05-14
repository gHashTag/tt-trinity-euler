# TRI-1 v2: 6 LOW-complexity lanes (L-S22, L-S23, L-S24, L-S28, L-S32, L-S33)

**Parent EPIC:** [`gHashTag/trinity-fpga#52`](https://github.com/gHashTag/trinity-fpga/issues/52)
**Sibling EPIC:** [`gHashTag/trinity-fpga#51`](https://github.com/gHashTag/trinity-fpga/issues/51) (TRI-1 TOPS Boost)
**Anchor:** φ² + φ⁻² = 3
**DOI:** [10.5281/zenodo.19227877](https://doi.org/10.5281/zenodo.19227877)
**Simulation gate:** `sim/tri1_v2/Makefile` — expects `TRI1_V2_LANES_GREEN` (currently 30/30 PASS).

## Lanes in this PR

| Lane    | Module                       | Purpose                                                 | PhD anchor                                |
|---------|------------------------------|---------------------------------------------------------|-------------------------------------------|
| L-S22   | `plrm_counter.v`             | Period-Locked Runtime Monitor, mutual exclusion         | SCH-1 Qed · Lucas 29 / 47 periods         |
| L-S23   | `cassini_post.v`             | Cassini–Lucas identity POST checker (n=2..5)            | Lₙ·Lₙ₊₁ − Lₙ₋₁·Lₙ₊₂ = 5·(−1)ⁿ            |
| L-S24   | `nca_entropy_monitor.v`      | NCA 81-cell entropy-band popcount monitor               | INV-4 NcaEntropyBand Qed                  |
| L-S28   | `strobe_seed_guard.v`        | seed mod 34 ∈ [8,11] forbidden, replaces with sanitised | Strobe-aware RNG gate                     |
| L-S32   | `phi_distance_oracle.v`      | 360° φ-distance LUT (8-anchor linear interp, Q1.15)     | `PhiDistance.v` `phi_distance_nonneg`     |
| L-S33   | `bpb_lower_bound_guard.v`    | BPB ≥ 0 + Shannon floor                                 | THM-25-3 Qed (`bpb_non_negative`)         |

## Lanes deferred to follow-up PRs

| Lane    | Why deferred                                          |
|---------|-------------------------------------------------------|
| L-S25   | MED — needs cycle-accurate FSM + Coq schedule lemma   |
| L-S26   | Coq-blocked — `TheoremX.v` Admitted                   |
| L-S27   | MED — depends on L-S25 timing                         |
| L-S29   | HIGH — full Wishbone slave + 4 KiB SRAM model         |
| L-S30   | HIGH — needs RTL+Coq co-design for invariant ring     |
| L-S31   | Coq-blocked — Lucas interval lemma Admitted           |

These are tracked as child issues under EPIC `trinity-fpga#52`.

## Run the simulation gate

```bash
cd sim/tri1_v2 && make
# expects "TRI1_V2_LANES_GREEN: 30/30" in tri1_v2_lanes.log
```

## R-SI-1 (no new DSP) compliance

All multipliers in the 6 modules operate on small constants (≤8-bit × ≤8-bit),
which Yosys ABCs to LUT4/LUT6 without inferring SKY130 DSP cells. Confirmed by
inspection; runtime gate will be added when these modules are wired into the
top in a follow-up PR.

## License

Apache-2.0 — `LICENSE` at repo root.
