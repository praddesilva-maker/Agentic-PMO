# STATE.md

_Last updated: 2026-08-02_

## Where we are

**Migration status**: Section 11 (Migration — adopting these rules in an
existing repo) is in progress. This file is part of the Phase 1 — Scaffold
deliverable.

- Phase 0 (Audit): complete. Baseline report delivered 2026-08-02; no
  application stack, no test suite, 8/8 `verify.sh` checks blocked.
- Phase 1 (Scaffold): complete, gate approved 2026-08-02.
- Phase 2 (Verification + ratchet): in progress — this PR.
  - `scripts/verify.sh` check 8 fixed (was checking the stale `docs/adr/`
    path; now checks the real `docs/engineering/01-architect/adr/`).
  - `docs/engineering/ratchet.json` created — 7 of 8 checks recorded as
    `blocked` (no stack/tools exist; explicitly not the same as a `0`
    baseline), check 8 `ok_after_path_fix`.
  - **Open**: branch protection on `main`. Per Section 0, no agent has
    write access to branch-protection settings — this is a human action.
    Recommended settings for `praddesilva-maker/Agentic-PMO` → Settings →
    Branches → rule on `main`: require a PR before merging, require status
    checks once CI reports `verify.sh`, disallow force pushes and deletions.
- Phase 3 (Rehearsal ticket): not started. Planned direction (agreed
  2026-08-02): a small, non-stack-dependent addition to the BMAD tooling
  layer, run through all six Section 2 stages, rather than an arbitrary
  stub in an as-yet-unchosen application stack.
- Phase 4 (Burn-down): not started.

**No ticket is currently active.** No spec and no ADR (other than the
retrospective ADR-000) exists under the Section 2 lifecycle yet.

## Repo map

| Path | What it is | Status |
|---|---|---|
| `AGENT_OPERATING_RULES.md` | The constitution | Foundational |
| `CLAUDE.md` | Pointer to the constitution + project context placeholder | Foundational |
| `quickstart.md` | BMAD agent/skill reference | Legacy — see `LEGACY.md` |
| `STATE.md` | This file | Foundational |
| `LEGACY.md` | Directories not yet under these rules | Foundational |
| `docs/engineering/` | Section 10 structure | New — governed from now on |
| `docs/` (root) | Empty; bmm `project_knowledge` scan target | Empty |
| `_bmad/` | BMAD Method v6.10.0 install (bmm/tea/cis/gds/wds/bmad-loop/bmb/core configs) | Legacy — vendored |
| `.claude/skills/` | Vendored BMAD skill packages | Legacy — vendored |
| `.claude/settings.json` | Hook registrations from `bmad-loop init` | Legacy — installer-managed |
| `.bmad-loop/` | bmad-loop orchestrator state, hook script, `policy.toml` | Legacy — installer-managed |
| `scripts/verify.sh`, `scripts/hooks/` | Section 4 gate + pre-push hook | Legacy — built ad hoc, pre-migration |
| `design-artifacts/` | Empty WDS output scaffold | Empty |
| `_bmad-output/` | Empty BMM output scaffold | Empty |

## Next action

Awaiting Phase 2 gate approval. Blocking item: you enabling branch
protection on `main` (see above) — everything else in Phase 2 is done.
Once approved: Phase 3 — rehearsal ticket.
