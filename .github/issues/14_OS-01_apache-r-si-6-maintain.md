# OS-01: Maintain Apache-2.0 only + R-SI-6 grep guard

**Local plan ID:** `#14`  (placeholder)
**Track:** Open source
**SIP row:** [`docs/SCIENTIFIC_IMPROVEMENT_PLAN.md`](../../docs/SCIENTIFIC_IMPROVEMENT_PLAN.md) §6 OS-01
**Label:** `maintain`

## Context

[`LICENSE`](../../LICENSE) is Apache-2.0; R-SI-6 grep guard is in place
([STATUS.md §3](../../STATUS.md) LICENSE row).

## Scope

- Ongoing maintenance: no action unless a violation is detected.

## Acceptance criteria

- [ ] On each violation report, restore Apache-2.0 only state.

## Non-claims

- Does not change any license terms.
- Does not modify CI workflows.
