# Makefile — Trinity USB-3 loopback bitstream build & flash for QMTECH XC7A100T
#
# Targets:
#   make bit             - build trinity_usb3_loopback.bit via Vivado (batch)
#   make program         - load bitstream into FPGA volatile RAM via openFPGALoader
#   make flash           - program SPI flash (W25Q64JV) with .bin via openFPGALoader
#   make silicon-g1      - one-shot: bit -> program -> run host runner -> verdict
#   make clean           - wipe out/
#
# Tool fallback chain (in priority order):
#   1. Vivado (preferred):    xilinx Vivado 2023.x or 2024.x in $$PATH
#   2. openFPGALoader:        for loading existing .bit/.bin onto the FPGA
#                             (does NOT build, only programs)
#
# Anchor: phi^2 + phi^-2 = 3
# Lane:   L-DPC6 silicon-G1

VIVADO         ?= vivado
OPENFPGALOADER ?= openFPGALoader
CABLE          ?= ft2232          # QMTECH default JTAG
BOARD          ?= qmtech_artix7_100t

REPO_ROOT := $(abspath $(CURDIR)/../../..)
OUT_DIR   := $(CURDIR)/out
BIT       := $(OUT_DIR)/trinity_usb3_loopback.bit
BIN       := $(OUT_DIR)/trinity_usb3_loopback.bin
TIMING    := $(OUT_DIR)/timing_summary.rpt
UTIL      := $(OUT_DIR)/utilization.rpt

HOST_RUNNER := $(REPO_ROOT)/host/silicon_g1_runner.py

.PHONY: all bit program flash silicon-g1 verify clean help

all: bit

help:
	@echo "Trinity silicon-G1 — make targets:"
	@echo "  make bit          build .bit via Vivado batch (build.tcl)"
	@echo "  make program      load .bit into FPGA RAM (openFPGALoader)"
	@echo "  make flash        program SPI flash with .bin (openFPGALoader)"
	@echo "  make silicon-g1   bit -> program -> run -> verdict (one shot)"
	@echo "  make verify       run host runner only (assumes FPGA already programmed)"
	@echo "  make clean        wipe out/"

$(BIT): build.tcl \
        $(REPO_ROOT)/boards/qmtech_a100t/top_usb3_loopback.v \
        $(REPO_ROOT)/boards/qmtech_a100t/sync_reset_n.v \
        $(REPO_ROOT)/boards/qmtech_a100t/trinity_async_pkt_fifo.v \
        $(REPO_ROOT)/boards/qmtech_a100t/qmtech_a100t.xdc \
        $(REPO_ROOT)/src/trinity_usb3_fifo_bridge.v
	@command -v $(VIVADO) >/dev/null || { \
	  echo "ERROR: $(VIVADO) not in PATH — source Vivado settings64.sh first"; exit 2; }
	@mkdir -p $(OUT_DIR)
	cd $(OUT_DIR) && $(VIVADO) -mode batch -source $(CURDIR)/build.tcl \
	  -log vivado.log -journal vivado.jou

bit: $(BIT)
	@test -s $(BIT) && echo "OK: $(BIT) ($$(stat -c%s $(BIT) 2>/dev/null || stat -f%z $(BIT)) bytes)"
	@grep -E "^(PASS|FAIL)" $(OUT_DIR)/vivado.log || true

program: $(BIT)
	@command -v $(OPENFPGALOADER) >/dev/null || { \
	  echo "ERROR: openFPGALoader not in PATH (try: brew install openfpgaloader / apt install openfpgaloader)"; exit 2; }
	$(OPENFPGALOADER) -c $(CABLE) -b $(BOARD) $(BIT)

flash: $(BIN)
	@command -v $(OPENFPGALOADER) >/dev/null || { \
	  echo "ERROR: openFPGALoader not in PATH"; exit 2; }
	$(OPENFPGALOADER) -c $(CABLE) -b $(BOARD) --write-flash --verify $(BIN)

verify:
	@command -v python3 >/dev/null || { echo "ERROR: python3 not in PATH"; exit 2; }
	python3 $(HOST_RUNNER) --jobs 100 --out $(OUT_DIR)/silicon_g1_receipts.jsonl

silicon-g1: bit program verify
	@echo ""
	@echo "==> silicon-G1 ONE-SHOT complete. Receipts at $(OUT_DIR)/silicon_g1_receipts.jsonl"
	@echo "    Acceptance gate: 100/100 0x47C0 received from real FT601 on real FPGA."

clean:
	rm -rf $(OUT_DIR)
