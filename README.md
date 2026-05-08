# Tiny Tapeout Verilog Project

## Trinity GF16 Dot Product Accelerator

GF16 (Golden Float 16-bit, bias=31, 6-bit exponent, 9-bit mantissa) dot product N=4 accelerator.

### Features
- 4 parallel GF16 multipliers + 3 adders (tree reduction)
- FPGA-validated at **323 MHz** on QMTECH XC7A100T (openXC7 toolchain)
- **0 latches**, **0 timing violations**
- Combinational design — result available in same cycle

### Test
- Hardcoded: dot4([1,2,3,4], [1,2,3,4]) = **30.0** (0x47C0)
- Output: `uo_out` = result[7:0] (0xC0), `uio_out` = result[15:8] (0x47)

### Encoding
- GF16 1.0 = 0x3E00, 2.0 = 0x4000, 3.0 = 0x4100, 4.0 = 0x4200
- Specials: +inf=0x7E00, -inf=0xFE00, NaN=0xFE01

## License
Apache-2.0
