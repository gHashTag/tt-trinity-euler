# Issue pack — TRI-NET 2026 Scientific Improvement Plan (e-engine)

This directory holds the EPIC and 16 child issue drafts for the TRI-NET
2026 plan, e-engine view. Plan source is
[`docs/SCIENTIFIC_IMPROVEMENT_PLAN.md`](../../docs/SCIENTIFIC_IMPROVEMENT_PLAN.md).

## ID convention (read this first)

The numeric prefix on every file in this directory (`00_`, `01_`, …,
`16_`) is a **local plan ID** that pairs 1-to-1 with the SIP row. It is
**not a GitHub issue number**. No GitHub issue exists for any of these
files until [`create_issues.sh`](create_issues.sh) is run with `--apply`
and `gh issue create` returns a real URL.

This is the R5-honest convention: the repo never claims an issue exists
before GitHub actually assigns a number.

## File index

| Local ID | File | Track | SIP § | Subject |
|---|---|---|---|---|
| `#0`  | [`00_EPIC_2026.md`](00_EPIC_2026.md) | EPIC | overall | TRI-NET 2026 plan EPIC (e-engine) |
| `#1`  | [`01_CL-01_d2d-restraint-hold-rtl.md`](01_CL-01_d2d-restraint-hold-rtl.md) | CL | §2 CL-01 | D2D `RESTRAINT_HOLD` SPEC-DRAFT → RTL |
| `#2`  | [`02_CL-02_clara-proof-status-sweep.md`](02_CL-02_clara-proof-status-sweep.md) | CL | §2 CL-02 | CLARA proof-status sweep |
| `#3`  | [`03_CL-03_host-evidence-reader.md`](03_CL-03_host-evidence-reader.md) | CL | §2 CL-03 | Minimal `host/` evidence reader |
| `#4`  | [`04_CL-04_formal-cross-walk.md`](04_CL-04_formal-cross-walk.md) | CL | §2 CL-04 | Formal cross-walk annotation |
| `#5`  | [`05_EN-01_rbb-rtl.md`](05_EN-01_rbb-rtl.md) | EN | §3 EN-01 | `src/rbb_active_path.v` |
| `#6`  | [`06_EN-02_cross-deck-exclusivity.md`](06_EN-02_cross-deck-exclusivity.md) | EN | §3 EN-02 | Cross-deck exclusivity assertion |
| `#7`  | [`07_EN-03_tops-w-projection-back-link.md`](07_EN-03_tops-w-projection-back-link.md) | EN | §3 EN-03 | TOPS/W back-link audit |
| `#8`  | [`08_SN-01_nmse-harness.md`](08_SN-01_nmse-harness.md) | SN | §4 SN-01 | NMSE harness + first JSON record |
| `#9`  | [`09_SN-02_spike-summary-rx-rtl.md`](09_SN-02_spike-summary-rx-rtl.md) | SN | §4 SN-02 | D2D `SPIKE_SUMMARY` RX counter |
| `#10` | [`10_SN-03_restraint-hold-d2d-frame.md`](10_SN-03_restraint-hold-d2d-frame.md) | SN | §4 SN-03 | Restraint back-pressure as D2D frame |
| `#11` | [`11_PUB-01_workshop-paper-evidence-path.md`](11_PUB-01_workshop-paper-evidence-path.md) | PUB | §5 PUB-01 | Workshop paper on evidence path |
| `#12` | [`12_PUB-02_nmse-protocol-note.md`](12_PUB-02_nmse-protocol-note.md) | PUB | §5 PUB-02 | NMSE protocol note |
| `#13` | [`13_PUB-03_tri-net-line-note.md`](13_PUB-03_tri-net-line-note.md) | PUB | §5 PUB-03 | TRI-NET line note (cross-repo) |
| `#14` | [`14_OS-01_apache-r-si-6-maintain.md`](14_OS-01_apache-r-si-6-maintain.md) | OS | §6 OS-01 | Apache-2.0 + R-SI-6 maintenance |
| `#15` | [`15_OS-02_make-check-one-liner.md`](15_OS-02_make-check-one-liner.md) | OS | §6 OS-02 | `make check` one-liner |
| `#16` | [`16_OS-03_contributing-md.md`](16_OS-03_contributing-md.md) | OS | §6 OS-03 | `CONTRIBUTING.md` |

## How to file as real GitHub issues

```bash
# Dry-run (default, read-only — see what would be filed):
./.github/issues/create_issues.sh --dry-run

# Apply (actually create issues — idempotent, skips duplicates by title):
./.github/issues/create_issues.sh --apply
```

The script:

- Is **read-only by default** (`--dry-run` implied).
- Checks GitHub for an OPEN issue with the same title before each
  creation; skips if it already exists. Idempotent and safe to re-run.
- Never closes, edits, or deletes anything.
- Never modifies CI workflows.
- Returns non-zero if any `gh issue create` failed.

## Honesty contract

- No GitHub issue number is claimed by any file here until `gh issue
  create` returns one.
- No row in [STATUS.md](../../STATUS.md) or
  [BENCHMARKS.md](../../BENCHMARKS.md) is promoted by filing an issue.
- Every child issue carries an explicit **Non-claims** block restating
  the relevant anti-claim (no funding, no silicon date, no `1000×` /
  `4000 TOPS/W` as fact, no paper acceptance, no new DOI, no measured
  promotion).
