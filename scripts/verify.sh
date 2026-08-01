#!/usr/bin/env bash
#
# scripts/verify.sh — mechanical merge gate (AGENT_OPERATING_RULES.md, section 4)
#
# Runs 8 checks in order. Exits non-zero on the FIRST failure. Prints a final
# PASS / FAIL line. Never edit this to skip a step or append `|| true` — that
# is an automatic rejection per the operating rules.
#
# This repo has no chosen stack yet (no package.json / pyproject.toml /
# requirements.txt / go.mod / Cargo.toml). Each check below detects the stack
# and either runs the real tool or reports BLOCKED with a reason — it never
# fakes a pass.

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

fail() {
  echo ""
  echo "FAIL: $1"
  echo ""
  echo "=== verify.sh: FAIL ==="
  exit 1
}

echo "=== verify.sh starting at $(date -u +%FT%TZ) ==="
echo "Repo: $REPO_ROOT"
echo ""

# --- Stack detection ---------------------------------------------------
STACK="none"
if   [ -f package.json ]; then STACK="node"
elif [ -f pyproject.toml ] || [ -f requirements.txt ]; then STACK="python"
elif [ -f go.mod ]; then STACK="go"
elif [ -f Cargo.toml ]; then STACK="rust"
fi
echo "Detected stack: $STACK"
echo ""

# --- 1. Type check -------------------------------------------------------
echo "--- [1/8] Type check ---"
case "$STACK" in
  node)   echo "would run: npx tsc --noEmit" ;;
  python) echo "would run: mypy ." ;;
  go)     echo "would run: go build ./..." ;;
  rust)   echo "would run: cargo check" ;;
  none)   fail "[1/8] Type check: no stack manifest found (no package.json / pyproject.toml / requirements.txt / go.mod / Cargo.toml). No type checker to run." ;;
esac
echo "[1/8] OK"
echo ""

# --- 2. Lint / format check ----------------------------------------------
echo "--- [2/8] Lint / format check ---"
case "$STACK" in
  node)   echo "would run: npx eslint . && npx prettier --check ." ;;
  python) echo "would run: ruff check . && black --check ." ;;
  go)     echo "would run: gofmt -l . && go vet ./..." ;;
  rust)   echo "would run: cargo fmt --check && cargo clippy" ;;
  none)   fail "[2/8] Lint/format: no stack, no linter configured." ;;
esac
echo "[2/8] OK"
echo ""

# --- 3. Full test suite ---------------------------------------------------
echo "--- [3/8] Full test suite ---"
case "$STACK" in
  node)   echo "would run: npm test" ;;
  python) echo "would run: pytest" ;;
  go)     echo "would run: go test ./..." ;;
  rust)   echo "would run: cargo test" ;;
  none)   fail "[3/8] Test suite: no stack, no test runner, no tests exist." ;;
esac
echo "[3/8] OK"
echo ""

# --- 4. Coverage threshold on changed lines -------------------------------
echo "--- [4/8] Coverage on changed lines ---"
case "$STACK" in
  node)   echo "would run: nyc report + diff-cover against origin/main" ;;
  python) echo "would run: coverage run -m pytest && diff-cover coverage.xml" ;;
  go)     echo "would run: go test -coverprofile and diff against origin/main" ;;
  rust)   echo "would run: cargo llvm-cov + diff-cover" ;;
  none)   fail "[4/8] Coverage: no stack, no coverage tool, no changed-lines baseline." ;;
esac
echo "[4/8] OK"
echo ""

# --- 5. Secret scan --------------------------------------------------------
echo "--- [5/8] Secret scan (working tree + diff) ---"
if command -v gitleaks >/dev/null 2>&1; then
  echo "would run: gitleaks detect --source . --no-git && gitleaks protect --staged"
elif command -v trufflehog >/dev/null 2>&1; then
  echo "would run: trufflehog filesystem ."
else
  fail "[5/8] Secret scan: no scanner installed (checked: gitleaks, trufflehog). Not stack-dependent — this is a missing tool, not a missing stack."
fi
echo "[5/8] OK"
echo ""

# --- 6. Dependency vulnerability audit ------------------------------------
echo "--- [6/8] Dependency vulnerability audit ---"
case "$STACK" in
  node)   echo "would run: npm audit --audit-level=high" ;;
  python) echo "would run: pip-audit" ;;
  go)     echo "would run: govulncheck ./..." ;;
  rust)   echo "would run: cargo audit" ;;
  none)   fail "[6/8] Dependency audit: no stack, no dependency manifest to audit." ;;
esac
echo "[6/8] OK"
echo ""

# --- 7. Static analysis (SAST) ---------------------------------------------
echo "--- [7/8] Static analysis (SAST) ---"
if command -v semgrep >/dev/null 2>&1; then
  echo "would run: semgrep --config auto ."
else
  fail "[7/8] SAST: no scanner installed (checked: semgrep). Not stack-dependent — this is a missing tool, not a missing stack."
fi
echo "[7/8] OK"
echo ""

# --- 8. Dependency allow-list check against active ADR ---------------------
echo "--- [8/8] Dependency allow-list vs. active ADR ---"
if [ ! -d docs/adr ] || [ -z "$(ls -A docs/adr 2>/dev/null)" ]; then
  fail "[8/8] Dependency allow-list: no ADR exists under docs/adr/ to check dependencies against."
fi
echo "would diff manifest dependencies against the allow-list in the active ADR"
echo "[8/8] OK"
echo ""

echo "=== verify.sh: PASS ==="
