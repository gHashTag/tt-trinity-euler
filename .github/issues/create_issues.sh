#!/usr/bin/env bash
# create_issues.sh — file the TRI-NET 2026 SIP issue pack onto GitHub.
#
# SAFETY MODEL
#   * Read-only by default. With no flags, --dry-run is implied.
#     You must pass --apply explicitly to make GitHub API calls.
#   * Idempotent. Before creating a new issue, the script checks whether an
#     OPEN issue with the same title already exists in the target repo; if
#     it does, that row is skipped (not duplicated, not updated, not closed).
#   * No destructive operations. Nothing is closed, edited, or deleted by
#     this script. It only calls `gh issue create`.
#   * No --no-verify / no --force / no rm. Never bypasses any check.
#
# USAGE
#   ./.github/issues/create_issues.sh [--dry-run | --apply] [--repo OWNER/REPO]
#
#   --dry-run        (default) Print every gh command that would run; do
#                    nothing else. No network calls except the existence
#                    pre-check, which uses `gh issue list`.
#   --apply          Actually call `gh issue create`. Required to create
#                    issues. Without it, nothing is created.
#   --repo OWNER/REPO  Target repo. Default: the current git remote's
#                    GitHub slug, parsed from `gh repo view`.
#   --skip-epic      Do not file 00_EPIC_2026.md (only the 16 child rows).
#   -h, --help       Print this help.
#
# EXIT CODES
#   0   success (or dry-run completed)
#   1   usage / argument error
#   2   prerequisite missing (gh CLI, auth, repo)
#   3   one or more `gh issue create` calls failed (others may have succeeded)
#
# PREREQUISITES
#   * gh CLI authenticated against the target host (`gh auth status`).
#   * Repo write access for issues (`gh repo view --json viewerPermission`).
#
# ID CONVENTION
#   The numeric prefix on each issue file (00, 01, ..., 16) is a LOCAL
#   plan ID that pairs with the SIP row in
#   docs/SCIENTIFIC_IMPROVEMENT_PLAN.md. It is NOT a GitHub issue number.
#   GitHub assigns issue numbers when this script runs in --apply mode.

set -Eeuo pipefail

# --- defaults ------------------------------------------------------------
MODE="dry-run"
REPO=""
SKIP_EPIC="no"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
EXIT_CODE=0

usage() {
  sed -n '2,40p' "$0"
}

# --- argument parsing ----------------------------------------------------
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)   MODE="dry-run"; shift ;;
    --apply)     MODE="apply"; shift ;;
    --repo)      REPO="${2:-}"; shift 2 ;;
    --skip-epic) SKIP_EPIC="yes"; shift ;;
    -h|--help)   usage; exit 0 ;;
    *)           echo "ERROR: unknown argument: $1" >&2; usage >&2; exit 1 ;;
  esac
done

# --- prerequisites --------------------------------------------------------
if ! command -v gh >/dev/null 2>&1; then
  echo "ERROR: gh CLI not found in PATH." >&2
  echo "       Install from https://cli.github.com/ and run 'gh auth login'." >&2
  exit 2
fi

# Resolve target repo.
if [[ -z "$REPO" ]]; then
  if ! REPO="$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null)"; then
    echo "ERROR: could not determine target repo. Pass --repo OWNER/REPO." >&2
    exit 2
  fi
fi

echo "create_issues.sh"
echo "  mode      : $MODE"
echo "  repo      : $REPO"
echo "  skip-epic : $SKIP_EPIC"
echo "  src dir   : $SCRIPT_DIR"
echo

# --- pick files in deterministic order -----------------------------------
mapfile -t FILES < <(LC_ALL=C ls "$SCRIPT_DIR" | grep -E '^[0-9]{2}_.*\.md$' | sort)

if [[ "$SKIP_EPIC" == "yes" ]]; then
  FILTERED=()
  for f in "${FILES[@]}"; do
    [[ "$f" == "00_EPIC_2026.md" ]] && continue
    FILTERED+=("$f")
  done
  FILES=("${FILTERED[@]}")
fi

if [[ ${#FILES[@]} -eq 0 ]]; then
  echo "ERROR: no issue markdown files found in $SCRIPT_DIR" >&2
  exit 2
fi

# --- extract title from first H1 line ('# Title') ------------------------
extract_title() {
  local file="$1"
  local title
  title="$(grep -m1 '^# ' "$file" | sed -E 's/^#[[:space:]]+//' || true)"
  if [[ -z "$title" ]]; then
    echo "ERROR: no H1 title in $file" >&2
    return 1
  fi
  printf '%s\n' "$title"
}

# --- check whether an OPEN issue with this title already exists ----------
title_exists_open() {
  local title="$1"
  # gh issue list --search "in:title \"$title\"" --state open --json title -q '.[].title'
  # Use exact-match in-title search. Returns 0 if any open issue has this title.
  local hits
  hits="$(gh issue list --repo "$REPO" --state open --search "in:title \"$title\"" --json title -q '.[].title' 2>/dev/null || true)"
  while IFS= read -r existing; do
    [[ "$existing" == "$title" ]] && return 0
  done <<< "$hits"
  return 1
}

# --- main loop ------------------------------------------------------------
CREATED=0
SKIPPED_EXISTS=0
WOULD_CREATE=0
FAILED=0

for f in "${FILES[@]}"; do
  path="$SCRIPT_DIR/$f"
  title="$(extract_title "$path")" || { FAILED=$((FAILED+1)); continue; }

  if title_exists_open "$title"; then
    echo "[SKIP exists] $f  ::  $title"
    SKIPPED_EXISTS=$((SKIPPED_EXISTS+1))
    continue
  fi

  if [[ "$MODE" == "dry-run" ]]; then
    echo "[DRY-RUN]     $f  ::  $title"
    WOULD_CREATE=$((WOULD_CREATE+1))
    continue
  fi

  echo "[CREATE]      $f  ::  $title"
  if url="$(gh issue create --repo "$REPO" --title "$title" --body-file "$path" 2>&1)"; then
    echo "              -> $url"
    CREATED=$((CREATED+1))
  else
    echo "ERROR: gh issue create failed for $f: $url" >&2
    FAILED=$((FAILED+1))
  fi
done

echo
echo "Summary:"
echo "  files scanned        : ${#FILES[@]}"
echo "  skipped (exists)     : $SKIPPED_EXISTS"
if [[ "$MODE" == "dry-run" ]]; then
  echo "  would create         : $WOULD_CREATE"
  echo "  ($MODE — no GitHub issues were actually filed. Pass --apply to file them.)"
else
  echo "  created              : $CREATED"
fi
echo "  failed               : $FAILED"

if [[ $FAILED -gt 0 ]]; then
  EXIT_CODE=3
fi

exit "$EXIT_CODE"
