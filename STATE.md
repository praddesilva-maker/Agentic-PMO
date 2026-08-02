# STATE.md

_Last updated: 2026-08-02 (RT-001 Stage 1-5 complete, awaiting Gate 3 + Stage 6)_

## Where we are

**Migration status**: Section 11 (Migration — adopting these rules in an
existing repo) is in progress. This file is part of the Phase 1 — Scaffold
deliverable.

- Phase 0 (Audit): complete. Baseline report delivered 2026-08-02; no
  application stack, no test suite, 8/8 `verify.sh` checks blocked.
- Phase 1 (Scaffold): complete, gate approved 2026-08-02.
- Phase 2 (Verification + ratchet): complete, gate approved 2026-08-02.
  - `scripts/verify.sh` check 8 fixed (was checking the stale `docs/adr/`
    path; now checks the real `docs/engineering/01-architect/adr/`).
  - `docs/engineering/ratchet.json` created — 7 of 8 checks recorded as
    `blocked` (no stack/tools exist; explicitly not the same as a `0`
    baseline), check 8 `ok_after_path_fix`.
  - Branch protection on `main` enabled by the human (2026-08-02) —
    Section 0 gives agents no write access to that setting.
- Phase 3 (Rehearsal ticket): **in progress — ticket RT-001**, "quickstart
  skill-name validator." A small, non-stack-dependent addition to the BMAD
  tooling layer, run through all six Section 2 stages.
  - Stage 1 (spec): Approved, Gate 1 signed off 2026-08-02.
    `docs/engineering/00-product/specs/RT-001-quickstart-skill-validator.md`
  - Stage 2 (ADR): Approved, Gate 2 signed off 2026-08-02.
    `docs/engineering/01-architect/adr/ADR-001-quickstart-skill-validator.md`.
    **Friction note, on the record per Phase 3's purpose**: Section 1
    requires the Architect role to run in a session separate from the rest
    of this work. Honored by dispatching a `Plan` subagent with only the
    spec as input (no conversation history) rather than writing the ADR
    in-session — genuinely isolated context, not role-play. It paid off:
    the subagent caught that a correct AC-1 implementation will fire
    against the real `quickstart.md` today (the "Known issue" callout
    backtick-wraps its own broken-name examples), a finding easy to miss
    with full context of having written that file. Mechanically heavier
    than staying in-session, though — worth deciding whether this is the
    standing pattern for every future Architect stage or a rehearsal-only
    cost.
  - Docs-only PR (spec + ADR) pushed: `docs/RT-001-spec-design`
    (branched from `main` post-Phase-1/2-merge, per Section 5). Awaiting
    merge to `main` before Stage 3 (tests) starts on a `feat/RT-001-*`
    branch, per Section 2's "spec+ADR merge before any code branch."
  - **Friction note**: `scripts/hooks/pre-push` blocks every push on this
    repo right now (checks 1–7 genuinely blocked, no stack exists) —
    every docs-only push this session has needed an explicit `--no-verify`
    confirmation. Expected to resolve once a real stack exists and
    `verify.sh` can actually pass; until then this is a repeat-friction
    point worth deciding a standing policy for for future tickets.
  - Stage 3 (tests): complete. 5 tests written against ADR-001 before the
    script existed; genuine RED (0 passed, 5 failed, every failure a real
    assertion mismatch — see `docs/engineering/02-developer/RT-001/test-evidence.md`).
  - Stage 4 (implementation): complete.
    `scripts/verify-quickstart-skills.sh`, all 5 tests GREEN on the first
    attempt. NFRs (read-only, no network, sub-second, no new deps) verified
    with evidence, not just claimed.
  - Stage 5 (review): complete, **CHANGES REQUIRED then fixed**. Run as an
    isolated `Plan` subagent in a fresh git worktree — genuinely separate
    context, not role-play, per Section 1. Full verdict:
    `docs/engineering/03-reviewer/RT-001-review.md`.
    **Friction note**: the isolated reviewer earned its keep a second
    time. It independently re-ran everything (didn't trust any of the
    Developer's pasted output), reproduced the RED state from an earlier
    commit itself, and found two real, reproducible defects the Developer
    stage missed entirely: an unreadable `quickstart.md` silently passing
    (exit 0) instead of the exit 2 the ADR itself documents for that case,
    and a stray/unbalanced backtick silently dropping a real reference
    with no signal at all — worse than a risk the ADR explicitly already
    accepted. It also caught a false claim in the Developer's own commit
    message (asserted `STATE.md` was updated; it wasn't). Both defects
    fixed, 2 regression tests added (7 total), all passing. This is
    strong evidence the separate-session Architect/Reviewer pattern is
    worth the mechanical overhead noted above, not just a rehearsal-only
    cost — recommend keeping it as the standing pattern going forward,
    not just for this rehearsal.
  - Gate 3 (human reviews the verdict) and Stage 6 (human runs it,
    merges, tags): **pending — this is the next action.**

**Active ticket: RT-001** (quickstart skill-name validator). Stages 1–5
complete. Final PR open on branch `feat/RT-001-quickstart-skill-validator`,
awaiting your Gate 3 review and Stage 6 merge.

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

Awaiting your Gate 3 review of `docs/engineering/03-reviewer/RT-001-review.md`
and Stage 6 (you run `./tests/scripts/verify-quickstart-skills.test.sh` and
`./scripts/verify-quickstart-skills.sh` yourself, then merge and tag).
Once RT-001 lands: Phase 3 is complete. Section 11 migration status at
that point — Phases 0–3 done; Phase 4 (Burn-down) has no discrete
task, it's the ongoing policy of pulling a `LEGACY.md` entry into the
lifecycle only when it's next touched. "Adoption complete" (Section 11)
requires either an empty `LEGACY.md` or every remaining entry being a
consciously accepted, dated risk — not reached yet, since RT-001 added
new code without touching any existing `LEGACY.md` entry. That's expected
or the ticket would have been "small, low-risk" in name only.
