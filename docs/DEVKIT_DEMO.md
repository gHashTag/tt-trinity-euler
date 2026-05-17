# DevKit Demo — Euler (8×2 E-Engine Inference Chip, SKY 26b)

This document describes the firmware demo plan for the Tiny Tapeout DevKit loaded with the **Euler** chip — an 8×2 tile e-engine inference accelerator.

---

## 1. Quick Bring-up

After flashing the RP2040 firmware onto the DevKit and applying power:

- After reset, the **7-segment display** shows `0x47C0` — the canonical POST signature confirming all 16 inference tiles are live and clocked at 50 MHz.
- When `load_mode=1` is asserted (via UART command or GPIO), the Euler engine reads a token prompt from **UART RX** and begins inference, streaming output tokens back on **UART TX**.
- UART console (115200 8N1) prints on reset:

```
[EULER] POST OK  tiles=8x2(16)  f=50MHz  load_mode=0
```

When `load_mode=1` is triggered:

```
[EULER] load_mode=1  ready for token input
```

---

## 2. Demo Sequence

### 2.1 Connect via USB

```bash
# macOS / Linux
screen /dev/tty.usbmodem* 115200
# or
minicom -D /dev/ttyACM0 -b 115200
```

Windows: use PuTTY → Serial → `COM<N>` → 115200.

### 2.2 Run the inference demo

```bash
tt-demo euler --inference "hello"
```

**Expected output:**

```
[EULER] Running inference demo...
  tiles     : 8x2 (16 total)
  clock_MHz : 50
  load_mode : 1
  input     : "hello"
  throughput: 63 tok/s/W @ 80 mW

[EULER] Inference output:
  hello → [token_0] [token_1] [token_2] ...
[EULER] DONE  latency=<40ms
```

The 7-segment display cycles through token IDs as they are emitted.

### 2.3 Expected outputs summary

| Test                              | 7-seg      | UART result                       |
|-----------------------------------|------------|-----------------------------------|
| Power-on / reset                  | `47C0`     | POST OK, load_mode=0              |
| `tt-demo euler --inference "hello"` | token IDs | Inference tokens streamed to UART |
| Idle (load_mode=0)                | `47C0`     | Waiting for input                 |

---

## 3. Trinity Pipeline Demo

> **The full Trinity Pipeline Demo (MicroPython orchestrator, latency targets, wiring diagram) is documented in the Phi repo:**  
> [`tt-trinity-phi / docs/DEVKIT_DEMO.md § 3. Trinity Pipeline Demo`](https://github.com/aeraterta/tt-trinity-phi/blob/main/docs/DEVKIT_DEMO.md#3-trinity-pipeline-demo)

In the Trinity pipeline, Euler's role is:

1. Receive the `seed=0x47C0` from **Phi** over UART.
2. Initialise the KV-cache with the seed value.
3. Run inference token-by-token on the input prompt.
4. Forward token embeddings to **Gamma** for neuromorphic processing.
5. Relay Gamma's spike-feedback word back upstream to Phi.

Euler operates in `load_mode=1` throughout a Trinity pipeline run and returns to `load_mode=0` (displaying `47C0`) when the pipeline is idle.

---

## 4. Energy Estimate

| Chip  | Freq     | Tiles  | Power    | Efficiency      |
|-------|----------|--------|----------|-----------------|
| Phi   | 50 MHz   | 1×1    | ~5 mW    | anchor/POST     |
| Euler | 50 MHz   | 8×2    | ~80 mW   | 63 tok/s/W      |
| Gamma | 50 MHz   | 8×4    | ~160 mW  | neuromorphic    |
| **Total (Trinity)** | — | **32 tiles** | **~245 mW** | full pipeline |

Euler alone draws ~80 mW at 50 MHz — well within the USB 500 mA budget even when all three DevKits are powered simultaneously (~245 mW total).

---

*Document revision: 2025 — Trinity SKY 26b DevKit firmware demo plan.*
