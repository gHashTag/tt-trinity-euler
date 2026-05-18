# LINEUP — TRI-NET silicon line

**Last updated:** 2026-05-17
**Scope:** the four repositories that together form the TRI-NET open
high-assurance ternary AI silicon substrate.

This file gives the *line view* — what each repository is for, who its
intended user is, and how the four pieces compose. For "what is real today
inside this repo" see [STATUS.md](STATUS.md).

---

## 1. Positioning (one paragraph)

TRI-NET is an **open high-assurance ternary AI silicon substrate**. The
thesis is not "beat NVIDIA on raw TOPS" — the thesis is that a fully open
RTL + open PDK + ternary numeric format + on-chip audit / proof-trace path
is a more useful primitive for **safety-critical, formally-auditable, and
DARPA-aligned AI compute** than another closed INT8 NPU. The line is built
out of three sibling chips that share an ISA family and a numeric format
registry, plus one toolchain repo that authors them.

---

## 2. The four repositories

| Repo | Role | Sacred constant | Tile budget | Posture | Audience |
|---|---|---|---|---|---|
| [`tt-trinity-phi`](https://github.com/gHashTag/tt-trinity-phi) | **Anchor / proof-of-identity chip** | φ ≈ 1.61803 | 1×1 | Smallest, fastest to silicon; canary for the line | Anyone who wants to verify the Trinity identity `φ²+φ⁻²=3` runs on real silicon; CLARA Gap-4 (bounded rationality) demo |
| **`tt-trinity-euler`** (this repo) | **Balanced / DARPA-CLARA-facing SKU — e-engine** | e ≈ 2.71828 | 8×2 | **Main line SKU** — full SUPER-CROWN + 10 CLARA gaps + D2D mesh + on-chip BLAKE3 receipt + audit ring buffer | DARPA-CLARA-aligned evaluators, formal-methods researchers, anyone integrating an assurance-bearing AI accelerator |
| [`tt-trinity-gamma`](https://github.com/gHashTag/tt-trinity-gamma) | **Surface / 32-PE neuromorphic mesh** | γ ≈ 0.57721 | 8×4 | Larger compute surface, ternary PE mesh; explores throughput end of the line | ML researchers running ternary networks (BitNet-class) and JEPA-T workloads |
| [`t27`](https://github.com/gHashTag/t27) | **Spec → RTL toolchain + numeric format registry** | (none — it's the meta-layer) | n/a | The `.t27` source language, format conformance suite, and the generator that lowers it to per-chip RTL | Internal chip authors; anyone reproducing the line |

> **Repo evidence inside this checkout:** the sibling repo URLs are
> referenced in [README.md](README.md) (header) and in
> [`info.yaml`](info.yaml) under `project.description`. The "t27 toolchain"
> is referenced as the .t27 conformance contract in
> [`conformance/FORMAT-SPEC-001.json`](conformance/FORMAT-SPEC-001.json) and
> the `toolchain` assertion in [`assertions/toolchain.json`](assertions/toolchain.json).

---

## 3. Why three chips instead of one

The line is intentionally **stratified by tile budget** so that each chip
can answer a different question on its own and still compose.

| Question | Answered by | How |
|---|---|---|
| "Can a single 1×1 Tiny Tapeout tile carry the Trinity identity and act as a POST anchor for the whole line?" | **phi** | φ²+φ⁻²=3 verified at boot via Lucas chain on a 1×1 die |
| "Can a balanced SKU host the full safety story — 10 CLARA gaps, on-chip audit ring, BLAKE3 receipts, D2D mesh — and still tape out on SKY130A inside an 8×2 budget?" | **euler** (this repo) | 8×2 tiles, 18 SUPER-CROWN modules + 10 CLARA gaps; this is the SKU we put forward in DARPA-CLARA-style proposals |
| "Can the same ISA scale up into a wider ternary PE surface for throughput-oriented workloads?" | **gamma** | 8×4 tiles, 32 ternary PEs |
| "Can all three be authored from one spec, with a numeric format registry that round-trips?" | **t27** | `.t27` → RTL generator + conformance suite |

The three chips are **siblings, not a hierarchy**. Euler is the
*balanced* / *flagship-for-assurance* SKU because it carries the safety
story that defence and high-assurance customers ask about; the other two
are not "smaller / bigger Euler" but distinct points in the design space.

---

## 4. Shared substrate

What is genuinely common across the three chips (and therefore lives in
`t27`, not in any single chip repo):

- **Ternary {−1, 0, +1} numeric format** as the canonical compute domain.
- **R-SI-1**: zero new `*` operators in synthesisable RTL — enforced per
  chip (see [`.github/workflows/no_star.yaml`](.github/workflows/no_star.yaml) in this repo).
- **Trinity Interconnect Protocol v1.0** for cross-tile / cross-die packet
  framing — frozen in
  [`docs/INTERCONNECT_PROTOCOL_V1.md`](docs/INTERCONNECT_PROTOCOL_V1.md) at
  TTSKY26b.
- **CLARA gap taxonomy** (10 gaps, mapped to TA1 / TA1.1 / TA1.2 / TA1.4
  buckets — see [CLARA_TRACEABILITY.md](CLARA_TRACEABILITY.md) for euler's
  per-module mapping).
- **Numeric format registry** (`FORMAT-SPEC-001`) — see
  [`conformance/FORMAT-SPEC-001.json`](conformance/FORMAT-SPEC-001.json).
- **Sacred algebraic anchor** φ²+φ⁻²=3 (DOI
  [10.5281/zenodo.19227877](https://doi.org/10.5281/zenodo.19227877)) — the
  line-wide POST check.

---

## 5. What is **not** shared

- Tile counts, top-level module names, pinouts, and `info.yaml` are
  per-chip.
- Per-chip SUPER-CROWN module inventories diverge — euler has 18 SUPER-CROWN
  modules, phi has the minimal anchor set, gamma the wider PE mesh.
- Shuttle submissions are independent per chip.

---

## 6. Where Euler sits in the line — single line per concern

| Concern | Euler position |
|---|---|
| Smallest die in the line | No — that's `phi` (1×1) |
| Largest compute surface | No — that's `gamma` (8×4, 32 PE) |
| Most CLARA gaps in one die | **Yes — 10/10** |
| Most SUPER-CROWN modules in one die | **Yes — 18 (per [`info.yaml`](info.yaml))** |
| On-chip BLAKE3 RECEIPT signer | **Yes ([`src/blake3_anchor.v`](src/blake3_anchor.v))** |
| D2D 4-port holo mesh router | **Yes ([`src/d2d_holo_mesh.v`](src/d2d_holo_mesh.v))** |
| DARPA-CLARA-facing proposal target | **Yes** — see [`docs/TRI_NET_DARPA_CLARA_PROPOSAL.md`](docs/TRI_NET_DARPA_CLARA_PROPOSAL.md) |
| Spec-to-RTL authoring | No — that lives in `t27` |

---

## 7. Sibling links

- φ-anchor: <https://github.com/gHashTag/tt-trinity-phi>
- **e-engine (this repo):** <https://github.com/gHashTag/tt-trinity-euler>
- γ-surface: <https://github.com/gHashTag/tt-trinity-gamma>
- t27 toolchain: <https://github.com/gHashTag/t27>

External anchors:

- DOI: [10.5281/zenodo.19227877](https://doi.org/10.5281/zenodo.19227877)
- DARPA CLARA programme: <https://www.darpa.mil/research/programs/clara>
- Tiny Tapeout shuttle index: <https://tinytapeout.com/chips/>

---

## 8. Line-wide protocol / integration docs (new in 2026-05-18 lineup pass)

These docs describe how Euler participates in the line beyond the
TTSKY26b-frozen board-level handshake. Each carries readiness labels —
none of them weakens the existing [STATUS.md](STATUS.md) ladder.

- [`docs/D2D_PROTOCOL.md`](docs/D2D_PROTOCOL.md) — die-to-die packet
  layer above the frozen 3-wire (SPEC-DRAFT); Euler as safety/control
  bridge between Phi (φ-anchor) and Gamma (γ-surface).
- [`docs/GF16_BFLOAT16_NMSE.md`](docs/GF16_BFLOAT16_NMSE.md) — standard
  NMSE comparison protocol; reuses the existing
  `sim/tb_gf16_dot8.v` testbench; t27 is the upstream owner.
- [`docs/TRIPLE_DECK_STATUS.md`](docs/TRIPLE_DECK_STATUS.md) — RBB →
  FBB → CAP_BOOST (AVS-96) status on Euler + cross-chip conformance
  contract for Phi and Gamma to match.
- [`docs/TRI_NET_API.md`](docs/TRI_NET_API.md) — external-integration
  view of the e-engine surface.
- [`docs/WHITEPAPER_LINKS.md`](docs/WHITEPAPER_LINKS.md) — value-prop
  paragraph + link index for evaluators.
- [`docs/PROJECTIONS_22FDX.md`](docs/PROJECTIONS_22FDX.md) — 22FDX
  TOPS/W projection and Zenodo bundle readiness (labelled projections
  / plans only).
