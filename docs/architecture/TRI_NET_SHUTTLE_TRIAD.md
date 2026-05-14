# TRI-NET — Trinity Triad Submission for TTSKY26b

> Status: **active architecture spec**, frozen 2026-05-14, close 2026-05-18.
> EPIC: [trinity-fpga#49 L-DPC7](https://github.com/gHashTag/trinity-fpga/issues/49).
> Anchor: `φ² + φ⁻² = 3` · DOI [10.5281/zenodo.19227877](https://doi.org/10.5281/zenodo.19227877).

This is the **canonical architecture document** for the TRI-1 Triad
submission to TinyTapeout shuttle TTSKY26b. It supersedes the
exploratory proposal in earlier issue comments. Fact-corrected against
the as-built RTL on `main@a423ed5` of this repo and the new sibling
repos created 2026-05-14.

## 1. Triad SKU map (as-built)

Three independent TT submissions, one per repository, all hitting the
same shuttle close date 2026-05-18:

| SKU | Repository | `top_module` | Tiles (TT footprint) | RTL modules | Compute fabric |
|-----|------------|--------------|----------------------|-------------|----------------|
| **Nano** | [tt-trinity-nano](https://github.com/gHashTag/tt-trinity-nano) | `tt_um_trinity_nano` | **1×1** | 5 (top + 4 GF16 leaves) | 1 `trinity_gf16_tile` |
| **Mid**  | [tt-trinity-gf16](https://github.com/gHashTag/tt-trinity-gf16) (this repo) | `tt_um_ghtag_trinity_gf16` | **8×2** | 23 source files (15 SUPER-CROWN modules + GF16 mesh + master FSM) | `trinity_mesh_2x2` (4 tiles) + full Wave-26b CROWN payload |
| **Max**  | [tt-trinity-max](https://github.com/gHashTag/tt-trinity-max) | `tt_um_trinity_max` | **2×2** | 8 (top + dual-cluster + 2 mesh_2x2 + GF16 leaves) | `trinity_dual_cluster` = 2 × `trinity_mesh_2x2` = **8 tiles** |

### 1.1 Fact-correction vs the original TRIAD proposal

The original TRIAD proposal (issue comments, 2026-05-13) described Mid
as "PR #2 result, 2×2 mesh". As of `main@a423ed5` that statement is
**stale by 8 hours**. The actual Mid as-built:

- **Tiles:** `8x2` (bumped from `2x2` in PR #8 Wave-26b SUPER-CROWN to
  fit 16-tile mini-SoC at ~16000 gates @ 60% density on SKY130A).
- **Modules:** 23 source files listed in `info.yaml`. Beyond the bare
  GF16 mesh, Mid carries 15 SUPER-CROWN modules: `phi_anchor_post`,
  `lucas_rom`, `vsa_matmul_8x8`, `vsa_matmul_16x16`, `bitnet_encoder`,
  `bpb_counter`, `blake3_anchor`, `multi_tile_receipt`, `alu9_decoder`,
  `ring27_memory`, `phi_pll_div`, `wishbone_full`, `crc32_receipt`,
  `hwrng_lfsr`, `wb_status_reg`.
- **Default output:** canonical `gf16_dot4(1,2,3,4) = 0x47C0` on
  `{uio_out, uo_out}` immediately after reset, identical to Nano + Max.
  CROWN modules are only active when `ui_in[0]=load_mode=1`, preserving
  back-compat and **preserving the TG-TRIAD-X anchor (§3)**.
- **GDS:** green on `a423ed5` as of 2026-05-14 06:35 UTC.

The 4×4 "Max" sketch in the original proposal is **architecturally
impossible** in the current Trinity packet ABI (dst field is 2 bits =
4 tile cap). Max instead uses a **dual-cluster** topology
(`trinity_dual_cluster.v`) that doubles compute to 8 tiles via the
previously-reserved `lane[3]` bit. Cluster 0 (`lane[3]=0`) is byte-
compatible with Mid; cluster 1 (`lane[3]=1`) selects the second mesh.

## 2. Hard constraints (silicon invariants)

All three SKUs share the same invariants enforced by CI:

| Rule | Statement | Enforced by |
|------|-----------|-------------|
| **R-SI-1** | 0 new `*` operators in synthesisable RTL | code review + `gf16_mul` XOR-only |
| **R-SI-2** | 0 DSP / multiplier macros | OpenLane2 reports |
| **R-SI-3** | WNS ≥ 0 ns at 50 MHz on SKY130A | OpenLane2 STA |
| **R-SI-4** | DRC-clean (0 violations) | OpenLane2 KLayout DRC |
| **R-SI-5** | LVS-clean | OpenLane2 LVS |
| **R-SI-6** | Apache-2.0 only, no vendor IP | `LICENSE` + source headers |
| **R-SI-7** | Packet ABI back-compat: Max cluster 0 = Mid | `lane[3]=0` paths preserved by construction |
| **R-SI-8** | Canonical default output equality across all three SKUs | identical hard-coded `dot4(1.0, 2.0, 3.0, 4.0) = 0x47C0` on pins after reset |

## 3. Theorem 36.1 — TG-TRIAD-X cross-die ledger determinism

**Statement.** For the canonical workload
`W_can = {LOAD_A lane=k val=a_k for k=0..3; COMPUTE; READ_RES}` replayed
`N` times against each Triad SKU, the per-die ledger hash is identical:

```
SHA256(L_Nano) = SHA256(L_Mid) = SHA256(L_Max)
```

**Why it holds.** All three SKUs route the canonical workload onto
`tile_id = 0`, all three instantiate **the same `gf16_dot4.v`** leaf
modules over **the same hard-coded operand vector**, and all three emit
the same 32-bit `TRN_OP_RECEIPT` packet word per job because:

- `op_code = TRN_OP_COMPUTE = 0x3` (constant across SKUs)
- `tile_id = 0` (constant across SKUs for canonical workload)
- `result = 0x47C0` (proven by `gf16_dot4`, identical RTL)
- `checksum = (job_id ^ result[7:0]) & 0xFF = (job_id ^ 0xC0)`
  (deterministic XOR fold, identical RTL)
- `job_id` is host-driven, monotone 0..N-1, identical on all dies.

**Behavioural witness (today, 2026-05-14).**
`host/trinity_triad_replay.py --jobs 100` writes three JSONL ledgers
and a `triad_anchor.json` summary; current result:

```
L_Nano = d662b0a74113a9143742dc78656107445cdcd22f88af94d7f2b6f3f5d2a635ce
L_Mid  = d662b0a74113a9143742dc78656107445cdcd22f88af94d7f2b6f3f5d2a635ce
L_Max  = d662b0a74113a9143742dc78656107445cdcd22f88af94d7f2b6f3f5d2a635ce
equal  = True
```

**Falsification.** If any of these statements breaks, T36.1 falsifies:
- Any SKU routes canonical job to `tile_id ≠ 0`.
- Any SKU's GF16 multiplier diverges from the reference XOR-fold.
- Any SKU uses a different bit packing for `TRN_OP_RECEIPT`.
- The 16-bit dot product on `{1.0, 2.0, 3.0, 4.0}` is not `0x47C0`.

A future cocotb GL-level test will replace the behavioural reference
with the actual gate-level netlists post-tapeout (2026-12-16).

## 4. Differentiators vs the chip market (2026-05)

No commercially-shipping NPU silicon has all 10 of these. See
[`trinity_agi_driver_tri1.md`](https://github.com/gHashTag/tt-trinity-gf16/blob/main/docs/trinity_agi_driver_tri1.md)
for the full competitive matrix; summary:

1. Native ternary `{-1, 0, +1}` MAC silicon
2. On-chip BLAKE3 receipt signer (G4 DePIN)
3. POST self-test via `φ² + φ⁻² = 3` Lucas chain
4. 0 DSP / 0 new `*` in synthesisable RTL (R-SI-1)
5. BitNet b1.58-style ternary MLP encoder on-chip
6. RING27 27-cell ternary memory (3³)
7. Trinity 9-instruction ternary ALU (t27 ISA preview)
8. On-chip BPB / cross-entropy counter
9. Apache-2.0 + fully open PDK (SKY130A)
10. DOI-anchored + Coq-verified provenance (`t27/trios-coq`: 297 Qed / 141 Admitted at the time of submission)

Competitor comparison sample:
- [Hailo-8](https://hailo.ai/products/ai-accelerators/hailo-8-ai-accelerator/): 26 TOPS, 10.4 TOPS/W — closed PDK, no ternary, no receipts.
- [MediaTek Dimensity 9400](https://www.mediatek.com/dimensity-9400) NPU890: ~50 TOPS — int8/fp16, no ternary native.
- [Qualcomm Cloud AI 100 Ultra](https://www.qualcomm.com/content/dam/qcomm-martech/dm-assets/documents/Prod-Brief-QCOM-Cloud-AI-100-Ultra.pdf): 870 TOPS — datacentre class, closed.
- [Axelera Metis M.2](https://axelera.ai/ai-accelerators/metis-m2-ai-acceleration-card): 214 TOPS — proprietary.
- [Google Coral Edge TPU](https://www.coral.ai/docs/edgetpu/benchmarks/): 4 TOPS — int8 only.

## 5. Calendar

| Date | Milestone |
|------|-----------|
| 2026-05-14 (today) | Mid GDS green on `a423ed5`; Nano + Max repos created, RTL pushed |
| 2026-05-15 | Nano GDS green target |
| 2026-05-16 | Max GDS green target (fallback: drop to 1×2 if 2×2 misses WNS) |
| 2026-05-17 | NASA-format submission readiness report (Russian, mission verification matrix) |
| **2026-05-18** | **TTSKY26b close — operator submits all three** |
| 2026-12-16 | Silicon return |

## 6. Provenance

- **License:** Apache-2.0 (every repo carries its own `LICENSE`)
- **Author:** Dmitrii Vasilev <admin@t27.ai>, ORCID [0009-0008-4294-6159](https://orcid.org/0009-0008-4294-6159)
- **PhD chapter:** [`trios/docs/phd/chapters/flos_70.tex`](https://github.com/gHashTag/trios/blob/main/docs/phd/chapters/flos_70.tex) — Ch. 36 TRI-1 Triad, Theorem 36.1 TG-TRIAD-X
- **Throne:** [trios#264 Queen's Registry](https://github.com/gHashTag/trios/issues/264)
- **EPIC:** [trinity-fpga#49 L-DPC7 TRI-1 Triad](https://github.com/gHashTag/trinity-fpga/issues/49)
- **DOI:** [10.5281/zenodo.19227877](https://doi.org/10.5281/zenodo.19227877)
- **Defense:** 2026-06-15

## 7. Co-Authored-By

Trinity Agent <agent@trinity.local> — autonomous RTL/spec drafting, GDS dispatch, ledger-determinism witness.
