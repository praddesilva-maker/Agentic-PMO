# STATE.md

_Last updated: 2026-08-02 (repo renamed to BMAD Team; RT-001 merged; Agentic PMO brief+PRD drafted)_

## Where we are

**This repo is "BMAD Team"** — the BMAD Method tooling/planning
workspace, renamed 2026-08-02 from "Agentic PMO" (see CLAUDE.md). The
actual Agentic PMO product now lives in its own repo,
`/data/ProjectTeams/Agentic PMO`, freshly created and seeded the same day
(see that repo's own STATE.md/README for its status — it's pre-code,
brief+PRD only).

**Migration status**: Section 11 (Migration — adopting these rules in
this repo) — **Phases 0–3 complete.**

- Phase 0 (Audit): complete, 2026-08-02.
- Phase 1 (Scaffold): complete, gate approved 2026-08-02.
- Phase 2 (Verification + ratchet): complete, gate approved 2026-08-02.
  Branch protection on `main` enabled by the human.
- Phase 3 (Rehearsal ticket RT-001, "quickstart skill-name validator"):
  **complete and merged.** All six Section 2 stages run: spec (Gate 1) →
  ADR-001 via isolated Architect subagent (Gate 2) → tests (Stage 3,
  genuine RED) → implementation (Stage 4, GREEN first attempt) → review
  via isolated Reviewer subagent (Stage 5, CHANGES REQUIRED → 2 real
  defects found and fixed, 7 tests passing) → human Gate 3 + Stage 6
  merge (PR #3, merged to `main` as `e8e4b61`). Full detail:
  `docs/engineering/` (specs, ADR, test evidence, review verdict),
  `docs/engineering/traceability/matrix.md`.
  - **Standing recommendation from this rehearsal**: run Architect and
    Reviewer stages as isolated subagents (fresh context, no conversation
    history) going forward, not just for rehearsals — both caught real
    issues a same-session pass would likely have missed.
- Phase 4 (Burn-down): ongoing policy, not a discrete task. `LEGACY.md`
  entries enter the lifecycle only when next touched. "Adoption complete"
  (empty `LEGACY.md`, or every remaining entry a consciously accepted
  dated risk) not yet reached — expected, since RT-001 didn't touch any
  existing `LEGACY.md` entry.

## Agentic PMO product planning (via BMAD Method, in this repo)

Product brief and PRD for the **Agentic PMO** product (skills layer +
tools layer, Jira/Confluence connector first) were drafted here via
`bmad-product-brief` and `bmad-prd`:

- `_bmad-output/planning-artifacts/briefs/brief-agentic-pmo-2026-08-02/`
  — `brief.md`, `addendum.md`, `.memlog.md`
- `_bmad-output/planning-artifacts/prds/prd-agentic-pmo-2026-08-02/` —
  `prd.md`, `addendum.md`, `.memlog.md`

Both were **reframed 2026-08-02** after auditing a prior working
implementation the user shared,
`/home/praddesilva/ProjectTeams/SRG-Apps/Apps/Copilot-PMAgentv2` (a real
MCP server already doing Jira/Confluence read/update/create). Key
outcomes of that reframe:
- Issue/page **creation moved into v1 scope** (a proven reference exists).
- **Per-user identity flagged as real, unavoidable new work** — the prior
  app's single-shared-credential auth model does not satisfy it.
- **Node 22.22 resolved**: an internal convention specific to that prior
  repo, not an Atlassian requirement — Agentic PMO doesn't inherit it.
- **New risk surfaced**: this organisation already once abandoned a
  centrally-hosted (Azure) MCP approach for lack of subscription/admin
  access — direct precedent risk for the incoming MCP Gateway plan.
- **Open, unresolved**: a possible further-along parallel TypeScript
  rewrite (`PM-Agent-Service` / `Transformation-PM-Agent-Service`)
  referenced by stray files in the audited checkout but unverified —
  needs the user to confirm it exists before architecture work locks in
  `Copilot-PMAgentv2` as the primary reference.

Committed on branch `Atlassian-Skills` (pushed to
`origin/Atlassian-Skills`), not yet merged to `main` — this planning work
was done on its own branch since it's a distinct workstream from the
Section 11 migration/RT-001 work.

**Finalized copies** of `brief.md` and `prd.md` have also been seeded into
the new `/data/ProjectTeams/Agentic PMO` repo as that product's own
reference docs — the canonical, living versions with full memlog audit
trail stay here in BMAD Team.

## Repo rename — what's done, what's still manual

- ✅ Local folder renamed: `/data/ProjectTeams/Agentic PMO` →
  `/data/ProjectTeams/BMAD Team` (also accessible via
  `/home/praddesilva/ProjectTeams/BMAD Team` — same filesystem location).
- ✅ New product repo created and seeded: `/data/ProjectTeams/Agentic PMO`
  (git-initialized locally, not yet pushed to any GitHub remote).
- ❌ **GitHub remote for this repo is still named `Agentic-PMO`**
  (`praddesilva-maker/Agentic-PMO`) — renaming it requires GitHub
  UI/API access this session doesn't have (no `gh` CLI, no admin token).
  Manual step: rename that GitHub repo to something like `BMAD-Team`.
- ❌ **No GitHub remote exists yet for the new Agentic PMO product repo**
  — needs to be created (GitHub UI, `gh repo create`, or grant this
  session a token) and then `git remote add origin ... && git push -u
  origin main` from `/data/ProjectTeams/Agentic PMO`.

## Repo map

| Path | What it is | Status |
|---|---|---|
| `AGENT_OPERATING_RULES.md` | The constitution | Foundational |
| `CLAUDE.md` | Pointer to the constitution + BMAD Team identity | Foundational |
| `quickstart.md` | BMAD agent/skill reference | Legacy — see `LEGACY.md` |
| `STATE.md` | This file | Foundational |
| `LEGACY.md` | Directories not yet under these rules | Foundational |
| `docs/engineering/` | Section 10 structure (RT-001's full trail) | Governed |
| `_bmad-output/planning-artifacts/` | Agentic PMO brief + PRD (this session) | New |
| `_bmad/` | BMAD Method v6.10.0 install | Legacy — vendored |
| `.claude/skills/` | Vendored BMAD skill packages | Legacy — vendored |
| `.bmad-loop/` | bmad-loop orchestrator state | Legacy — installer-managed |
| `scripts/verify.sh`, `scripts/hooks/`, `scripts/verify-quickstart-skills.sh` | Section 4 gate + RT-001's validator | Governed (RT-001) / Legacy (verify.sh) |
| `design-artifacts/` | Empty WDS output scaffold | Empty |

## Next action

1. Review/merge `Atlassian-Skills` branch (brief + PRD) into `main` when
   ready — currently sitting as a pushed, unmerged branch.
2. Resolve the `PM-Agent-Service` open question (PRD §14, item 9) before
   architecture work begins on Agentic PMO.
3. Manual: rename this repo's GitHub remote; create a GitHub remote for
   the new `/data/ProjectTeams/Agentic PMO` repo and push it.
4. Whenever code work starts on Agentic PMO itself, it happens in that
   repo, not here — this repo (BMAD Team) stays the planning/skills-
   development workspace.
