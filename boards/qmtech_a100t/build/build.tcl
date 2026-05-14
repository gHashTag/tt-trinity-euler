################################################################################
# build.tcl - Vivado non-project flow for Trinity USB-3 loopback on
#              QMTECH XC7A100T-FGG484-2 + FT601 daughterboard.
#
# Usage:
#   vivado -mode batch -source build.tcl
#
# Output:
#   boards/qmtech_a100t/build/out/trinity_usb3_loopback.bit
#   boards/qmtech_a100t/build/out/trinity_usb3_loopback.bin   (flash)
#   boards/qmtech_a100t/build/out/timing_summary.rpt
#   boards/qmtech_a100t/build/out/utilization.rpt
#
# Anchor: phi^2 + phi^-2 = 3
# Lane:   L-DPC6 silicon-G1
################################################################################

set scriptDir [file dirname [file normalize [info script]]]
set repoRoot  [file normalize [file join $scriptDir ".." ".." ".."]]
set outDir    [file join $scriptDir "out"]
file mkdir $outDir

# ---------- Target part ----------
# QMTECH XC7A100T core board: XC7A100T-FGG484-2 (Artix-7, 484-ball FBGA, speed -2).
# If your physical board has -1 speed grade, edit here only.
set TARGET_PART "xc7a100tfgg484-2"

create_project -in_memory -part $TARGET_PART

# ---------- Source files (synthesizable RTL only) ----------
# CROWN rules:
#   R1: no Linux / soft-CPU / AXI in compute core
#   R2: no new `*` multipliers in new RTL (gf16_mul.v legacy tolerated)
#   R3: USB-3 is a boundary FIFO, no vendor black-box IP
#   R4: mesh PHY off-chip
#   R5: TRI settlement off-chip
set rtlFiles [list \
    [file join $repoRoot "src" "trinity_packet.vh"]              \
    [file join $repoRoot "src" "gf16_add.v"]                     \
    [file join $repoRoot "src" "gf16_mul.v"]                     \
    [file join $repoRoot "src" "gf16_dot4.v"]                    \
    [file join $repoRoot "src" "trinity_gf16_tile.v"]            \
    [file join $repoRoot "src" "trinity_router_2x2.v"]           \
    [file join $repoRoot "src" "trinity_mesh_2x2.v"]             \
    [file join $repoRoot "src" "trinity_master_fsm.v"]           \
    [file join $repoRoot "src" "trinity_mesh_adapter_stub.v"]    \
    [file join $repoRoot "src" "trinity_usb3_fifo_bridge.v"]     \
    [file join $repoRoot "boards" "qmtech_a100t" "sync_reset_n.v"]            \
    [file join $repoRoot "boards" "qmtech_a100t" "trinity_async_pkt_fifo.v"]  \
    [file join $repoRoot "boards" "qmtech_a100t" "top_usb3_loopback.v"]       \
]

foreach f $rtlFiles {
    if {![file exists $f]} {
        puts "ERROR: missing RTL source: $f"
        exit 2
    }
    read_verilog $f
}

# Verilog include search path (for `include "trinity_packet.vh")
set_property include_dirs [list [file join $repoRoot "src"]] [current_fileset]

# ---------- Constraints ----------
set xdcFile [file join $repoRoot "boards" "qmtech_a100t" "qmtech_a100t.xdc"]
if {![file exists $xdcFile]} {
    puts "ERROR: missing XDC: $xdcFile"
    exit 2
}
read_xdc $xdcFile

# ---------- Synthesis ----------
puts "==> synth_design"
synth_design -top top_usb3_loopback -part $TARGET_PART -flatten_hierarchy rebuilt

# R2 honesty gate (post-synth): assert no DSP48 inferred from new RTL.
# Legacy gf16_mul.v uses bit-XOR/shift, not `*`, so DSP count MUST be 0.
set dsp_count [llength [get_cells -hierarchical -filter {REF_NAME =~ "DSP48*"}]]
if {$dsp_count != 0} {
    puts "FAIL: R2 multiplier-free rule violated - $dsp_count DSP48 cells inferred."
    exit 3
}
puts "PASS R2: 0 DSP48 inferred (multiplier-free)."

# ---------- Place & Route ----------
puts "==> opt_design"
opt_design

puts "==> place_design"
place_design

puts "==> phys_opt_design"
phys_opt_design

puts "==> route_design"
route_design

# ---------- Reports ----------
report_timing_summary -file [file join $outDir "timing_summary.rpt"]
report_utilization    -file [file join $outDir "utilization.rpt"]
report_drc            -file [file join $outDir "drc.rpt"]

# Timing gate: WNS must be >= 0 for 50 MHz domain
set wns [get_property SLACK [get_timing_paths -max_paths 1 -setup]]
if {$wns < 0} {
    puts "FAIL: timing closure failed, WNS=$wns ns"
    exit 4
}
puts "PASS timing: WNS=$wns ns"

# ---------- Bitstream ----------
puts "==> write_bitstream"
write_bitstream -force [file join $outDir "trinity_usb3_loopback.bit"]

# Flash image (SPI x4, BPI off — QMTECH default is W25Q64JV in SPI mode)
write_cfgmem -format bin -interface spix4 -size 8 -loadbit \
    "up 0x00000000 [file join $outDir trinity_usb3_loopback.bit]" \
    -file [file join $outDir "trinity_usb3_loopback.bin"] -force

puts "==> build.tcl DONE - bitstream at $outDir/trinity_usb3_loopback.bit"
exit 0
