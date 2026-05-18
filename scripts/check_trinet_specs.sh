#!/usr/bin/env bash
# check_trinet_specs.sh — TRI-NET verification gate
#
# Verifies that:
#   1. docs/VERIFICATION_CLAIMS_MATRIX.md exists and contains rows for every
#      known TRI-NET numerical claim ID (`VCM-*` IDs).
#   2. Each numerical claim referenced in TRI-NET docs maps to a row in the
#      matrix.
#   3. Conformance JSON assets parse as valid JSON.
#   4. (Optional) the `t27c` toolchain is invoked on `specs/numeric/*.t27`
#      if `t27c` is available on PATH. If it is not, the step is skipped
#      and the script does NOT fail.
#
# This script is intentionally portable bash (no rg, no jq required).
# Exits 0 on PASS, 1 on FAIL.

set -u
# Do NOT `set -e` — we want to count failures and report them all.

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MATRIX="${REPO_ROOT}/docs/VERIFICATION_CLAIMS_MATRIX.md"
CONFORMANCE_DIR="${REPO_ROOT}/conformance"
SPECS_NUMERIC_DIR="${REPO_ROOT}/specs/numeric"
TESTS_VECTORS_DIR="${REPO_ROOT}/tests/vectors"

FAIL=0
WARN=0

pass() { printf "  [PASS] %s\n" "$1"; }
fail() { printf "  [FAIL] %s\n" "$1"; FAIL=$((FAIL+1)); }
warn() { printf "  [WARN] %s\n" "$1"; WARN=$((WARN+1)); }
info() { printf "  [INFO] %s\n" "$1"; }
header() { printf "\n==> %s\n" "$1"; }

#
# --- Step 0 — sanity ---------------------------------------------------------
#
header "Step 0: sanity — matrix file"
if [ ! -f "$MATRIX" ]; then
  fail "missing $MATRIX"
else
  pass "found $MATRIX"
fi

#
# --- Step 1 — required claim IDs --------------------------------------------
#
# The set below is the canonical list of claim IDs that must always be present
# in the matrix. Each ID corresponds to a claim referenced from one of the
# TRI-NET docs (D2D, NMSE, Triple-Decker, Projections, etc.).
#
header "Step 1: required claim IDs are present in the matrix"

REQUIRED_IDS=(
  "VCM-GF16-001"
  "VCM-GF16-002"
  "VCM-GF16-003"
  "VCM-NMSE-001"
  "VCM-NMSE-002"
  "VCM-TOPS-001"
  "VCM-TOPS-002"
  "VCM-TOPS-003"
  "VCM-TOPS-004"
  "VCM-TOPS-005"
  "VCM-TILES-001"
  "VCM-FORMATS-001"
  "VCM-PHI-001"
  "VCM-D2D-001"
  "VCM-D2D-002"
  "VCM-D2D-003"
  "VCM-D2D-004"
  "VCM-DECK1-001"
  "VCM-DECK2-001"
  "VCM-DECK3-001"
  "VCM-DECK-EXC-001"
  "VCM-DECK-FSM-001"
  "VCM-DOI-001"
  "VCM-DOI-002"
  "VCM-FUND-001"
  "VCM-FPGA-001"
  "VCM-CLARA-001"
  "VCM-RSI-001"
)

if [ -f "$MATRIX" ]; then
  for id in "${REQUIRED_IDS[@]}"; do
    if grep -Fq "\`${id}\`" "$MATRIX"; then
      pass "matrix contains row for ${id}"
    else
      fail "matrix is missing row for ${id}"
    fi
  done
fi

#
# --- Step 2 — referenced IDs in docs all resolve in the matrix --------------
#
header "Step 2: every VCM-* referenced in docs resolves in the matrix"

if [ -f "$MATRIX" ]; then
  # All VCM-* references anywhere under docs/ + conformance/ + tests/.
  # Canonical form: VCM-<WORD>-<3+ digits>. This pattern intentionally
  # rejects the document-ID prefix "TRINITY-VCM-V0.1".
  REF_IDS=$(grep -RhoE 'VCM-[A-Z0-9]+-[0-9]{3,}' \
    "${REPO_ROOT}/docs" "${CONFORMANCE_DIR}" "${TESTS_VECTORS_DIR}" 2>/dev/null \
    | sort -u || true)

  if [ -z "$REF_IDS" ]; then
    warn "no VCM-* references found under docs/ conformance/ tests/ (expected at least one)"
  else
    for id in $REF_IDS; do
      if grep -Fq "\`${id}\`" "$MATRIX"; then
        pass "${id} resolved"
      else
        fail "${id} referenced in docs but missing from matrix"
      fi
    done
  fi
fi

#
# --- Step 3 — anti-claim coverage -------------------------------------------
#
header "Step 3: repo-wide anti-claims present"

ANTI_CLAIMS=(
  "NO-SILICON"
  "NO-FAKE-DOI"
  "NO-FUNDING"
  "NO-MEASURED-TOPS"
  "NO-MEASURED-NMSE"
)
if [ -f "$MATRIX" ]; then
  for ac in "${ANTI_CLAIMS[@]}"; do
    if grep -Fq "\`${ac}\`" "$MATRIX"; then
      pass "anti-claim ${ac} declared"
    else
      fail "anti-claim ${ac} missing from matrix"
    fi
  done
fi

#
# --- Step 4 — DOI honesty ----------------------------------------------------
#
header "Step 4: only the canonical Zenodo DOI appears in TRI-NET docs"

# Canonical DOI is 10.5281/zenodo.19227877. Anything else cited is a bug.
DOI_HITS=$(grep -RhoE '10\.5281/zenodo\.[0-9]+' "${REPO_ROOT}/docs" 2>/dev/null | sort -u || true)
if [ -z "$DOI_HITS" ]; then
  info "no Zenodo DOI references found under docs/ (acceptable)"
else
  for doi in $DOI_HITS; do
    if [ "$doi" = "10.5281/zenodo.19227877" ]; then
      pass "canonical DOI ${doi}"
    else
      fail "non-canonical Zenodo DOI cited in docs/: ${doi}"
    fi
  done
fi

#
# --- Step 5 — JSON conformance assets parse ---------------------------------
#
header "Step 5: conformance JSON assets parse as JSON"

JSON_FILES=$(find "$CONFORMANCE_DIR" "$TESTS_VECTORS_DIR" -name '*.json' -type f 2>/dev/null | sort)
if [ -z "$JSON_FILES" ]; then
  warn "no JSON files found under conformance/ or tests/vectors/"
else
  # Prefer python3 for JSON validation (universally available on CI runners).
  if command -v python3 >/dev/null 2>&1; then
    for f in $JSON_FILES; do
      if python3 -c "import json,sys; json.load(open(sys.argv[1]))" "$f" >/dev/null 2>&1; then
        rel="${f#${REPO_ROOT}/}"
        pass "valid JSON: ${rel}"
      else
        rel="${f#${REPO_ROOT}/}"
        fail "invalid JSON: ${rel}"
      fi
    done
  else
    warn "python3 unavailable; skipping JSON parse check"
  fi
fi

#
# --- Step 6 — NMSE vector pack: no measured-silicon / no leaked numbers -----
#
header "Step 6: NMSE vector pack honesty"

NMSE_VEC="${TESTS_VECTORS_DIR}/nmse/gf16_vs_bfloat16_v0.json"
if [ -f "$NMSE_VEC" ]; then
  if command -v python3 >/dev/null 2>&1; then
    python3 - "$NMSE_VEC" <<'PY'
import json, sys
p = sys.argv[1]
with open(p) as fh: d = json.load(fh)
ok = True
def fail(msg):
    global ok
    print("    [FAIL] %s" % msg); ok = False
def pas(msg):
    print("    [PASS] %s" % msg)
h = d.get("honesty", {})
if h.get("is_measured_silicon") is not False:
    fail("honesty.is_measured_silicon must be exactly false")
else:
    pas("honesty.is_measured_silicon == false")
if h.get("is_measured_bf16_npu") is not False:
    fail("honesty.is_measured_bf16_npu must be exactly false")
else:
    pas("honesty.is_measured_bf16_npu == false")
sk = d.get("result_skeleton", {})
for k in ("nmse_mean", "nmse_p99", "nmse_db_mean", "canonical_anchor_exact"):
    if sk.get(k) is not None:
        fail("result_skeleton.%s must be null in the vector pack (results live in sim/nmse/, not here)" % k)
    else:
        pas("result_skeleton.%s is null" % k)
sys.exit(0 if ok else 1)
PY
    if [ $? -ne 0 ]; then
      FAIL=$((FAIL+1))
    fi
  else
    warn "python3 unavailable; skipping NMSE honesty check"
  fi
else
  fail "missing NMSE golden vector pack at ${NMSE_VEC#${REPO_ROOT}/}"
fi

#
# --- Step 7 — Triple-Decker FSM states present ------------------------------
#
header "Step 7: Triple-Decker FSM lists all four named states"

FSM_DOC="${REPO_ROOT}/docs/TRIPLE_DECK_STATE_MACHINE.md"
if [ ! -f "$FSM_DOC" ]; then
  fail "missing $FSM_DOC"
else
  for s in IDLE RBB FBB CAP_BOOST; do
    if grep -Fq "\`${s}\`" "$FSM_DOC"; then
      pass "state ${s} present in FSM doc"
    else
      fail "state ${s} missing from FSM doc"
    fi
  done
  for s in IDLE RBB FBB CAP_BOOST; do
    if grep -Fq "\`${s}\`" "$MATRIX"; then
      pass "state ${s} cross-referenced in matrix"
    else
      warn "state ${s} not cited in matrix (recommended for VCM-DECK-FSM-001 row)"
    fi
  done
fi

#
# --- Step 8 — D2D conformance test cases all named --------------------------
#
header "Step 8: D2D conformance test cases present"

D2D_SPEC="${CONFORMANCE_DIR}/D2D-CONFORMANCE-V0.json"
if [ -f "$D2D_SPEC" ]; then
  for tc in D2D-TC-001 D2D-TC-002 D2D-TC-003 D2D-TC-004 D2D-TC-005 D2D-TC-006; do
    if grep -Fq "$tc" "$D2D_SPEC"; then
      pass "${tc} declared in spec"
    else
      fail "${tc} missing from D2D-CONFORMANCE-V0.json"
    fi
    # Filenames use underscores instead of dashes: D2D-TC-001 -> d2d_tc_001
    tc_lower="$(echo "$tc" | tr 'A-Z-' 'a-z_')"
    # shellcheck disable=SC2086
    if ls "${CONFORMANCE_DIR}/d2d/"${tc_lower}*.json >/dev/null 2>&1; then
      pass "${tc} vector file present"
    else
      fail "${tc} vector file missing under conformance/d2d/ (expected ${tc_lower}*.json)"
    fi
  done
else
  fail "missing $D2D_SPEC"
fi

#
# --- Step 9 — Optional t27c parse -------------------------------------------
#
header "Step 9: optional t27c parse over specs/numeric/*.t27"

if command -v t27c >/dev/null 2>&1; then
  if [ -d "$SPECS_NUMERIC_DIR" ]; then
    for f in "$SPECS_NUMERIC_DIR"/*.t27; do
      [ -f "$f" ] || continue
      if t27c --parse "$f" >/dev/null 2>&1; then
        pass "t27c parsed $(basename "$f")"
      else
        fail "t27c failed to parse $(basename "$f")"
      fi
    done
  else
    warn "specs/numeric/ directory not found"
  fi
else
  info "t27c not installed; skipping (safe — does not fail the gate)"
fi

#
# --- Summary -----------------------------------------------------------------
#
header "Summary"
printf "  warnings: %d\n" "$WARN"
printf "  failures: %d\n" "$FAIL"

if [ "$FAIL" -ne 0 ]; then
  echo "RESULT: FAIL"
  exit 1
fi
echo "RESULT: PASS"
exit 0
