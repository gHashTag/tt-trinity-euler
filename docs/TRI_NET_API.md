# TRI-NET API — External Integration Notes

**Document ID:** TRINITY-API-V0.1
**Status:** DRAFT — integration notes for downstream consumers
**Last updated:** 2026-05-18
**Scope:** how an external system (FPGA bridge, MCU, host driver, evaluator
tool) talks to TRI-1 Euler and, through Euler, to the TRI-NET line.
**Companion docs:** [`docs/API.md`](API.md) (per-module RTL surface — required
reading), [`docs/D2D_PROTOCOL.md`](D2D_PROTOCOL.md),
[`docs/INTERCONNECT_PROTOCOL_V1.md`](INTERCONNECT_PROTOCOL_V1.md)

---

## 1. Why this document exists

[`docs/API.md`](API.md) describes the **internal RTL surface** — every port,
every opcode, every status bit of the e-engine. That document is for
RTL-level integrators (people writing testbenches, attaching cocotb
suites, or porting the design).

This document is for the **other audience** — a partner who wants to wire
TRI-1 Euler into a larger system without reading the RTL. It collects the
external-facing handles: pinout, protocol entry points, host-side
interfaces, and what an integrator does and does not need to know.

> **Readiness:** all rows are labelled. Nothing here is `MEASURED`; the
> integration surfaces are `SPEC-FROZEN` at TTSKY26b, the host driver
> linkage is `SPEC-DRAFT`.

---

## 2. The three integration surfaces

External systems talk to TRI-1 Euler through exactly three surfaces:

| # | Surface | Layer | Status | Document |
|---|---|---|---|---|
| 1 | **TT pinout** (`ui_in[7:0]`, `uo_out[7:0]`, `uio_in[7:0]`, `uio_out[7:0]`) | pin-level | `SPEC-FROZEN` | [`docs/PINOUT.md`](PINOUT.md), [`docs/API.md`](API.md) |
| 2 | **TIP v1.0** — board 3-wire handshake (Wire A `LOAD_MODE`, Wire B `SYNC_STROBE`, Wire C `ACK`) | board-level | `SPEC-FROZEN` | [`docs/INTERCONNECT_PROTOCOL_V1.md`](INTERCONNECT_PROTOCOL_V1.md) |
| 3 | **D2D Holo packet layer** — what flows over `uio[7:0]` once handshake is up | packet-level | `RTL-STUB` + `SPEC-DRAFT` | [`docs/D2D_PROTOCOL.md`](D2D_PROTOCOL.md) |

Anything an external system observes about the chip MUST reduce to one of
these three surfaces. If a behaviour is not reachable from any of them, it
is not part of the external API.

---

## 3. Quickstart — talking to a single Euler die

### 3.1 Bring-up sequence (`SPEC-FROZEN`)

```
1. Assert rst_n = 0 for ≥ 8 clock cycles
2. Hold ui_in = 0 (canonical mode)
3. Release rst_n
4. After 1 clock, read {uio_out, uo_out} — must equal 0x47C0
5. If 0x47C0 → POST passed. Proceed to load mode if needed.
6. If not 0x47C0 → hold chip in reset; treat as a faulted slot.
```

The `0x47C0` invariant is the TG-TRIAD-X anchor — see
[`docs/CROSS_TILE_INTERCONNECT.md`](CROSS_TILE_INTERCONNECT.md) §2 for the
mathematics and [BENCHMARKS.md §2](../BENCHMARKS.md) for the simulation
evidence.

### 3.2 Load mode (`SPEC-FROZEN`)

To send compute payload:

1. Drive `ui_in[0] = 1` (load mode).
2. Drive `ui_in[6] = compute_strobe` per [`docs/API.md`](API.md).
3. Read result on `{uio_out, uo_out}` per the load-mode mapping in
   [`docs/API.md`](API.md).

### 3.3 Control surfaces — what's reachable

| Capability | Pin | Status | Reference |
|---|---|---|---|
| Canonical POST | `ui_in[0]=0` | `SPEC-FROZEN` | [`docs/API.md`](API.md) "Output Behavior" |
| Lucas ROM read | `ui_in[3:1]` | `SPEC-FROZEN` | [`docs/API.md`](API.md), [`src/lucas_rom.v`](../src/lucas_rom.v) |
| HWRNG enable | `ui_in[4]` | `RTL` | [`src/hwrng_lfsr.v`](../src/hwrng_lfsr.v) |
| Restraint mode (CLARA Gap-4) | `ui_in[5]` | `RTL` | [`src/restraint_ctrl.v`](../src/restraint_ctrl.v) |
| CROWN47 ROM | `ui_in[7]=1, ui_in[0]=0` | `RTL` | [`src/crown47_rom.v`](../src/crown47_rom.v) |
| D2D N/E/S/W | `uio[7:0]` | `RTL-STUB` | [`src/d2d_holo_mesh.v`](../src/d2d_holo_mesh.v), [`docs/D2D_PROTOCOL.md`](D2D_PROTOCOL.md) |

---

## 4. Connecting Euler into the TRI-NET line

### 4.1 Single chip on a Tiny Tapeout board

Bring-up uses §3.1 alone. The chip is functional with no other dies
attached as long as `uio[7:4]` inputs are tied off (RX idle).

### 4.2 Trinity Triad (Phi + Euler + Gamma) on DevKit

Full Triad bring-up is specified in
[`docs/CROSS_TILE_INTERCONNECT.md`](CROSS_TILE_INTERCONNECT.md). Summary
for integrators:

1. All three chips assert `0x47C0` post-reset (§3.1 per chip).
2. Phi drives `LOAD_MODE` and `SYNC_STROBE` via the DevKit IO mux to
   Euler and Gamma.
3. Euler and Gamma return `ACK` on the open-drain Wire C.
4. Once handshake is up, compute payloads flow Phi→Euler→Gamma per
   [`docs/INTERCONNECT_PROTOCOL_V1.md`](INTERCONNECT_PROTOCOL_V1.md).
5. D2D-level packets (spike summaries, GF tags, receipt beacons) flow
   per [`docs/D2D_PROTOCOL.md`](D2D_PROTOCOL.md).

### 4.3 Bridge boards (FPGA / MCU) — what to implement

The minimum a bridge board MUST implement to talk to Euler:

- 8 wires for `ui_in`, 8 wires for `uo_out`, 8 wires for `uio` (with
  direction control via `uio_oe`).
- 10 kΩ pull-up on Wire C if participating in the 3-wire handshake.
- 2-FF synchroniser on every input from Euler (CDC safety).
- Optional: replicate the BLAKE3 receipt path in software to verify the
  `RECEIPT_BEACON` frames described in
  [`docs/D2D_PROTOCOL.md`](D2D_PROTOCOL.md) §4.3.

A bridge that does **not** want to participate in the 3-wire handshake can
operate Euler as a standalone die using only §3 of this document.

---

## 5. Host-side integration

> **Readiness:** `SPEC-DRAFT`. There is no shipped host driver in this
> repo; this section describes what one would expose.

A canonical host driver should present three layers:

| Layer | Purpose | Backed by |
|---|---|---|
| `tip_link` | TIP v1.0 framing — open/close, send, receive, ack | [`docs/INTERCONNECT_PROTOCOL_V1.md`](INTERCONNECT_PROTOCOL_V1.md) |
| `d2d_packet` | D2D frame encode/decode (`KIND`, `EPOCH`, `PAYLOAD`, `RECEIPT`) | [`docs/D2D_PROTOCOL.md`](D2D_PROTOCOL.md) §4 |
| `evidence` | Audit-ring readback, BLAKE3 receipt verify, restraint state | [`src/audit_log_ring_buffer.v`](../src/audit_log_ring_buffer.v), [`src/blake3_anchor.v`](../src/blake3_anchor.v), [`src/restraint_ctrl.v`](../src/restraint_ctrl.v) |

Suggested host folder when a driver lands: `host/` (already exists in
this repo as a scaffold). Until a driver is shipped, integrators MUST
write directly against the pin-level surface in §3.

---

## 6. What integrators do NOT need to know

By design, the following internal details are *not* part of the API and
may change without notice:

- The internal microarchitecture of any e-engine module (compute fabric,
  CLARA gap implementations, internal FSM states).
- The internal layout of the 16-tile 8×2 mesh.
- Sub-module opcode wiring beyond what is exposed by `ui_in`.
- The internal AVS-96 / FBB / Purkinje thermal control loop (Triple-Deck
  internals — see [`docs/TRIPLE_DECK_STATUS.md`](TRIPLE_DECK_STATUS.md)).

A change to any of these is a non-breaking change as long as the three
surfaces in §2 remain conformant.

---

## 7. Versioning policy

| Version | Surfaces | Status |
|---|---|---|
| **v1.0 — TTSKY26b** | Pinout, TIP v1.0, D2D pin contract (§3 of [`D2D_PROTOCOL.md`](D2D_PROTOCOL.md)) | FROZEN |
| v1.1+ | D2D packet layer (§4 of [`D2D_PROTOCOL.md`](D2D_PROTOCOL.md)) | future — backward-compat negotiation per `INTERCONNECT_PROTOCOL_V1` §1.3 |

A v1.0 integrator (anything implementing §3 of this document and §3 of
[`INTERCONNECT_PROTOCOL_V1.md`](INTERCONNECT_PROTOCOL_V1.md)) MUST continue
to work against any future v1.x chip; the protocol is forward-compatible
via the version field already reserved in TIP v1.0.

---

## 8. Links

- RTL-level API surface: [`docs/API.md`](API.md)
- Pinout: [`docs/PINOUT.md`](PINOUT.md)
- Board / 3-wire protocol: [`docs/INTERCONNECT_PROTOCOL_V1.md`](INTERCONNECT_PROTOCOL_V1.md)
- D2D packet protocol (draft): [`docs/D2D_PROTOCOL.md`](D2D_PROTOCOL.md)
- Cross-tile board view: [`docs/CROSS_TILE_INTERCONNECT.md`](CROSS_TILE_INTERCONNECT.md)
- Readiness ladder: [STATUS.md](../STATUS.md)
- Sibling repositories: [LINEUP.md §2](../LINEUP.md)
