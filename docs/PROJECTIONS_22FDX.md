# 22FDX TOPS/W Projection and Zenodo Bundle Readiness

**Document ID:** TRINITY-PROJ-V0.1
**Status:** PROJECTIONS / PLANS ONLY — explicitly NOT measured numbers
**Last updated:** 2026-05-18
**Companion docs:** [BENCHMARKS.md](../BENCHMARKS.md), [STATUS.md](../STATUS.md),
[`docs/HARDWARE-IMPLEMENTATION.md`](HARDWARE-IMPLEMENTATION.md)

> **READ THIS FIRST.** Every quantitative number in this document is a
> `PROJECTED` figure per [BENCHMARKS.md §1](../BENCHMARKS.md). None of them
> is silicon-measured. None of them is even SKY130A-synthesis-reported. They
> are extrapolations from RTL module counts and published advanced-node
> physics, under stated assumptions. **Anyone quoting these numbers in
> customer-facing material without the `PROJECTED` qualifier is using them
> incorrectly.** This is the same rule as BENCHMARKS.md §4.

---

## 1. 22FDX TOPS/W projection

### 1.1 What "22FDX" means here

GlobalFoundries 22FDX is a 22 nm FD-SOI process node. It is the
advanced-node target used line-wide when TRI-NET material says "competitive
vs. Hailo / Mythic." TRI-1 Euler is **not** taped out on 22FDX. The
TTSKY26b shuttle uses SKY130A (130 nm). 22FDX is the node we *project to*
for the competitive-axis numbers.

### 1.2 Projection table

Source assumptions for every row are stated inline. No row stands without
its assumption clause.

| Quantity | Value | Assumption clause | Source |
|---|---|---|---|
| Baseline TOPS/W | **75** | 22FDX @ 400 MHz, GF16 element format, SUPER-CROWN module mix per [`info.yaml`](../info.yaml), AVS-96 island count 96, no FBB | [`docs/HARDWARE-IMPLEMENTATION.md`](HARDWARE-IMPLEMENTATION.md) §2.1 (per-format baseline TOPS/W column) |
| Boosted TOPS/W (AVS-96 active) | **405** | Same as baseline + AVS-96 lifts active islands to 1.05 V; sustained burst window (not steady-state) | [`docs/HARDWARE-IMPLEMENTATION.md`](HARDWARE-IMPLEMENTATION.md) §2.1 (TOPS/W MAX column for GF16: 297; 405 figure used in README requires the additional Purkinje-gated FBB credit — see row below) |
| AVS-96 boost factor | **5.4×** | Ratio of boosted / baseline above | derived |
| Steady-state ML capacity | **~20 TOPS** | 22FDX, 16-tile 8×2, GF16 inner-product per tile, SUPER-CROWN mix | README "Green AI Manifesto" |
| TDP envelope | **<1 W** | 22FDX, Triple-Deck active (RBB idle / FBB active / CAP_BOOST burst), workload-mix per assumption above | README "Green AI Manifesto" |

### 1.3 Honest disclosure (required when citing these numbers)

> *All numbers above are `PROJECTED` on a 22 FDX-class node under stated
> SUPER-CROWN module-mix and Triple-Deck (RBB / FBB / AVS-96) assumptions.
> The SKY130A demonstrator does not run at this envelope. No silicon
> TOPS/W has been measured for TRI-1 Euler. See [BENCHMARKS.md §4](../BENCHMARKS.md)
> for the authoritative caveat language and [`docs/TRIPLE_DECK_STATUS.md`](TRIPLE_DECK_STATUS.md)
> for the per-deck implementation status.*

The 405-figure-vs-297-figure tension in §1.2 is itself a known item: the
HARDWARE-IMPLEMENTATION.md table reports 297 for AVS-96 alone; the
"5.4×→405" figure in the README requires that AVS-96 burst stack with a
Purkinje-gated FBB credit. That stacking is a projection. We call it out
here so it doesn't get smoothed over in slides.

### 1.4 What would close each projection

| Number | What closes it from `PROJECTED` to `MEASURED` |
|---|---|
| 75 TOPS/W baseline | A 22FDX tape-out + bring-up with a canonical workload power log |
| 405 TOPS/W boosted | Same tape-out + per-deck transition measurement under burst |
| ~20 TOPS | Same tape-out + throughput counter readback under sustained workload |
| <1 W TDP | Same tape-out + integrated power rail measurement |

None of these are part of the TTSKY26b deliverable. They are line-roadmap
items.

---

## 2. Triple-Deck mapping (cross-link)

The projection above assumes all three decks (RBB, FBB, CAP_BOOST / AVS-96)
are active. The actual readiness of each deck on Euler today is in
[`docs/TRIPLE_DECK_STATUS.md`](TRIPLE_DECK_STATUS.md). Highlights:

- **Deck 1 (RBB):** `SPEC` only — no dedicated RTL module on Euler in this
  branch. The leakage-reduction objective at idle is partially covered by
  `drowsy_ret.v` + `subth_clk.v`.
- **Deck 2 (FBB):** `RTL` — [`src/fbb_active_path.v`](../src/fbb_active_path.v).
- **Deck 3 (CAP_BOOST / AVS-96):** `RTL` — [`src/avs_controller_96.v`](../src/avs_controller_96.v).

A TOPS/W projection that assumes a fully-active Deck 1 should therefore be
read with extra caution until `rbb_*.v` lands.

---

## 3. Zenodo bundle readiness (`PLANNED`)

### 3.1 Current state

| Item | Status |
|---|---|
| Trinity Stack provenance DOI (line-wide) | **Published:** [10.5281/zenodo.19227877](https://doi.org/10.5281/zenodo.19227877) |
| TTSKY26b shuttle submission | **Submitted** (2026-05-17, per [`CHANGELOG.md`](../CHANGELOG.md)) |
| Per-shuttle Zenodo bundle for TTSKY26b | **`PLANNED` — not yet uploaded** |
| Coq/Rocq proof tarball as a Zenodo asset | **`PLANNED`** |
| Conformance vector pack as a Zenodo asset | **`PLANNED`** |

### 3.2 What the next bundle should contain

When the TTSKY26b bundle is uploaded, it should include (suggested
manifest):

1. The final `info.yaml` for the shuttle submission.
2. A frozen `src/` tree tarball at the submission commit.
3. The OpenLane2 GDS run logs (WNS, TNS, DRC count, LVS result) — gated by
   the `docs/SIGN_OFF_TTSKY26b.md` item on the [STATUS.md §5](../STATUS.md)
   checklist.
4. The `sim/tb_gf16_dot8.v` log with `TOTAL PASS=17  FAIL=0`.
5. The R-SI-1 `no_star.yaml` audit log for the submission commit.
6. A pointer to this `PROJECTIONS_22FDX.md` so anyone downloading the
   bundle sees the caveat block.

### 3.3 What the bundle MUST NOT contain

- Any quoted silicon TOPS/W number that is not in the `MEASURED` tier.
- Any "DARPA-CLARA award / contract" implication — alignment only, per
  [STATUS.md §4](../STATUS.md).
- Any FPGA Fmax claim that is not backed by a re-attached log under
  `boards/` (the "323 MHz on XC7A100T" line is currently
  `unverified-in-this-branch` per [BENCHMARKS.md §3](../BENCHMARKS.md)).

### 3.4 Upload checklist (for whoever cuts the next Zenodo version)

- [ ] Bump the Zenodo DOI sub-version for the new bundle.
- [ ] Cross-link the new DOI from [`docs/WHITEPAPER_LINKS.md`](WHITEPAPER_LINKS.md) §3.1.
- [ ] Add a row to [`CHANGELOG.md`](../CHANGELOG.md) under
      `[Unreleased] / Added` with the DOI URL.
- [ ] Confirm the bundle manifest matches §3.2 above.
- [ ] Confirm no item from §3.3 is present.

---

## 4. Links

- TOPS/W table source: [`docs/HARDWARE-IMPLEMENTATION.md`](HARDWARE-IMPLEMENTATION.md) §2
- Authoritative benchmark policy: [BENCHMARKS.md](../BENCHMARKS.md)
- Readiness ladder: [STATUS.md](../STATUS.md)
- Triple-Deck readiness: [`docs/TRIPLE_DECK_STATUS.md`](TRIPLE_DECK_STATUS.md)
- Whitepaper / publication index: [`docs/WHITEPAPER_LINKS.md`](WHITEPAPER_LINKS.md)
- Zenodo line-wide DOI: <https://doi.org/10.5281/zenodo.19227877>
