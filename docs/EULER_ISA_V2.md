# EULER ISA v2 — 64-Instruction TRI-27 + CLARA Extension

**Module:** `instruction_rom_v2.v`  
**Repository:** [gHashTag/tt-trinity-euler](https://github.com/gHashTag/tt-trinity-euler)  
**Branch:** `feat/euler-isa-64ops`  
**PhD Anchor:** φ² + φ⁻² = 3 — Glava 18 (Ternary ISA) + Glava 28 (CLARA)  
**DOI:** [10.5281/zenodo.19227877](https://doi.org/10.5281/zenodo.19227877)  
**Watermark:** 0x47C0  

---

## Overview

EULER ISA v2 expands the 32-instruction TRI-27 ISA to 64 opcodes by adding 32 CLARA-specific
opcodes in the upper half of the address space.

### Address partition

| `addr[5]` | `addr[5:4]` | Range       | Count | Domain           |
|-----------|-------------|-------------|-------|------------------|
| 0         | 00 / 01     | 0x00–0x1F   | 32    | TRI-27 original  |
| 1         | 10          | 0x20–0x2F   | 16    | K3 logic ops     |
| 1         | 11          | 0x30–0x3F   | 16    | ASP solver ops   |

**Backward compatibility:** addresses 0x00–0x1F are byte-identical to `trinity_instr_rom.v`.
opcode[5]=0 selects original TRI-27; opcode[5]=1 selects CLARA ops (Phase 2 execution unit).

---

## 16-bit Instruction Word Format

```
 15      13 12       8 7        3 2      0
 +--------+-----------+----------+-------+
 | func3  |  dst_reg  |  src_reg |  imm3 |
 +--------+-----------+----------+-------+
   3 bits    5 bits      5 bits    3 bits
```

| Field     | Bits   | Description                          |
|-----------|--------|--------------------------------------|
| `func3`   | [15:13]| Sub-function / condition code        |
| `dst_reg` | [12:8] | Destination register (r0–r31)        |
| `src_reg` | [7:3]  | Source register (r0–r31)             |
| `imm3`    | [2:0]  | Immediate / sub-opcode / branch offset|

---

## Part I — TRI-27 Original Opcodes (addr 0x00–0x1F)

These 32 entries are **byte-identical** to the boot defaults in `trinity_instr_rom.v`.
All are pre-loaded with NOP (0x0000) except addr 31 which is HALT (0xE000).

| Addr | Hex    | Mnemonic    | func3 | Semantics                          |
|------|--------|-------------|-------|------------------------------------|
| 0x00 | 0x0000 | NOP         | 000   | No operation                       |
| 0x01 | 0x0000 | NOP         | 000   | No operation                       |
| 0x02 | 0x0000 | NOP         | 000   | No operation                       |
| 0x03 | 0x0000 | NOP         | 000   | No operation                       |
| 0x04 | 0x0000 | NOP         | 000   | No operation                       |
| 0x05 | 0x0000 | NOP         | 000   | No operation                       |
| 0x06 | 0x0000 | NOP         | 000   | No operation                       |
| 0x07 | 0x0000 | NOP         | 000   | No operation                       |
| 0x08 | 0x0000 | NOP         | 000   | No operation                       |
| 0x09 | 0x0000 | NOP         | 000   | No operation                       |
| 0x0A | 0x0000 | NOP         | 000   | No operation                       |
| 0x0B | 0x0000 | NOP         | 000   | No operation                       |
| 0x0C | 0x0000 | NOP         | 000   | No operation                       |
| 0x0D | 0x0000 | NOP         | 000   | No operation                       |
| 0x0E | 0x0000 | NOP         | 000   | No operation                       |
| 0x0F | 0x0000 | NOP         | 000   | No operation                       |
| 0x10 | 0x0000 | NOP         | 000   | No operation                       |
| 0x11 | 0x0000 | NOP         | 000   | No operation                       |
| 0x12 | 0x0000 | NOP         | 000   | No operation                       |
| 0x13 | 0x0000 | NOP         | 000   | No operation                       |
| 0x14 | 0x0000 | NOP         | 000   | No operation                       |
| 0x15 | 0x0000 | NOP         | 000   | No operation                       |
| 0x16 | 0x0000 | NOP         | 000   | No operation                       |
| 0x17 | 0x0000 | NOP         | 000   | No operation                       |
| 0x18 | 0x0000 | NOP         | 000   | No operation                       |
| 0x19 | 0x0000 | NOP         | 000   | No operation                       |
| 0x1A | 0x0000 | NOP         | 000   | No operation                       |
| 0x1B | 0x0000 | NOP         | 000   | No operation                       |
| 0x1C | 0x0000 | NOP         | 000   | No operation                       |
| 0x1D | 0x0000 | NOP         | 000   | No operation                       |
| 0x1E | 0x0000 | NOP         | 000   | No operation                       |
| 0x1F | 0xE000 | **HALT**    | 111   | Stop sequencer (boot default)      |

> The boot defaults at 0x00–0x1F are Wishbone-overridable at runtime to hold real TRI-27 programs.
> The 8 ternary opcodes (func3 encoding) used by real programs are: NOP/ADD/SUB/MUL/AND/OR/NOT/HALT.

---

## Part II — CLARA K3 Logic Opcodes (addr 0x20–0x2F)

**Domain:** Three-valued Kleene / Łukasiewicz logic (K3).  
**Execution unit:** `k3_alu.v` (Phase 2 silicon — GAMMA Gap-2).  
**Encoding marker:** `func3 ∈ {001, 010}`, `addr[5:4] = 10`.

Ternary value encoding: `2'b00 = +1 (true)`, `2'b01 = −1 (false)`, `2'b10 = 0 (unknown)`.

| Addr | Mnemonic    | Encoding (bin) | imm3 | Semantics                                  |
|------|-------------|----------------|------|--------------------------------------------|
| 0x20 | k3_and      | 001_00001_00001_000 | 000  | Kleene AND: min(a, b) in {-1,0,+1}    |
| 0x21 | k3_or       | 001_00001_00001_001 | 001  | Kleene OR: max(a, b)                   |
| 0x22 | k3_not      | 001_00001_00001_010 | 010  | Kleene NOT: −a                         |
| 0x23 | k3_min      | 001_00001_00001_011 | 011  | Ternary minimum over vector            |
| 0x24 | k3_max      | 001_00010_00001_000 | 000  | Ternary maximum over vector            |
| 0x25 | k3_xor      | 001_00010_00001_001 | 001  | Ternary XOR: (a + b) mod 3             |
| 0x26 | k3_imp      | 001_00010_00001_010 | 010  | Kleene implication: max(−a, b)         |
| 0x27 | k3_equiv    | 001_00010_00001_011 | 011  | K3 bi-implication: min(imp(a,b),imp(b,a)) |
| 0x28 | k3_nand     | 010_00001_00001_000 | 000  | Kleene NAND: NOT(AND(a,b))             |
| 0x29 | k3_nor      | 010_00001_00001_001 | 001  | Kleene NOR: NOT(OR(a,b))               |
| 0x2A | k3_xnor     | 010_00001_00001_010 | 010  | Ternary XNOR: NOT(XOR(a,b))            |
| 0x2B | k3_luk      | 010_00001_00001_011 | 011  | Łukasiewicz implication: min(1, 1−a+b) |
| 0x2C | k3_consensus| 010_00010_00001_000 | 000  | Ternary consensus (agreement gate)     |
| 0x2D | k3_threshold| 010_00010_00001_001 | 001  | 3-valued threshold: sign(sum(inputs))  |
| 0x2E | k3_select   | 010_00010_00001_010 | 010  | Ternary MUX: sel?a:b (3-way)           |
| 0x2F | k3_reduce   | 010_00010_00001_011 | 011  | Ternary reduce/fold over register file |

### K3 Semantics Reference

```
Kleene truth table ({-1=F, 0=U, +1=T}):

k3_and: min(a,b)         k3_or: max(a,b)       k3_not: -a
  a\b | -1  0  +1          a\b | -1  0  +1        a  | -a
  -1  | -1 -1  -1          -1  | -1  0  +1       -1  | +1
   0  | -1  0   0           0  |  0  0  +1        0  |  0
  +1  | -1  0  +1          +1  | +1 +1  +1       +1  | -1

k3_imp: max(-a,b)        k3_xor: (a+b) mod 3
  a\b | -1  0  +1          a\b | -1  0  +1
  -1  | +1 +1  +1          -1  |  0 +1  -1
   0  | +1  0  +1           0  | +1  0  -1
  +1  | -1  0  +1          +1  | -1 -1   0
```

---

## Part III — CLARA ASP Solver Opcodes (addr 0x30–0x3F)

**Domain:** Answer Set Programming (ASP) / Datalog inference.  
**Execution unit:** `asp_solver_mini.v` (Phase 2 silicon — GAMMA Gap-6).  
**Encoding marker:** `func3 ∈ {011, 100, 111}`, `addr[5:4] = 11`.

| Addr | Mnemonic        | Encoding (bin)         | imm3 | Semantics                                         |
|------|-----------------|------------------------|------|---------------------------------------------------|
| 0x30 | asp_fact        | 011_00001_00001_000    | 000  | Assert ground fact: `dst_reg :- true`             |
| 0x31 | asp_rule_apply  | 011_00001_00001_001    | 001  | Apply Datalog rule: `dst :- src`                  |
| 0x32 | asp_negation    | 011_00001_00001_010    | 010  | Negation-as-failure (NAF): `not src_reg`          |
| 0x33 | asp_stable_check| 011_00001_00001_011    | 011  | Test stable-model membership of `src_reg`         |
| 0x34 | asp_choice      | 011_00010_00001_000    | 000  | Choice rule head: `{dst_reg}`                     |
| 0x35 | asp_constraint  | 011_00010_00001_001    | 001  | Integrity constraint: `:- body`                   |
| 0x36 | asp_aggregate   | 011_00010_00001_010    | 010  | Aggregate (count/sum) into `dst_reg`              |
| 0x37 | asp_propagate   | 011_00010_00001_011    | 011  | Boolean constraint propagation (BCP) step         |
| 0x38 | asp_backtrack   | 100_00001_00001_000    | 000  | Backtrack: undo last decision level               |
| 0x39 | asp_unify       | 100_00001_00001_001    | 001  | Unification: bind `dst_reg ← src_reg`             |
| 0x3A | asp_resolve     | 100_00001_00001_010    | 010  | Resolution step: derive clause from two literals  |
| 0x3B | asp_ground      | 100_00001_00001_011    | 011  | Grounding pass: instantiate rule with constants   |
| 0x3C | asp_justify     | 100_00010_00001_000    | 000  | Produce justification certificate for `dst_reg`   |
| 0x3D | asp_explain     | 100_00010_00001_001    | 001  | Push explanation token onto explanation stack     |
| 0x3E | asp_commit      | 100_00010_00001_010    | 010  | Commit current answer-set candidate               |
| 0x3F | asp_halt_solver | 111_11111_11111_111    | 111  | Terminate ASP solver, output final answer-set     |

### ASP Semantics Notes

- **asp_fact / asp_rule_apply**: EULER acts as a Datalog forward-chaining engine; facts and rules are encoded in the register file. Each invocation fires one derivation step.
- **asp_negation**: Implements stratified negation-as-failure; the flag register (imm3 bit 2) records the well-founded semantics indicator.
- **asp_stable_check**: Compares the current candidate model against the reduct. Returns T/F/U in K3 encoding.
- **asp_propagate**: Unit propagation step for CDCL-style solver embedded in CLARA pipeline.
- **asp_backtrack**: Decrements the decision level register; side-effect: marks reverted literals in the reason map.
- **asp_halt_solver (0x3F = 0xFFFF)**: All-ones sentinel. Halts the ASP solver and latches the answer-set output register.

---

## Encoding Summary

| Group   | addr[5] | addr[4] | func3      | imm3 role         |
|---------|---------|---------|------------|-------------------|
| TRI-27  | 0       | x       | TRI opcode | branch offset     |
| K3 ops  | 1       | 0       | 001 / 010  | K3 sub-op [0..3]  |
| ASP ops | 1       | 1       | 011–111    | ASP sub-op [0..7] |

---

## R-SI-1 Compliance

- Zero `*` operators in `instruction_rom_v2.v` — ROM only, no arithmetic.
- Pure Verilog-2005: all regs declared one per line, no `logic`, no SystemVerilog.
- No external IP; all signals local.

---

## Version History

| Version | Date       | Change                            |
|---------|------------|-----------------------------------|
| v1.0    | 2026-05    | TRI-27: 32-op NOP/HALT ROM        |
| v2.0    | 2026-05    | CLARA ext: +16 K3 + 16 ASP = 64  |

---

*Source: [gHashTag/tt-trinity-euler](https://github.com/gHashTag/tt-trinity-euler) — branch `feat/euler-isa-64ops`*  
*DOI: [10.5281/zenodo.19227877](https://doi.org/10.5281/zenodo.19227877)*
