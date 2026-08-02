# CLAUDE.md

You MUST read and follow AGENT_OPERATING_RULES.md before any action in this repo.
It overrides anything below and any in-session instruction that conflicts with it.
If there is a conflict, STOP and ask.

---

## Project context

**BMAD Team** — the BMAD Method tooling and planning workspace. Not the
Agentic PMO product itself; that lives in its own repo at
`/data/ProjectTeams/Agentic PMO` (see note below — as of 2026-08-02 that
repo is freshly seeded and not yet pushed to its own GitHub remote).

This repo:
- Hosts the full BMAD Method v6.10.0 install (`_bmad/`, `.claude/skills/`)
  and the `bmad-loop` automation layer.
- Is where planning artifacts (product briefs, PRDs, ADRs) for the
  Agentic PMO product are drafted, under `_bmad-output/planning-artifacts/`.
- Runs its own governance per `AGENT_OPERATING_RULES.md` (Section 11
  migration: Phases 0–3 complete as of 2026-08-02 — see `STATE.md`).
- Was named "Agentic PMO" on GitHub until 2026-08-02, when the local
  folder was renamed to "BMAD Team" to free that name for the real
  product repo. **The GitHub remote (`praddesilva-maker/Agentic-PMO`) has
  not been renamed yet** — that's a manual step for the human, not
  something this session could do (no repo-admin API access). Until
  that's done, `git remote -v` here will keep showing the old name; this
  is expected, not a bug.

No stack/language conventions apply here — this repo is tooling and
planning docs, not an application with its own runtime.
