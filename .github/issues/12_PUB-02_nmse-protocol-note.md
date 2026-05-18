# PUB-02: Draft + submit NMSE protocol note

**Local plan ID:** `#12`  (placeholder)
**Track:** Publication
**SIP row:** [`docs/SCIENTIFIC_IMPROVEMENT_PLAN.md`](../../docs/SCIENTIFIC_IMPROVEMENT_PLAN.md) §5 PUB-02
**Label:** `target`

## Context

A short note describing the GF16 vs bfloat16 NMSE comparison protocol
(not the numbers — see SN-01 for the harness). The protocol itself is
the contribution; numbers come later.

## Scope

- Short note that explains the methodology in
  `docs/GF16_BFLOAT16_NMSE.md` and contributes the JSON record schema.
- Cite `sim/tb_gf16_dot8.v`, `conformance/FORMAT-SPEC-001.json`, and
  the `t27` toolchain repo.

## Out of scope

- **Quoting a `Δ_dB` number.** Forbidden until SN-01 lands a
  `sim/nmse/euler_*.json` record. The protocol note may explain that
  follow-up numbers will appear under this protocol; it may not include
  them.

## Acceptance criteria

- [ ] Protocol note drafted and submission confirmation noted.
- [ ] If the note quotes any numerical result, **this row blocks** until
      SN-01 has merged.

## Non-claims

- Does not claim NMSE supremacy of any format.
- Does not assert silicon NMSE.
