# Contributing to TRI-NET e-engine

Thank you for your interest in contributing to the Trinity TRI-NET project!

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Workflow](#development-workflow)
- [Commit Message Format](#commit-message-format)
- [Pull Request Process](#pull-request-process)
- [Coding Standards](#coding-standards)
- [Testing Requirements](#testing-requirements)
- [R-SI Compliance](#r-si-compliance)
- [CLARA Gap Guidelines](#clara-gap-guidelines)

---

## Code of Conduct

- Be respectful and inclusive
- Focus on technical discussions
- Assume good intent
- Credit others appropriately

---

## Getting Started

### Prerequisites

```bash
# Install Verilog tools
brew install iverilog cocotb  # macOS
sudo apt-get install iverilog cocotb  # Ubuntu

# Install pre-commit hooks
pip install pre-commit

# Install Verible linter (optional)
brew install verible  # macOS
```

### Setup

```bash
# Fork and clone
git clone https://github.com/YOUR_USERNAME/tt-trinity-euler
cd tt-trinity-euler
git remote add upstream https://github.com/gHashTag/tt-trinity-euler

# Install pre-commit hooks
pre-commit install
```

---

## Development Workflow

```bash
# 1. Create a feature branch
git checkout -b feature/amazing-feature

# 2. Make your changes
# ... edit files ...

# 3. Run tests
cd test
./sim.sh tb_gf16_dot8

# 4. Run pre-commit hooks
pre-commit run --all-files

# 5. Commit
git add .
git commit -m 'feat(clara): implement datalog_engine_mini'

# 6. Push and create PR
git push origin feature/amazing-feature
```

---

## Commit Message Format

```
<type>(<scope>): brief description

Detailed description explaining the change.

Closes #<issue>

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
```

### Types

| Type | Description |
|------|-------------|
| `feat` | New feature |
| `fix` | Bug fix |
| `docs` | Documentation only |
| `refactor` | Code refactoring |
| `test` | Test additions/changes |
| `perf` | Performance improvement |
| `clara` | CLARA AI Safety Gap work |

### Scopes

| Scope | Description |
|-------|-------------|
| `gf16` | GF16 arithmetic modules |
| `quant` | Quantization modules |
| `power` | Power management (AVS, FBB, Purkinje) |
| `post` | POST and ROM modules |
| `mesh` | D2D and mesh routing |
| `clara` | CLARA AI Safety Gaps |
| `vsa` | VSA and holographic binding |
| `bitnet` | BitNet b1.58 modules |

### Examples

```
feat(clara): implement datalog_engine_mini for Gap-3

Implements forward-chain Datalog with 16 clauses and 16 atoms.
Uses 21-bit clause encoding for R-SI-1 compliance.
TA1 traceability documented in CLARA_TRACEABILITY.md.

Closes #45

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
```

```
fix(vsa): correct holo_mux_x4 FHRR binding

Previous implementation had incorrect hypervector XOR
order. Fixed to match FHRR specification.

Closes #72

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
```

---

## Pull Request Process

1. **Before opening PR:**
   - All tests pass locally
   - Pre-commit hooks pass
   - R-SI compliance verified
   - Documentation updated

2. **PR Title:** Follow commit format
   - Good: `feat(clara): implement datalog_engine_mini`
   - Bad: `Added CLARA gap`

3. **PR Description:** Include:
   - Summary of changes
   - Motivation/why
   - Testing approach
   - CLARA TA traceability (if applicable)
   - Breaking changes (if any)

4. **CI Checks:**
   - ✅ t27 Format
   - ✅ R-SI-1 no-star
   - ✅ RTL & Cocotb
   - ✅ FPGA Synthesis
   - ✅ GDS (if applicable)

5. **Code Review:**
   - At least one approval required
   - Address all review comments
   - Keep PRs focused and small

---

## Coding Standards

### Verilog-2005 Compliance

```verilog
// Good
module datalog_engine_mini (
    input  wire clk,
    input  wire rst_n,
    input  wire [20:0] clause_in,   // 21-bit clause encoding
    input  wire valid_in,
    output wire [3:0]  result_out,
    output wire        valid_out,
    output wire        datalog_ok
);
    // ...
endmodule

// Bad (SystemVerilog)
module datalog_engine_mini (
    input  logic clk,
    input  logic rst_n,
    input  logic [20:0] clause_in,
    input  logic valid_in,
    output logic [3:0]  result_out,
    output logic        valid_out,
    output logic        datalog_ok
);
    // ...
endmodule
```

### R-SI-1 Compliance (No `*` operators)

```verilog
// Wrong (R-SI-1 violation)
wire [15:0] result = a * b;

// Correct (shift-add)
wire [15:0] pp0 = b[0] ? a : 16'b0;
wire [15:0] pp1 = b[1] ? {a, 1'b0} : 16'b0;
wire [15:0] pp2 = b[2] ? {a, 2'b0} : 16'b0;
wire [15:0] pp3 = b[3] ? {a, 3'b0} : 16'b0;
wire [15:0] result = pp0 + pp1 + pp2 + pp3;
```

### Naming Conventions

| Type | Convention | Example |
|------|------------|---------|
| Modules | `lower_snake_case` | `datalog_engine_mini`, `k3_alu` |
| Signals | `lower_snake_case` | `clause_fire`, `fact_mask` |
| Parameters | `UPPER_SNAKE_CASE` | `NUM_CLAUSES`, `NUM_ATOMS` |
| Constants | `lower_snake_case` | `lut_depth`, `nf4_levels` |

---

## Testing Requirements

### Unit Tests

Every CLARA gap module must have a testbench:

```verilog
`default_nettype none
`timescale 1ns / 1ps

module tb_datalog_engine_mini;
    // DUT signals
    reg clk;
    reg rst_n;
    reg [20:0] clause_in;
    reg valid_in;
    wire [3:0] result_out;
    wire valid_out;
    wire datalog_ok;

    // Instantiate DUT
    datalog_engine_mini u_dut (
        .clk(clk),
        .rst_n(rst_n),
        .clause_in(clause_in),
        .valid_in(valid_in),
        .result_out(result_out),
        .valid_out(valid_out),
        .datalog_ok(datalog_ok)
    );

    // Test tracking
    integer pass_count = 0;
    integer fail_count = 0;

    task check;
        input expected;
        input actual;
        input [100*8:1] msg;
        begin
            if (expected === actual) begin
                $display("PASS: %s", msg);
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL: %s (expected=%b, actual=%b)", msg, expected, actual);
                fail_count = fail_count + 1;
            end
        end
    endtask

    initial begin
        $dumpfile("tb_datalog_engine_mini.vcd");
        $dumpvars(0, tb_datalog_engine_mini);

        rst_n = 0;
        #100;
        rst_n = 1;
        #100;

        // Test case 1: Simple forward chain
        // ...

        $display("\n=== SUMMARY ===");
        $display("PASS: %d", pass_count);
        $display("FAIL: %d", fail_count);
        $finish;
    end

endmodule
```

### Integration Tests

For CLARA gap interactions:

```bash
test/tb_integration_clara.v   # All 10 gaps interaction
test/tb_integration_d2d.v     # D2D mesh + CLARA
test/tb_integration_vsa.v     # VSA + CLARA
```

---

## R-SI Compliance

### R-SI-1: Zero `*` operators

```bash
# Check for multiplication operators
grep -n '\*' src/*.v

# Should return empty (or only comments)
```

### R-SI-2 through R-SI-6

See [phi/CONTRIBUTING.md](https://github.com/gHashTag/tt-trinity-phi/blob/main/CONTRIBUTING.md) for full details.

---

## CLARA Gap Guidelines

### Gap-specific requirements:

| Gap | Module | TA | Key Requirements |
|-----|--------|----|------------------|
| Gap-1 | redteam_filter.v | TA1 | Adversarial detection, 5 categories |
| Gap-2 | k3_alu.v | TA1.1 | K3 logic, no SystemVerilog |
| Gap-3 | datalog_engine_mini.v | TA1 | Forward-chain, 16 clauses |
| Gap-4 | restraint_ctrl.v | TA1.4 | Bounded rationality, Q1.15 |
| Gap-5 | explainability_unit.v | TA1.2 | Proof-trace emission |
| Gap-6 | asp_solver_mini.v | TA1.1 | ASP solver with NAF |
| Gap-7 | composition_kernel.v | - | Orchestrator, no `*` |
| Gap-8 | proof_trace_writer.v | - | On-chip audit receipt |
| Gap-9 | sat_solver_mini.v | - | DPLL SAT, 8 vars |
| Gap-10 | audit_log_ring_buffer.v | - | 64-entry event log |

### Documentation requirements:

For each CLARA gap, document in `CLARA_TRACEABILITY.md`:
- Gap number and TA mapping
- Module implementation
- Test coverage
- Falsifiability witnesses
- Coq proofs (if applicable)

---

## Resources

- [Architecture](docs/ARCHITECTURE.md)
- [CLARA Traceability](CLARA_TRACEABILITY.md)
- [API Documentation](docs/API.md)
- [Troubleshooting Guide](docs/TROUBLESHOOTING.md)
- [Hardware Bring-Up](docs/HARDWARE_BRINGUP.md)
- [DARPA CLARA Program](https://www.darpa.mil/research/programs/clara)

---

## License

By contributing, you agree that your contributions will be licensed under the **Apache-2.0** license.

---

## Contact

- GitHub Issues: https://github.com/gHashTag/tt-trinity-euler/issues
- Discussions: https://github.com/gHashTag/tt-trinity-euler/discussions