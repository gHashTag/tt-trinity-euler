# Trinity DePIN Node — Architecture (honest scope)

> Status: **design document**. PR #2 ships v0 of the on-chip packet fabric only.
> Nothing here promises a deployed Helium-style decentralized internet — this
> file describes the boundary modules and product-board path that future
> hardware revisions will need.

## 1. Vision (long-horizon, NOT yet built)

The end-state product is a **Trinity DePIN node**: a small FPGA-centric board
that (a) executes ternary / GF16 compute jobs received from peers, (b) emits
deterministic *compute receipts*, and (c) is paid in **TRI tokens** by the
clients whose jobs it ran. Many such nodes form a mesh — this is the "ternary
internet" idea, an analogue of Helium's IoT/MOBILE network but for
**ternary/GF16 compute** instead of LoRa coverage.

This vision spans years and multiple board spins. This repo is **step 0** of
that path.

## 2. What is actually in this repo today

```
   ┌────────────────────────────────────────────────────┐
   │   Trinity v0 (PR #2, on-chip only, processorless)  │
   │                                                    │
   │   master_fsm ── 32b pkt ──▶ router_2x2 ──▶ tile0..3│
   │       ▲                          │          (GF16  │
   │       └──────── result ◀─────────┘          dot4)  │
   │                                                    │
   │   No CPU. No Linux. No AXI. No vendor IP.          │
   │   No external I/O above TT pins.                   │
   └────────────────────────────────────────────────────┘
```

R-honest claims:
- **Yes**: on-die 32-bit packet fabric, 4 GF16 dot4 tiles, single-hop crossbar
  called "router_2x2", CPU-less canned-sequence host FSM.
- **No** (not yet): USB-3 link, external mesh radios, TRI token settlement,
  on-chip receipt cryptography, multi-hop XY routing, ternary matmul tile.

The rest of this file is the **boundary spec** for the modules that PR #2
introduces only as stubs (or documents-only), so the next gate of work is
unambiguous.

## 3. Layered architecture (target node)

```
   ┌────────────────────────────────────────────────────────────────┐
   │ Trinity DePIN node (target product board, future revision)     │
   │                                                                │
   │   ┌────────────┐  USB-3 FIFO   ┌──────────────────────────┐   │
   │   │ Host PC /  │◀────FT60x────▶│ trinity_usb3_fifo_bridge │   │
   │   │ phone app  │  (245-sync)   │  (this PR: stub)         │   │
   │   └────────────┘                └────────────┬─────────────┘   │
   │                                              │ 32-bit pkt     │
   │                                              ▼                │
   │   ┌────────────┐  external     ┌──────────────────────────┐   │
   │   │ Mesh radio │◀───SPI/UART──▶│ trinity_mesh_adapter_stub│   │
   │   │ /backhaul  │  (out of die) │  (this PR: stub)         │   │
   │   └────────────┘                └────────────┬─────────────┘   │
   │                                              │ 32-bit pkt     │
   │                ┌─────────────────────────────┴───┐            │
   │                ▼                                 ▼            │
   │        ┌───────────────┐                ┌────────────────┐    │
   │        │ master_fsm    │                │  router_2x2    │    │
   │        │  (CPU-less)   │◀──pkt──────────▶ + GF16 tiles   │    │
   │        └───────────────┘                └────────────────┘    │
   │                                                                │
   │   Receipt path (off-chip settlement; on-chip just emits        │
   │   deterministic RESULT packets w/ job_id + tile_id):           │
   │     tile → router → host bridge → host SW → TRI ledger         │
   └────────────────────────────────────────────────────────────────┘
```

Every external surface is a **32-bit Trinity packet** (see
`src/trinity_packet.vh`). All boundary modules therefore have the same
shape — `(pkt[31:0], valid, ready)` in both directions — and the existing
`router_2x2` can already be the on-die hub.

## 4. Boundary: USB-3 FIFO bridge

**Goal.** Bring host-PC operands and read host-PC results over USB-3 at
practical bandwidth without putting any vendor soft-IP or PCIe complex on
the FPGA.

**Chosen interface.** FTDI **FT600 / FT601** "FIFO" mode (the `245`-style
synchronous FIFO that the chip exposes after USB-3 enumeration). The FT60x
is an external IC; on the FPGA side it looks like a 16/32-bit synchronous
FIFO with `RXF#`, `TXE#`, `RD#`, `WR#`, `OE#`, `CLK` (and `DATA[31:0]`).
No vendor RTL is used; the FPGA just speaks the FIFO protocol.

**Shim contract.** The on-die boundary module
`src/trinity_usb3_fifo_bridge.v` exposes:

```
   ┌──── FT60x side ────┐         ┌──── Trinity side ────┐
   ── ft_clk         ──▶│         │── 32-bit host_in_pkt ──▶
   ── ft_data[31:0] ◀──▶│ bridge  │   host_in_valid       ──▶
   ── ft_rxf_n       ──▶│         │── host_in_ready       ◀──
   ── ft_txe_n       ──▶│         │
   ── ft_rd_n        ◀──│         │   host_out_pkt        ◀──
   ── ft_wr_n        ◀──│         │   host_out_valid      ◀──
   ── ft_oe_n        ◀──│         │── host_out_ready      ──▶
   └────────────────────┘         └──────────────────────┘
```

In v0 (this PR) the bridge is a **pass-through skeleton**: it accepts a
32-bit word per FIFO read and presents it as a Trinity packet; same in
reverse. Real FT601 timing (turn-around between RD/WR, OE# delays, the
`be[3:0]` byte-enables) is left as `TODO` comments — there is no point
synthesising a fully-timed bridge until the carrier board exists.

The shim must therefore **not** be wired into the TT top — TinyTapeout has
no FT60x lines. It compiles stand-alone and will be instantiated by a
future board-top wrapper (see §7).

## 5. Boundary: external mesh / backhaul adapter

**Goal.** Let a node forward Trinity packets to another Trinity node over a
*non-FPGA* radio (LoRa, ESP32 Wi-Fi, BLE-mesh, sub-GHz, whatever the
carrier board chooses). The radio sits **outside** the die; the FPGA only
sees a serial framed link to it.

**Why a stub, not a PHY.** A LoRa or Wi-Fi PHY in fabric is a multi-month
project of its own, requires vendor IP for the analog front-end, and is
flatly out of scope for a TinyTapeout submission. The honest split is:

1. FPGA only speaks the **packet API** (`pkt, valid, ready`) to a
   board-level radio module (LoRa SoC, ESP32-C6, etc.) via SPI or UART.
2. That external module turns Trinity packets into RF frames and back.
3. Multi-hop routing across the mesh is decided **outside** the die for
   now (host SW or radio firmware); the FPGA stays a leaf endpoint.

The boundary module is `src/trinity_mesh_adapter_stub.v`. It exposes the
same `(pkt, valid, ready)` shape as the USB bridge so the eventual board
top can fan both into the same on-die router.

## 6. Compute receipts (off-chip settlement, on-chip determinism)

The FPGA never holds TRI tokens. What it **does** do is emit a receipt
field next to every RESULT packet so a host-side verifier (or, later, a
zk-proof generator) can attribute work to this node.

Proposed receipt fields, carried alongside or following a `RESULT` packet:

| field           | width  | meaning                                            |
|-----------------|--------|----------------------------------------------------|
| `compute_job_id`| 16b    | host-assigned id of the job being settled          |
| `tile_id`       | 2b     | which on-die tile produced the result              |
| `op_code`       | 4b     | which op was executed (matches packet `op` field)  |
| `result`        | 16b    | the GF16 (or future ternary) scalar/vector word    |
| `nonce`         | 16b    | per-job freshness, supplied by host                |
| `checksum`      | 8b     | XOR-fold placeholder; real MAC is host-side in v0  |

These are placeholders defined in
`src/trinity_packet.vh` (see the `TRN_RCPT_*` section). They are **not**
yet emitted by the tiles in this PR; v0 still uses the single-word RESULT
packet. The constants are committed so the next gate (G4) can add receipt
emission without renumbering anything.

**Settlement** (TRI accrual / payment) happens *off-chip* in the host SW
ledger. The FPGA's contract is only: "for the same `(job_id, nonce,
operands)`, this node returns the same `(result, tile_id, op_code)`."
That determinism is what makes a future ZK or fraud-proof attestation
possible.

## 7. Product-board path (the next several gates)

The TT die in this repo is **never** the product board — it is the proof
the compute fabric works in silicon. The DePIN product board adds:

- FPGA (Lattice ECP5 or Xilinx XC7A class; openXC7-friendly).
- FTDI FT601 (USB-3 to FIFO).
- An external radio (TBD: LoRa SX1262 or ESP32-C6 over SPI).
- Power: USB-3 5 V + 3.3 V LDO; the FPGA carries no on-die regulators.
- A small MCU or no MCU at all — the FPGA's CPU-less `master_fsm` keeps
  the BoM minimal.

The five gates below define the order of work. They map 1:1 to the
README roadmap section.

| Gate | Deliverable                                                       | Status (TRI-NET-G1)        |
|------|-------------------------------------------------------------------|----------------------------|
| G0   | TT GDS green on `feat/trinity-mesh-v0`                            | placement-fix applied      |
| G1   | USB-3 FIFO loopback on a dev FPGA + FT601 breakout                | GREEN in sim (100/100)     |
| G2   | UART/USB packet parser (byte stream ↔ 32-bit Trinity packet)     | GREEN in sim (100/100)     |
| G3   | 2× node mesh demo over the radio adapter (point-to-point first)   | spec frozen; hardware HOLD |
| G4   | TRI receipt verifier (host SW + on-die receipt emission)          | GREEN (7/7 unit + 100/100) |
| G5   | Custom Trinity DePIN carrier board (FPGA + FT601 + radio)         | schematic spec frozen      |

### TRI-NET-G1 Pre-Registration

The boundary work for gates G1..G5 above was driven by mission **TRI-NET-G1**.
Pre-registered acceptance criteria, falsification rule, and evidence map are:

* **H1 primary hypothesis**: a CPU-less Trinity FPGA node can act as a packet-
  compute endpoint where (a) the PC sends a 32-bit Trinity job stream over
  USB-3 FIFO, (b) the FPGA routes it through the on-chip mesh to a GF16/ternary
  tile, and (c) returns a deterministic RESULT/RECEIPT packet without any
  Linux, soft CPU, AXI, or new hardware multiplier in the compute core.
* **Falsification witness**: H1 is FALSE if any G1 loopback fails to reproduce
  the canonical result `0x47C0`, or if the path requires Linux / soft CPU /
  AXI / new arithmetic multipliers inside the compute core.
* **Witness status (2026-05-13)**: NOT HIT. 100/100 deterministic loopbacks
  passed in `sim/g1_loopback/`. No Linux, no soft CPU, no AXI, no new
  multipliers were introduced in any synthesizable RTL touched by this PR
  (`grep -n '\*' src/trinity_*.v boards/qmtech_a100t/*.v` returns only
  pre-existing operators inside `gf16_mul.v` legacy substrate).

### Evidence artifacts

| Gate | Evidence file                                                    |
|------|------------------------------------------------------------------|
| G0   | `info.yaml` tiles `2x2`, `src/config.json` density 45            |
| G1   | `sim/g1_loopback/g1_loopback.log` — `G1_GATE_GREEN: 100/100`     |
| G2   | `host/g2_receipts.jsonl` — 100 receipts, all `status: pass`      |
| G3   | `docs/boards/G3_MESH_ADAPTER_SPEC.md` — boundary contract        |
| G4   | `tools/receipt_verifier/test_g4_verifier.py` — 7/7 PASS;         |
|      |   `host/g4_verified.jsonl` — 100/100 `verifier_status: verified` |
| G5   | `docs/boards/G5_CARRIER_BOARD_SPEC.md` — schematic checklist     |

### Reproduction commands

```bash
# G1 USB-3 loopback gate (Icarus Verilog)
cd sim/g1_loopback && make

# G2 host packet tool (sim backend; ftd3xx backend requires real FT601)
python3 host/trinity_packet_tool.py --backend sim --jobs 100 \
    --out host/g2_receipts.jsonl

# G4 verifier gate (unit + replay against G2 stream)
python3 tools/receipt_verifier/test_g4_verifier.py
python3 tools/receipt_verifier/tri_receipt_verifier.py \
    -i host/g2_receipts.jsonl -o host/g4_verified.jsonl
```

## 8. Hard constraints (recap, will not be violated)

- **No Linux**, no soft CPU, no AXI, no vendor PCIe/USB-3 hard-IP wrappers.
- **No new multipliers** introduced in this PR (R-SI-1). The boundary
  stubs are control-plane only — no arithmetic operators.
- **TT pinout unchanged** by anything in this PR; the new modules are not
  wired into the TT top, only into a hypothetical future board top.
- We will not claim a full external mesh implementation until G3 is
  demonstrated on real hardware.
