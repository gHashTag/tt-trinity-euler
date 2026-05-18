# CL-03: Minimal `host/` evidence reader (BLAKE3 receipt + audit-ring decoder)

**Local plan ID:** `#3`  (placeholder)
**Track:** CLARA alignment
**SIP row:** [`docs/SCIENTIFIC_IMPROVEMENT_PLAN.md`](../../docs/SCIENTIFIC_IMPROVEMENT_PLAN.md) §2 CL-03
**Label:** `target`

## Context

[`docs/TRI_NET_API.md`](../../docs/TRI_NET_API.md) §5 sketches an
`evidence` host layer that decodes the BLAKE3 receipt and the last `N`
audit-ring entries. It is `SPEC-DRAFT` today. The `host/` folder exists
as a scaffold.

## Scope

- A minimal CLI reader (language at implementer's discretion — Python
  preferred for parity with `t27` tooling).
- Reads a hex/binary stream representing the audit-ring tail and prints
  decoded fields: epoch, kind, payload, receipt.
- Verifies the BLAKE3 receipt against (kind, epoch, payload) per the
  framing in [`docs/D2D_PROTOCOL.md`](../../docs/D2D_PROTOCOL.md) §4.2.

## Out of scope

- USB / JTAG transport. Reader takes a file or stdin.
- Anything that touches `src/`.

## Acceptance criteria

- [ ] `host/evidence_read.<py|rs>` exists with a usage block.
- [ ] One golden input fixture under `host/fixtures/` plus a decoded
      golden output that the reader can reproduce.
- [ ] README in `host/` linking back to `TRI_NET_API.md` §5.

## Non-claims

- Does not ship a full driver.
- Does not assert measured silicon behaviour.
- Does not change any RTL.
