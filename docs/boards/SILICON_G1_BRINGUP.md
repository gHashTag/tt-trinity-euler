# Silicon-G1 Bring-Up Procedure — QMTECH XC7A100T + FT601

**Lane:** L-DPC6 silicon-G1
**Parent:** [trinity-fpga#48](https://github.com/gHashTag/trinity-fpga/issues/48)
**EPIC:** [trinity-fpga#19](https://github.com/gHashTag/trinity-fpga/issues/19)
**Anchor:** `phi^2 + phi^-2 = 3`
**Status:** PRE-REGISTERED — bitstream/runner shipped, hardware run pending

This document is a **pre-registered** acceptance protocol. All gate
thresholds and refusal conditions are frozen BEFORE the first physical run,
so the silicon-G1 verdict cannot be moved post-hoc. R5-honest.

---

## 0. Hardware required

| Item | Spec | Qty |
|---|---|---|
| FPGA carrier | QMTECH Artix-7 core board, **XC7A100T-FGG484-2** | 1 |
| USB-3 daughter | FT601-based FMC/PMOD daughterboard (245 Synchronous FIFO mode, 32-bit) | 1 |
| JTAG cable | FTDI FT2232-based (default QMTECH JTAG) | 1 |
| USB-3 cable | USB 3.0 / 3.1 Type-A → Type-C (or whatever FT601 board exposes) | 1 |
| Bench power | 5 V / ≥1 A or USB-3 bus-powered if board supports | 1 |
| Host PC | Linux or macOS with `ftd3xx` Python driver | 1 |

## 1. Tool requirements (host PC)

```bash
# Build tools (one of these)
vivado -version                       # Vivado 2023.x or 2024.x preferred
# OR (if you only need to load an existing .bit / .bin):
openFPGALoader --Version              # >= 0.12

# Host runner deps
python3 --version                     # >= 3.9
pip install ftd3xx                    # https://pypi.org/project/ftd3xx/
```

If you are on macOS, the FTDI D3XX driver must be loaded; on Linux you
typically need to blacklist `ftdi_sio` for the FT601 USB IDs (0403:601f /
0403:601e) so D3XX can claim the device.

## 2. Bitstream build

```bash
cd boards/qmtech_a100t/build
make bit
```

Internally runs `vivado -mode batch -source build.tcl`. Expected output:

```
PASS R2: 0 DSP48 inferred (multiplier-free).
PASS timing: WNS=<positive> ns
==> build.tcl DONE - bitstream at out/trinity_usb3_loopback.bit
```

**Build-time pre-registered gates (FAIL = R5 RED):**

- **G-Build-1 — R2 multiplier-free:** `report_utilization` must show **0 DSP48** cells inferred. Build.tcl `exit 3` if violated.
- **G-Build-2 — Timing closure:** WNS ≥ 0 ns on the 50 MHz / 100 MHz domains. Build.tcl `exit 4` if violated.
- **G-Build-3 — DRC clean:** `report_drc` produces no `CRITICAL WARNING` rows.

Artefacts to commit to the silicon-G1 evidence dir:

- `out/trinity_usb3_loopback.bit`
- `out/timing_summary.rpt`
- `out/utilization.rpt`
- `out/drc.rpt`
- `out/vivado.log` (filtered to PASS/FAIL/CRIT lines)

## 3. Program FPGA RAM (volatile, fast iteration)

```bash
cd boards/qmtech_a100t/build
make program
```

Internally:

```bash
openFPGALoader -c ft2232 -b qmtech_artix7_100t out/trinity_usb3_loopback.bit
```

Expected stdout: `DONE` line and the DONE LED on the QMTECH board lights solid.

## 4. Connect FT601 daughterboard, power up

Order matters to avoid hot-plug confusion:

1. Power down the carrier (unplug 5 V or carrier USB).
2. Mate the FT601 daughterboard into its FMC/PMOD slot.
3. Plug the USB-3 cable from FT601 to the host PC.
4. Power up the carrier.
5. Verify on host:
   ```bash
   lsusb | grep 0403:601    # Linux  — expect "FTDI FT600/FT601"
   system_profiler SPUSBDataType | grep -A2 FT60   # macOS
   ```

If `lsusb` shows the device but the runner reports `REFUSAL: no FT60x
device detected`, you most likely have the wrong kernel driver attached
(`ftdi_sio`). Blacklist it or unbind manually.

## 5. Run the host acceptance runner

```bash
python3 host/silicon_g1_runner.py --jobs 100 \
    --out boards/qmtech_a100t/build/out/silicon_g1_receipts.jsonl
```

Expected stdout last line:

```
SILICON_G1_GATE_GREEN: 100/100 0x47C0 received from real FPGA
```

Expected exit code: **0**.

## 6. Pre-registered acceptance gates

| Gate | Test | Expected | Falsifies H1 if |
|---|---|---|---|
| **SG1-01** | DSP48 count from Vivado synth | `0` | any `*` operator infers DSP in new RTL |
| **SG1-02** | Setup timing slack (50 MHz / 100 MHz) | WNS ≥ 0 ns | timing closure fails |
| **SG1-03** | DRC | no CRITICAL_WARNING rows | route-level rule violated |
| **SG1-04** | Bitstream size sanity | 3 MB ≤ size ≤ 6 MB (XC7A100T) | gross size mismatch |
| **SG1-05** | FT601 enumeration | `lsusb` shows 0403:601f or 601e | board not detected |
| **SG1-06** | `silicon_g1_runner.py --jobs 100` | exit 0 + `100/100 0x47C0` line | any `observed ≠ 0x47C0` |
| **SG1-07** | Ledger byte sha256 | reproducible across reruns up to nonce/ts | non-deterministic compute |
| **SG1-08** | No Linux/CPU/AXI on chip | grep utilization.rpt for `MicroBlaze`, `AXI*`, `LMB*` → 0 hits | any soft-CPU/bus IP appears |

ANY of SG1-01..SG1-06 = ❌ FAIL ⇒ TRI-NET-G1 hypothesis (H1) marked
**FALSIFIED** for the silicon lane; lane returns to RTL/sim for repair.

## 7. After silicon-G1 GREEN — next lane

- **silicon-G3:** procure a second QMTECH+FT601 node. Run two host-PC
  shells (or the same PC with two FT601 boards), exchange one job + one
  receipt over the off-chip mesh adapter per `docs/boards/G3_MESH_ADAPTER_SPEC.md`,
  produce a 2-node ledger row.
- Only after **silicon-G3 GREEN** can the R6 "DePIN node — 2 physical nodes
  exchange" milestone be claimed. Until then, **no "Helium competitor"
  language anywhere.**

## 8. Reporting

The silicon-G1 run must produce a `TRI-NET-G1-RVR-002` NASA mission report
(`nasa-mission-report` skill) with:

- Document ID `TRI-NET-G1-RVR-002`
- Verification matrix populated from probes SG1-01..SG1-08
- As-flown configuration: Vivado version, board serial, FT601 serial, host
  OS, ledger sha256
- Anomaly log: any deviation between sim G1 and silicon G1 receipts

— END OF PRE-REGISTRATION —
