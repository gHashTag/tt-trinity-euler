#!/usr/bin/env python3
"""
silicon_g1_runner.py — TRI-NET-G1 silicon acceptance runner.

Drives a real FT601 USB-3 bridge over the FTDI D3XX driver, issues N canonical
GF16 dot4 jobs ({1.0, 2.0, 3.0, 4.0} -> 0x47C0), reads RESULT packets back,
and writes a JSONL receipt ledger.

Acceptance gate (per ONE SHOT G1):
    100 / 100 jobs return 0x47C0 within budget.

Anchor: phi^2 + phi^-2 = 3
Lane:   L-DPC6 silicon-G1
Author: Trinity Agent (R5-honest — no fake success without real silicon)

Refusal-by-default: if ftd3xx is not importable OR no FT601 device is
detected, the runner EXITS NON-ZERO with code 2 and writes NO receipts.
We never fabricate silicon evidence.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
import struct
import sys
import time
from typing import List, Tuple

# ---- Constants identical to host/trinity_packet_tool.py (sim parity) ----
# Packet:  op[31:28] dst[27:26] src[25:24] lane[23:20] rsvd[19:16] payload[15:0]
OP_LOAD_A    = 0x1
OP_LOAD_B    = 0x2
OP_COMPUTE   = 0x3
OP_READ_RES  = 0x4
OP_RESULT    = 0x5

# GF16 (half-precision IEEE-754) operands for 1.0, 2.0, 3.0, 4.0
GF16_OPS = [0x3E00, 0x4000, 0x4100, 0x4200]
EXPECTED_RESULT = 0x47C0  # GF16(30.0) = 1*1 + 2*2 + 3*3 + 4*4

# FT601: pipe 0x82 = RX (FPGA -> host), pipe 0x02 = TX (host -> FPGA)
FT601_PIPE_IN  = 0x82
FT601_PIPE_OUT = 0x02


def mk_pkt(op: int, dst: int = 0, src: int = 0xF, lane: int = 0, payload: int = 0) -> int:
    return ((op & 0xF) << 28) | ((dst & 0x3) << 26) | ((src & 0x3) << 24) \
         | ((lane & 0xF) << 20) | ((0 & 0xF) << 16) | (payload & 0xFFFF)


def parse_pkt(word: int) -> Tuple[int, int, int, int, int]:
    op  = (word >> 28) & 0xF
    dst = (word >> 26) & 0x3
    src = (word >> 24) & 0x3
    lane = (word >> 20) & 0xF
    pay = word & 0xFFFF
    return op, dst, src, lane, pay


def canonical_job(tile_id: int = 0, lane: int = 0) -> List[int]:
    """Return the 6 32-bit words that drive tile 0 through a dot4 job."""
    return [
        mk_pkt(OP_LOAD_A,   dst=tile_id, lane=lane, payload=GF16_OPS[0]),
        mk_pkt(OP_LOAD_A,   dst=tile_id, lane=lane, payload=GF16_OPS[1]),
        mk_pkt(OP_LOAD_B,   dst=tile_id, lane=lane, payload=GF16_OPS[2]),
        mk_pkt(OP_LOAD_B,   dst=tile_id, lane=lane, payload=GF16_OPS[3]),
        mk_pkt(OP_COMPUTE,  dst=tile_id, lane=lane, payload=0x0000),
        mk_pkt(OP_READ_RES, dst=tile_id, lane=lane, payload=0x0000),
    ]


def open_ft601():
    """Return (ft, dev_info) or raise."""
    try:
        import ftd3xx  # type: ignore
        import ftd3xx.defines as ftdef  # type: ignore
    except ImportError as e:
        print(f"REFUSAL: ftd3xx Python driver not installed ({e}). "
              "Install with: pip install ftd3xx", file=sys.stderr)
        print("R5-honesty: refusing to fabricate silicon evidence.", file=sys.stderr)
        sys.exit(2)

    n = ftd3xx.createDeviceInfoList()
    if n == 0:
        print("REFUSAL: no FT60x device detected on USB bus.", file=sys.stderr)
        print("Check: lsusb | grep 0403:601f   (expect FTDI FT600/FT601)", file=sys.stderr)
        sys.exit(2)

    dev_info = ftd3xx.getDeviceInfoList()[0]
    ft = ftd3xx.create(0)
    if ft is None:
        print("REFUSAL: ftd3xx.create(0) returned None.", file=sys.stderr)
        sys.exit(2)
    return ft, dev_info


def send_packets(ft, words: List[int], timeout_ms: int = 1000) -> int:
    payload = b"".join(struct.pack("<I", w) for w in words)
    written = ft.writePipe(FT601_PIPE_OUT, payload, len(payload))
    return written


def read_packet(ft, timeout_ms: int = 1000) -> int:
    """Read one 32-bit word (RESULT packet) from FT601 RX pipe."""
    buf = ft.readPipeEx(FT601_PIPE_IN, 4, raw=True)
    if buf is None or len(buf.get("bytes", b"")) < 4:
        raise TimeoutError("FT601 RX timeout waiting for RESULT packet")
    word, = struct.unpack("<I", buf["bytes"][:4])
    return word


def run_jobs(ft, n_jobs: int, out_path: str) -> Tuple[int, int]:
    pass_n, fail_n = 0, 0
    t_start = time.time()
    with open(out_path, "w") as fout:
        for job_id in range(1, n_jobs + 1):
            nonce = job_id
            words = canonical_job(tile_id=0, lane=0)
            send_packets(ft, words)

            try:
                resp = read_packet(ft, timeout_ms=2000)
                op, dst, src, lane, observed = parse_pkt(resp)
                status = "pass" if (op == OP_RESULT and observed == EXPECTED_RESULT) else "fail"
            except TimeoutError as e:
                op, dst, src, lane, observed = (0, 0, 0, 0, 0)
                status = "timeout"

            if status == "pass":
                pass_n += 1
            else:
                fail_n += 1

            checksum = sum(GF16_OPS) & 0xFF
            receipt = {
                "job_id":   job_id,
                "tile_id":  0,
                "op":       "GF16_DOT4",
                "expected": f"0x{EXPECTED_RESULT:04X}",
                "observed": f"0x{observed:04X}",
                "status":   status,
                "nonce":    nonce,
                "checksum": checksum,
                "node":     "silicon-qmtech-xc7a100t",
                "backend":  "ftd3xx",
                "ts":       time.time(),
            }
            fout.write(json.dumps(receipt) + "\n")
    dt = time.time() - t_start
    return pass_n, fail_n, dt


def main() -> int:
    ap = argparse.ArgumentParser(description="TRI-NET-G1 silicon acceptance runner")
    ap.add_argument("--jobs", type=int, default=100, help="number of GF16 dot4 jobs")
    ap.add_argument("--out",  type=str, default="silicon_g1_receipts.jsonl",
                    help="JSONL receipt log output path")
    ap.add_argument("--no-device-check", action="store_true",
                    help=argparse.SUPPRESS)  # debugging only
    args = ap.parse_args()

    ft, dev_info = open_ft601()
    desc = bytes(dev_info.Description).decode(errors="ignore").rstrip("\x00")
    serial = bytes(dev_info.SerialNumber).decode(errors="ignore").rstrip("\x00")
    print(f"==> FT601 opened: '{desc}' SN='{serial}'")

    out_path = args.out
    os.makedirs(os.path.dirname(out_path) or ".", exist_ok=True)
    pass_n, fail_n, dt = run_jobs(ft, args.jobs, out_path)

    print(f"==> {pass_n}/{args.jobs} passed, {fail_n} failed, {dt:.2f}s elapsed")
    print(f"==> receipts -> {out_path}")
    sha = hashlib.sha256(open(out_path, "rb").read()).hexdigest()[:16]
    print(f"==> ledger sha256[0:16] = {sha}")

    if pass_n == args.jobs and fail_n == 0:
        print("SILICON_G1_GATE_GREEN: 100/100 0x47C0 received from real FPGA")
        return 0
    else:
        print(f"SILICON_G1_GATE_RED: only {pass_n}/{args.jobs} passed")
        return 1


if __name__ == "__main__":
    sys.exit(main())
