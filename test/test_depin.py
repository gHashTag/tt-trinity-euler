# SPDX-License-Identifier: Apache-2.0
# DePIN module cocotb stubs: B3 RPKI, B5 ZK, B6 GKR
# Author: Dmitrii Vasilev (sole author, admin@t27.ai)

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge


# ---------------------------------------------------------------------------
# B3 — depin_b3_rpki
# ---------------------------------------------------------------------------
@cocotb.test()
async def test_b3_rpki_reset(dut):
    """B3 RPKI: signature clears on reset."""
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    dut.rst_n.value = 0
    dut.route_prefix.value = 0xABCD
    dut.signing_key.value = 0x1234
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    assert dut.signature.value == 0, "signature must be 0 in reset"


@cocotb.test()
async def test_b3_rpki_compute(dut):
    """B3 RPKI: signature = (prefix<<1) ^ key ^ byteswap(prefix)."""
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    dut.rst_n.value = 0
    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    dut.route_prefix.value = 0x00FF
    dut.signing_key.value = 0x0F0F
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    prefix = 0x00FF
    key = 0x0F0F
    byteswap = ((prefix & 0xFF) << 8) | ((prefix >> 8) & 0xFF)
    expected = ((prefix << 1) & 0xFFFF) ^ key ^ byteswap
    assert int(dut.signature.value) == expected, \
        f"expected 0x{expected:04X}, got 0x{int(dut.signature.value):04X}"


# ---------------------------------------------------------------------------
# B5 — depin_b5_zk
# ---------------------------------------------------------------------------
@cocotb.test()
async def test_b5_zk_reset(dut):
    """B5 ZK: valid is 0 after reset."""
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    dut.rst_n.value = 0
    dut.job_input_hash.value = 0
    dut.job_output_hash.value = 0
    dut.proof_a.value = 0
    dut.proof_b.value = 0
    dut.proof_c.value = 0
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    assert dut.valid.value == 0, "valid must be 0 in reset"


@cocotb.test()
async def test_b5_zk_valid_proof(dut):
    """B5 ZK: valid=1 when proof_a^proof_b^proof_c == input^output."""
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    dut.rst_n.value = 0
    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    ih = 0xCAFE
    oh = 0xBEEF
    expected = ih ^ oh          # 0x7411
    dut.job_input_hash.value = ih
    dut.job_output_hash.value = oh
    dut.proof_a.value = expected
    dut.proof_b.value = 0x0000
    dut.proof_c.value = 0x0000
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    assert dut.valid.value == 1, "valid should be 1 for matching proof"


# ---------------------------------------------------------------------------
# B6 — depin_b6_gkr
# ---------------------------------------------------------------------------
@cocotb.test()
async def test_b6_gkr_reset(dut):
    """B6 GKR: sum_eval clears on reset."""
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    dut.rst_n.value = 0
    dut.poly_coeff.value = 0xFFFF
    dut.challenge.value = 0xFFFF
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    assert dut.sum_eval.value == 0, "sum_eval must be 0 in reset"


@cocotb.test()
async def test_b6_gkr_compute(dut):
    """B6 GKR: sum_eval = poly_coeff + 2*challenge + 4*challenge."""
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    dut.rst_n.value = 0
    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    a = 0x0010
    b = 0x0003
    dut.poly_coeff.value = a
    dut.challenge.value = b
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    expected = (a + (b << 1) + (b << 2)) & 0xFFFF
    assert int(dut.sum_eval.value) == expected, \
        f"expected 0x{expected:04X}, got 0x{int(dut.sum_eval.value):04X}"
