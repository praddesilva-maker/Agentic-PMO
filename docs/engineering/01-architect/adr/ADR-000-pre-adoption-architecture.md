---
id: ADR-000
type: adr
status: Accepted (retrospective)
author_role: architect
approved_by: Prad
date: 2026-08-02
supersedes: n/a
---

# ADR-000 — Pre-adoption architecture

## Status

Accepted (retrospective). The one retrospective ADR permitted under Section
11 — documents the as-is system as of migration adoption. This is not a
design produced through Stage 2's Architect role, and it does not imply the
as-is state is good design — see "Known weak points."

## Context

This repo was bootstrapped in a single session:
1. A minimal `AGENT_OPERATING_RULES.md` constitution.
2. BMAD Method v6.10.0 (5 modules: bmm, tea, cis, gds, wds, plus bmb and
   core) via its own installer → `_bmad/`, `.claude/skills/`.
3. The `bmad-loop` orchestrator (`uv tool install` from
   `github.com/bmad-code-org/bmad-loop`), bootstrapped via `bmad-loop init`
   → `.bmad-loop/`, hooks in `.claude/settings.json`.
4. A hand-built `scripts/verify.sh` (Section 4 gate, currently blocked on
   all 8 checks) and `scripts/hooks/pre-push`, wired via `core.hooksPath`.

None of this was produced through the Section 2 lifecycle — no spec, no
prior ADR, no independent review. It predates adoption of Section 11.

## As-is system description

- **No application code exists** — confirmed in the Phase 0 audit
  (2026-08-02): zero non-vendored source files, no package manifest in any
  language, no test suite.
- **BMAD tooling layer** installed and operable — see `quickstart.md`.
- **Automation layer**: `bmad-loop` hooked into every Claude Code session
  via `.claude/settings.json`, nothing to automate yet — no
  `sprint-status.yaml` exists.
- **Verification gate**: `scripts/verify.sh` correctly reports all 8 checks
  blocked (no stack, no scanners installed, no `docs/adr/` predating this
  PR). `pre-push` correctly enforces this and has already blocked a push in
  practice.
- **Version control**: two commits predate this ADR, neither following the
  Section 5 commit convention — both explicit, human-approved bootstrap
  exceptions, not examples of the intended workflow.

## Known weak points

- No branch protection observed on `main` (inferred from push behaviour,
  not a direct API check).
- `verify.sh` has never produced a `PASS` — every check is blocked by
  absence, not verified by a passing run.
- `_bmad/wds/module-help.csv` is stale — references skill names that don't
  exist in the installed `.claude/skills/` tree (see `quickstart.md`).
- `AGENT_OPERATING_RULES.md` itself had an uncommitted local edit
  (sections 8–11) discovered during the Phase 0 audit — a process gap in
  how the constitution itself gets versioned.
- No secret scanner or SAST tool installed — checks 5 and 7 blocked by
  tooling absence, independent of the stack question.

## Traceability

**Pre-adoption code and configuration has no spec or ADR traceability.**
Nothing above should be cited in `docs/engineering/traceability/matrix.md`
as satisfying any acceptance criterion. It is grandfathered per
`LEGACY.md` and enters the lifecycle only when next modified (Phase 4).

## Rollback

Not applicable — this ADR documents existing state; it does not authorize
a change.
