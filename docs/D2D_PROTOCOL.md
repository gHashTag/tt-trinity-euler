# D2D Protocol — Holographic Chip-to-Chip Communication for TRI-NET

**Document ID:** TRINITY-D2D-V0.1-DRAFT
**Status:** DRAFT / SPEC-STUB — readiness label per row, see §1.3
**Last updated:** 2026-05-18
**Applies to:** TRI-1 Phi (1×1, #4914), TRI-1 Euler (8×2, #4915), TRI-1 Gamma (8×4, #4913)
**Companion docs:**
[`INTERCONNECT_PROTOCOL_V1.md`](INTERCONNECT_PROTOCOL_V1.md) (board-level 3-wire handshake, FROZEN at TTSKY26b),
[`CROSS_TILE_INTERCONNECT.md`](CROSS_TILE_INTERCONNECT.md) (DevKit board view)

---

## 1. Scope, purpose, and readiness honesty

### 1.1 Purpose

The Trinity Interconnect Protocol (TIP) v1.0 frozen at TTSKY26b
([`INTERCONNECT_PROTOCOL_V1.md`](INTERCONNECT_PROTOCOL_V1.md)) covers the
**board-level 3-wire handshake** (Wire A `LOAD_MODE`, Wire B `SYNC_STROBE`,
Wire C open-drain `ACK`) between Phi, Euler, and Gamma on the DevKit board.
TIP v1.0 does **not** describe what flows *across* die boundaries once the
handshake is up.

This document — the **D2D (Die-to-Die) Protocol** — is the spec stub for
that next layer. It describes how holographic packets (spike summaries, GF16
tags, audit-ring receipts) move from chip to chip, with **Euler as the
safety/control endpoint** that sits between the φ-anchor (Phi) and the
γ-surface (Gamma) for TRI-NET.

### 1.2 Why Euler is the safety/control endpoint

Per [LINEUP.md §6](../LINEUP.md), Euler is the only chip in the line that
carries the full safety story:

| Concern | Euler position | Evidence |
|---|---|---|
| 10/10 CLARA gaps as RTL | Yes | [`info.yaml`](../info.yaml) `source_files:` + [`CLARA_TRACEABILITY.md`](../CLARA_TRACEABILITY.md) |
| On-chip BLAKE3 RECEIPT signer | Yes | [`src/blake3_anchor.v`](../src/blake3_anchor.v) |
| Audit-ring proof-trace writer | Yes | [`src/audit_log_ring_buffer.v`](../src/audit_log_ring_buffer.v), [`src/proof_trace_writer.v`](../src/proof_trace_writer.v) |
| D2D 4-port N/E/S/W mesh router | Yes | [`src/d2d_holo_mesh.v`](../src/d2d_holo_mesh.v) |
| Explainability + red-team filter | Yes | [`src/explainability_unit.v`](../src/explainability_unit.v), [`src/redteam_filter.v`](../src/redteam_filter.v) |
| Restraint controller (control-engine) | Yes | [`src/restraint_ctrl.v`](../src/restraint_ctrl.v) |
| Multi-tile receipt aggregator | Yes | [`src/multi_tile_receipt.v`](../src/multi_tile_receipt.v) |

Phi (anchor) emits a POST identity proof; Gamma (surface) emits spike
activity; Euler is where both streams are reconciled, signed, and
audit-logged. That is the **e-engine** role — *evidence-engine* — and it is
why Euler is the natural D2D bridge endpoint.

### 1.3 Readiness ladder (per row in this document)

Every claim in this doc carries one of the labels below. The labels match
[STATUS.md §1](../STATUS.md). No claim in this document is `MEASURED`.

| Label | Meaning | Where it applies in this doc |
|---|---|---|
| `SPEC-FROZEN` | Frozen in markdown / RTL pin contract for TTSKY26b | Pin assignments inherited from TIP v1.0, `d2d_holo_mesh.v` interface |
| `SPEC-DRAFT` | Drafted here for the first time, not yet implemented | Holographic packet framing (§4), priority semantics (§5), error model (§6) |
| `RTL-STUB` | RTL exists as a pin-correct stub but is not a full mesh router | [`src/d2d_holo_mesh.v`](../src/d2d_holo_mesh.v) — pin-correct registered TX/RX, single SYNC strobe; explicitly self-describes as "R5-HONEST stub" |
| `PROJECTED` | Behaviour expected after the full mesh wave; not implemented | Multi-hop routing, congestion control, retransmit |
| `PLANNED` | Scoped for a future shuttle / wave; no RTL or sim yet | Inter-die ECC, mesh QoS, holographic broadcast modes |

> **Conservative reading:** the D2D substrate on TTSKY26b is a **pin-correct
> stub** with deterministic single-strobe behaviour, plus a board-level
> 3-wire handshake (FROZEN). The packet-layer protocol described below is
> `SPEC-DRAFT` and will be promoted row-by-row as RTL lands.

---

## 2. Topology — where Euler sits

```
            ┌──────────────────┐
            │  TRI-1 Phi       │  φ-anchor / POST gate / master
            │  1×1 — #4914     │
            └─────────┬────────┘
                      │ TIP v1.0 (board 3-wire)
                      ▼
            ┌──────────────────┐
            │  TRI-1 Euler     │  ◀── safety / control / D2D bridge
            │  8×2 — #4915     │  audit ring + BLAKE3 receipt
            └─────────┬────────┘
                      │ d2d_holo_mesh (uio[7:0], 4-port N/E/S/W stub)
                      ▼
            ┌──────────────────┐
            │  TRI-1 Gamma     │  γ-surface / 32-PE neuromorphic mesh
            │  8×4 — #4913     │
            └──────────────────┘
```

- **Phi → Euler:** board-level 3-wire TIP v1.0 (`SPEC-FROZEN`).
- **Euler → Gamma:** D2D mesh via `d2d_holo_mesh` (`RTL-STUB` for TTSKY26b;
  full mesh router is `PLANNED` for a future wave).
- **Euler ↔ Euler (next die over) and Euler ↔ Gamma (other faces):** all
  four N/E/S/W ports exist in the RTL stub but only `w_tx` (SYNC strobe)
  has dynamic protocol behaviour today; the other three TX directions are
  registered broadcasts of spike summary / GF16 tag (see
  [`src/d2d_holo_mesh.v`](../src/d2d_holo_mesh.v) header).

---

## 3. Pin contract (inherited / `SPEC-FROZEN`)

The pin assignments below are **already frozen** for TTSKY26b. They are
restated here so the D2D layer can be understood without cross-referencing
two other documents.

Source: [`src/d2d_holo_mesh.v`](../src/d2d_holo_mesh.v) header,
[`docs/PINOUT.md`](PINOUT.md), [`INTERCONNECT_PROTOCOL_V1.md`](INTERCONNECT_PROTOCOL_V1.md) §3.

| Pin | Direction | Function | Frozen at |
|---|---|---|---|
| `uio[0]` | out | `n_tx` — North TX | TTSKY26b |
| `uio[1]` | out | `e_tx` — East TX | TTSKY26b |
| `uio[2]` | out | `s_tx` — South TX | TTSKY26b |
| `uio[3]` | out | `w_tx` — West TX / SYNC strobe (LAYER-FROZEN gate per Thm 36.1 R18) | TTSKY26b |
| `uio[4]` | in | `n_rx` — North RX | TTSKY26b |
| `uio[5]` | in | `e_rx` — East RX | TTSKY26b |
| `uio[6]` | in | `s_rx` — South RX | TTSKY26b |
| `uio[7]` | in | `w_rx` — West RX | TTSKY26b |

`uio[3]` doubles as the cross-die SYNC strobe consumed by the TIP v1.0
handshake on the DevKit board — see
[`CROSS_TILE_INTERCONNECT.md`](CROSS_TILE_INTERCONNECT.md) §4.

---

## 4. Packet framing (`SPEC-DRAFT`)

> **Readiness:** `SPEC-DRAFT`. This section describes the framing the full
> mesh router will use. The current stub only emits the single-bit
> derivations described in
> [`src/d2d_holo_mesh.v`](../src/d2d_holo_mesh.v).

### 4.1 Symbol stream

Each TX direction carries a **1-bit serial symbol stream** clocked by `clk`,
gated by `ena`, and reset by `rst_n` (active-low). One symbol per cycle.

### 4.2 Frame layout (proposed)

| Field | Width | Notes |
|---|---|---|
| `SYNC` | 1 bit | High pulse on `w_tx` marks frame boundary (already implemented in stub) |
| `KIND` | 4 bits | Frame kind — see §4.3 |
| `EPOCH` | 8 bits | Monotonic frame epoch (wraps); pairs with the audit-ring epoch |
| `PAYLOAD` | variable | Per-kind payload — see §4.3 |
| `RECEIPT` | 32 bits | Truncated BLAKE3 receipt over (`KIND`, `EPOCH`, `PAYLOAD`) |

### 4.3 Frame kinds (`SPEC-DRAFT`)

| `KIND` | Name | Direction | Payload | Notes |
|---|---|---|---|---|
| `0x0` | `IDLE` | any | none | Sent when no other frame queued. Stub today: TX pins hold last registered bit |
| `0x1` | `SPIKE_SUMMARY` | E→W (Gamma→Euler) | 4 bits `spike_count` + 8 bits `spike_vec` | Already emitted by stub on `n_tx`/`e_tx` |
| `0x2` | `GF_TAG` | any | 4 bits `gf_tag` | Already emitted by stub on `s_tx` |
| `0x3` | `RECEIPT_BEACON` | Euler→any | 32 bits truncated BLAKE3 over current epoch | Backed by [`src/blake3_anchor.v`](../src/blake3_anchor.v) |
| `0x4` | `RESTRAINT_HOLD` | Euler→any | 1 bit `hold` + 7 bits reason code | Backed by [`src/restraint_ctrl.v`](../src/restraint_ctrl.v); when asserted, downstream chip MUST stop emitting non-`IDLE` frames |
| `0x5` | `AUDIT_FLUSH` | Euler→any | 8 bits ring-buffer pointer | Backed by [`src/audit_log_ring_buffer.v`](../src/audit_log_ring_buffer.v) |
| `0xE` | `LAYER_FROZEN` | Euler→Gamma | 1 bit | Asserts when the holographic attractor has converged. Today: implemented as gating of `w_tx` SYNC strobe by `layer_frozen` register (PhD Thm 36.1 R18) |
| `0xF` | `RESERVED` | — | — | Must be ignored by v0.1 receivers |

### 4.4 Conformance — minimal stub behaviour

A `SPEC-FROZEN` v0.1 D2D endpoint MUST:

1. Hold `w_tx = 0` when `rst_n = 0` or `ena = 0`.
2. Hold `w_tx = 0` whenever `layer_frozen = 1` (PhD Thm 36.1 R18). This is
   already implemented in [`src/d2d_holo_mesh.v`](../src/d2d_holo_mesh.v).
3. Register all RX inputs through at least one flop before downstream
   logic (CDC safety — TX from a neighbour die is asynchronous to local
   `clk`).
4. Emit a `SYNC` pulse on `w_tx` only when the local strobe condition
   holds (current stub: `spike_count == 4'h8`).

A `SPEC-DRAFT` v0.1 endpoint SHOULD additionally:

5. Frame `KIND ∈ {0x0..0xF}` on every byte boundary.
6. Honour `RESTRAINT_HOLD` from Euler within one local clock cycle.
7. Emit `RECEIPT_BEACON` once per audit-ring epoch (default: every 256
   cycles when `ena = 1`).

---

## 5. Euler's role as safety / control e-engine endpoint

> **Readiness:** the bridge role is `RTL-STUB` (pin-correct, with the
> safety control surfaces wired internally inside Euler); the protocol-level
> contract below is `SPEC-DRAFT`.

### 5.1 What "safety / control endpoint" means

In TRI-NET, Euler is the only die where every cross-die transaction is:

- **Audit-logged** in the on-chip ring buffer
  ([`src/audit_log_ring_buffer.v`](../src/audit_log_ring_buffer.v))
- **Receipt-signed** via BLAKE3
  ([`src/blake3_anchor.v`](../src/blake3_anchor.v))
- **Gated** by the restraint controller
  ([`src/restraint_ctrl.v`](../src/restraint_ctrl.v))
- **Cross-checked** against the φ-anchor POST
  ([`src/phi_anchor_post.v`](../src/phi_anchor_post.v))

This is the property that lets a third-party verifier (CLARA-style
evaluator) reconstruct a trace of every cross-die transaction from the
audit ring alone, without having to read internal RTL state.

### 5.2 Bridge between φ-anchor (Phi) and γ-surface (Gamma)

| Direction | Carried by | Carried what | Status |
|---|---|---|---|
| Phi → Euler | TIP v1.0 board 3-wire | POST `0x47C0` anchor, LOAD_MODE, SYNC_STROBE | `SPEC-FROZEN` |
| Euler → internal | core data path | φ-anchor result fed into [`src/phi_anchor_post.v`](../src/phi_anchor_post.v) gating downstream activity | `RTL` |
| Euler → Gamma | `d2d_holo_mesh` | SPIKE_SUMMARY / GF_TAG / SYNC strobe today; full kinds (`§4.3`) `PLANNED` | `RTL-STUB` |
| Gamma → Euler | `d2d_holo_mesh` RX | spike feedback (latched) | `RTL-STUB` |
| Euler → Phi | TIP v1.0 ACK on Wire C | open-drain ACK | `SPEC-FROZEN` |

The bridge invariant (Thm 36.1, R18 — `SPEC-FROZEN`): **no SYNC strobe
crosses to Gamma unless φ-anchor POST has succeeded AND restraint controller
is not holding.** In RTL today this is the conjunction of:

- `phi_anchor_post` having latched the canonical `0x47C0`, AND
- `layer_frozen = 0`, AND
- `restraint_ctrl` not asserting `hold` (per kind `0x4` above).

### 5.3 The "evidence engine" property

Every D2D frame that Euler emits SHOULD (`SPEC-DRAFT`) appear in the
on-chip audit ring within one epoch. This is what makes Euler an
*evidence engine* in the CLARA sense — not just a router, but a router that
leaves a third-party-readable trace of what it routed.

---

## 6. Error model (`SPEC-DRAFT`)

| Error | Detect | Local action | D2D action |
|---|---|---|---|
| RX symbol stuck | 256-cycle watchdog on each RX | log to audit ring | emit `RESTRAINT_HOLD` upstream |
| φ-anchor POST mismatch | `phi_anchor_post` flag | gate `w_tx` SYNC (already implemented) | no SYNC ever asserted ⇒ Gamma stays in canonical mode |
| BLAKE3 receipt mismatch | per-epoch compare | log to audit ring | emit `RESTRAINT_HOLD` to all faces |
| Restraint hold | `restraint_ctrl` asserts | clamp local compute | broadcast `RESTRAINT_HOLD` (`KIND=0x4`) for ≥1 cycle |

This table is `SPEC-DRAFT` — none of the cross-die error frames are emitted
by the current stub. The local actions, however, are implemented in the
referenced RTL.

---

## 7. Out of scope for v0.1

The following are explicitly *out of scope* for the v0.1 D2D protocol and
must be marked `PLANNED` whenever they appear in customer-facing material:

- Multi-hop routing across more than two dies.
- Congestion-aware QoS / arbitration.
- Inter-die ECC and FEC.
- Holographic broadcast modes beyond single-bit SYNC.
- Per-frame back-pressure beyond the binary `RESTRAINT_HOLD`.
- D2D-level encryption (the BLAKE3 receipt provides integrity, not
  confidentiality; out of scope intentionally — see
  [`docs/CLARA_PROOF_MANIFEST.md`](CLARA_PROOF_MANIFEST.md) on why
  confidentiality is a host-side concern).

---

## 8. Relationship to other documents

| Document | Role |
|---|---|
| [`INTERCONNECT_PROTOCOL_V1.md`](INTERCONNECT_PROTOCOL_V1.md) | Board-level 3-wire handshake, FROZEN at TTSKY26b. *Required reading.* |
| [`CROSS_TILE_INTERCONNECT.md`](CROSS_TILE_INTERCONNECT.md) | DevKit board view; role assignment; pin mux. |
| [`PINOUT.md`](PINOUT.md) | Authoritative pin assignments per chip. |
| [`STATUS.md`](../STATUS.md) | Readiness ladder for everything in this repo. |
| [`LINEUP.md`](../LINEUP.md) | Why Euler is the bridge / safety SKU in the line. |
| [`TRI_NET_API.md`](TRI_NET_API.md) | External-integration view of the D2D surface. |

---

## 9. Update policy

This file is a `SPEC-DRAFT` document. Promote a row from `SPEC-DRAFT` to
`SPEC-FROZEN` only when:

1. The RTL has been merged into `src/`, AND
2. A testbench under `sim/` exercises the framing, AND
3. The row in §4.3 or §6 has been cross-listed in
   [STATUS.md](../STATUS.md) §3 (Evidence table).

Until then, every claim that references this file in external material
MUST include the readiness label.
