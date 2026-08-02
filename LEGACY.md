# LEGACY.md

Directories and files that exist in this repo but were **not** produced
under the Section 2 six-stage lifecycle — no spec, no ADR, no fresh-session
review. Per Section 11's governing principle, these are grandfathered as-is
and enter the lifecycle only when next modified (Phase 4), not on a
schedule.

None of these currently touch auth, payments, or personal data — there is
no application code in this repo yet (confirmed in the Phase 0 audit,
2026-08-02).

| Path | Why it's here | Provenance |
|---|---|---|
| `_bmad/` | BMAD Method v6.10.0 module configuration | Vendored / installer-managed |
| `.claude/skills/` | Vendored BMAD skill packages (all 5 modules + bmad-loop) | Vendored / installer-managed |
| `.claude/settings.json` | Hook registrations written by `bmad-loop init` | Installer-managed |
| `.bmad-loop/` | bmad-loop orchestrator hook script, run state, `policy.toml` | Installer-managed |
| `scripts/verify.sh` | Section 4 verification gate | Built ad hoc, pre-migration |
| `scripts/hooks/` | pre-push hook + install README | Built ad hoc, pre-migration |
| `quickstart.md` | BMAD agent/skill reference doc | Written ad hoc, pre-migration |
| `design-artifacts/` | Empty WDS pipeline scaffold | Installer-managed, unpopulated |
| `_bmad-output/` | Empty BMM output scaffold | Installer-managed, unpopulated |

## Burn-down priority

Per Section 11 Phase 4: risk-first, not tidiness-first. None of the above
touches auth, money, personal data, or external input directly — the
closest exception is `.bmad-loop/bmad_loop_hook.py`, which runs
automatically on every Claude Code session (SessionStart/Stop/SessionEnd/
PreCompact). Everything else can wait indefinitely per the anti-goals —
none of it should be bulk-rewritten or retrofitted with invented specs.
