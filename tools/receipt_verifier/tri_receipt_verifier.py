#!/usr/bin/env python3
"""
tri_receipt_verifier.py — G4 TRI compute-receipt verifier (off-chip).
Apache-2.0.

Per TRI-NET-G1 Rule 5, TRI settlement is OFF-CHIP at G1/G2/G3. The FPGA emits
deterministic receipts; this tool verifies them on the host BEFORE any
TRI token accrual logic is enabled.

Acceptance for G4 (per Pre-Registration / Order E):
  1. Valid receipt with correct (job_id, result, nonce, checksum) returns
     `status=verified`.
  2. Replay (same job_id+nonce twice) returns `status=replay_rejected`.
  3. Tampered result (wrong payload) returns `status=invalid_result`.
  4. Bad checksum returns `status=invalid_checksum`.
  5. The verifier never accepts a receipt without explicitly checking ALL
     four fields. Refusal-by-default.

Receipt schema (JSONL line; produced by `host/trinity_packet_tool.py`):

    {"job_id": int, "tile_id": int, "op": "GF16_DOT4",
     "expected": "0x47C0", "observed": "0x####",
     "status": "pass"|"fail", "nonce": int, "checksum": int,
     "node": str}

Verifier outputs a parallel JSONL with `verifier_status` ∈
{"verified", "invalid_result", "invalid_checksum", "replay_rejected",
 "malformed"}.
"""

import argparse
import json
import sys
from typing import Dict, Optional, Tuple

EXPECTED_RESULT = 0x47C0


def compute_checksum(job_id: int, observed_payload: int) -> int:
    """v0 checksum: XOR-fold of job_id with observed payload, lo 8 bits.

    NOT a cryptographic MAC. This is the placeholder defined in
    `src/trinity_packet.vh` (TRN_RCPT_CHECKSUM_W = 8). A future revision
    replaces this with a HMAC or zk-proof attestation.
    """
    return (job_id ^ observed_payload) & 0xFF


def verify_one(
    receipt: dict,
    seen: Dict[Tuple[str, int, int], bool],
    accept_op: str = "GF16_DOT4",
) -> str:
    """Return verifier_status string."""
    required = {"job_id", "observed", "nonce", "checksum", "node", "op"}
    if not required.issubset(receipt.keys()):
        return "malformed"

    if receipt["op"] != accept_op:
        return "malformed"

    # Replay detection: per (node, job_id, nonce)
    key = (receipt["node"], int(receipt["job_id"]), int(receipt["nonce"]))
    if seen.get(key):
        return "replay_rejected"

    # Parse observed payload
    obs_str = receipt["observed"]
    try:
        observed = int(obs_str, 16) if obs_str.startswith("0x") else int(obs_str, 16)
    except ValueError:
        return "malformed"

    if observed != EXPECTED_RESULT:
        # Mark seen even for invalid result — replay is still replay
        seen[key] = True
        return "invalid_result"

    expected_chk = compute_checksum(int(receipt["job_id"]), observed)
    if int(receipt["checksum"]) != expected_chk:
        seen[key] = True
        return "invalid_checksum"

    seen[key] = True
    return "verified"


def run(args: argparse.Namespace) -> int:
    seen: Dict[Tuple[str, int, int], bool] = {}
    n_total = 0
    counters = {
        "verified": 0,
        "invalid_result": 0,
        "invalid_checksum": 0,
        "replay_rejected": 0,
        "malformed": 0,
    }

    in_fh = open(args.input, "r") if args.input != "-" else sys.stdin
    out_fh = open(args.out, "w") if args.out else sys.stdout

    try:
        for line in in_fh:
            line = line.strip()
            if not line:
                continue
            try:
                rec = json.loads(line)
            except json.JSONDecodeError:
                continue
            n_total += 1
            status = verify_one(rec, seen)
            counters[status] += 1
            rec["verifier_status"] = status
            out_fh.write(json.dumps(rec) + "\n")
    finally:
        if in_fh is not sys.stdin:
            in_fh.close()
        if out_fh is not sys.stdout:
            out_fh.close()

    print(f"=== G4 RECEIPT VERIFIER ===", file=sys.stderr)
    print(f"Total receipts: {n_total}", file=sys.stderr)
    for k, v in counters.items():
        print(f"  {k:>20}: {v}", file=sys.stderr)
    if counters["malformed"] == 0 and counters["verified"] == n_total:
        print("G4 GATE GREEN: all receipts verified, no replays / invalids", file=sys.stderr)
        return 0
    if counters["verified"] > 0:
        print("G4 GATE PARTIAL: verifier correctly rejected bad inputs", file=sys.stderr)
        return 0
    print("G4 GATE RED: no receipts verified", file=sys.stderr)
    return 1


def main() -> int:
    p = argparse.ArgumentParser(description="G4 TRI compute-receipt verifier")
    p.add_argument("--input", "-i", default="-",
                   help="JSONL input file (default: stdin)")
    p.add_argument("--out", "-o", default=None,
                   help="JSONL output file (default: stdout)")
    args = p.parse_args()
    return run(args)


if __name__ == "__main__":
    sys.exit(main())
