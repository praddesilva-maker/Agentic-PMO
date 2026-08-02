#!/usr/bin/env bash
#
# Stage 3 tests for RT-001
# (docs/engineering/00-product/specs/RT-001-quickstart-skill-validator.md)
# and ADR-001
# (docs/engineering/01-architect/adr/ADR-001-quickstart-skill-validator.md).
#
# Written before scripts/verify-quickstart-skills.sh exists. Deliberately
# does not invoke the missing script directly (that would abort on a shell
# "No such file or directory" — a missing-file error, which
# AGENT_OPERATING_RULES.md Section 2 explicitly says does not count as a
# genuine RED state). Instead every invocation goes through run_validator(),
# which always captures a real exit code/stdout/stderr and lets the
# assertions themselves fail meaningfully.

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT="$REPO_ROOT/scripts/verify-quickstart-skills.sh"
FIXTURES="$REPO_ROOT/tests/fixtures/rt-001-quickstart-skill-validator"

PASS=0
FAIL=0
TEST_FAILED=0

assert_eq() {
  local desc="$1" expected="$2" actual="$3"
  if [ "$expected" = "$actual" ]; then
    echo "  ok: $desc"
  else
    echo "  FAIL: $desc — expected [$expected], got [$actual]"
    TEST_FAILED=1
  fi
}

assert_contains() {
  local desc="$1" haystack="$2" needle="$3"
  if printf '%s\n' "$haystack" | grep -qF -- "$needle"; then
    echo "  ok: $desc"
  else
    echo "  FAIL: $desc — expected output to contain [$needle]"
    echo "        got: $haystack"
    TEST_FAILED=1
  fi
}

assert_not_contains() {
  local desc="$1" haystack="$2" needle="$3"
  if printf '%s\n' "$haystack" | grep -qF -- "$needle"; then
    echo "  FAIL: $desc — expected output NOT to contain [$needle]"
    echo "        got: $haystack"
    TEST_FAILED=1
  else
    echo "  ok: $desc"
  fi
}

LAST_STDOUT=""
LAST_STDERR=""
LAST_EXIT=""

run_validator() {
  local err_file
  err_file="$(mktemp)"
  LAST_STDOUT="$("$SCRIPT" "$@" 2>"$err_file")"
  LAST_EXIT=$?
  LAST_STDERR="$(cat "$err_file")"
  rm -f "$err_file"
}

run_test() {
  local name="$1"
  TEST_FAILED=0
  echo "--- $name ---"
  "$name"
  if [ "$TEST_FAILED" -eq 0 ]; then
    PASS=$((PASS + 1))
  else
    FAIL=$((FAIL + 1))
  fi
}

# AC-1: a referenced name with no matching .claude/skills/ directory is
# reported, and exit is non-zero.
test_ac1_unresolved_reference_reported() {
  run_validator "$FIXTURES/ac1/quickstart.md" "$FIXTURES/ac1/skills"
  assert_eq "AC-1: exit code is 1 when a reference is unresolved" "1" "$LAST_EXIT"
  assert_contains "AC-1: unresolved name is listed" "$LAST_STDOUT" "UNRESOLVED: bmad-does-not-exist"
  assert_not_contains "AC-1: resolved name is not reported as unresolved" "$LAST_STDOUT" "UNRESOLVED: bmad-prd"
}

# AC-2: every referenced name resolves -> exit 0, deduplicated summary
# count. This fixture also carries the D1-vs-D2 regression from ADR-001's
# "Options considered": it contains `bmad-loop run` / `bmad-loop tui`
# (multi-word CLI spans) and a bare `gds` module name, neither of which has
# a matching directory under ac2/skills. If the validator matched the
# first word of a span (rejected Option D1) instead of the whole span
# (chosen Option D2), it would incorrectly report "bmad-loop" as
# unresolved and this test would fail with a nonzero exit — that failure
# IS the regression test; no separate fixture needed.
test_ac2_all_resolved_with_dedup_and_no_false_positives() {
  run_validator "$FIXTURES/ac2/quickstart.md" "$FIXTURES/ac2/skills"
  assert_eq "AC-2: exit code is 0 when everything resolves" "0" "$LAST_EXIT"
  assert_contains "AC-2: summary states the deduplicated count (2, not 3)" "$LAST_STDOUT" "2 unique"
  assert_not_contains "AC-2/regression: multi-word span not treated as a candidate (Option D2, not D1)" "$LAST_STDOUT" "bmad-loop"
  assert_not_contains "AC-2/regression: bare module name not treated as a candidate" "$LAST_STDOUT" "UNRESOLVED: gds"
}

# AC-3: quickstart.md missing entirely -> fails clearly, not silently, not
# a crash.
test_ac3_missing_quickstart_file_fails_clearly() {
  run_validator "$FIXTURES/does-not-exist.md" "$FIXTURES/ac2/skills"
  assert_eq "AC-3: exit code is 2 when quickstart.md is missing" "2" "$LAST_EXIT"
  assert_contains "AC-3: stderr states the missing path" "$LAST_STDERR" "does-not-exist.md"
  assert_not_contains "AC-3: no raw bash error text leaks to stdout" "$LAST_STDOUT" "No such file or directory"
}

# Same failure class as AC-3, for the second input (ADR-001 Failure modes:
# "same class of error as AC-3... same principle applies").
test_missing_skills_dir_fails_clearly() {
  run_validator "$FIXTURES/ac2/quickstart.md" "$FIXTURES/does-not-exist-dir"
  assert_eq "Missing SKILLS_DIR: exit code is 2" "2" "$LAST_EXIT"
  assert_contains "Missing SKILLS_DIR: stderr states the missing path" "$LAST_STDERR" "does-not-exist-dir"
}

# Pinned integration test (ADR-001 Test strategy): runs against the REAL
# quickstart.md and .claude/skills/, not a fixture. Verified by hand
# (2026-08-02) before this script existed: exactly these three names are
# unresolved, no others. If this ever starts passing differently, either
# the real file was fixed (update this test in its own commit, per Section
# 2 Stage 4's rule on changing tests) or the validator regressed.
test_real_quickstart_reports_known_stale_names() {
  run_validator "$REPO_ROOT/quickstart.md" "$REPO_ROOT/.claude/skills"
  assert_eq "Real file: exit code is 1 (known stale names present)" "1" "$LAST_EXIT"
  assert_contains "Real file: bmad-wds-idun reported" "$LAST_STDOUT" "UNRESOLVED: bmad-wds-idun"
  assert_contains "Real file: bmad-wds-saga reported" "$LAST_STDOUT" "UNRESOLVED: bmad-wds-saga"
  assert_contains "Real file: bmad-wds-project-brief reported" "$LAST_STDOUT" "UNRESOLVED: bmad-wds-project-brief"
  assert_eq "Real file: exactly 3 unresolved, no others" "3" "$(printf '%s\n' "$LAST_STDOUT" | grep -c '^UNRESOLVED:')"
}

run_test test_ac1_unresolved_reference_reported
run_test test_ac2_all_resolved_with_dedup_and_no_false_positives
run_test test_ac3_missing_quickstart_file_fails_clearly
run_test test_missing_skills_dir_fails_clearly
run_test test_real_quickstart_reports_known_stale_names

echo ""
echo "=== $PASS passed, $FAIL failed ==="
[ "$FAIL" -eq 0 ]
