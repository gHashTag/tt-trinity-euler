# sim/tri1_v2/Makefile — TRI-1 v2 LOW-complexity lanes simulation gate
# Apache-2.0
#
# Tests L-S22, L-S23, L-S24, L-S28, L-S32, L-S33.
#
#   make            -> compile + run + check
#   make clean

ROOT := ../..
SRC  := \
  $(ROOT)/src/plrm_counter.v \
  $(ROOT)/src/cassini_post.v \
  $(ROOT)/src/nca_entropy_monitor.v \
  $(ROOT)/src/strobe_seed_guard.v \
  $(ROOT)/src/phi_distance_oracle.v \
  $(ROOT)/src/bpb_lower_bound_guard.v \
  tb_tri1_v2_lanes.v

all: run

tb_tri1_v2_lanes.vvp: $(SRC)
	iverilog -g2012 -o $@ $(SRC)

run: tb_tri1_v2_lanes.vvp
	vvp $< | tee tri1_v2_lanes.log
	@grep -q "TRI1_V2_LANES_GREEN" tri1_v2_lanes.log || (echo "TRI-1 v2 LANES GATE FAILED" && exit 1)
	@echo "TRI-1 V2 LANES GATE PASSED"

clean:
	rm -f tb_tri1_v2_lanes.vvp tb_tri1_v2_lanes.vcd tri1_v2_lanes.log
