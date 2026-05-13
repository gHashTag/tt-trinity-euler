# boards/qmtech_a100t/qmtech_a100t.xdc
# Vivado / openXC7 pin & timing constraints for the QMTECH XC7A100T core board
# with an FT601-Q (UMFT601A) USB-3 daughterboard on the GPIO header.
# Apache-2.0
#
# These pins are typical for the QMTECH XC7A100T-CORE board (Bank 35 / Bank 16
# 3.3 V LVCMOS). They are illustrative defaults — the operator MUST verify the
# exact GPIO mapping for their specific QMTECH revision and FT601 carrier before
# bitstream generation. The mapping below targets the QMTECH Daughter-Board GPIO
# header J6/J7 connected to the UMFT601A's CN1.

# --------------------------------------------------------------------------
# Primary clock (on-board 50 MHz oscillator, pin G22 on QMTECH XC7A100T-CORE)
# --------------------------------------------------------------------------
set_property -dict {PACKAGE_PIN G22 IOSTANDARD LVCMOS33} [get_ports sys_clk_50]
create_clock -name sys_clk_50 -period 20.000 [get_ports sys_clk_50]

# --------------------------------------------------------------------------
# Push-button reset (active low)
# --------------------------------------------------------------------------
set_property -dict {PACKAGE_PIN H4 IOSTANDARD LVCMOS33} [get_ports sys_rst_n]

# --------------------------------------------------------------------------
# FT601 clock (100 MHz output from FT601's PLL on its CLK pin)
# --------------------------------------------------------------------------
set_property -dict {PACKAGE_PIN T20 IOSTANDARD LVCMOS33} [get_ports ft_clk]
create_clock -name ft_clk -period 10.000 [get_ports ft_clk]

# --------------------------------------------------------------------------
# CDC: declare the two clocks asynchronous so timer ignores async paths
# inside trinity_async_pkt_fifo (we synchronize gray pointers ourselves).
# --------------------------------------------------------------------------
set_clock_groups -asynchronous \
  -group [get_clocks sys_clk_50] \
  -group [get_clocks ft_clk]

# --------------------------------------------------------------------------
# FT601 control pins
# --------------------------------------------------------------------------
set_property -dict {PACKAGE_PIN R19 IOSTANDARD LVCMOS33} [get_ports ft_rxf_n]
set_property -dict {PACKAGE_PIN R20 IOSTANDARD LVCMOS33} [get_ports ft_txe_n]
set_property -dict {PACKAGE_PIN P19 IOSTANDARD LVCMOS33} [get_ports ft_rd_n]
set_property -dict {PACKAGE_PIN P20 IOSTANDARD LVCMOS33} [get_ports ft_wr_n]
set_property -dict {PACKAGE_PIN N19 IOSTANDARD LVCMOS33} [get_ports ft_oe_n]

# --------------------------------------------------------------------------
# FT601 32-bit data bus (illustrative QMTECH GPIO mapping; verify per board rev)
# --------------------------------------------------------------------------
set_property IOSTANDARD LVCMOS33 [get_ports {ft_data[*]}]
set_property PACKAGE_PIN AB22 [get_ports {ft_data[0]}]
set_property PACKAGE_PIN AB21 [get_ports {ft_data[1]}]
set_property PACKAGE_PIN AA20 [get_ports {ft_data[2]}]
set_property PACKAGE_PIN Y20  [get_ports {ft_data[3]}]
set_property PACKAGE_PIN AB20 [get_ports {ft_data[4]}]
set_property PACKAGE_PIN AA19 [get_ports {ft_data[5]}]
set_property PACKAGE_PIN AB18 [get_ports {ft_data[6]}]
set_property PACKAGE_PIN Y18  [get_ports {ft_data[7]}]
set_property PACKAGE_PIN W19  [get_ports {ft_data[8]}]
set_property PACKAGE_PIN V19  [get_ports {ft_data[9]}]
set_property PACKAGE_PIN W20  [get_ports {ft_data[10]}]
set_property PACKAGE_PIN V20  [get_ports {ft_data[11]}]
set_property PACKAGE_PIN U20  [get_ports {ft_data[12]}]
set_property PACKAGE_PIN T20  [get_ports {ft_data[13]}]
set_property PACKAGE_PIN R18  [get_ports {ft_data[14]}]
set_property PACKAGE_PIN T18  [get_ports {ft_data[15]}]
set_property PACKAGE_PIN P16  [get_ports {ft_data[16]}]
set_property PACKAGE_PIN P15  [get_ports {ft_data[17]}]
set_property PACKAGE_PIN N17  [get_ports {ft_data[18]}]
set_property PACKAGE_PIN P17  [get_ports {ft_data[19]}]
set_property PACKAGE_PIN R16  [get_ports {ft_data[20]}]
set_property PACKAGE_PIN R17  [get_ports {ft_data[21]}]
set_property PACKAGE_PIN V18  [get_ports {ft_data[22]}]
set_property PACKAGE_PIN V17  [get_ports {ft_data[23]}]
set_property PACKAGE_PIN N13  [get_ports {ft_data[24]}]
set_property PACKAGE_PIN N14  [get_ports {ft_data[25]}]
set_property PACKAGE_PIN N15  [get_ports {ft_data[26]}]
set_property PACKAGE_PIN M16  [get_ports {ft_data[27]}]
set_property PACKAGE_PIN M15  [get_ports {ft_data[28]}]
set_property PACKAGE_PIN L14  [get_ports {ft_data[29]}]
set_property PACKAGE_PIN L13  [get_ports {ft_data[30]}]
set_property PACKAGE_PIN K13  [get_ports {ft_data[31]}]

# --------------------------------------------------------------------------
# Status LEDs (QMTECH XC7A100T-CORE: 4 user LEDs)
# --------------------------------------------------------------------------
set_property -dict {PACKAGE_PIN E6  IOSTANDARD LVCMOS33} [get_ports {led_status[0]}]
set_property -dict {PACKAGE_PIN K3  IOSTANDARD LVCMOS33} [get_ports {led_status[1]}]
set_property -dict {PACKAGE_PIN J4  IOSTANDARD LVCMOS33} [get_ports {led_status[2]}]
set_property -dict {PACKAGE_PIN H4  IOSTANDARD LVCMOS33} [get_ports {led_status[3]}]

# --------------------------------------------------------------------------
# Configuration
# --------------------------------------------------------------------------
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
