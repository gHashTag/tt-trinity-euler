import os

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer

# When cocotb runs against the post-synthesis gate-level netlist, internal
# hierarchical signals are flattened away. The Tiny Tapeout Makefile sets
# GATES=yes in that mode, which we use to skip RTL-only assertions.
GL_TEST = os.environ.get("GATES", "no").lower() == "yes"


@cocotb.test()
async def test_dot4_result(dut):
    dut._log.info("Start test_dot4_result")
    clock = Clock(dut.clk, 10, units="us")
    cocotb.start_soon(clock.start())

    dut.rst_n.value = 0
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    await Timer(50, units="us")
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)
    await Timer(1, units="us")

    result = (dut.uio_out.value.integer << 8) | dut.uo_out.value.integer
    dut._log.info(f"dot4 result: 0x{result:04X}")
    assert result == 0x47C0, f"Expected 0x47C0 (30.0), got 0x{result:04X}"


@cocotb.test()
async def test_uio_oe(dut):
    dut._log.info("Start test_uio_oe")
    assert dut.uio_oe.value.integer == 0xFF, "uio_oe should be 0xFF"


@cocotb.test()
async def test_dot4_with_receipt(dut):
    """G4 DePIN: chip must emit a deterministic RECEIPT packet paired with RESULT.

    Canned vectors driven by trinity_master_fsm: job_id=0x01, nonce=0x55,
    result=0x47C0. Expected on-die checksum:
        (job_id ^ result_lo) & 0xFF = (0x01 ^ 0xC0) & 0xFF = 0xC1
    Expected tile_id = 0 (tile 0 is the FSM target).
    Expected job_id_lo = 0x01.
    """
    dut._log.info("Start test_dot4_with_receipt")
    clock = Clock(dut.clk, 10, units="us")
    cocotb.start_soon(clock.start())

    dut.rst_n.value = 0
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    await Timer(50, units="us")
    dut.rst_n.value = 1

    # 64 cycles is a generous budget: 4 LOAD_A + 4 LOAD_B + LOAD_JOB +
    # LOAD_NONCE + COMPUTE + READ_RES + RESULT handoff + RECEIPT handoff
    # ~= 14-20 cycles. Existing tb.v uses the same budget.
    for _ in range(64):
        await RisingEdge(dut.clk)

    if GL_TEST:
        dut._log.info(
            "SKIP test_dot4_with_receipt internal assertions: GATES=yes "
            "(post-synthesis netlist has internal signals flattened)."
        )
        return

    # Drill into the master FSM via the hierarchical path. cocotb exposes the
    # registers of u_master through the top-level dut.
    rcpt_valid = int(dut.user_project.mesh_rcpt_valid.value)
    rcpt_checksum = int(dut.user_project.mesh_rcpt_checksum.value)
    rcpt_job_id = int(dut.user_project.mesh_rcpt_job_id.value)
    rcpt_tile_id = int(dut.user_project.mesh_rcpt_tile_id.value)

    dut._log.info(
        f"receipt: valid={rcpt_valid} checksum=0x{rcpt_checksum:02X} "
        f"job_id=0x{rcpt_job_id:02X} tile_id={rcpt_tile_id}"
    )

    assert rcpt_valid == 1, "expected rcpt_valid_q == 1 after RECEIPT handshake"
    assert rcpt_checksum == 0xC1, (
        f"expected silicon checksum 0xC1, got 0x{rcpt_checksum:02X} "
        "(host model: (0x01 ^ 0xC0) & 0xFF)"
    )
    assert rcpt_job_id == 0x01, (
        f"expected job_id 0x01, got 0x{rcpt_job_id:02X}"
    )
    assert rcpt_tile_id == 0, (
        f"expected tile_id 0, got {rcpt_tile_id}"
    )
