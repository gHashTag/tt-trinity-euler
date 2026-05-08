import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer


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
