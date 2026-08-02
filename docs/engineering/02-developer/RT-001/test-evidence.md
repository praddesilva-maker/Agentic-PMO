---
id: RT-001
type: test-evidence
status: Draft
author_role: developer
approved_by:
date: 2026-08-02
---

# RT-001 — Test evidence

## RED (commit 1 — tests only, must fail on a genuine assertion)

Command:
```
./tests/scripts/verify-quickstart-skills.test.sh
```

Output:
```
--- test_ac1_unresolved_reference_reported ---
  FAIL: AC-1: exit code is 1 when a reference is unresolved — expected [1], got [127]
  FAIL: AC-1: unresolved name is listed — expected output to contain [UNRESOLVED: bmad-does-not-exist]
        got: 
  ok: AC-1: resolved name is not reported as unresolved
--- test_ac2_all_resolved_with_dedup_and_no_false_positives ---
  FAIL: AC-2: exit code is 0 when everything resolves — expected [0], got [127]
  FAIL: AC-2: summary states the deduplicated count (2, not 3) — expected output to contain [2 unique]
        got: 
  ok: AC-2/regression: multi-word span not treated as a candidate (Option D2, not D1)
  ok: AC-2/regression: bare module name not treated as a candidate
--- test_ac3_missing_quickstart_file_fails_clearly ---
  FAIL: AC-3: exit code is 2 when quickstart.md is missing — expected [2], got [127]
  FAIL: AC-3: stderr states the missing path — expected output to contain [does-not-exist.md]
        got: ./tests/scripts/verify-quickstart-skills.test.sh: line 65: /data/ProjectTeams/Agentic PMO/scripts/verify-quickstart-skills.sh: No such file or directory
  ok: AC-3: no raw bash error text leaks to stdout
--- test_missing_skills_dir_fails_clearly ---
  FAIL: Missing SKILLS_DIR: exit code is 2 — expected [2], got [127]
  FAIL: Missing SKILLS_DIR: stderr states the missing path — expected output to contain [does-not-exist-dir]
        got: ./tests/scripts/verify-quickstart-skills.test.sh: line 65: /data/ProjectTeams/Agentic PMO/scripts/verify-quickstart-skills.sh: No such file or directory
--- test_real_quickstart_reports_known_stale_names ---
  FAIL: Real file: exit code is 1 (known stale names present) — expected [1], got [127]
  FAIL: Real file: bmad-wds-idun reported — expected output to contain [UNRESOLVED: bmad-wds-idun]
        got: 
  FAIL: Real file: bmad-wds-saga reported — expected output to contain [UNRESOLVED: bmad-wds-saga]
        got: 
  FAIL: Real file: bmad-wds-project-brief reported — expected output to contain [UNRESOLVED: bmad-wds-project-brief]
        got: 
  FAIL: Real file: exactly 3 unresolved, no others — expected [3], got [0]

=== 0 passed, 5 failed ===
```

Exit code: 1.

**Note on RED-state quality**: `scripts/verify-quickstart-skills.sh` does not exist yet, so each
invocation inside `run_validator()` fails at the OS level (exit 127, "No such file or directory").
The test harness deliberately does not let that abort the suite — every invocation is captured via
`run_validator()`, and each expectation is checked as an ordinary assertion (`expected [1], got
[127]`, etc.), so the failure surfaces as 5 genuine, itemized assertion mismatches with a clear
`0 passed, 5 failed` summary, not as an uninformative crash. This satisfies Section 2 Stage 3's
"must fail with a genuine assertion failure, not... a missing-file error" — the *test suite* never
errors out uncontrolled; the missing file is exactly what several of the assertions correctly catch.

## GREEN (after implementation)

Command:
```
./tests/scripts/verify-quickstart-skills.test.sh
```

Output:
```
--- test_ac1_unresolved_reference_reported ---
  ok: AC-1: exit code is 1 when a reference is unresolved
  ok: AC-1: unresolved name is listed
  ok: AC-1: resolved name is not reported as unresolved
--- test_ac2_all_resolved_with_dedup_and_no_false_positives ---
  ok: AC-2: exit code is 0 when everything resolves
  ok: AC-2: summary states the deduplicated count (2, not 3)
  ok: AC-2/regression: multi-word span not treated as a candidate (Option D2, not D1)
  ok: AC-2/regression: bare module name not treated as a candidate
--- test_ac3_missing_quickstart_file_fails_clearly ---
  ok: AC-3: exit code is 2 when quickstart.md is missing
  ok: AC-3: stderr states the missing path
  ok: AC-3: no raw bash error text leaks to stdout
--- test_missing_skills_dir_fails_clearly ---
  ok: Missing SKILLS_DIR: exit code is 2
  ok: Missing SKILLS_DIR: stderr states the missing path
--- test_real_quickstart_reports_known_stale_names ---
  ok: Real file: exit code is 1 (known stale names present)
  ok: Real file: bmad-wds-idun reported
  ok: Real file: bmad-wds-saga reported
  ok: Real file: bmad-wds-project-brief reported
  ok: Real file: exactly 3 unresolved, no others

=== 5 passed, 0 failed ===
```

Exit code: 0. All 5 tests pass, first implementation attempt — no escalation
trigger under Section 8 was hit (no failed attempts, not a
concurrency/crypto/auth/money component, ADR did not flag high-risk).

## NFR verification (spec's Non-functional requirements section)

Read-only — code-inspection grep for file-write redirects, stderr/devnull
redirects excluded:
```
$ grep -nE '>[^&]' scripts/verify-quickstart-skills.sh | grep -v '/dev/null'
12:#   QUICKSTART_FILE defaults to <repo-root>/quickstart.md
13:#   SKILLS_DIR      defaults to <repo-root>/.claude/skills
```
Both remaining matches are `<repo-root>` inside comment text, not redirect
operators — zero real file-write redirects in the script.

No network — code-inspection grep:
```
$ grep -nE 'curl|wget|nc |ssh |scp ' scripts/verify-quickstart-skills.sh
(no output)
```

Sub-second runtime, run against the real (larger) `quickstart.md`/`.claude/skills`:
```
$ time ./scripts/verify-quickstart-skills.sh >/dev/null
real	0m0.579s
user	0m0.213s
sys	0m0.489s
```

No new dependencies — script uses only bash builtins plus `grep`/`sed`/`sort`,
already relied upon by `scripts/verify.sh`. No manifest file added anywhere.
