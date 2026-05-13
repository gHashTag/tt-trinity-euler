# G3 — External Mesh Adapter Boundary (Trinity DePIN Node)

> **Status:** Spec + simulation contract. No physical radio fabric is built
> in this PR. Per `TRI-NET-G1` Rule 4, mesh radio is **off-chip** at G1/G2:
> the FPGA does not implement LoRa/Wi-Fi PHY. This document defines the
> deterministic boundary contract that any external transport — radio,
> Ethernet, or Wi-Fi — must satisfy before two physical Trinity nodes are
> declared "G3 GREEN".

## 1. Architectural placement

```
   Node A (FPGA)                    Node B (FPGA)
   ┌────────────────┐               ┌────────────────┐
   │ trinity_mesh_  │               │ trinity_mesh_  │
   │  adapter_stub  │               │  adapter_stub  │
   │ (this PR)      │               │ (this PR)      │
   └───────┬────────┘               └───────┬────────┘
           │ 32-bit Trinity                 │
           │ packets, ready/valid           │
           ▼                                ▼
   ┌────────────────┐    radio /    ┌────────────────┐
   │ Radio MCU /    │◀──Ethernet───▶│ Radio MCU /    │
   │ Wi-Fi SoC      │   /Wi-Fi/LoRa │ Wi-Fi SoC      │
   │ (off-die)      │               │ (off-die)      │
   └────────────────┘               └────────────────┘
```

The FPGA only sees `(ext_in_word, ext_in_valid, ext_in_ready)` and
`(ext_out_word, ext_out_valid, ext_out_ready)` in the `trinity_mesh_adapter_stub`
module. Everything else — frame CRC, retransmit, MAC, modulation, PHY — lives
in firmware on an external SoC (ESP32-C6, SX1262 + RP2040, etc.).

## 2. Hard rules

- **No LoRa/Wi-Fi PHY in FPGA fabric.** Forbidden. The FPGA is a packet
  endpoint; the radio is a separate IC.
- **No new multipliers in the adapter.** The shim is control-plane only:
  counters, FSM, ready/valid plumbing.
- **No Linux soft-CPU.** The on-die receiver/transmitter remains the same
  CPU-less master FSM + tile fabric.
- **No vendor encrypted IP** between the radio module and the FPGA pins.
  SPI/UART only; the firmware on the radio MCU is open.

## 3. Frame format on the external link

The external transport carries variable-length frames; each frame is one
*batch* of 32-bit Trinity packets:

```
   ┌───────────────┬───────────────┬───────────────┬───────────────┐
   │ MAGIC(2B)     │ LEN(2B, N pkts)│ NODE_ID(4B)  │ NONCE(4B)     │
   ├───────────────┴───────────────┴───────────────┴───────────────┤
   │ pkt[0]  (4B, little-endian)                                   │
   │ pkt[1]  (4B)                                                  │
   │   ...                                                         │
   │ pkt[N-1] (4B)                                                 │
   ├───────────────────────────────────────────────────────────────┤
   │ CRC32(MAGIC..pkt[N-1])                                        │
   └───────────────────────────────────────────────────────────────┘
```

- `MAGIC = 0xT3 0xT1` = `0x5433 0x5431` (ASCII 'T3T1').
- `LEN` ≤ 64 packets per frame. Larger jobs MUST be split across frames.
- `NODE_ID` is the 32-bit identifier of the *sender* node; used by the
  receiving node to address replies.
- `NONCE` is monotonically increasing per `(sender_node_id, dst_tile)` pair.
- `CRC32` is IEEE 802.3 polynomial 0x04C11DB7, init 0xFFFFFFFF, xor 0xFFFFFFFF.

The radio MCU enforces frame framing/CRC. The FPGA sees only the inner
`pkt[0..N-1]` words after the MCU has validated the frame.

## 4. Two-node packet exchange (G3 acceptance)

```
  Node A                                                  Node B
  ──────                                                  ──────
  1. host PC pushes 10-pkt canonical job (dst tile 0)
     into Node A's USB-3 bridge.

  2. Node A's master FSM is quiescent (host overrides);
     Trinity packets flow into router; tile 0 produces
     a RESULT packet.

  3. Instead of draining via USB, host re-routes RESULT
     packets to mesh_adapter_stub.ext_out_word, which
     the radio MCU encapsulates into a frame and ships
     to Node B.

  4. Radio MCU on Node B validates CRC, strips frame,
     and pushes each pkt[i] into Node B's
     mesh_adapter_stub.ext_in_word in order.

  5. Node B's router routes each packet by `dst`. The
     RESULT packet (op=4) addressed to Node B's "host"
     port (src=0 in the frame metadata) is delivered to
     Node B's USB-3 egress, where a PC verifies it.

  Acceptance: Node B's host receives a JSON receipt
  whose `observed` payload equals `0x47C0` AND whose
  `node` field is "node_a". 1000/1000 frames pass.
```

## 5. ext_in / ext_out signal table (mirrors `trinity_mesh_adapter_stub.v`)

| Direction          | Signal           | Width | Notes                                |
|--------------------|------------------|------:|--------------------------------------|
| Radio MCU → FPGA   | `ext_in_word`    | 32    | One Trinity packet per word          |
| Radio MCU → FPGA   | `ext_in_valid`   | 1     | High when word is valid              |
| FPGA → Radio MCU   | `ext_in_ready`   | 1     | High when adapter can accept now     |
| FPGA → Radio MCU   | `ext_out_word`   | 32    | One Trinity packet per word          |
| FPGA → Radio MCU   | `ext_out_valid`  | 1     | High when adapter has a word to send |
| Radio MCU → FPGA   | `ext_out_ready`  | 1     | High when MCU can accept now         |

The link between the FPGA and the radio MCU is typically a 4-wire SPI or
a UART at 1 Mbps. The MCU firmware serializes/deserializes 32-bit words
across that link; the FPGA only sees the parallel `ext_*` ports.

## 6. Forbidden actions for G3

- Do **not** claim "mesh internet" until two physical nodes have exchanged
  a job + RESULT receipt over a real external link.
- Do **not** introduce LoRa/Wi-Fi PHY into FPGA fabric.
- Do **not** add token settlement to the adapter — TRI accrual is G4 work.
- Do **not** wire `trinity_mesh_adapter_stub` into the TT die top.

## 7. Simulation contract (interim G3-sim gate)

Until physical hardware exists, the G3 boundary can be exercised in
simulation by chaining two instances of `top_usb3_loopback` and looping
`ext_out_word` of node A to `ext_in_word` of node B (skipping the radio
entirely). This is **not** G3 acceptance — it is only a smoke test that
the adapter's ready/valid contract composes correctly. Acceptance demands
two physical FPGA + radio nodes.

## 8. Open items deferred to G3 hardware

1. Choice of radio: SX1262 (LoRa, low-rate, long-range) **or** ESP32-C6
   (Wi-Fi/802.11ax + BLE, high-rate, short-range). Final pick blocked on
   bench measurement of latency vs throughput targets.
2. Frame-segmentation/reassembly for jobs > 64 packets.
3. Multi-hop XY routing across ≥ 3 nodes (G3 only validates 2-node).
4. Radio-firmware reference implementation (likely RP2040 + SX1262 board).
