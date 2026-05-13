# Trinity GF16 — v0 RTL Mesh-Computer (TinyTapeout)

Bare-RTL **processorless** prototype of a GF16 dot4 mesh computer.
There is **no Linux, no soft-CPU, no AXI**. The host (board pins / future UART / USB-JTAG)
talks to the mesh through a small packet protocol; an on-die FSM walks the protocol so
that nothing on-chip needs an instruction stream.

This is **v0** of the Trinity Silicon roadmap (R-SI-* compliance, see `info.yaml`). It is
NOT a decentralised internet mesh — it is the **on-chip packet fabric foundation** that
future radio / Ethernet / mesh adapters will plug into.

## What's on the die

```
   ┌────────────────────────────────────────────────────┐
   │ tt_um_ghtag_trinity_gf16 (TT top)                  │
   │                                                    │
   │  ┌──────────────┐  32-bit pkt  ┌──────────────┐    │
   │  │ master_fsm   │─────────────▶│              │    │
   │  │ (no CPU)     │              │ router_2x2   │    │
   │  │ canned LOAD/ │◀─────────────│ (v0 xbar)    │    │
   │  │ COMPUTE/READ │              └─────┬────────┘    │
   │  └──────────────┘                    │             │
   │                                      ▼             │
   │         ┌───────────┬────────────┬────┴────┐       │
   │         ▼           ▼            ▼         ▼       │
   │     ┌───────┐   ┌───────┐    ┌───────┐  ┌───────┐  │
   │     │tile 0 │   │tile 1 │    │tile 2 │  │tile 3 │  │
   │     │gf16_  │   │gf16_  │    │gf16_  │  │gf16_  │  │
   │     │dot4   │   │dot4   │    │dot4   │  │dot4   │  │
   │     └───────┘   └───────┘    └───────┘  └───────┘  │
   │   uo_out / uio_out ◀── final_result                │
   └────────────────────────────────────────────────────┘
```

### Modules (synthesizable, Apache-2.0)
- `gf16_mul.v`, `gf16_add.v`, `gf16_dot4.v` — existing combinational GF16 demo
- `trinity_packet.vh` — 32-bit packet format constants (op, dst, src, lane, payload)
- `trinity_gf16_tile.v` — wraps `gf16_dot4` as a packet-addressable tile (LOAD_A / LOAD_B / COMPUTE / READ_RES → RESULT)
- `trinity_router_2x2.v` — single-hop crossbar with 4 tile ports + host port (round-robin return). Honest name: **minimal mesh fabric v0**, not a full XY-routed mesh yet
- `trinity_mesh_2x2.v` — 4 tiles + 1 router wired as the fabric
- `trinity_master_fsm.v` — CPU-less host FSM, canned `[1,2,3,4]·[1,2,3,4]` boot sequence
- `tt_um_ghtag_trinity_gf16.v` — TT top, preserves the legacy combinational output AND exposes the mesh result on the same pins after boot

### Packet format (32 bits)
```
[31:28] op       4'h1 LOAD_A | 4'h2 LOAD_B | 4'h3 COMPUTE | 4'h4 RESULT | 4'h5 READ_RES
[27:26] dst      flat tile id 0..3
[25:24] src      flat tile id of sender (host uses 0)
[23:20] lane     0..3 for operand lanes
[19:16] rsv
[15:0]  payload  GF16 operand or result
```

## TinyTapeout pinout
Unchanged from the previous submission (`info.yaml`). `ui_in[0]` doubles as
`load_mode` (reserved for future host operand override).

## Test
- **Legacy:** `dot4([1,2,3,4], [1,2,3,4]) = 30.0 = 0x47C0` — visible immediately on `{uio_out, uo_out}`.
- **Mesh:** the same value reached via the packet protocol after ~20 cycles. `tb.v` covers both paths.

```bash
cd test
make            # cocotb + iverilog
```

## R-SI compliance (silicon constraints)
- **R-SI-1** Zero NEW multipliers: no `*` introduced in new RTL. `gf16_mul.v:30` keeps its pre-existing 10×10 mantissa multiply (legacy, deliberately not touched in v0).
- **R-SI-2** Ternary/GF16 path preserved; the tile interface is operand-agnostic so a ternary matmul tile can drop in later by swapping `gf16_dot4` inside `trinity_gf16_tile.v`.
- **R-SI-4** 50 MHz clock, no PLL, synchronous design with async-low reset (`negedge rst_n`).
- Apache-2.0 only.

## Path to FPGA board flashing
This v0 keeps the existing TT pinout and synthesises stand-alone. To target a board now:
1. Wrap `tt_um_ghtag_trinity_gf16` in a board-specific top (clock, reset, LEDs) — e.g. QMTECH XC7A100T via openXC7: `clk` ← 50 MHz on-board oscillator, `rst_n` ← active-low button, expose `uo_out`/`uio_out` on LEDs/PMOD, `ui_in` on DIP switches.
2. Host I/O later: replace the canned master FSM with a UART / USB-UART RX→packet parser (RX byte stream → 32-bit packet) and TX driver (RESULT packet → bytes). FSM module stays; only the operand source changes.
3. Future Trinity CPU integration: replace `trinity_master_fsm.v` with the Trinity CPU's instruction-fetch unit and let it issue the same 32-bit packets directly.

## Trinity DePIN node — honest scope
The end-goal product is a small FPGA-centric node that runs ternary / GF16
compute jobs, emits deterministic receipts, and is paid in **TRI** tokens by
peers in a mesh — a Helium-style DePIN, but for compute. This repo is **step 0**
of that path: only the on-die packet fabric is real. USB-3 host I/O, external
radios, multi-hop mesh routing, and TRI settlement are *not* implemented yet.
The boundary contracts are documented in [docs/TRINITY_DEPIN_NODE.md](docs/TRINITY_DEPIN_NODE.md)
and exposed by two synthesizable boundary stubs:

- `src/trinity_usb3_fifo_bridge.v` — FT60x (FT600/FT601) synchronous-FIFO shim
  to the Trinity 32-bit packet handshake. Skeleton-only: real FT601 timing,
  byte-enables, and CDC are marked TODO. Not wired into the TT top (TinyTapeout
  has no FT60x pins).
- `src/trinity_mesh_adapter_stub.v` — pass-through boundary to an external
  radio / backhaul module (LoRa / ESP32 / etc.). No LoRa/Wi-Fi PHY in fabric.
  Not wired into the TT top.

Receipt-format constants for off-chip TRI settlement (`compute_job_id`,
`tile_id`, `op_code`, `result`, `nonce`, `checksum`) are reserved in
[`src/trinity_packet.vh`](src/trinity_packet.vh) — see the `TRN_RCPT_*`
block. Tiles do NOT emit receipts in v0; constants are committed so gate
G4 can light them up without renumbering.

## Roadmap — next gates

| Gate | Deliverable                                                           | Status      |
|------|-----------------------------------------------------------------------|-------------|
| G0   | On-die 32-bit packet fabric + 4 GF16 tiles + CPU-less FSM             | **done (PR #2)** |
| G1   | USB-3 FIFO loopback on dev FPGA + FT601 breakout                      | planned     |
| G2   | UART/USB packet parser (byte stream ↔ 32-bit Trinity packet)         | planned     |
| G3   | 2× node mesh demo over the external radio adapter                     | planned     |
| G4   | TRI receipt verifier (host SW + on-die receipt emission)              | planned     |
| G5   | Custom Trinity DePIN carrier board (FPGA + FT601 + radio)             | planned     |

Until G3 is demonstrated on real hardware, this project will NOT claim a full
external mesh implementation, and the term "ternary internet" stays a
design-doc concept, not a product claim.

## License
Apache-2.0
