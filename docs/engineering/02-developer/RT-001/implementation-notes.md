---
id: RT-001
type: implementation-notes
status: Draft
author_role: developer
approved_by:
date: 2026-08-02
---

# RT-001 — Implementation notes

Implementation followed ADR-001 exactly — no deviation, no "design did not
survive contact with reality" escalation needed. Notes below are
implementation-level detail not already covered by the ADR.

- `extract_candidates()` uses a `while read <<< "$candidates"` here-string
  pattern (not `cmd | while read`) specifically so `total` and the
  `unresolved` array persist outside the loop — a `| while read` loop runs
  in a subshell in bash, which would silently reset both to empty after
  the loop. Worth a comment if this file is ever refactored.
- `set -uo pipefail` used, deliberately no `set -e`, matching ADR-001's
  Failure modes note: `grep`/`[[ =~ ]]` return non-zero on "no match,"
  which is a valid outcome here (e.g. zero unresolved names), not an
  error condition — `set -e` would have aborted the script on that valid
  path.
- All 5 Stage 3 tests passed on the first implementation attempt against
  this design; no escalation trigger under Section 8 applies (no failed
  attempts, not a concurrency/crypto/auth/money component, ADR did not
  flag high-risk) — Sonnet 5 throughout, as budgeted.

## Deviation from Section 10's stated sequencing

Section 10 states: "Every AC has a row [in `traceability/matrix.md`]
before Stage 3 begins. Rows are created from the spec, not discovered
later." Those rows were actually added during Stage 4 (this commit), not
between Gate 1 and Stage 3 as the rule describes — an accepted
Phase 3 rehearsal finding, not a deliberate design choice. Recorded here
per the "log assumptions/recommendations along the way" instruction,
and in `STATE.md`'s Phase 3 friction notes.
