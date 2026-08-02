# Engineering docs — index

Section 10 documentation structure from `AGENT_OPERATING_RULES.md`. Each
role writes only into its own folder — see the write-permission table in
Section 10.

- `_templates/` — fill these; never invent structure.
- `00-product/` — specs and acceptance criteria. Human-owned; agents draft,
  the human approves.
- `01-architect/` — ADRs and interface contracts.
- `02-developer/` — test evidence and implementation notes, per ticket.
- `03-reviewer/` — review verdicts.
- `traceability/matrix.md` — the spine: one row per acceptance criterion.
- `ledger/token-ledger.csv` — per-stage token/cost ledger (Section 9, Tier 2).

## Open tickets

None. No ticket has entered the Section 2 lifecycle yet.

## Where things live

See `../../STATE.md` for migration/repo status, `../../LEGACY.md` for what
predates this structure.
