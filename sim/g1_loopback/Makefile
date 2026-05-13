# sim/g1_loopback/Makefile
# G1 USB-3 loopback simulation gate.
# Requires Icarus Verilog (iverilog >= 11) — no vendor IP, no Linux, no AXI.
#
#   make            -> compile + run + check
#   make clean

ROOT := ../..
SRC  := \
  $(ROOT)/src/gf16_add.v \
  $(ROOT)/src/gf16_mul.v \
  $(ROOT)/src/gf16_dot4.v \
  $(ROOT)/src/trinity_gf16_tile.v \
  $(ROOT)/src/trinity_router_2x2.v \
  $(ROOT)/src/trinity_mesh_2x2.v \
  $(ROOT)/src/trinity_master_fsm.v \
  $(ROOT)/src/trinity_usb3_fifo_bridge.v \
  $(ROOT)/boards/qmtech_a100t/sync_reset_n.v \
  $(ROOT)/boards/qmtech_a100t/trinity_async_pkt_fifo.v \
  $(ROOT)/boards/qmtech_a100t/top_usb3_loopback.v \
  ft601_fifo_model.v \
  tb_g1_loopback.v

INCLUDES := -I$(ROOT)/src

all: run

tb_g1_loopback.vvp: $(SRC)
	iverilog -g2012 $(INCLUDES) -o $@ $(SRC)

run: tb_g1_loopback.vvp
	vvp $< | tee g1_loopback.log
	@grep -q "G1_GATE_GREEN: 100/100" g1_loopback.log || (echo "G1 GATE FAILED" && exit 1)
	@echo "G1 GATE PASSED"

clean:
	rm -f tb_g1_loopback.vvp tb_g1_loopback.vcd g1_loopback.log
