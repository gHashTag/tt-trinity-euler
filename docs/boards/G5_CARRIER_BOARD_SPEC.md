# G5 — Trinity DePIN Carrier Board (schematic spec)

> **Status:** Schematic specification only. Per `TRI-NET-G1` §12, custom PCB
> production is **HOLD until G1 + G2 logs**. G1 and G2 are now GREEN in
> simulation; this document is the input to the schematic review that must
> happen before any board is fabbed.

## 1. Bill-of-materials (target carrier)

| Function           | Reference         | Notes                                    |
|--------------------|-------------------|------------------------------------------|
| FPGA               | Xilinx XC7A100T-2FGG484C (Artix-7) | openXC7-friendly, fits Trinity 2x2 mesh + USB bridge + CDC FIFO |
| USB-3 bridge       | FTDI FT601Q       | 32-bit 245-sync FIFO, no vendor RTL on FPGA needed |
| Config flash       | Winbond W25Q64JV  | SPI x4, 64 Mbit, holds Artix-7 bitstream |
| Radio module (G3)  | Header for SX1262 LoRa **or** ESP32-C6 | not populated at G5; G3 spin will pick |
| Power input        | USB-C 5 V (USB-3 PD-capable) | feeds FT601 directly + on-board LDO chain |
| 3.3 V LDO          | TPS7A4533DKD      | 1.5 A, 5 V → 3.3 V, drives FPGA banks + flash |
| 1.0 V LDO (FPGA core)| TPS65086         | dual rail incl. 1.0 V VCCINT |
| 50 MHz XO          | SiT8208           | LVCMOS, primary FPGA clock |
| JTAG / SPI header  | 14-pin Xilinx     | for openOCD / Vivado HW Manager |
| User LEDs          | 4 × 0603 LEDs     | status bus from `top_usb3_loopback.led_status[3:0]` |
| Push-button reset  | TS-7-2.2          | feeds `sys_rst_n` (active low) |

**Forbidden BOM items (per TRI-NET-G1):**
- No on-board MCU/SBC (no Linux on the board).
- No vendor encrypted IP cores embedded in the FPGA flash payload.
- No PHY chip that would push USB-3 protocol decoding into FPGA fabric.
- No on-board crypto chip — all token settlement is off-chip in host SW
  until G4 verifier matures.

## 2. Pinout commitment

The FPGA-side pinout commits to the QMTECH-compatible map shipped in
`boards/qmtech_a100t/qmtech_a100t.xdc`. Any custom Trinity-branded
carrier board MUST place the FT601 32-bit data bus on the same FPGA
package balls as that XDC, or ship its own `*_trinity.xdc` that the
build picks up via `-c` flag.

## 3. Power topology

```
   USB-C 5V (≤ 1.5 A) ──┬──▶ FT601 VBUS pin
                        │
                        └──▶ TPS7A4533DKD ──┬──▶ 3.3V FPGA banks
                                            └──▶ 3.3V flash + LDO chain
                              │
                              └──▶ TPS65086 ──▶ 1.0V VCCINT
                                                1.8V VCCAUX
                                                1.5V VCCO_HP

   No power enters the FPGA via the on-die `ena` line — per
   TinyTapeout R-PIN-1, ena is a fabric-only signal.
```

## 4. Mechanical envelope (illustrative)

- Board outline: 60 × 80 mm, 4-layer PCB (signal/GND/PWR/signal).
- USB-C receptacle on one short edge; FT601 chip 5 mm from connector to
  keep diff-pair length ≤ 25 mm.
- Radio module header on opposite short edge so antenna is far from FPGA
  switching noise.
- FPGA centered between the FT601 and the radio header so the 32-bit
  FIFO bus and the SPI/UART radio bus both reach the FPGA in ≤ 30 mm
  of routing.

## 5. Schematic review GO criteria (G5 gate)

The G5 gate is GREEN when **every** item below has a written reviewer
sign-off:

| # | Item                                                     | Status |
|---|----------------------------------------------------------|--------|
| 1 | FPGA, FT601, flash, USB-C, LDOs all present              | spec   |
| 2 | FT601 32-bit DATA, RD#, WR#, OE#, RXF#, TXE# wired to    | spec   |
|   |   FPGA bank pins consistent with `qmtech_a100t.xdc`      |        |
| 3 | 50 MHz XO drives FPGA `sys_clk_50` on global clock pin   | spec   |
| 4 | Reset push-button connects to `sys_rst_n` via Schmitt    | spec   |
|   |   trigger and pull-up                                    |        |
| 5 | 4 status LEDs wired to `led_status[3:0]`                 | spec   |
| 6 | Power-up sequencing matches Artix-7 datasheet            | spec   |
| 7 | Radio module header (SX1262 OR ESP32-C6 footprint;       | spec   |
|   |   final pick deferred to G3 spin)                        |        |
| 8 | JTAG header polarity matches Vivado HW Manager           | spec   |
| 9 | No on-board MCU / Linux SBC                              | spec   |
|10 | No vendor encrypted IP in the bitstream                  | spec   |

The G5 gate **does NOT** authorize a board fab order. It only states
the schematic is internally consistent. Fab orders gated separately.

## 6. Forbidden actions for G5

- Do **not** fab a PCB until G1 + G2 logs are green AND a human reviewer
  signs off on this schematic spec.
- Do **not** add token economics into the BOM or layer stack.
- Do **not** replace the FT601 with a vendor PCIe complex.
- Do **not** add a soft-CPU to the FPGA build to "simplify" boot — the
  CPU-less master FSM stays.

## 7. Open items for the G3 spin

- Final radio choice (SX1262 vs ESP32-C6) — needs latency+throughput
  bench measurement.
- Whether to expose `ext_in_word` / `ext_out_word` via an FX2-style
  edge connector for easy module swap.
- Whether to pin the radio MCU's debug UART out a separate header for
  firmware iteration without reflowing the module.
