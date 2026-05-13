#!/usr/bin/env python3
"""G4 verifier acceptance tests.

Falsification:
  * A `verified` verdict MUST require all four checks to pass (op, observed,
    nonce/replay, checksum). Any short-circuit accepts a bad receipt.
  * The verifier MUST be refusal-by-default: missing fields => `malformed`.

Run: `python3 test_g4_verifier.py`. Exit code 0 on green, 1 on red.
"""
import io
import json
import sys
from contextlib import redirect_stderr

sys.path.insert(0, ".")
from tri_receipt_verifier import verify_one, compute_checksum, EXPECTED_RESULT


def good_receipt(job_id=1, node="A", payload=EXPECTED_RESULT):
    return {
        "job_id": job_id,
        "tile_id": 0,
        "op": "GF16_DOT4",
        "expected": f"0x{EXPECTED_RESULT:04X}",
        "observed": f"0x{payload:04X}",
        "status": "pass",
        "nonce": job_id,
        "checksum": compute_checksum(job_id, payload),
        "node": node,
    }


def expect(actual, expected, label):
    if actual != expected:
        print(f"FAIL {label}: got {actual!r}, expected {expected!r}")
        return 1
    print(f"PASS {label}")
    return 0


def main() -> int:
    fails = 0
    seen = {}

    # T1: valid receipt -> verified
    fails += expect(verify_one(good_receipt(1), seen), "verified", "T1 valid")

    # T2: same job_id+nonce+node again -> replay_rejected
    fails += expect(verify_one(good_receipt(1), seen), "replay_rejected", "T2 replay")

    # T3: wrong payload -> invalid_result
    r = good_receipt(2, payload=0xDEAD)
    fails += expect(verify_one(r, seen), "invalid_result", "T3 wrong payload")

    # T4: bad checksum -> invalid_checksum
    r = good_receipt(3)
    r["checksum"] = (r["checksum"] + 1) & 0xFF
    fails += expect(verify_one(r, seen), "invalid_checksum", "T4 bad checksum")

    # T5: missing field -> malformed
    r = good_receipt(4)
    del r["nonce"]
    fails += expect(verify_one(r, seen), "malformed", "T5 missing field")

    # T6: wrong op -> malformed
    r = good_receipt(5)
    r["op"] = "GF16_MUL"  # unsupported
    fails += expect(verify_one(r, seen), "malformed", "T6 wrong op")

    # T7: a fresh valid receipt after the bad ones -> verified
    fails += expect(verify_one(good_receipt(6), seen), "verified", "T7 fresh valid")

    # T8: silicon <-> host contract. Decode a raw 32-bit RECEIPT packet using
    # the exact bit layout of `TRN_MK_RCPT` in src/trinity_packet.vh:
    #     [31:28] op       = 0x6 (TRN_OP_RECEIPT)
    #     [27:26] dst      = 0   (host)
    #     [25:24] tile_id  = 0   (tile 0)
    #     [23:20] op_code  = 0x3 (TRN_OP_COMPUTE)
    #     [19:16] reserved = 0
    #     [15:8]  checksum = 0xC1
    #     [7:0]   job_lo   = 0x01
    # That word is exactly what `trinity_gf16_tile.v` emits for the canned demo
    # (job_id=1, result_lo=0xC0). The verifier MUST accept the decoded JSONL.
    raw_word = (0x6 << 28) | (0 << 26) | (0 << 24) | (0x3 << 20) | (0 << 16) \
               | ((0xC1 & 0xFF) << 8) | (0x01 & 0xFF)
    decoded_checksum = (raw_word >> 8) & 0xFF
    decoded_job_lo   = raw_word & 0xFF
    decoded_tile_id  = (raw_word >> 24) & 0x3
    decoded_op_code  = (raw_word >> 20) & 0xF

    # Sanity: the chip's wire-level checksum must agree with the host model.
    fails += expect(decoded_checksum,
                    compute_checksum(decoded_job_lo, EXPECTED_RESULT),
                    "T8a chip_checksum == host_model(job_id, EXPECTED_RESULT)")
    fails += expect(decoded_tile_id, 0, "T8b chip_tile_id")
    fails += expect(decoded_op_code, 0x3, "T8c chip_op_code == COMPUTE")

    # Turn the on-die fields into the JSONL schema the verifier consumes and
    # confirm it round-trips through `verify_one()` as 'verified'.
    chip_emitted = {
        "job_id": decoded_job_lo,
        "tile_id": decoded_tile_id,
        "op": "GF16_DOT4",                  # op_code 0x3 == TRN_OP_COMPUTE
        "expected": f"0x{EXPECTED_RESULT:04X}",
        "observed": f"0x{EXPECTED_RESULT:04X}",
        "status": "pass",
        "nonce": 0x55,                       # CANNED_NONCE in trinity_master_fsm.v
        "checksum": decoded_checksum,
        "node": "trinity_chip_g4",
    }
    fails += expect(verify_one(chip_emitted, seen),
                    "verified", "T8d chip_emitted_packet -> verified")

    if fails == 0:
        print("=== G4 VERIFIER TESTS GREEN ===")
        return 0
    print(f"=== G4 VERIFIER TESTS RED: {fails} fails ===")
    return 1


if __name__ == "__main__":
    sys.exit(main())
