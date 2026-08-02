---
id: RT-001
type: spec
status: Approved
author_role: product
approved_by: Prad
date: 2026-08-02
---

# RT-001 — Quickstart skill-name validator

## Problem and business outcome

`quickstart.md` (and any future BMAD-related doc) references installed
skill names in prose and tables. Nothing checks those references stay
real. This already went stale once — `_bmad/wds/module-help.csv`
referenced skill names (`bmad-wds-idun`, `bmad-wds-project-brief`, etc.)
that don't exist in the actually-installed `.claude/skills/` tree, found
only by manual cross-check. A validator catches this class of drift
automatically, in a script, instead of by hand-auditing every time.

## In scope

A script that scans `quickstart.md` for skill-name references (backtick-
wrapped tokens matching installed-skill naming conventions) and checks
each one against the directories under `.claude/skills/`.

## Out of scope

- The reverse check (skills installed but not documented in
  `quickstart.md`). Real value, separate concern — a candidate for a
  future ticket, not bundled into this one.
- Checking any file other than `quickstart.md`.
- Auto-fixing anything. Report only.

## Acceptance criteria

- **AC-1**: Given `quickstart.md` references a skill name with no matching
  directory under `.claude/skills/`, when the validator runs, then it
  exits non-zero and lists every unresolved name.
- **AC-2**: Given every skill name `quickstart.md` references exists under
  `.claude/skills/`, when the validator runs, then it exits 0 and prints a
  summary count of names checked.
- **AC-3**: Given `quickstart.md` is missing entirely, when the validator
  runs, then it fails clearly with a stated reason — not a silent pass,
  not an unhandled crash.

## Non-functional requirements

- Read-only: never modifies any file it inspects.
- No network access.
- No new dependencies beyond what's already present on this machine (bash
  + coreutils).
- Runs in well under a second.

## Definition of done

- Script + tests committed on a `feat/RT-001-*` branch.
- Tests written first (Stage 3), fail on a genuine assertion, then pass
  after implementation (Stage 4).
- `scripts/verify.sh` behavior unaffected by this change.
- Reviewed (Stage 5) and accepted (Stage 6) through all six stages.
- `STATE.md` updated with friction notes, per Phase 3's purpose of finding
  where the process breaks while stakes are low.

## Assumptions

- "Skill-name reference" = backtick-wrapped tokens in `quickstart.md`
  matching the naming convention of installed skills (e.g. `bmad-*`,
  `wds-*`, `gds-*`, `bmm`/`tea`/`cis` skill prefixes) — not every backtick
  span in the file (some wrap file paths, commands, etc.). The validator
  needs a concrete rule to tell these apart; documented in the script
  itself as a comment where the pattern lives, per Section 3's "assertion,
  not just implementation" transparency norm.

## Budget

Token budget / dollar cap for this ticket: small, per Section 8 defaults
(Sonnet 5 for Stages 1/3/4, Opus 5 for Stage 2 Architect and Stage 5
Reviewer). Set 2026-08-02.

## Change Log

—
