# GF16 vs bfloat16 — NMSE Standard Comparison Protocol

**Document ID:** TRINITY-NMSE-V0.1-DRAFT
**Status:** SPEC-DRAFT — comparison protocol; values to be reported per
[BENCHMARKS.md §1](../BENCHMARKS.md) tiers
**Last updated:** 2026-05-18
**Scope:** TRI-NET line — applies to TRI-1 Phi, Euler, Gamma; protocol owner
is the [`t27`](https://github.com/gHashTag/t27) toolchain repo
**Companion docs:** [BENCHMARKS.md](../BENCHMARKS.md), [STATUS.md](../STATUS.md),
[`conformance/FORMAT-SPEC-001.json`](../conformance/FORMAT-SPEC-001.json)

---

## 1. Why this document exists

When customers ask "is GF16 actually competitive with bfloat16?" — the only
honest answer is **a normalised-mean-squared-error (NMSE) comparison run on
the same workload, with the same vectors, on the chip RTL**. Today the
[`sim/tb_gf16_dot8.v`](../sim/tb_gf16_dot8.v) testbench proves the GF16
inner-product hardware matches its own structural golden model (17/17 PASS,
`TOTAL PASS=17 FAIL=0`). That is **correctness**, not **accuracy vs. another
format**.

This document specifies a **standard NMSE comparison protocol** so any
implementer (us, a reviewer, an external auditor) can produce a comparable
NMSE number for any TRI-NET chip without re-inventing methodology.

> **Honesty contract:** until this protocol is implemented and a run logged
> under `sim/` or `boards/`, every NMSE claim in customer-facing material
> MUST be labelled `SPEC-DRAFT` and MUST NOT quote a number.

---

## 2. Definitions

### 2.1 NMSE

For a target vector `y` (FP64 reference) and a candidate vector `ŷ`
(produced by the format under test):

```
                  sum_i (y_i - ŷ_i)^2
    NMSE(y, ŷ) = ─────────────────────
                       sum_i y_i^2
```

NMSE is dimensionless and lower is better. NMSE = 0 means bit-exact under
the FP64 reference; NMSE = 1 means the candidate output carries no useful
signal relative to the reference (RMS error equals RMS of target).

We report NMSE in dB:

```
    NMSE_dB = 10 · log10(NMSE)
```

### 2.2 The two formats under test

| Format | Bit width | Where defined | Hardware in this repo |
|---|---|---|---|
| **GF16** | 16-bit GF(2^16) dot-product element | [`conformance/FORMAT-SPEC-001.json`](../conformance/FORMAT-SPEC-001.json), [`src/gf16_*.v`](../src/) | [`src/gf16_mul.v`](../src/gf16_mul.v), [`src/gf16_add.v`](../src/gf16_add.v), [`src/gf16_dot4.v`](../src/gf16_dot4.v), [`src/gf16_dot8.v`](../src/gf16_dot8.v) |
| **bfloat16** | 16-bit Brain Float (8 exp / 7 mant) | [IEEE 754 + Google bfloat16](https://en.wikipedia.org/wiki/Bfloat16_floating-point_format) | Reference model only (software golden); **not** synthesised in this repo |

> **Note:** this repo does not ship a bfloat16 multiplier. The bfloat16 path
> is a *software reference* used to compute NMSE; the GF16 path is the
> *hardware under test* via the existing testbench infrastructure.

### 2.3 Workload

The standard workload is the inner-product micro-benchmark already
exercised by [`sim/tb_gf16_dot8.v`](../sim/tb_gf16_dot8.v):

- 16 randomised dot-8 vectors (`dot8_tv0..tv15`), and
- the canonical anchor vector dot4([1,2,3,4],[1,2,3,4]) → `0x47C0`.

Each row produces one NMSE sample per format. Reported NMSE is the mean
across the 16 randomised vectors. The canonical anchor is reported
separately because it is a single deterministic point, not a sample.

---

## 3. The protocol (`SPEC-DRAFT`)

### 3.1 Reference path

For each test vector `(a, b)` where `a` and `b` are length-N integer
vectors representing the GF16-encoded operand stream:

1. Decode `a`, `b` into FP64 via the GF16 element-to-real mapping defined in
   [`conformance/FORMAT-SPEC-001.json`](../conformance/FORMAT-SPEC-001.json).
2. Compute `y = sum(a_fp64 * b_fp64)` in FP64. This is the **reference**.

### 3.2 GF16 candidate path

3. Run `(a, b)` through `gf16_dot4` / `gf16_dot8` RTL via iverilog (already
   instrumented by [`sim/tb_gf16_dot8.v`](../sim/tb_gf16_dot8.v)).
4. Decode the 16-bit GF16 result back into FP64 via the same mapping.
5. Record as `ŷ_gf16`.

### 3.3 bfloat16 candidate path

6. Round `a_fp64`, `b_fp64` to bfloat16 (round-to-nearest-even, no
   subnormal trap — standard Google bfloat16 rounding).
7. Multiply pairwise in bfloat16 with FP32 accumulator (this is the
   standard "bfloat16 multiply, FP32 accumulate" path used by every
   bfloat16 NPU); round the final accumulator back to bfloat16.
8. Decode to FP64 and record as `ŷ_bf16`.

### 3.4 NMSE computation

For each format, compute `NMSE(y, ŷ_format)` over the 16 vectors. Report:

| Field | Required |
|---|---|
| `format` | `gf16` or `bf16` |
| `n_vectors` | 16 (matches `tb_gf16_dot8.v`) |
| `nmse_mean` | mean NMSE across the n_vectors |
| `nmse_p99` | 99th-percentile NMSE |
| `nmse_db_mean` | `10 * log10(nmse_mean)` |
| `canonical_anchor_exact` | `True` / `False` — did the format reproduce `0x47C0` bit-exact on the canonical vector? |
| `seed` | RNG seed used to generate the 16 vectors (must be the same as `tb_gf16_dot8.v`, see §5.2) |
| `tool_versions` | iverilog version, Python version |
| `chip` | `phi` / `euler` / `gamma` |
| `tier` | `SIMULATED` (today); `MEASURED` only after silicon |

### 3.5 Reporting block

Each run produces a single JSON record, suggested location:
`sim/nmse/{chip}_{date}.json`. Example skeleton:

```json
{
  "format": "gf16",
  "chip": "euler",
  "n_vectors": 16,
  "seed": 0xDEADBEEF,
  "nmse_mean": null,
  "nmse_p99": null,
  "nmse_db_mean": null,
  "canonical_anchor_exact": true,
  "tier": "SIMULATED",
  "tool_versions": { "iverilog": "12.0", "python": "3.11" }
}
```

Empty `null` fields mean "not yet computed under this protocol" — the
record is still meaningful because the schema is fixed.

---

## 4. What we can say today vs. after the harness lands

| Claim | Today | After harness |
|---|---|---|
| GF16 dot4 canonical = `0x47C0` is bit-exact under the reference mapping | **YES** — `SIMULATED`, see [BENCHMARKS.md §2](../BENCHMARKS.md) | unchanged |
| 16 randomised GF16 dot8 vectors match the structural golden model | **YES** — `SIMULATED`, see [BENCHMARKS.md §2](../BENCHMARKS.md) | unchanged |
| Mean NMSE of GF16 vs. FP64 reference | unknown | populated as `SIMULATED` |
| Mean NMSE of bfloat16 vs. FP64 reference | unknown | populated as `SIMULATED` |
| "GF16 beats / matches / is within X dB of bfloat16 on this workload" | **MUST NOT BE QUOTED** | populated as `SIMULATED`, quote-able with the `SIMULATED` qualifier |
| Same statement on silicon | unknown | promotes to `MEASURED` only after returned die has been exercised |

Until the harness lands, this document is the only place in the repo that
specifies *how* such a comparison would be made. Anyone quoting NMSE
numbers without pointing back here is using made-up numbers.

---

## 5. Implementation harness — recommended layout

> **Readiness:** `PLANNED`. The skeleton below is non-normative; an
> implementer is free to choose a different layout as long as the JSON
> record in §3.5 is preserved.

```
sim/nmse/
├── run_nmse.py          # generates vectors, drives iverilog, computes NMSE
├── gf16_mapping.py      # GF16 element → FP64 (matches FORMAT-SPEC-001)
├── bfloat16_ref.py      # FP64 → bfloat16 → FP64 round-trip helpers
└── results/             # per-chip per-date JSON records
```

### 5.1 Linking to the existing testbench

The harness MUST reuse [`sim/tb_gf16_dot8.v`](../sim/tb_gf16_dot8.v) as the
GF16 RTL driver — no reimplementation of the inner product in software.
This guarantees that the GF16 candidate path measures the chip's actual
hardware, not a paper model.

### 5.2 Vector source

The 16 randomised vectors used by `tb_gf16_dot8.v` are generated inside
the testbench. The harness MUST either:

- emit those same 16 vectors deterministically from the same seed, or
- snoop them via `$display` from the testbench and replay.

Either approach is acceptable as long as the JSON record names the seed.

### 5.3 Cross-chip applicability

The same protocol applies unchanged to TRI-1 Phi (1×1) and TRI-1 Gamma
(8×4). Each repo MUST cite this file rather than re-specify the
protocol, so all three chips publish NMSE the same way. The protocol
itself lives upstream in [`t27`](https://github.com/gHashTag/t27)
(format conformance — see
[`conformance/FORMAT-SPEC-001.json`](../conformance/FORMAT-SPEC-001.json)).

---

## 6. Honest disclosure block (required in any external NMSE quote)

When this document's protocol is used to produce a number, the number MUST
appear with the following caveat block in any customer-facing material:

> *NMSE comparison computed per
> [`docs/GF16_BFLOAT16_NMSE.md`](GF16_BFLOAT16_NMSE.md) on the
> `tb_gf16_dot8.v` inner-product workload (16 randomised vectors + 1
> canonical anchor). Tier: `SIMULATED` on SKY130A RTL. Not a MLPerf number.
> bfloat16 path is a software reference, not measured on a bfloat16 NPU.
> Numbers do not generalise to other workloads (transformer attention,
> convolution, etc.) without separate harness runs.*

This caveat is non-negotiable. It is the price of using the word "NMSE" in
TRI-NET material.

---

## 7. Links

- Existing testbench (golden source): [`sim/tb_gf16_dot8.v`](../sim/tb_gf16_dot8.v)
- Format spec (canonical GF16 mapping): [`conformance/FORMAT-SPEC-001.json`](../conformance/FORMAT-SPEC-001.json)
- t27 conformance toolchain: <https://github.com/gHashTag/t27>
- Repo benchmark policy: [BENCHMARKS.md](../BENCHMARKS.md)
- Readiness ladder: [STATUS.md](../STATUS.md)
- 2026 plan tracking the NMSE harness landing: [`docs/SCIENTIFIC_IMPROVEMENT_PLAN.md`](SCIENTIFIC_IMPROVEMENT_PLAN.md) §4 SN-01 + §5 PUB-02 (both `target`; **no `Δ_dB` number permitted in this repo until a `sim/nmse/euler_*.json` record exists**).
