# COMPETITORS — TRI-1 Euler

**Last updated:** 2026-05-17
**Posture:** TRI-NET is **not** trying to beat commercial NPUs on raw
TOPS or $/inference. The differentiation is **open RTL + open PDK +
native ternary numeric path + on-chip audit/proof-trace + line-wide
formal-assurance posture**. This file says what each commercial product
*is*, what we can verify from its own public material, and the *narrow*
axis on which Euler is actually different.

> **Tone rule.** No headline-grabbing ratio is quoted here unless we can
> point to a line in our own [BENCHMARKS.md](BENCHMARKS.md) (with its
> caveats) and a public vendor document. Marketing-style "10×" /
> "50×" / "100×" claims are explicitly out of scope.

---

## 1. The field as it actually exists

The chips below are the relevant **edge / embedded / data-centre-edge AI
accelerators** to compare against. None of them are a like-for-like
competitor to a Tiny Tapeout SKY130A research die — we list them because
they define the market category Euler positions *adjacent to*.

| Vendor / part | What it is | Form factor | Numeric | Open PDK | Open RTL | Posture vs Euler |
|---|---|---|---|---|---|---|
| **Qualcomm Cloud AI 100 Ultra** ([product brief PDF][qc-pdf]) | Data-centre / edge-cloud inference accelerator | PCIe / OCP card | INT8 / FP16 | No | No | Different category (data-centre TOPS race); shares ~no design assumptions with Euler |
| **Hailo-8** ([product page][hailo]) | Embedded/edge AI accelerator for video | M.2 / mini-PCIe / module | INT8 (structured-sparsity) | No | No | Closest commercial peer for "edge ML at low power"; closed silicon |
| **Axelera Metis** ([product page][axelera]) | Edge AI processing unit, in-memory compute | M.2 / PCIe | Mixed-signal in-memory + INT8 | No | No | Interesting architectural cousin (non-traditional MAC) but closed RTL/PDK |
| **Google Coral Edge TPU** ([benchmarks page][coral]) | USB / M.2 / dev-board edge accelerator | USB / M.2 / SoM | INT8 | No | No | Reference point for "edge inference at known measured throughput" |
| **MediaTek Dimensity NPU** (e.g. NPU 890 in Dimensity 9400+, [product page][mtk]) | Mobile-SoC integrated NPU | Inside smartphone SoC | INT8 / INT4 / mixed | No | No | Mobile-NPU category; not directly comparable to a standalone die |
| **Research baseline — BitNet b1.58** ([arXiv:2402.17764][bitnet]) | A *numerical regime*, not a chip — ternary LLM weights | — | Ternary {−1, 0, +1} | n/a | n/a | The literature anchor that motivates Euler's ternary path |

[qc-pdf]: https://www.qualcomm.com/content/dam/qcomm-martech/dm-assets/documents/Prod-Brief-QCOM-Cloud-AI-100-Ultra.pdf
[hailo]: https://hailo.ai/products/ai-accelerators/hailo-8-ai-accelerator/
[axelera]: https://axelera.ai/ai-accelerators/aipu/metis
[coral]: https://www.coral.ai/docs/edgetpu/benchmarks/
[mtk]: https://www.mediatek.com/products/smartphones/mediatek-dimensity-9400-plus
[bitnet]: https://arxiv.org/abs/2402.17764

---

## 2. What we will and will not claim

| We will claim | We will *not* claim |
|---|---|
| Euler is **open RTL** under Apache-2.0 — see [`LICENSE`](LICENSE). | "Euler outperforms <commercial NPU> at <X>" in TOPS, TOPS/W, or $/inference on real workloads — no such head-to-head measurement exists. |
| Euler is on **open PDK** (SKY130A) via Tiny Tapeout. | "Euler matches Hailo-8 / Coral / Metis throughput" — those chips ship measured numbers on production nodes; Euler is on a research-grade educational node. |
| Euler implements **native ternary {−1,0,+1} MAC** in synthesisable RTL — see [`src/bitnet_encoder.v`](src/bitnet_encoder.v), [`src/vsa_matmul_8x8.v`](src/vsa_matmul_8x8.v), [`src/vsa_matmul_16x16.v`](src/vsa_matmul_16x16.v). | "Commercial NPUs lack ternary" without qualifying — most of them *don't* expose a native ternary mode, but some implement INT2 or sparsity tricks that approximate part of the benefit. |
| Euler carries an **on-chip BLAKE3 receipt signer** — see [`src/blake3_anchor.v`](src/blake3_anchor.v) — and a 64-entry **audit ring buffer** — [`src/audit_log_ring_buffer.v`](src/audit_log_ring_buffer.v). | "No competitor has any audit primitive at all." Some have secure-boot / attestation IP; what we claim is that *open, inspectable*, ternary-aligned audit RTL is what Euler offers as a substrate. |
| Euler is structured around the **10 CLARA-style AI-safety gaps** — see [CLARA_TRACEABILITY.md](CLARA_TRACEABILITY.md). | A DARPA CLARA award, sub-award, or selection — see [STATUS.md §4](STATUS.md). |
| The line has a **reproducible `.t27` → RTL → shuttle path** via the `t27` toolchain repo (see [LINEUP.md](LINEUP.md)). | That the toolchain is feature-complete for arbitrary external IP. |

---

## 3. Where Euler is genuinely different — the narrow axis

Forget the TOPS race. The four axes on which TRI-NET / Euler differ from
*every* row in the table above:

1. **Open RTL** (Apache-2.0) you can read, fork, audit, and re-tape-out.
   Hailo-8 / Coral / Metis / QC AI 100 / MTK NPU are closed RTL.
2. **Open PDK** (SKY130A) via Tiny Tapeout. None of the commercial
   products ship on an open PDK.
3. **Native ternary numeric path** as a *first-class compute domain* — see
   [`src/bitnet_encoder.v`](src/bitnet_encoder.v), with the BitNet b1.58
   paper ([arXiv:2402.17764][bitnet]) as the research anchor. The
   commercial products quantise to INT8/INT4 but do not ship a ternary
   MAC at the silicon level.
4. **Formal-assurance + audit-receipt posture**: on-chip BLAKE3 receipt
   signer + 64-entry audit ring buffer + 10-gap CLARA structure with
   external `Qed`-closed lemmas (see [CLARA_TRACEABILITY.md](CLARA_TRACEABILITY.md)).
   Closed commercial accelerators may have *parts* of this story (e.g.
   secure boot), but they are not *open*, *inspectable*, *paper-traceable*
   assurance substrates.

Anything else (peak TOPS, sustained TOPS/W on real silicon, INT8
benchmarks against MLPerf) is **not** an axis on which a Tiny Tapeout
research die competes today.

---

## 4. Per-vendor restrained notes

### 4.1 Qualcomm Cloud AI 100 Ultra
Per the public product brief ([PDF][qc-pdf]) it targets large-scale
inference acceleration in a data-centre / edge-cloud envelope with INT8
performance in the high hundreds of TOPS at multi-tens-of-watts class
power. **Different category** — Euler is a sub-watt research die. Useful
to cite only as the upper bound of "data-centre-edge AI silicon today."

### 4.2 Hailo-8
Per the product page ([link][hailo]) it is a 26-TOPS class M.2/mini-PCIe
embedded NPU using a proprietary dataflow architecture and structured
sparsity, INT8. The most natural commercial peer for the *use case* Euler
research might land in long-term. Closed RTL, closed silicon, no open
PDK.

### 4.3 Axelera Metis
Per the product page ([link][axelera]) it is an edge AIPU using
in-memory compute and a proprietary numeric path. Architecturally
*interesting* (non-standard MAC) and worth tracking as a peer; closed
RTL and proprietary node.

### 4.4 Google Coral Edge TPU
Per the published benchmarks ([link][coral]) it is the canonical INT8
edge-TPU baseline for MobileNet/Inception-class workloads. Useful as a
*reference axis* for "what `INT8 edge inference at known measured
throughput` looks like." Not an open-RTL/open-PDK product.

### 4.5 MediaTek Dimensity NPU (e.g. NPU 890 in Dimensity 9400+)
Per the product page ([link][mtk]) it is an integrated mobile-SoC NPU
with mixed-precision support including aggressive INT4 paths. Different
category (mobile SoC, not standalone die). Worth citing only to point at
where the mobile market's INT4 trend is going — Euler goes one step
narrower, to native ternary.

### 4.6 BitNet b1.58 (research baseline, not a chip)
The 2024 paper ([arXiv:2402.17764][bitnet]) shows ternary {−1, 0, +1}
weights are competitive with full-precision baselines at LLM scale.
Euler exists, in part, to give *that* numeric regime a first-class silicon
host — see [`src/bitnet_encoder.v`](src/bitnet_encoder.v).

---

## 5. References (canonical sources for cited facts)

- DARPA CLARA programme — <https://www.darpa.mil/research/programs/clara>
- Qualcomm Cloud AI 100 Ultra (product brief PDF) — <https://www.qualcomm.com/content/dam/qcomm-martech/dm-assets/documents/Prod-Brief-QCOM-Cloud-AI-100-Ultra.pdf>
- Hailo-8 — <https://hailo.ai/products/ai-accelerators/hailo-8-ai-accelerator/>
- Axelera Metis — <https://axelera.ai/ai-accelerators/aipu/metis>
- Google Coral Edge TPU benchmarks — <https://www.coral.ai/docs/edgetpu/benchmarks/>
- MediaTek Dimensity 9400+ — <https://www.mediatek.com/products/smartphones/mediatek-dimensity-9400-plus>
- BitNet b1.58 — <https://arxiv.org/abs/2402.17764>
- Tiny Tapeout chips index — <https://tinytapeout.com/chips/>
