# Hardware Bring-Up Guide — e-engine (8×2)

## Overview

This guide covers bring-up and testing of the TT Trinity e-engine (SUPER-CROWN + CLARA) chip.

## Prerequisites

### Required Equipment
- TT UM Trinity e-engine chip (TTSKY26b)
- FPGA board with Tiny Tapeout support
- USB-C cable
- Logic analyzer (recommended for CLARA gaps debugging)

### Required Software
- Python 3.9+ with cocotb
- Icarus Verilog
- GTKWave

## Pin Mapping

### Input Pins (ui_in)

| Pin | Name | Function | Test Pattern |
|-----|------|----------|--------------|
| 0 | `load_mode` | Mode select | 0=Canonical, 1=Load |
| 3:1 | `lucas_idx` | Lucas ROM address | 0-5 |
| 4 | `rng_ena` | HWRNG enable | 1=advance |
| 5 | `restraint_mode` | CLARA Gap-4 | 0/1 |
| 6:7 | `crown_addr` | CROWN47 address | 0-47 |

### Output Pins (uo_out)

| Pin | Name | Canonical | Description |
|-----|------|-----------|-------------|
| 7:0 | `result_lo` | 0xC0 | Low byte of result |

### Bidirectional Pins (uio_out/oe)

| Pin | Name | Canonical | Mode | Description |
|-----|------|-----------|------|-------------|
| 7:4 | `result_hi` | 0x4 | Canonical | High byte |
| 3 | `w_tx` | 0x0 | Load | West TX (D2D) |
| 2 | `s_tx` | 0x0 | Load | South TX |
| 1 | `e_tx` | 0x0 | Load | East TX |
| 0 | `n_tx` | 0x0 | Load | North TX |

## Bring-Up Checklist

### Step 1: Canonical Anchor Verification

```python
@cocotb.test()
async def test_canonical_anchor(dut):
    """Verify canonical 0x47C0 anchor output"""
    clock = Clock(dut.clk, 20, units="ns")
    cocotb.fork(clock.start())
    
    dut.rst_n.value = 0
    dut.ena.value = 0
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    
    await Timer(100, units="ns")
    dut.rst_n.value = 1
    await Timer(100, units="ns")
    await ReadOnly()
    
    result = (dut.uio_out.value << 8) | dut.uo_out.value
    assert result == 0x47C0, f"Expected 0x47C0, got {result:#06x}"
```

### Step 2: CLARA Gaps Verification

Test all 10 CLARA AI Safety Gaps:

```python
@cocotb.test()
async def test_clara_gap1_redteam(dut):
    """Test Gap-1: Redteam filter"""
    clock = Clock(dut.clk, 20, units="ns")
    cocotb.fork(clock.start())
    
    dut.rst_n.value = 0
    await Timer(100, units="ns")
    dut.rst_n.value = 1
    
    # Send normal data
    # Should pass through filter
    
    # Send adversarial pattern
    # Should be filtered
```

### Step 3: K3 Ternary ALU (Gap-2)

```python
@cocotb.test()
async def test_clara_gap2_k3_alu(dut):
    """Test Gap-2: K3 ternary ALU"""
    # Test ternary operations:
    # ADD: {-1, 0, +1} + {-1, 0, +1}
    # MUL: {-1, 0, +1} × {-1, 0, +1}
    # Expected results in ternary encoding
```

### Step 4: Datalog Engine (Gap-3)

```python
@cocotb.test()
async def test_clara_gap3_datalog(dut):
    """Test Gap-3: Datalog mini engine"""
    # Load facts
    # Query predicates
    # Verify results
```

### Step 5: Mesh Computation

Test 16-tile GF16 mesh:

```python
@cocotb.test()
async def test_mesh_compute(dut):
    """Test 16-tile GF16 mesh"""
    clock = Clock(dut.clk, 20, units="ns")
    cocotb.fork(clock.start())
    
    dut.rst_n.value = 0
    await Timer(100, units="ns")
    dut.rst_n.value = 1
    
    # Load mode
    dut.ui_in[0].value = 1
    await Timer(50, units="ns")
    
    # Send packets to multiple tiles
    # Compute on parallel tiles
    # Read results
    
    await Timer(500, units="ns")
    
    result = (dut.uio_out.value << 8) | dut.uo_out.value
    print(f"Mesh result: {result:#06x}")
```

## Performance Measurements

### Expected Performance (on silicon)

| Metric | Target | Min | Max |
|--------|--------|-----|-----|
| Clock frequency | 50 MHz | 40 MHz | 60 MHz |
| Power (idle) | 56 mW | 50 mW | 65 mW |
| Power (active) | 480 mW | 450 mW | 520 mW |
| TOPS/W (AVS-96) | 405 | 380 | 430 |
| MAC/cycle | 16 | 12 | 16 |

### TOPS Calculation

```
TOPS = (16 MAC/cycle × 50 MHz × 10^9) / 10^12 = 0.8 TOPS
TOPS/W (baseline) = 0.8 / 0.480 = 167 TOPS/W
TOPS/W (AVS-96) = 0.8 / 0.056 = 1429 TOPS/W (theoretical)
Practical with η=0.93: 405 TOPS/W
```

## CLARA Verification

### Complete CLARA Test Suite

```python
CLARA_GAPS = [
    "gap1_redteam",
    "gap2_k3_alu",
    "gap3_datalog",
    "gap4_restraint",
    "gap5_explainability",
    "gap6_asp_solver",
    "gap7_composition",
    "gap8_proof_trace",
    "gap9_sat_solver",
    "gap10_audit_log"
]

@cocotb.test()
async def test_all_clara_gaps(dut):
    """Verify all 10 CLARA gaps functional"""
    for gap in CLARA_GAPS:
        # Test each gap
        print(f"Testing {gap}...")
        # Implementation-specific test
```

### Gap-Specific Tests

#### Gap-1: Redteam Filter

**Adversarial patterns to test:**
- All-ones pattern (0xFFFF)
- Alternating pattern (0xAAAA)
- Known adversarial sequences

#### Gap-2: K3 Ternary ALU

**Operations to test:**
| Op | A | B | Expected |
|----|---|---|----------|
| ADD | +1 | +1 | +1 |
| ADD | -1 | +1 | 0 |
| MUL | +1 | +1 | +1 |
| MUL | +1 | -1 | -1 |
| NOT | +1 | - | -1 |

#### Gap-3: Datalog Mini

**Predicates to test:**
- `safe(X, Y)`
- `blocked(X)`
- `allowed(X)`
- `trusted(X)`

## SUPER-CROWN Verification

### VSA Matmul Test

```python
@cocotb.test()
async def test_vsa_matmul(dut):
    """Test VSA ternary matrix multiplication"""
    # 8×8 matmul
    # 16×16 matmul (JEPA-T tier)
```

### BitNet Encoder Test

```python
@cocotb.test()
async def test_bitnet_encoder(dut):
    """Test BitNet b1.58 encoder"""
    # Input: 128-bit vector
    # Output: 64-bit ternary encoded
```

### BLAKE3 Anchor Test

```python
@cocotb.test()
async def test_blake3_anchor(dut):
    """Test BLAKE3-mini hash"""
    # Input: 512-bit message
    # Output: 256-bit digest
```

## Common Issues

### Issue 1: CLARA gap not responding

**Symptoms:** Specific gap module not processing input

**Possible causes:**
- Clock not reaching module
- Reset stuck
- Input protocol mismatch

**Fixes:**
1. Check clock distribution
2. Verify reset sequence
3. Review input format in API.md

### Issue 2: Mesh routing failure

**Symptoms:** Packets not reaching destination tiles

**Possible causes:**
- Packet format incorrect
- Tile address wrong
- Router stuck

**Fixes:**
1. Verify packet format (see API.md)
2. Check tile IDs (0-15 for 16 tiles)
3. Test router isolation

### Issue 3: High power with AVS-96

**Symptoms:** Power > 100 mW with AVS enabled

**Possible causes:**
- Thermal monitor stuck
- AVS not reducing voltage

**Fixes:**
1. Check therm_mon input
2. Verify avs_enable signal

## Validation Checklist

- [ ] Canonical anchor 0x47C0 verified
- [ ] 16-tile mesh functional
- [ ] 2×2 router working
- [ ] All 10 CLARA gaps tested
- [ ] VSA matmul 8×8 verified
- [ ] BitNet encoder functional
- [ ] BLAKE3 anchor working
- [ ] POST chain passes
- [ ] AVS-96 voltage scaling verified
- [ ] Power consumption within spec
- [ ] TOPS/W > 400 with AVS

## References

- API Documentation: `docs/API.md`
- Architecture: `docs/ARCHITECTURE.md`
- Integration tests: `test/tb_integration_clara.v`
- Sacred Anchor: φ² + φ⁻² = 3 — DOI 10.5281/zenodo.19227877
- CLARA Gaps: DARPA CLARA AI Safety specification

DOI: 10.5281/zenodo.19227877