# NMSE Golden Vectors — GF16 vs bfloat16

**Scope:** these files are the **golden test-vector pack** that backs the
NMSE comparison protocol described in
[`docs/GF16_BFLOAT16_NMSE.md`](../../../docs/GF16_BFLOAT16_NMSE.md).

> **R5-Honesty contract.** Nothing in this directory is a measured silicon
> result. The vectors are deterministic seeds + distribution descriptors +
> a tolerance and a baseline statement. Any future `sim/nmse/*.json` run
> that quotes a number MUST be reproducible from these vectors and MUST
> NOT change the seed without bumping the file's `vector_set_id` and
> adding a row to the [Verification Claims Matrix](../../../docs/VERIFICATION_CLAIMS_MATRIX.md).

## Files

| File | Purpose |
|---|---|
| [`gf16_vs_bfloat16_v0.json`](gf16_vs_bfloat16_v0.json) | Primary golden vector pack — 16 randomised dot-8 inputs + 1 canonical anchor. |
| [`schema.json`](schema.json) | JSON-schema (informal) for the vector pack and for a future result record. |

## Determinism

The 16 randomised vectors are *seed-driven*, not literal coordinate dumps.
The contract is: "any harness that consumes `gf16_vs_bfloat16_v0.json`,
seeds the named PRNG with `seed_u32`, samples 16 length-8 vectors from
`distribution`, and runs them through both paths, MUST report identical
NMSE statistics down to the documented `tolerance`."

This keeps the vector file small (constant size, independent of N) while
remaining bit-reproducible for any conformant implementation.

## What is `null`

Result fields (`nmse_mean`, `nmse_p99`, `nmse_db_mean`) are `null` because
no run has been logged in this branch. They are populated by a
`sim/nmse/euler_*.json` record written by the harness in
[`docs/GF16_BFLOAT16_NMSE.md`](../../../docs/GF16_BFLOAT16_NMSE.md) §5 —
not here.

## What this is not

- Not a silicon measurement.
- Not a bfloat16 NPU measurement (the bfloat16 path is a software
  round-trip reference).
- Not a MLPerf number.
- Not a generalisation to non-inner-product workloads.
