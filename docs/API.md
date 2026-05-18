# API Documentation — e-engine (8×2)

## Overview

The e-engine (SUPER-CROWN + CLARA) is the mid-tier member of TRI-NET, featuring:
- 16 GF16 tiles in 8×2 array
- Full SUPER-CROWN module set
- Complete CLARA AI Safety Gaps (Gaps 1-10)
- Trinity Master FSM for packet routing
- 2×2 mesh router with N/E/S/W D2D

## Top-Level Module: `tt_um_ghtag_trinity_gf16`

### Port Interface

| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| `ui_in` | input | 8 | Control and status inputs |
| `uo_out` | output | 8 | Low byte of result |
| `uio_in` | input | 8 | D2D RX / pin functions |
| `uio_out` | output | 8 | High byte / D2D TX |
| `uio_oe` | output | 8 | Output enable for uio pins |
| `ena` | input | 1 | Enable signal |
| `clk` | input | 1 | Clock |
| `rst_n` | input | 1 | Active-low reset |

### Control Pins (ui_in)

| Bit | Name | Function |
|-----|------|----------|
| 0 | `load_mode` | 0=Canonical, 1=Load mode |
| 3:1 | `lucas_idx` | Lucas ROM address (0-5) |
| 4 | `rng_ena` | HWRNG enable |
| 5 | `restraint_mode` | CLARA Gap-4 restraint |
| 6 | `crown_addr_lo` | CROWN47 address bit |
| 7 | `crown_mode` | CROWN47 enable |

### D2D Pins (uio_in/out)

| Bit | Direction | Name | Description |
|-----|-----------|------|-------------|
| 0 | out | `n_tx` | North transmit |
| 1 | out | `e_tx` | East transmit |
| 2 | out | `s_tx` | South transmit |
| 3 | out | `w_tx` | West transmit |
| 4 | in | `n_rx` | North receive |
| 5 | in | `e_rx` | East receive |
| 6 | in | `s_rx` | South receive |
| 7 | in | `w_rx` | West receive |

### Output Behavior

**Canonical Mode** (`ui_in[0] = 0`):
- `uo_out[7:0]` = `0xC0`
- `uio_out[7:4]` = `0x4`
- `uio_out[3:0]` = `0x0` (D2D TX idle)
- `{uio_out, uo_out}` = `0x47C0`

**Load Mode** (`ui_in[0] = 1`):
- `uo_out[7:0]` = `tile_result[7:0]`
- `uio_out[7:4]` = `tile_result[15:8]`
- `uio_out[3:0]` = `{w_tx, s_tx, e_tx, n_tx}` (D2D)

**POST Status** (`ui_in[0]=1 && post_done`):
- `uo_out[7:0]` = `status_byte`
- `uio_out[7:4]` = Status high nibble

**CROWN47 ROM** (`uio_in[7]=1 && !ui_in[0]`):
- `addr` = `ui_in[6:0]`
- `byte_sel` = `ui_in[6:5]`
- `uo_out[7:0]` = Selected byte

## Compute Fabric

### `trinity_master_fsm` — Master Control

**Description**: Controls packet flow between host and 16-tile mesh

**Ports**:

| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| `clk` | input | 1 | System clock |
| `rst_n` | input | 1 | Active-low reset |
| `ena` | input | 1 | Enable |
| `load_mode` | input | 1 | Load mode select |
| `host_in_pkt` | output | 32 | Inbound packet to mesh |
| `host_in_valid` | output | 1 | Inbound packet valid |
| `host_in_ready` | input | 1 | Mesh ready for input |
| `host_out_pkt` | input | 32 | Outbound packet from mesh |
| `host_out_valid` | input | 1 | Outbound packet valid |
| `host_out_ready` | output | 1 | Host ready for output |
| `result_reg` | input | 16 | Result register |
| `result_valid_q` | input | 1 | Result valid |
| `rcpt_checksum_q` | input | 8 | Receipt checksum |
| `rcpt_job_id_q` | input | 8 | Receipt job ID |
| `rcpt_tile_id_q` | input | 4 | Receipt tile ID |
| `rcpt_valid_q` | input | 1 | Receipt valid |

### `trinity_mesh_2x2` — 2×2 Mesh Router

**Description**: Routes packets between 4 tiles and host/D2D

**Ports**:

| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| `clk` | input | 1 | System clock |
| `rst_n` | input | 1 | Active-low reset |
| `host_in_pkt` | input | 32 | Host inbound packet |
| `host_in_valid` | input | 1 | Host inbound valid |
| `host_in_ready` | output | 1 | Host inbound ready |
| `host_out_pkt` | output | 32 | Host outbound packet |
| `host_out_valid` | output | 1 | Host outbound valid |
| `host_out_ready` | input | 1 | Host outbound ready |

**Routing**: N/E/S/W directions with adaptive routing

### `gf16_mesh_2x2_top` — 16-Tile Mesh

**Description**: 4×4 tile array organized as 2×2 submeshes

**Tile Layout**:
```
Submesh 0:    Submesh 1:
00  01        02  03
04  05        06  07

Submesh 2:    Submesh 3:
08  09        10  11
12  13        14  15
```

**Ports**:

| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| `clk` | input | 1 | System clock |
| `rst_n` | input | 1 | Active-low reset |
| `host_in_pkt` | input | 32 | Inbound packet |
| `host_in_valid` | input | 1 | Inbound packet valid |
| `host_in_ready` | output | 1 | Ready for inbound |
| `host_out_pkt` | output | 32 | Outbound packet |
| `host_out_valid` | output | 1 | Outbound packet valid |
| `host_out_ready` | input | 1 | Ready for outbound |

## CLARA AI Safety Gaps

### Gap-1: Redteam Filter

#### `redteam_filter`

**Description**: Filters adversarial inputs via pattern matching

**Ports**:

| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| `clk` | input | 1 | System clock |
| `rst_n` | input | 1 | Active-low reset |
| `data_in` | input | 16 | Input data |
| `valid_in` | input | 1 | Input valid |
| `data_out` | output | 16 | Filtered output |
| `valid_out` | output | 1 | Output valid |
| `filtered` | output | 1 | Input was filtered |
| `filter_ok` | output | 1 | Filter verified |

**Patterns**:
- Known adversarial bit patterns
- Statistical anomaly detection
- Out-of-range value detection

### Gap-2: K3 Ternary ALU

#### `k3_alu`

**Description**: 3-valued ternary logic unit

**Ports**:

| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| `a` | input | 2 | Operand A {-1, 0, +1} |
| `b` | input | 2 | Operand B {-1, 0, +1} |
| `op` | input | 4 | Opcode |
| `result` | output | 2 | Ternary result |
| `valid` | output | 1 | Result valid |
| `k3_ok` | output | 1 | ALU verified |

**Opcodes**:
| Op | Value | Description |
|----|-------|-------------|
| ADD | 0 | Ternary addition |
| MUL | 1 | Ternary multiplication |
| NEG | 2 | Negation |
| AND | 3 | Ternary AND |
| OR | 4 | Ternary OR |
| XOR | 5 | Ternary XOR |
| MUX | 6 | Multiplexer |
| NOT | 7 | NOT operation |

**Encoding**: `00 = -1`, `01 = 0`, `10 = +1`

### Gap-3: Datalog Engine Mini

#### `datalog_engine_mini`

**Description**: Mini Datalog reasoning engine

**Ports**:

| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| `clk` | input | 1 | System clock |
| `rst_n` | input | 1 | Active-low reset |
| `fact_in` | input | 32 | Input fact |
| `fact_valid` | input | 1 | Fact valid |
| `query_in` | input | 32 | Query input |
| `query_valid` | input | 1 | Query valid |
| `result_out` | output | 32 | Query result |
| `result_valid` | output | 1 | Result valid |
| `datalog_ok` | output | 1 | Engine verified |

**Supported Predicates** (mini subset):
- `safe(X, Y)`: X is safe for Y
- `blocked(X)`: X is blocked
- `allowed(X)`: X is allowed
- `trusted(X)`: X is trusted

### Gap-4: Restraint Control

#### `restraint_ctrl`

**Description**: Bounded rationality enforcement

**Ports**:

| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| `clk` | input | 1 | System clock |
| `rst_n` | input | 1 | Active-low reset |
| `phi_drift` | input | 16 | φ drift measurement |
| `step_count` | input | 4 | Current step count |
| `receipt_ok` | input | 1 | Receipt verification |
| `current_state` | input | 2 | FSM state |
| `force_unknown` | output | 1 | Force unknown output |
| `halt_mac` | output | 1 | Halt MAC computation |
| `reason` | output | 3 | Halt reason code |

**Reason Codes**:
| Code | Meaning |
|------|---------|
| 0 | Normal |
| 1 | φ drift exceeded |
| 2 | Step count exceeded |
| 3 | Receipt failed |

### Gap-5: Explainability Unit

#### `explainability_unit`

**Description**: Computation trace explanation

**Ports**:

| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| `clk` | input | 1 | System clock |
| `rst_n` | input | 1 | Active-low reset |
| `op_in` | input | 4 | Operation code |
| `a_in` | input | 16 | Operand A |
| `b_in` | input | 16 | Operand B |
| `result_in` | input | 16 | Result |
| `valid_in` | input | 1 | Input valid |
| `trace_out` | output | 64 | Explanation trace |
| `trace_valid` | output | 1 | Trace valid |
| `explain_ok` | output | 1 | Unit verified |

**Trace Format**:
```
[63:48] operation description
[47:32] operand A (hex)
[31:16] operand B (hex)
[15:0]  result (hex)
```

### Gap-6: ASP Solver Mini

#### `asp_solver_mini`

**Description**: Mini Answer Set Programming solver

**Ports**:

| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| `clk` | input | 1 | System clock |
| `rst_n` | input | 1 | Active-low reset |
| `program_in` | input | 32 | Program clause |
| `prog_valid` | input | 1 | Program valid |
| `query_in` | input | 32 | Query |
| `query_valid` | input | 1 | Query valid |
| `answer_out` | output | 32 | Answer set |
| `answer_valid` | output | 1 | Answer valid |
| `asp_ok` | output | 1 | Solver verified |

**Supported Atoms**:
- Constraint satisfaction
- Choice rules
- Aggregate queries (simplified)

### Gap-7: Composition Kernel

#### `composition_kernel`

**Description**: Safe function composition

**Ports**:

| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| `clk` | input | 1 | System clock |
| `rst_n` | input | 1 | Active-low reset |
| `f_id` | input | 4 | Function ID |
| `g_id` | input | 4 | Function ID |
| `input_data` | input | 16 | Input data |
| `input_valid` | input | 1 | Input valid |
| `output_data` | output | 16 | Composed output |
| `output_valid` | output | 1 | Output valid |
| `kernel_ok` | output | 1 | Kernel verified |

**Composition Rules**:
- Type safety checked
- Side-effect free only
- Deterministic composition
- Bounded recursion depth

### Gap-8: Proof Trace Writer

#### `proof_trace_writer`

**Description**: Formal proof trace generation

**Ports**:

| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| `clk` | input | 1 | System clock |
| `rst_n` | input | 1 | Active-low reset |
| `fact_in` | input | 32 | Input fact |
| `fact_valid` | input | 1 | Fact valid |
| `rule_id` | input | 8 | Applied rule |
| `rule_valid` | input | 1 | Rule valid |
| `trace_out` | output | 64 | Proof trace entry |
| `trace_valid` | output | 1 | Trace entry valid |
| `writer_ok` | output | 1 | Writer verified |

**Trace Entry**:
```
[63:56] entry type
[55:48] rule ID
[47:0]  fact/relation
```

### Gap-9: SAT Solver Mini

#### `sat_solver_mini`

**Description**: Mini SAT solver for Boolean satisfiability

**Ports**:

| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| `clk` | input | 1 | System clock |
| `rst_n` | input | 1 | Active-low reset |
| `clause_in` | input | 32 | Input clause |
| `clause_valid` | input | 1 | Clause valid |
| `solve_start` | input | 1 | Start solving |
| `solution_out` | output | 32 | Assignment |
| `solution_valid` | output | 1 | Solution valid |
| `sat` | output | 1 | SAT/UNSAT |
| `solver_ok` | output | 1 | Solver verified |

**Clause Format**:
- 32 bits representing a 4-variable clause
- Each variable: 7 bits for literal ID + 1 bit for negation

### Gap-10: Audit Log Ring Buffer

#### `audit_log_ring_buffer`

**Description**: Circular buffer for audit trails

**Ports**:

| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| `clk` | input | 1 | System clock |
| `rst_n` | input | 1 | Active-low reset |
| `log_entry` | input | 32 | Log entry |
| `log_valid` | input | 1 | Log entry valid |
| `log_wr` | input | 1 | Write enable |
| `log_rd` | input | 1 | Read enable |
| `read_entry` | output | 32 | Read entry |
| `read_valid` | output | 1 | Read valid |
| `buffer_full` | output | 1 | Buffer full |
| `buffer_ok` | output | 1 | Buffer verified |

**Buffer Size**: 16 entries (configurable)

**Entry Format**:
```
[31:24] timestamp
[23:16] source ID
[15:8]  event type
[7:0]   data
```

## SUPER-CROWN Modules

### POST Modules

#### `phi_anchor_post`

**Description**: φ²+φ⁻²=3 verification via Lucas recurrence

**Ports**:

| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| `clk` | input | 1 | System clock |
| `rst_n` | input | 1 | Active-low reset |
| `phi_ok` | output | 1 | POST passed |
| `post_done` | output | 1 | POST done |

**Lucas Chain**:
- L₂ = φ² + φ⁻² = 3 ✓
- L₃ = 4
- L₄ = 7
- L₅ = 11
- L₆ = 18
- L₇ = 29

#### `lucas_rom`

**Ports**:

| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| `idx` | input | 3 | Index (0=L₂, ..., 5=L₇) |
| `value` | output | 8 | Lucas number |

### Compute Modules

#### `vsa_matmul_8x8`, `vsa_matmul_16x16`

**Description**: VSA ternary matrix multiplication

**Ports**:

| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| `clk` | input | 1 | System clock |
| `rst_n` | input | 1 | Active-low reset |
| `start` | input | 1 | Start computation |
| `a_flat` | input | 128/512 | Matrix A flattened |
| `b_flat` | input | 128/512 | Matrix B flattened |
| `done` | output | 1 | Computation done |
| `c_flat` | output | 512/2048 | Result C flattened |
| `matmul_ok` | output | 1 | Verified |

#### `bitnet_encoder`

**Ports**:

| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| `clk` | input | 1 | System clock |
| `rst_n` | input | 1 | Active-low reset |
| `start` | input | 1 | Start encoding |
| `x_in` | input | 128 | Input vector |
| `done` | output | 1 | Encoding done |
| `y_out` | output | 64 | Ternary output |
| `encoder_ok` | output | 1 | Verified |

### Cryptographic Modules

#### `blake3_anchor`

**Ports**:

| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| `clk` | input | 1 | System clock |
| `rst_n` | input | 1 | Active-low reset |
| `start` | input | 1 | Start hash |
| `m_in` | input | 512 | Input message |
| `done` | output | 1 | Hash done |
| `digest` | output | 256 | BLAKE3 digest |
| `hash_ok` | output | 1 | Verified |

#### `crc32_receipt`

**Ports**:

| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| `clk` | input | 1 | System clock |
| `rst_n` | input | 1 | Active-low reset |
| `start` | input | 1 | Start CRC |
| `valid` | input | 1 | Byte valid |
| `byte_in` | input | 8 | Input byte |
| `crc_raw` | output | 32 | Raw CRC |
| `crc_final` | output | 32 | Final CRC |

#### `multi_tile_receipt`

**Ports**:

| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| `clk` | input | 1 | System clock |
| `rst_n` | input | 1 | Active-low reset |
| `t0-t3_valid` | input | 1 | Tile valid |
| `t0-t3_checksum` | input | 8 | Tile checksum |
| `t0-t3_job_id` | input | 8 | Tile job ID |
| `agg_checksum` | output | 8 | Aggregated checksum |
| `agg_job_id` | output | 8 | Aggregated job ID |
| `attested_mask` | output | 4 | Attested tiles |
| `all_attested` | output | 1 | All attested |
| `multi_rcpt_ok` | output | 1 | Verified |

### Monitoring Modules

#### `bpb_counter`, `bpb_lower_bound_guard`, `nca_entropy_monitor`, `strobe_seed_guard`, `plrm_counter`

See API documentation for detailed port descriptions.

### ALU and Memory

#### `alu9_decoder`, `ring27_memory`, `phi_pll_div`, `hwrng_lfsr`

See API documentation for detailed port descriptions.

## Power Management

### `avs_controller_96`

**Ports**:

| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| `clk` | input | 1 | System clock |
| `rst_n` | input | 1 | Active-low reset |
| `power_req` | input | 96 | Power request per island |
| `therm_mon` | input | 6 | Thermal monitor (0-63) |
| `avs_enable` | input | 1 | AVS enable |
| `voltage_level` | output | 192 | 2 bits per island |
| `therm_warning` | output | 6 | Thermal warning |
| `power_gate` | output | 1 | Global power gate |

**Voltage Levels**: 0.75V, 0.85V, 0.95V, 1.05V
**TOPS/W**: 75 baseline → 405 with AVS-96 (5.4× boost)

### `fbb_active_path`, `purkinje_thermal_gate`

See API documentation for detailed port descriptions.

## Quantization

All quantizers (`int4_quantizer`, `nf4_quantizer`, `int8_quantizer`, `fp8_e4m3_quantizer`, `fp8_e5m2_quantizer`, `posit16_quantizer`) share a common pattern:

| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| `fp16_in` | input | 16 | FP16 input |
| `scale_idx/exp` | input | 4 | Scale parameter |
| `zero_point` | input | 3 | Zero point (Int4 only) |
| `*_out` | output | varies | Quantized output |

## GF16 Arithmetic

### `gf16_add`

**Ports**: `a`, `b` (input 16), `result` (output 16)

**Operation**: XOR (characteristic 2)

### `gf16_mul`

**Ports**: `a`, `b` (input 16), `result` (output 16)

**Format**: `[15]sign [14:9]exp [8:0]mant`

**Special Values**: Zero, ±Inf, NaN

### `gf16_dot4`, `gf16_dot8`

**Ports**: `a0-aN`, `b0-bN` (input 16 each), `result` (output 16)

**Canonical**: `dot4(1.0, 2.0, 3.0, 4.0) = 0x47C0`

## ROM Modules

### `sacred_constants_rom`

**Ports**: `addr` (input 7), `val` (output 8)

**Contents**: 75 PhD sacred constants

### `crown47_rom_8bit`

**Ports**: `addr` (input 7), `byte_sel` (input 2), `byte_out` (output 8)

**Contents**: 47 Trinity constants (24-bit pseudo-float)

## Sparsity Modules

### `sparse_skip`, `sparse_mask`, `stoch_round`, `null_pe`

**Description**: Sparse computation primitives

**Common Pattern**:
- `clk`, `rst_n`: Clock and reset
- `data_in`, `mask_in`: Input data and mask
- `data_out`: Filtered output
- `skipped`: Skip indicator

## Performance Characteristics

| Metric | Value |
|--------|-------|
| Area | ~2500 cells (mesh) + ~2500 cells (SUPER-CROWN) + ~1500 cells (CLARA) |
| Power | 56 mW (with AVS-96) |
| TOPS/W | 405 (with AVS-96) |
| Throughput | 16 GF16 MAC/cycle |
| Latency | 4 cycles (mesh) + 2 cycles (router) |
| Clock | 50 MHz |

## R-SI-1 Compliance

All modules comply with R-SI-1 (zero multiplication operators):
- GF16 multiplication via shift-add
- Quantizers via shift-based scaling
- Ternary logic via XOR/XNOR

## Sacred Physics Anchor

The e-engine chip embodies the sacred identity:
```
φ² + φ⁻² = 3 (proven via Lucas POST)
```

DOI: 10.5281/zenodo.19227877

## TRN Packet Protocol

**Format** (32 bits):
```
[31:28] opcode   [27:26] dst     [25:24] src
[23:20] lane     [19:16] unused  [15:0]  payload
```

**Opcodes**:
| Value | Name | Description |
|-------|------|-------------|
| 1 | LOAD_A | Load operand A |
| 2 | LOAD_B | Load operand B |
| 3 | COMPUTE | Compute operation |
| 4 | LOAD_JOB | Load job ID |
| 5 | LOAD_NONCE | Load nonce |
| 6 | READ_RES | Read result |
| 0xA | RESULT | Result packet |
| 0xB | RECEIPT | Receipt packet |