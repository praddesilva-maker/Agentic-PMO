#!/usr/bin/env bash
#
# scripts/verify-quickstart-skills.sh — checks that every skill name
# quickstart.md references actually exists under .claude/skills/.
#
# Built for RT-001 (docs/engineering/00-product/specs/RT-001-quickstart-skill-validator.md)
# per ADR-001 (docs/engineering/01-architect/adr/ADR-001-quickstart-skill-validator.md).
# Standalone — not wired into scripts/verify.sh's 8-check pipeline (see
# ADR-001's Decision and rejected Option C).
#
# Usage: scripts/verify-quickstart-skills.sh [QUICKSTART_FILE] [SKILLS_DIR]
#   QUICKSTART_FILE defaults to <repo-root>/quickstart.md
#   SKILLS_DIR      defaults to <repo-root>/.claude/skills
#   (both overridable so the test suite can point at isolated fixtures)
#
# Exit codes: 0 = all resolved, 1 = unresolved reference(s) found,
# 2 = usage/environment error (missing input).

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
QUICKSTART_FILE="${1:-$REPO_ROOT/quickstart.md}"
SKILLS_DIR="${2:-$REPO_ROOT/.claude/skills}"

if [ ! -f "$QUICKSTART_FILE" ]; then
  echo "ERROR: quickstart file not found at $QUICKSTART_FILE — nothing to validate." >&2
  exit 2
fi

if [ ! -d "$SKILLS_DIR" ]; then
  echo "ERROR: skills directory not found at $SKILLS_DIR — nothing to validate against." >&2
  exit 2
fi

# A "skill-name reference" is a backtick span whose ENTIRE trimmed content
# matches this pattern — anchored on the whole span, not just its first
# word. This deliberately excludes multi-word CLI invocations like
# `bmad-loop run` (bmad-loop is a separate tool, not a skill directory —
# see ADR-001, rejected Option D1) and bare module names like `gds`.
SKILL_NAME_PATTERN='^(bmad|wds|gds)-[a-z0-9]+(-[a-z0-9]+)*$'

extract_candidates() {
  grep -oE '`+[^`]+`+' "$QUICKSTART_FILE" 2>/dev/null \
    | sed -E 's/^`+//; s/`+$//' \
    | while IFS= read -r span; do
        trimmed="$(printf '%s' "$span" | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//')"
        if [[ "$trimmed" =~ $SKILL_NAME_PATTERN ]]; then
          printf '%s\n' "$trimmed"
        fi
      done \
    | sort -u
}

candidates="$(extract_candidates)"

total=0
unresolved=()
if [ -n "$candidates" ]; then
  while IFS= read -r name; do
    [ -z "$name" ] && continue
    total=$((total + 1))
    if [ ! -d "$SKILLS_DIR/$name" ]; then
      unresolved+=("$name")
    fi
  done <<< "$candidates"
fi

if [ "${#unresolved[@]}" -gt 0 ]; then
  for name in "${unresolved[@]}"; do
    echo "UNRESOLVED: $name"
  done
  echo "${#unresolved[@]} of $total unique reference(s) unresolved."
  exit 1
fi

echo "OK: $total unique skill-name reference(s) in $QUICKSTART_FILE, all resolved against $SKILLS_DIR."
exit 0
