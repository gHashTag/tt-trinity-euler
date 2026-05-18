# Triple-Decker State Machine — RBB → FBB → CAP_BOOST → IDLE

**Document ID:** TRINITY-TRIPLEDECK-FSM-V0.1
**Status:** SPEC-DRAFT — state machine spec; no dedicated FSM RTL module
exists yet, the named transitions live across `fbb_active_path.v`,
`avs_controller_96.v`, `purkinje_thermal_gate.v`, and `restraint_ctrl.v`.
**Last updated:** 2026-05-18
**Scope:** TRI-1 Euler (this repo).
**Companion docs:** [`docs/TRIPLE_DECK_STATUS.md`](TRIPLE_DECK_STATUS.md),
[`docs/PROJECTIONS_22FDX.md`](PROJECTIONS_22FDX.md),
[`docs/VERIFICATION_CLAIMS_MATRIX.md`](VERIFICATION_CLAIMS_MATRIX.md),
[`docs/HARDWARE-IMPLEMENTATION.md`](HARDWARE-IMPLEMENTATION.md)

> **R5-Honesty contract.** No transition in this document has been
> exercised on silicon. The Coq spec covers per-deck behaviour but not the
> composed FSM. Promotion of any row from `SPEC-DRAFT` to `RTL` or higher
> requires (i) a dedicated `src/triple_deck_fsm.v` (or equivalent), (ii) a
> testbench under `sim/` or `test/`, and (iii) a row update in
> [`docs/VERIFICATION_CLAIMS_MATRIX.md`](VERIFICATION_CLAIMS_MATRIX.md)
> claim `VCM-DECK-FSM-001`.

---

## 1. States

| State | Encoding | Meaning | Owner module (today) |
|---|---|---|---|
| `IDLE`       | `2'b00` | No active compute; leakage-dominant; RBB **may** be applied | (Deck 1 has no RTL yet — leakage is partially controlled by [`src/drowsy_ret.v`](../src/drowsy_ret.v) + [`src/subth_clk.v`](../src/subth_clk.v)) |
| `RBB`        | `2'b01` | Idle / standby, Reverse Body Bias applied to raise Vth | spec-only, opcode `0xF1` per [`trios-coq/Physics/RBB.v`](../trios-coq/Physics/RBB.v) |
| `FBB`        | `2'b10` | Active compute path, Forward Body Bias lowers Vth | [`src/fbb_active_path.v`](../src/fbb_active_path.v) |
| `CAP_BOOST`  | `2'b11` | Peak / burst window, AVS-96 lifts island voltage | [`src/avs_controller_96.v`](../src/avs_controller_96.v) |

The state set is **exhaustive**. At any cycle the chip is in exactly one
state. This is the cross-deck exclusivity contract (see
[`docs/TRIPLE_DECK_STATUS.md`](TRIPLE_DECK_STATUS.md) §4.3 — claim
`VCM-DECK-EXC-001`).

---

## 2. Transitions

```
            ┌────────────────────────────────────────────────────────────┐
            │                                                            │
            ▼                                                            │
     ┌────────────┐ workload_request &           ┌───────────────┐       │
     │   IDLE     │ ─────────────────────────────▶│  RBB (idle)   │      │
     │            │ idle_dwell_expired           │  leakage min  │      │
     └────────────┘ (returns when ready_for_FBB) └───────────────┘       │
            ▲                                       │                    │
            │ idle_dwell_expired & no_workload      │ workload_active    │
            │                                       ▼                    │
            │                              ┌────────────────────┐        │
            │                              │  FBB (active)      │        │
            │                              │  Vth lowered       │        │
            │                              └────────────────────┘        │
            │                                       │                    │
            │ workload_done & cooldown_ok           │ burst_request &    │
            │                                       │ headroom_ok &      │
            │                                       │ thermal_ok &       │
            │                                       │ restraint_clear    │
            │                                       ▼                    │
            │                              ┌────────────────────┐        │
            │                              │  CAP_BOOST (peak)  │        │
            │                              │  AVS-96 lifts V    │        │
            │                              └────────────────────┘        │
            │                                       │                    │
            │ burst_window_expired                  │                    │
            └───────────────────────────────────────┘                    │
                                                                         │
   ┌─────────────────────────────────────────────────────────────────────┘
   │
   │ FAULT FALLBACK (any state → IDLE):
   │   brownout_detected | overcurrent_detected | thermal_red_zone | restraint_hold_asserted
   ▼
 (IDLE, with cooldown_timer started)
```

### 2.1 Transition table

Each row is a guarded transition. Multiple guards on a row are conjunctive
(AND); rows are evaluated in order.

| # | From | Event / Guard | To | Action | Cooldown |
|---|---|---|---|---|---|
| T1 | `IDLE`      | `workload_request && !restraint_hold` | `RBB`        | clear `cooldown_ctr`; enter leakage-min profile | n/a |
| T2 | `RBB`       | `workload_active && !restraint_hold` | `FBB`        | bias `fbb_active_path` to `FBB_LOW` then ramp to `FBB_MED` | n/a |
| T3 | `RBB`       | `idle_dwell_expired && !workload_active` | `IDLE`     | release RBB | n/a |
| T4 | `FBB`       | `burst_request && avs_headroom_ok && thermal_green && !restraint_hold` | `CAP_BOOST` | request AVS-96 lift; record `burst_start` epoch | n/a |
| T5 | `FBB`       | `workload_done && cooldown_ok`        | `IDLE`       | release FBB; start `cooldown_ctr` | start |
| T6 | `CAP_BOOST` | `burst_window_expired`                | `FBB`        | drop AVS-96 lift; keep `FBB_MED` | n/a |
| T7 | `CAP_BOOST` | `thermal_yellow_zone`                 | `FBB`        | drop AVS-96 lift; log `THERM_THROTTLE` row | n/a |
| T8 | any         | `brownout_detected`                   | `IDLE`       | force-release all biases; assert `RESTRAINT_HOLD` (D2D kind `0x4`); start `cooldown_ctr=CD_MAX` | force |
| T9 | any         | `overcurrent_detected`                | `IDLE`       | force-release all biases; assert `RESTRAINT_HOLD`; start `cooldown_ctr=CD_MAX` | force |
| T10 | any        | `thermal_red_zone`                    | `IDLE`       | force-release all biases; assert `RESTRAINT_HOLD`; start `cooldown_ctr=CD_MAX` | force |
| T11 | any        | `restraint_hold_asserted` (from D2D or local) | `IDLE` | force-release all biases; remain in `IDLE` until `restraint_clear` | start |

### 2.2 Guard definitions (informative)

| Guard | Defined by | Notes |
|---|---|---|
| `workload_request` | scheduler / control-engine | rising edge from the host queue |
| `workload_active`  | derived from active-path PE valids | high when at least one PE in the tile mesh is consuming operands |
| `workload_done`    | scheduler | falling edge of `workload_active` debounced ≥ `DEBOUNCE_CYC` |
| `burst_request`    | scheduler | opt-in opcode `0xF3` (CAP_BOOST request) |
| `avs_headroom_ok`  | `avs_controller_96` | at least one island can be lifted without exceeding the per-rail budget |
| `thermal_green` / `thermal_yellow_zone` / `thermal_red_zone` | [`src/purkinje_thermal_gate.v`](../src/purkinje_thermal_gate.v) | three-level thermal classifier |
| `restraint_hold` / `restraint_clear` | [`src/restraint_ctrl.v`](../src/restraint_ctrl.v) | sourced from local audit or from incoming D2D kind `0x4` |
| `brownout_detected` | external sense (`uio[*]`) or POR | latched until `cooldown_ctr` expires |
| `overcurrent_detected` | external sense | latched until `cooldown_ctr` expires |
| `idle_dwell_expired` | `idle_dwell_ctr` reaches `IDLE_DWELL_MAX` | parameter, default 2048 cycles |
| `burst_window_expired` | `burst_ctr` reaches `BURST_WINDOW_MAX` | parameter, default 4096 cycles |
| `cooldown_ok` | `cooldown_ctr` reaches 0 | parameter, default `CD_MAX = 8192` cycles |

### 2.3 Exclusivity invariants

These invariants must hold at all cycles. They are the C3 promotion gate
in [`docs/TRIPLE_DECK_STATUS.md`](TRIPLE_DECK_STATUS.md) §4.1 and are
indexed by claim `VCM-DECK-EXC-001`:

- **INV-EXC-1:** `RBB ∧ FBB = ∅` — no path is reverse-biased and forward-
  biased simultaneously.
- **INV-EXC-2:** `FBB ∧ CAP_BOOST` is **only** legal because `CAP_BOOST` is
  defined as "FBB + AVS lift on the active island." Outside of
  `CAP_BOOST`, AVS-96 MUST NOT lift voltage above the FBB rail.
- **INV-EXC-3:** `restraint_hold ⇒ state = IDLE`. Any non-IDLE state with
  `restraint_hold` asserted is an FSM bug.
- **INV-EXC-4:** `brownout ∨ overcurrent ∨ thermal_red ⇒ state = IDLE`
  within ≤ 1 cycle.

---

## 3. Cooldown and fault fallback

### 3.1 Cooldown semantics

`cooldown_ctr` is a parameterised down-counter (default `CD_MAX = 8192`
cycles) that gates re-entry into `RBB`/`FBB` after a fault or workload
completion. Behaviour:

- T5 (`FBB → IDLE` after `workload_done`) starts the counter at a "normal"
  value (`CD_NORMAL`, default 1024 cycles).
- T8/T9/T10 (any fault) starts the counter at `CD_MAX` (default 8192
  cycles).
- T1 (`IDLE → RBB`) is gated on `cooldown_ctr == 0`. While `cooldown_ctr >
  0` the FSM remains in `IDLE` regardless of `workload_request`.

### 3.2 Fault fallback

A "fault" is any of: `brownout_detected`, `overcurrent_detected`,
`thermal_red_zone`, or `restraint_hold_asserted`. On fault:

1. Force-release all biases (drop `FBB_*` and `CAP_BOOST` simultaneously).
2. Write a fault row to the audit ring
   ([`src/audit_log_ring_buffer.v`](../src/audit_log_ring_buffer.v)).
3. Emit a `RESTRAINT_HOLD` D2D frame
   ([`docs/D2D_PROTOCOL.md`](D2D_PROTOCOL.md) §4.3 kind `0x4`) for
   ≥ 1 cycle.
4. Enter `IDLE` and start `cooldown_ctr = CD_MAX`.
5. Stay in `IDLE` until `cooldown_ctr == 0` **and** the fault source has
   de-asserted for at least `DEBOUNCE_CYC` cycles (default 64).

### 3.3 Brownout / overcurrent specifics

| Source | Sense | Latch | Recovery |
|---|---|---|---|
| Brownout | Board-level rail sense via `uio[*]` (TBD pin in board layer; see [`docs/PINOUT.md`](PINOUT.md)) | Latched until `cooldown_ctr == 0` | Requires explicit `brownout_clear` strobe from the host |
| Overcurrent | Per-island AVS-96 current monitor | Latched per-island; aggregated by `avs_controller_96` | Requires `cooldown_ctr == 0` and per-island re-arm |
| Thermal red | [`src/purkinje_thermal_gate.v`](../src/purkinje_thermal_gate.v) | Latched until thermal classifier returns to `thermal_green` | Requires `DEBOUNCE_CYC` cycles in `thermal_green` |

---

## 4. Parameters

| Parameter | Default | Range | Notes |
|---|---|---|---|
| `IDLE_DWELL_MAX`  | 2048 | 64..65535 | Cycles in `IDLE` before allowing automatic RBB |
| `BURST_WINDOW_MAX`| 4096 | 64..65535 | Max cycles in `CAP_BOOST` per burst |
| `CD_NORMAL`       | 1024 | 0..65535  | Cooldown after a clean `workload_done` |
| `CD_MAX`          | 8192 | 0..65535  | Cooldown after a fault |
| `DEBOUNCE_CYC`    | 64   | 0..1024   | Debounce for state-change inputs |

All parameters are runtime-set by the host through the existing AVS / restraint
control surface; defaults are spec-only.

---

## 5. Today vs. after the FSM module lands

| Behaviour | Today | After `src/triple_deck_fsm.v` lands |
|---|---|---|
| `IDLE → FBB` triggered by workload | Implicit — FBB level is set by host via `fbb_active_path` opcode | Driven by T1+T2 above |
| `FBB → CAP_BOOST` on burst | Implicit — `avs_controller_96` is independent | Driven by T4 above with explicit guards |
| Brownout fallback to IDLE | Partial — `restraint_ctrl` clamps compute, no unified state | Driven by T8 |
| Cooldown | Not enforced as a single counter | `cooldown_ctr` |
| Cross-deck exclusivity | Partial; relies on host disciplined opcode use | Enforced by FSM encoding |

> **Bottom line:** the FSM described here is a **specification** of the
> compose-of-decks behaviour that already exists in pieces. Promoting any
> row above out of `SPEC-DRAFT` requires the FSM RTL.

---

## 6. Conformance hooks

A conforming Triple-Decker implementation MUST expose:

- A 2-bit `td_state[1:0]` observable (matching the encoding in §1) that
  the audit ring can sample.
- A `td_fault[3:0]` vector with one-hot bits for `BROWNOUT`,
  `OVERCURRENT`, `THERMAL_RED`, `RESTRAINT_HOLD`.
- A `td_cooldown_ctr` readable register.

These signals are the witness for claim `VCM-DECK-FSM-001` in
[`docs/VERIFICATION_CLAIMS_MATRIX.md`](VERIFICATION_CLAIMS_MATRIX.md).

---

## 7. Links

- Per-deck readiness: [`docs/TRIPLE_DECK_STATUS.md`](TRIPLE_DECK_STATUS.md)
- 22FDX projection (depends on this FSM being active): [`docs/PROJECTIONS_22FDX.md`](PROJECTIONS_22FDX.md)
- D2D fault upstream: [`docs/D2D_PROTOCOL.md`](D2D_PROTOCOL.md) §4.3 kind `0x4` + §6
- Coq specs: [`trios-coq/Physics/RBB.v`](../trios-coq/Physics/RBB.v),
  [`trios-coq/Physics/FBBActive.v`](../trios-coq/Physics/FBBActive.v),
  [`trios-coq/Physics/CapBoost.v`](../trios-coq/Physics/CapBoost.v),
  [`trios-coq/Physics/PowerCapping.v`](../trios-coq/Physics/PowerCapping.v)
- Readiness ladder: [STATUS.md](../STATUS.md)
