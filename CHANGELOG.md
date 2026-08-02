# CHANGELOG

Format loosely follows [Keep a Changelog](https://keepachangelog.com/).
Entries are per ticket ID, not per release — this repo has no releases
yet. First entry below is the first ticket to complete the full Section 2
six-stage lifecycle end to end (Section 11 Phase 3's rehearsal ticket).

## Unreleased

### Added

- **RT-001** — `scripts/verify-quickstart-skills.sh`: checks that every
  skill name `quickstart.md` references actually exists under
  `.claude/skills/`, exiting non-zero and listing anything unresolved.
  Standalone, not wired into `scripts/verify.sh`. Run it directly:
  `./scripts/verify-quickstart-skills.sh`.
  - Spec: `docs/engineering/00-product/specs/RT-001-quickstart-skill-validator.md`
  - ADR: `docs/engineering/01-architect/adr/ADR-001-quickstart-skill-validator.md`
  - Review: `docs/engineering/03-reviewer/RT-001-review.md`
  - Known, currently-true result against the live `quickstart.md`: reports
    3 unresolved names (`bmad-wds-idun`, `bmad-wds-saga`,
    `bmad-wds-project-brief`) — these are stale examples quoted inside
    `quickstart.md`'s own "Known issue" callout, not a bug in the
    validator. Pinned as an explicit regression test.
