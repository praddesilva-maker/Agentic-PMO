# Traceability matrix

One row per acceptance criterion. Each role fills only its own column. See
Section 10 of `AGENT_OPERATING_RULES.md`.

| AC | Requirement | ADR | Tests | Code | Review | Accepted | Status |
|---|---|---|---|---|---|---|---|
| AC-1 | Unresolved skill-name reference in `quickstart.md` is reported, exit non-zero | ADR-001 | `verify-quickstart-skills.test.sh::test_ac1_unresolved_reference_reported` | `scripts/verify-quickstart-skills.sh` | | | In review |
| AC-2 | All referenced skill names resolve → exit 0, deduplicated summary count | ADR-001 | `verify-quickstart-skills.test.sh::test_ac2_all_resolved_with_dedup_and_no_false_positives` | `scripts/verify-quickstart-skills.sh` | | | In review |
| AC-3 | `quickstart.md` missing entirely → fails clearly, not silently, not a crash | ADR-001 | `verify-quickstart-skills.test.sh::test_ac3_missing_quickstart_file_fails_clearly` | `scripts/verify-quickstart-skills.sh` | | | In review |
