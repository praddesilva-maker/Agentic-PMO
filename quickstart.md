# BMAD Quickstart

This project has BMAD Method v6.10.0 installed, with 5 modules and the
bmad-loop automation layer. This doc explains what's installed, what each
agent does, and how to actually run a workflow.

Grounded in what's on disk in this repo (`_bmad/_config/bmad-help.csv`, each
skill's `SKILL.md`) rather than generic BMAD documentation, plus a check
against docs.bmad-method.org for the interaction model.

---

## How to talk to an agent

There's no special syntax. Two ways in:

1. **Natural language** — "talk to John", "let's write the PRD", "ask Mary to
   do some market research". The right skill activates from what you say.
2. **Skill name directly** — `bmad-prd`, `bmad-loop run`, etc.

Once an agent (a named persona like John or Mary) activates, it **stays in
character** for the rest of the session — greets you, prefixes messages with
its icon, and shows a numbered menu of what it can do. It stays active until
you dismiss it or the conversation moves on. Workflow skills that aren't tied
to a persona (e.g. `bmad-architecture`, `bmad-code-review`) just run once and
return.

**Rules of thumb:**
- Run each skill in a **fresh context window** when you can — this is a
  standing recommendation baked into `bmad-help` itself; stale context from a
  prior phase can bias the next one.
- Lost or not sure what's next? Ask for **`bmad-help`** — it reads what's
  already been produced in this repo and tells you where you are and what to
  run next, rather than dumping the whole catalog on you.
- Every phase produces a real file (brief, PRD, architecture doc, epics,
  stories, sprint status...) under `_bmad-output/` or `docs/` — that's the
  artifact the next agent reads, and it's how agents "hand off" to each other.
  There's no shared memory between agent sessions beyond these files.
- You approve or redirect the plan at each stage — nothing downstream
  (an epic breakdown, a sprint, an implementation) runs on an assumption you
  haven't seen and signed off on.

---

## The agents

21 named personas across 5 modules. Each one, when active, greets you and
shows its own menu — you don't need to remember what it can do in advance.

| Agent | Module | Role | Skill |
|---|---|---|---|
| Mary 📊 | bmm | Business Analyst | `bmad-agent-analyst` |
| John 📋 | bmm | Product Manager | `bmad-agent-pm` |
| Winston 🏗️ | bmm | System Architect | `bmad-agent-architect` |
| Sally 🎨 | bmm | UX Designer | `bmad-agent-ux-designer` |
| Amelia 💻 | bmm | Senior Software Engineer (Dev) | `bmad-agent-dev` |
| Paige 📚 | bmm | Technical Writer | `bmad-agent-tech-writer` |
| Murat 🧪 | tea | Master Test Architect | `bmad-tea` |
| Freya 🎨 | wds | UX Designer / strategic design partner | `wds-agent-freya-ux` |
| Saga 📚 | wds | Business Analyst / product discovery | `wds-agent-saga-analyst` |
| Mimir 🔨 | wds | Builder — owns tech audit, PRD, implementation | `wds-agent-mimir-builder` |
| Sophia 📖 | cis | Master Storyteller | `bmad-cis-agent-storyteller` |
| Maya 🎨 | cis | Design Thinking Maestro | `bmad-cis-agent-design-thinking-coach` |
| Carson 🧠 | cis | Brainstorming Specialist | `bmad-cis-agent-brainstorming-coach` |
| Dr. Quinn 🔬 | cis | Master Problem Solver | `bmad-cis-agent-creative-problem-solver` |
| Victor ⚡ | cis | Disruptive Innovation Oracle | `bmad-cis-agent-innovation-strategist` |
| Caravaggio 🎬 | cis | Presentation / Visual Communication Expert | `bmad-cis-agent-presentation-master` |
| *(5 more in `gds`, Game Dev Studio — not detailed here since this isn't a game project; see the flat list below if needed.)* |||

---

## bmm — core software delivery pipeline (the main one for this project)

This is the primary phase flow. Phases run in order; `required=true` items
must complete before the next phase is meaningful. Everything is a soft
recommendation except those gates.

| Phase | Skill | What it produces | Gate? |
|---|---|---|---|
| 1 · Analysis | `bmad-brainstorming`, `bmad-market-research`, `bmad-domain-research`, `bmad-technical-research` | research docs, brainstorm notes | optional |
| 1 · Analysis | `bmad-product-brief` (or `bmad-prfaq` as an alternative) | product brief | optional but typical entry point |
| 2 · Planning | `bmad-prd` | PRD | **required** before solutioning |
| 2 · Planning | `bmad-ux` | UX design | optional, strongly recommended if there's a UI |
| 3 · Solutioning | `bmad-architecture` (Winston) | architecture spine — the invariants that keep epics/stories consistent | **required** |
| 3 · Solutioning | `bmad-create-epics-and-stories` | epics + stories | **required** |
| 3 · Solutioning | `bmad-check-implementation-readiness` | readiness report (PRD/UX/architecture/epics alignment check) | **required** before implementation |
| 4 · Implementation | `bmad-sprint-planning` | sprint status / plan | **required** to start implementation |
| 4 · Implementation | `bmad-create-story` (create → validate) | one story, ready for dev | **required** per story |
| 4 · Implementation | `bmad-dev-story` (Amelia) | implementation + tests | **required** per story |
| 4 · Implementation | `bmad-code-review` | review verdict; loops back to `bmad-dev-story` if issues found | recommended |
| 4 · Implementation | `bmad-qa-generate-e2e-tests` | E2E/API test suite | optional |
| 4 · Implementation | `bmad-retrospective` | end-of-epic lessons learned | optional, at epic end |
| anytime | `bmad-correct-course` | change proposal — use when something's gone off track and you might need to redo architecture, PRD, or planning | — |
| anytime | `bmad-quick-dev` | unified clarify→plan→implement→review→present, for smaller changes that don't need the full pipeline | — |
| anytime | `bmad-sprint-status`, `bmad-help`, `bmad-checkpoint-preview` | status / navigation / human review of a diff | — |

This maps closely onto `AGENT_OPERATING_RULES.md`'s role split in this repo:
Winston (Architect) → design/ADR stage, Amelia (Dev) → implementation stage,
`bmad-code-review` → the fresh-session Senior Reviewer stage. The manual gate
gaps between them are exactly where `AGENT_OPERATING_RULES.md`'s human gates
sit.

---

## tea — testing (Test Architecture Enterprise)

| Phase | Skill | Purpose |
|---|---|---|
| 0 · Learning | `bmad-teach-me-testing` (Murat) | 7-session testing fundamentals course, if you want to learn the discipline rather than just use it |
| 3 · Solutioning | `bmad-testarch-test-design` → `bmad-testarch-framework` → `bmad-testarch-ci` | risk-based test plan → framework scaffold → CI pipeline config |
| 4 · Implementation | `bmad-testarch-atdd` → `bmad-testarch-automate` → `bmad-testarch-test-review` → `bmad-testarch-nfr` → `bmad-testarch-trace` | red-phase acceptance tests → coverage expansion → quality audit (0–100 score) → NFR evidence audit → traceability matrix + gate decision |

This is the module that would satisfy `AGENT_OPERATING_RULES.md`'s demand for
"tests first" and a real coverage/traceability story, rather than the
skeleton `scripts/verify.sh` we hand-built earlier.

---

## wds — Web Design Studio (product/UX design pipeline)

⚠️ **Known issue**: this module's own `_bmad/wds/module-help.csv` lists skill
names (`bmad-wds-idun`, `bmad-wds-saga`, `bmad-wds-project-brief`, etc.) that
**do not exist** in `.claude/skills/` — that catalog is stale relative to the
actually-installed v0.4.3 skills. The table below uses the **real, installed**
skill names, confirmed against `.claude/skills/`.

| Phase | Skill | Purpose |
|---|---|---|
| 0 | `wds-0-alignment-signoff` | build alignment on the idea before the project starts |
| 0 | `wds-0-project-setup` | onboarding — determine project type, complexity, tech stack, route to the right phase |
| 1 | `wds-1-project-brief` (Saga) | establish project context — foundation for all design work |
| 2 | `wds-2-trigger-mapping` | map business goals to user psychology via structured workshops |
| 3 | `wds-3-scenarios` | UX scenario outlines from the Trigger Map |
| 4 | `wds-4-ux-design` (Freya) | detailed visual specs, scenario-driven |
| 5 | `wds-5-agentic-development` (Mimir) | AI-assisted build/test/reverse-engineering loop |
| 6 | `wds-6-asset-generation` | AI-generated visual/text assets from specs |
| 7 | `wds-7-design-system` | create/import/browse/maintain design system components + tokens |
| 8 | `wds-8-product-evolution` | brownfield improvement loop — the whole pipeline, in miniature, for an existing product |

---

## cis — Creative Intelligence Suite

All `anytime` skills — no phase gating, use whenever relevant:

| Skill | Purpose |
|---|---|
| `bmad-cis-innovation-strategy` (Victor) | disruption opportunities, business-model innovation |
| `bmad-cis-problem-solving` (Dr. Quinn) | systematic problem-solving methodologies |
| `bmad-cis-design-thinking` (Maya) | empathy-driven, human-centered design process |
| `bmad-cis-storytelling` (Sophia) | narrative frameworks |
| `bmad-brainstorming` (Carson, shared with bmm/core) | facilitated brainstorming |
| `bmad-party-mode` | multi-agent roundtable — get several personas' perspectives on the same question at once |

---

## gds — Game Dev Studio

Installed, but not detailed here since this isn't a game project. It mirrors
the bmm pipeline (`1-preproduction` → `2-design` → `3-technical` →
`4-production`, plus a `gametest` track) with game-specific agents (Cloud
Dragonborn, Samus Shepard, Link Freeman, Indie) and skills (`gds-gdd`,
`gds-game-architecture`, `gds-create-epics-and-stories`, `gds-dev-story`,
etc.). Run `bmad-help` if this ever becomes relevant — it'll route correctly
once GDD/game artifacts exist.

---

## bmad-loop — the automation layer

Everything above can be run by hand, one agent conversation at a time. The
**bmad-loop orchestrator** (a separate Python tool, installed alongside the
skills — see the earlier setup) automates the implementation phase: it spawns
fresh Claude Code sessions to run `bmad-dev-auto` (dev pass, self-reviewing),
optionally re-invokes it for an independent review pass, watches for
completion via hooks, and runs `bmad-loop-sweep` to triage deferred work.

- **`bmad-loop run`** — start the automated loop (walks `sprint-status.yaml`
  story by story)
- **`bmad-loop tui`** — dashboard view of an in-progress run
- **`bmad-loop validate`** — preflight check (this is what we ran earlier;
  it correctly reported `FAIL` since there's no sprint plan yet)
- **`bmad-loop confirm <story-key>`** — complete a story parked at
  `awaiting-operator` (its agent-doable work is done and committed, but it's
  blocked on a human action like buying a domain or granting an API key)
- **`/bmad-loop-resolve <story-key>`** — interactive, human-in-the-loop
  escalation resolution when an automated run hits a contradiction it can't
  safely resolve alone

Configuration lives in `.bmad-loop/policy.toml` (gates, review triggers,
per-stage adapter overrides, retention, etc. — see the comments in that file
for the full option set).

**Prerequisite before `bmad-loop run` will do anything**: `bmad-sprint-planning`
must have produced a `sprint-status.yaml`. Nothing to automate yet in this
repo — that's the very next thing needed if you want to use the loop.

---

## Illustrative walkthrough *(placeholder — not a real feature of this project)*

Say you wanted to add some made-up feature, e.g. "a CSV export for the sprint
board." Here's the shape of a full-pipeline run:

1. **`bmad-product-brief`** — nail down what "CSV export" actually means:
   which fields, who uses it, why now. → `planning_artifacts/product-brief.md`
2. **`bmad-prd`** — turn the brief into acceptance-criteria-bearing
   requirements. → PRD, gate: required before step 3.
3. **`bmad-architecture`** (Winston) — decide how it fits the existing
   invariants (e.g. does export go through the same data layer as the UI?).
   → architecture doc, gate: required.
4. **`bmad-create-epics-and-stories`** — break it into stories (e.g. "export
   button," "CSV formatting," "large-board pagination"). → epics/stories,
   gate: required.
5. **`bmad-check-implementation-readiness`** — sanity check PRD ↔ architecture
   ↔ stories actually agree before touching code. → readiness report, gate:
   required.
6. **`bmad-sprint-planning`** — turns the stories into `sprint-status.yaml`.
   → gate: required before implementation starts.
7. From here, **either**:
   - manually: `bmad-create-story` → `bmad-dev-story` (Amelia) →
     `bmad-code-review`, one story at a time, in fresh sessions each time; or
   - automated: `bmad-loop run`, which drives that exact create → dev → review
     cycle for every story in the sprint plan unattended, pausing only on a
     genuine escalation or an `awaiting-operator` story.
8. **`bmad-retrospective`** once the epic's done — what worked, what to change
   next time.

At any point, if reality contradicts the plan (the architecture doesn't
survive contact with the code, a story turns out to need a redesign), that's
what **`bmad-correct-course`** and `AGENT_OPERATING_RULES.md`'s "STOP, return
to Architect" rule are for — neither this pipeline nor bmad-loop is meant to
paper over a design that stopped working.
