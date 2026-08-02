---
id: ADR-001
type: adr
status: Approved
author_role: architect
approved_by: Prad
date: 2026-08-02
supersedes:
---

# ADR-001 — quickstart-skill-validator

## Context and constraints

RT-001 (`docs/engineering/00-product/specs/RT-001-quickstart-skill-validator.md`,
Approved 2026-08-02) requires a script that scans `quickstart.md` for
skill-name references and checks each one against the directories under
`.claude/skills/`, exiting non-zero and listing every unresolved name when
one is found (AC-1), exiting 0 with a summary count when all resolve (AC-2),
and failing clearly — not silently, not with a crash — when `quickstart.md`
is missing entirely (AC-3).

Constraints taken as fixed from the spec and from `AGENT_OPERATING_RULES.md`:

- Bash + coreutils only. No new dependencies, no network, read-only,
  sub-second (spec NFRs).
- Must sit next to `scripts/verify.sh` and `scripts/hooks/pre-push` in house
  style — same kind of header comment, `set` discipline, structured
  sections (Section 6 of the spec's "In scope"; explicit instruction from
  the ticket).
- `scripts/verify.sh` behaviour must be unaffected (spec DoD). This is not
  Stage-2 optional — Section 4 of `AGENT_OPERATING_RULES.md` treats
  `verify.sh` as production code requiring its own lifecycle for any
  change, so folding this validator into it is off the table for this
  ticket regardless of technical merit.
- The repo currently has **zero application code** (confirmed in
  `docs/engineering/01-architect/adr/ADR-000-pre-adoption-architecture.md`)
  and no chosen stack (`scripts/verify.sh` detects `STACK=none`). This is
  the first real code artifact produced through the Section 2 lifecycle —
  whatever pattern this ADR sets, the next ticket inherits it.

**Grounding performed against the actual files** (not assumed):

- `quickstart.md` was read in full and every backtick span extracted
  (`grep -oE '`+[^`]+`+' quickstart.md`). Real skill-name references look
  like `` `bmad-prd` ``, `` `wds-4-ux-design` ``, `` `gds-gdd` `` — a bare
  token, prefix + one or more hyphen-separated lowercase/digit segments,
  and nothing else inside the backticks. Alongside them, the file also
  backtick-wraps: file paths (`` `_bmad/wds/module-help.csv` ``,
  `` `.bmad-loop/policy.toml` ``, `` `AGENT_OPERATING_RULES.md` ``), bare
  module names (`` `gds` ``), status words (`` `anytime` ``,
  `` `required=true` ``, `` `FAIL` ``), and — critically —
  **CLI invocations with subcommands/arguments**:
  `` `bmad-loop run` ``, `` `bmad-loop tui` ``, `` `bmad-loop validate` ``,
  `` `bmad-loop confirm <story-key>` ``, and
  `` `/bmad-loop-resolve <story-key>` ``.
- `.claude/skills/` was listed directly: 122 subdirectories, all matching
  exactly `bmad-*`, `wds-*`, `gds-*`, plus two flat, unprefixed names
  (`memory`, `sync`) that never appear referenced in `quickstart.md`.
  **`bmad-loop` itself is not a directory under `.claude/skills/`** — the
  file's own prose confirms why: it's "a separate Python tool, installed
  alongside the skills," not a skill. `bmad-loop-resolve`,
  `bmad-loop-setup`, `bmad-loop-sweep` *are* real skills, but they're never
  referenced in the file as bare tokens — only inside multi-word CLI
  strings or with a leading `/` plus a trailing argument placeholder.
- `quickstart.md`'s own "Known issue" callout (the wds section) quotes
  `` `bmad-wds-idun` ``, `` `bmad-wds-saga` ``, `` `bmad-wds-project-brief` ``
  as backtick-wrapped examples of the exact stale-name problem the spec
  cites as motivation — and none of those three exist under
  `.claude/skills/` either. **This means a correct, literal implementation
  of AC-1 will currently fire against the real `quickstart.md`, today,
  inside a paragraph that is accurately describing a *different* file's
  historical drift.** This is not a bug to be designed around; it's
  addressed explicitly in Consequences and Test strategy below, because it
  changes what "the real file currently passes" means for anyone running
  this script for the first time.

## Options considered

Two independent decisions are bundled in this ADR: (1) how the script is
built and where it lives, and (2) how it decides a backtick span *is* a
skill-name reference. Both need a documented rejected alternative per
Section 2.

### Option A — Standalone bash script, sibling to `scripts/verify.sh` (chosen for decision 1)

A new `scripts/verify-quickstart-skills.sh`, independently runnable,
following `verify.sh`'s header-comment/`set -uo pipefail`/labelled-section
style. Not wired into `verify.sh`'s 8-check pipeline in this ticket.

Pros: zero new dependencies (matches NFR exactly), matches sibling house
style as instructed, keeps `verify.sh` untouched (DoD requirement), single
responsibility (a documentation-consistency check is a different category
from `verify.sh`'s stack-detection checks), trivially runnable in
sub-second time as its own command.

Cons: not yet part of the one-command merge gate — a human or a future
ticket has to remember to run it, or wire it in as a 9th `verify.sh` check
later.

### Option B — Python script with a markdown-aware parser

Use Python (e.g. stdlib `re` plus a hand-rolled scanner, or a markdown AST
library) for more robust parsing of code fences vs. inline spans.

**Rejected.** The spec's NFRs are explicit: bash + coreutils, zero new
dependencies. The repo has no `pyproject.toml`/`requirements.txt` — picking
Python here would be the first stack decision in a repo that has
deliberately stayed stack-agnostic (`scripts/verify.sh` currently reports
`STACK=none`), and that decision belongs to a PRD/architecture ticket for
the product itself, not to a documentation-linter ticket. It also fails
`verify.sh` check 8 (dependency allow-list against the active ADR) for no
benefit: the extra robustness (handling nested code fences, etc.) isn't
needed — `quickstart.md` has no fenced code blocks containing backticked
skill names today, and the spec scope is one file, not a general markdown
toolchain.

### Option C — Fold the check into `scripts/verify.sh` as a 9th step

Add the skill-reference scan as another numbered check in the existing
gate script.

**Rejected.** The spec's Definition of Done states `scripts/verify.sh`
behaviour must be unaffected by this change — this option directly
contradicts an approved-spec constraint, not just a style preference.
`AGENT_OPERATING_RULES.md` Section 4 also treats `verify.sh` as
production code requiring its own full lifecycle for any change, which
this ticket's budget and scope were not sized for. Noted as a natural
fast-follow ticket once this script has run cleanly a few times (see
Rollback plan).

### Option D — Skill-name token extraction: first-word-of-span vs. whole-span match (decision 2)

**D1 — extract the first whitespace-delimited word of every backtick span,
strip a leading `/`, test that word against the prefix pattern.**
Rejected: verified against the real file, this produces false positives.
`` `bmad-loop run` ``, `` `bmad-loop tui` ``, `` `bmad-loop validate` ``,
`` `bmad-loop confirm <story-key>` `` all first-word-extract to
`bmad-loop`, which is genuinely not a skill directory (it's a separate CLI
tool, by the file's own words) — a literal, correct implementation would
flag `bmad-loop` as unresolved four times over, on a file that isn't
actually wrong. That's exactly the kind of "crying wolf" outcome AC-1's
value depends on not producing.

**D2 — require the *entire* trimmed backtick-span content to match the
skill-prefix pattern, anchored start-to-end (chosen).** Concretely:
`^(bmad|wds|gds)-[a-z0-9]+(-[a-z0-9]+)*$` applied to the full span. This
naturally and correctly excludes, with no special-casing needed: every
file path (contains `/`, `.`, or leading `_`/`.`), every bare module name
(`` `gds` `` has no trailing `-segment`), every CLI invocation with a
subcommand or argument (contains whitespace or `<...>`), and every status
word. Verified by hand against all ~90 distinct backtick spans in the real
file: the *only* tokens the anchored whole-span pattern extracts are
genuine skill-name-shaped tokens — the legitimate ones (`bmad-prd`,
`wds-4-ux-design`, …) and the three known-stale ones inside the "Known
issue" callout (`bmad-wds-idun`, `bmad-wds-saga`, `bmad-wds-project-brief`)
— nothing else. Trade-off accepted: this also means genuine skill
mentions embedded in CLI-syntax spans (e.g. `bmad-loop-resolve` inside
`` `/bmad-loop-resolve <story-key>` ``) are **not** checked — a false
negative, not a false positive. Given the ticket's stated motivation is
catching wrong names, not exhaustively cataloguing every mention, erring
toward under-checking rather than crying wolf is the correct trade-off,
and it's cheap to extend later (see Rollback / follow-up).

## Decision

Build **Option A + Option D2**: a standalone bash script,
`scripts/verify-quickstart-skills.sh`, sibling to `scripts/verify.sh`,
that:

1. Extracts every backtick-delimited span from `quickstart.md`.
2. Keeps only spans whose entire trimmed content matches
   `^(bmad|wds|gds)-[a-z0-9]+(-[a-z0-9]+)*$` — documented as a comment
   directly above the pattern definition in the script, per the spec's
   Assumptions section and Section 3's evidence/transparency norm.
3. De-duplicates the surviving candidates (a name referenced twice is
   checked once; the "summary count" AC-2 asks for is a count of unique
   names).
4. For each unique candidate, tests whether `.claude/skills/<candidate>`
   exists **and is a directory** (not a stray file of the same name).
5. Reports and exits per the contract in the next section.

No exemption/allowlist mechanism is added for the three known-stale names
inside `quickstart.md`'s own "Known issue" prose. That would require
either prose-context detection (fragile, not bash/grep-shaped, violates
KISS) or an explicit ignore-marker convention that nothing in the approved
spec asks for and that would require editing `quickstart.md`'s content —
out of scope ("checking any file other than `quickstart.md`" is explicitly
in scope only as the *thing checked*, not as something this ticket edits;
"no auto-fixing anything" is explicit). The validator's job, per spec, is
a literal syntactic check, and it is not wrong here: those three names do
not exist under `.claude/skills/` today.

## Consequences

- **This script will exit non-zero the first time it is run against the
  real `quickstart.md`**, listing `bmad-wds-idun`, `bmad-wds-saga`,
  `bmad-wds-project-brief` as unresolved — not because the tool is broken,
  but because the "Known issue" callout backtick-wraps its counter-example
  names the same way live references are wrapped. This is flagged here so
  Stage 4/5 do not mistake it for an implementation bug. Recommended
  handling, **outside this ticket's deliverable** (script + tests only,
  per DoD): a human or a follow-up doc ticket reformats those three
  examples in `quickstart.md` to not use inline-code backticks (e.g. plain
  quotes), which resolves the noise without touching the validator. Until
  that happens, `AC-2`'s "given every skill name references exists" clean
  0-exit state is **not yet true of the real file** — this is recorded
  explicitly so Gate 3 doesn't treat a real-file run as a smoke test for
  "no bugs," only as a demonstration that AC-1 works and is currently,
  correctly, triggered.
- **Cost**: small. One script (~60–90 lines including comments, well under
  the 400-line Stage 4 cap), one hand-rolled bash test file, a handful of
  small fixture files. No build step, no install step.
- **Lock-in**: none beyond bash itself, already a hard dependency of this
  entire repo's tooling (`verify.sh`, `pre-push`). No package manager, no
  version pin to manage.
- **Maintenance**: owned by whoever owns `scripts/` generally — no new
  owner introduced. The regex is the one piece of encoded knowledge that
  needs updating if a fourth skill-prefix convention is ever introduced
  (e.g. a new module beyond bmm/tea/cis/gds/wds with a different prefix
  shape) or if `memory`/`sync`-style flat names start being referenced in
  `quickstart.md` — both are one-line regex edits, not redesigns.
- **`scripts/verify.sh` is unaffected**, per DoD — its check 3 ("Full test
  suite") will continue to report `BLOCKED: no stack manifest found` even
  after this ticket lands, because the new bash-based tests aren't
  detected by its `package.json`/`pyproject.toml`/`go.mod`/`Cargo.toml`
  stack-sniffing. This is a known, accepted gap, not a defect of this
  design — recorded so nobody is surprised `verify.sh`'s output doesn't
  change.
- **Precedent-setting**: this is the first application code in the repo
  produced through the full Section 2 lifecycle. Its structure (header
  comment citing the spec ID, `set -uo pipefail`, labelled sections,
  explicit exit-code contract) is the template the next ADR's script
  inherits by default unless explicitly deviated from.

## Interfaces / contracts / data model changes

No data model changes — this is a stateless, single-invocation, read-only
CLI script. No persisted state, no config file written, no schema.

**CLI surface:**

```
scripts/verify-quickstart-skills.sh [QUICKSTART_FILE] [SKILLS_DIR]
```

- `QUICKSTART_FILE` (optional, positional 1): path to the file to scan.
  Defaults to `<repo-root>/quickstart.md` (repo root resolved the same way
  `verify.sh` does: `cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd`).
- `SKILLS_DIR` (optional, positional 2): path to the ground-truth skills
  directory. Defaults to `<repo-root>/.claude/skills`.
- Both overrides exist **solely so the test suite can point the script at
  isolated fixtures** without touching real repo files — required because
  the real `quickstart.md` does not currently satisfy AC-2's precondition
  (see Consequences), so AC-2's "all resolved" test must run against a
  controlled fixture, not the live file, to be deterministic.

**Exit codes** (three-tier, grep-style convention — chosen because AC-1
and AC-3 are semantically different failure classes and tests need to
assert them independently; documented in the script header since
`verify.sh`'s own `fail()` doesn't distinguish these):

| Code | Meaning | Which AC |
|---|---|---|
| `0` | All skill-name references resolved (or none found) | AC-2 |
| `1` | One or more unresolved skill-name references found | AC-1 |
| `2` | Usage/environment error — `quickstart.md` missing, unreadable, or `SKILLS_DIR` missing/not a directory | AC-3 |

**Output format** (stdout for normal reporting, stderr reserved for
usage/environment errors so failures are `grep`-able and don't pollute
stdout parsing by a future caller):

- Success (AC-2): a single summary line to stdout, e.g.
  `OK: 55 unique skill-name reference(s) in quickstart.md, all resolved against .claude/skills/.`
  then exit 0.
- Unresolved (AC-1): one line per unresolved name to stdout, prefixed
  consistently (e.g. `UNRESOLVED: bmad-wds-idun`), followed by a summary
  line (`N of M unique reference(s) unresolved.`), then exit 1.
- Missing/invalid input (AC-3): a single, clearly worded line to stderr
  stating the file/path and the reason (e.g.
  `ERROR: quickstart.md not found at <path> — nothing to validate.`), then
  exit 2. No stack trace, no raw bash "No such file or directory" leak —
  the script guards the file-existence check explicitly before attempting
  to read.

## Failure modes and error-handling strategy

- **`quickstart.md` missing** → AC-3, exit 2, explicit stderr message
  (guarded via `[ -f "$QUICKSTART_FILE" ]` before any read attempt — never
  let `grep`/`cat` fail first and leak a raw OS error).
- **`SKILLS_DIR` missing or not a directory** → same class of error as
  AC-3 (not explicitly named in the spec's ACs, but the same "fail
  clearly, not silently, not a crash" principle applies), exit 2, explicit
  stderr message naming the path.
- **`quickstart.md` exists but unreadable (permissions)** → treated as an
  environment error, exit 2, not an unhandled crash.
- **Zero skill-name-shaped tokens found in an otherwise-valid file** →
  treated as a pass (0 of 0 unresolved), exit 0, with the summary line
  explicitly stating `0 unique skill-name reference(s) found` so it's
  visually distinguishable from "checked N, all resolved" rather than
  silently looking identical. Accepted risk, documented rather than
  engineered around: a regex that stops matching due to a future edit to
  `quickstart.md`'s formatting conventions would silently degrade to
  "always passes" rather than erroring. Out of scope for this ticket
  (would need a minimum-expected-count heuristic); flagged as a known
  limitation for a future revision.
- **`set -e` vs. "grep found nothing" gotcha**: extraction and filtering
  steps use `grep`/`[[ =~ ]]`, both of which return non-zero on "no
  match" — under `set -e` that would abort the script on the (valid,
  expected) case of zero unresolved names. The script's control flow must
  account for this explicitly (e.g. capturing match results into a
  variable via a construct that doesn't trip `set -e`, or checking counts
  rather than relying on grep's own exit code to drive control flow) —
  called out here because `verify.sh`'s house rule against appending
  `|| true` is about not faking a *gate* pass, not about forbidding
  ordinary defensive control-flow around "zero matches is a valid
  outcome." The implementer should not read that house rule as banning
  this.
- **Stray non-directory entry under `.claude/skills/`** matching a
  candidate name (e.g. a file, not a directory) → must not count as
  resolved. The existence check is `[ -d "$SKILLS_DIR/$candidate" ]`,
  never a bare `[ -e ... ]`.
- **The "Known issue" callout self-reference** (see Context) → not a
  script failure mode per se, but an expected, correct, currently-true
  non-zero exit against the real file. Documented so it isn't mistaken
  for a bug during Stage 5 review.

## Security posture

Minimal attack surface, and here's why: this is a local, read-only,
single-file, no-network bash script operating on repo-tracked content that
already goes through the same PR review as code. No authentication or
authorization applies (no remote calls, no credentials, nothing to
authenticate to). No secrets or PII are read, stored, or logged — the
inputs are a markdown doc and a directory listing of skill names, both
non-sensitive. No `eval`, no dynamic sourcing of file contents, no command
substitution built from untrusted input. Directory-listing extraction
should use `find "$SKILLS_DIR" -mindepth 1 -maxdepth 1 -type d -printf '%f\n'`
(or an equivalent loop) rather than parsing `ls` output, per standard bash
hygiene, even though the trusted, repo-local nature of `.claude/skills/`
makes this a defense-in-depth choice rather than a response to a live
threat. All path variables are double-quoted throughout to avoid
word-splitting/glob issues. The matching regex
(`^(bmad|wds|gds)-[a-z0-9]+(-[a-z0-9]+)*$`) is anchored and has no nested
ambiguous quantifiers, so it is linear-time — no ReDoS exposure even on
adversarially crafted input, which is moot anyway since input is
repo-tracked and PR-reviewed, not attacker-supplied at runtime. No writes
occur anywhere (satisfies the NFR directly, not just as a security
property): the script's own logic never opens any file for writing, never
shells out to anything that could mutate state (no `sed -i`, no `>`
redirects to source files), which should be verified in review by
grepping the script for write-capable constructs as a cheap static check.

## Test strategy

Pure bash test harness (no bats/shunit2 — neither is installed, and
installing one would violate the zero-new-dependencies NFR), at
`tests/scripts/verify-quickstart-skills.test.sh`, with fixtures under
`tests/fixtures/rt-001-quickstart-skill-validator/`. Each fixture pair is
a minimal `quickstart.md`-shaped file plus a minimal `.claude/skills/`-shaped
directory, so tests are deterministic and independent of the real file's
current state (which, per Consequences, does not itself satisfy AC-2
today).

| AC | Fixture | Invocation | Assertion |
|---|---|---|---|
| AC-1 | `ac1/quickstart.md` containing at least one bare skill-shaped backtick token (e.g. `` `bmad-does-not-exist` ``) plus a legitimate one; `ac1/skills/` containing only the legitimate one's directory | `verify-quickstart-skills.sh ac1/quickstart.md ac1/skills` | Exit code `1`; stdout contains `UNRESOLVED: bmad-does-not-exist` and does *not* list the legitimate name as unresolved |
| AC-2 | `ac2/quickstart.md` with N distinct skill-shaped backtick tokens (including at least one duplicate, to exercise dedup); `ac2/skills/` containing a directory for every one of them | `verify-quickstart-skills.sh ac2/quickstart.md ac2/skills` | Exit code `0`; stdout summary line states the deduplicated count |
| AC-3 | none — pass a deliberately nonexistent path | `verify-quickstart-skills.sh /nonexistent/quickstart.md ac2/skills` | Exit code `2`; stderr contains a stated reason naming the missing path; no raw/unhandled bash error text |

Additional coverage beyond the bare ACs (still testing this design, not
scope creep — these are regression tests for the false-positive risk
identified in Options considered):

- A regression test asserting `` `bmad-loop run` ``-style multi-word
  backtick spans are **not** extracted as candidates (proves Option D2 was
  actually implemented, not D1) — fixture reuses the real "bmad-loop" text
  pattern.
- A regression test asserting a bare module name like `` `gds` `` (no
  trailing hyphen segment) is **not** extracted.
- One pinned integration test that runs the script against the **real**
  `quickstart.md` and `.claude/skills/` and asserts it currently exits `1`
  with exactly the three known names
  (`bmad-wds-idun`, `bmad-wds-project-brief`, `bmad-wds-saga`) listed and
  nothing else — turning the Context-section finding into a tracked,
  intentional assertion rather than an undocumented surprise. This test is
  expected to start passing differently (exit 0) only once someone fixes
  the callout's backtick styling in `quickstart.md` — at which point the
  test itself gets updated in its own commit, per Section 2 Stage 4's rule
  on changing tests.

Stage 3 requirement satisfied: all of the above are written against this
ADR/the spec before `scripts/verify-quickstart-skills.sh` exists, so they
fail with a genuine assertion failure (script not found / non-2 exit code
mismatch) rather than a collection error, and the raw failing output goes
into the Stage 3 PR description; raw passing output goes into Stage 4's.

NFR verification (not AC-mapped, but required by spec): read-only is
verified by code inspection in review (grep the script for write-capable
constructs, per Security posture); no-network is verified the same way
(grep for `curl`/`wget`/`nc`/`ssh`); sub-second runtime is verified by
capturing `time scripts/verify-quickstart-skills.sh` raw output in the
Stage 3/4 test-evidence doc, per Section 3's "raw output, not a claim"
rule.

## Dependencies

None new. The script uses only bash builtins (`[[ =~ ]]`, parameter
expansion) plus `grep`, `find`, `sort` — all POSIX coreutils already
present and already relied upon by `scripts/verify.sh` and
`scripts/hooks/pre-push`. No package manager entry is added anywhere (no
`package.json`, no `requirements.txt`, nothing for `verify.sh` check 6 —
dependency vulnerability audit — or check 8 — dependency allow-list — to
newly evaluate). This directly honors the spec's NFR ("No new dependencies
beyond what's already present on this machine: bash + coreutils"); no
exception is being requested.

## Rollback plan

The script is additive and side-effect-free: it reads two paths and
prints to stdout/stderr. Rolling back is `git revert` of the commit(s)
adding `scripts/verify-quickstart-skills.sh` and its tests — nothing else
in the repo references or depends on it (per the Decision, it is
explicitly *not* wired into `scripts/verify.sh` or `pre-push` in this
ticket), so there is no cascading cleanup, no config to unwind, and no
migration to reverse. If the design is found not to survive contact with
reality during Stage 4 (per Section 2's "STOP, return to Architect" rule)
— e.g. the anchored-whole-span regex turns out to miss a real reference
shape not present in today's file — the fix is a superseding ADR, not a
silent implementation deviation, per Section 2's explicit requirement.

Natural, explicitly-deferred follow-ups (not part of this ADR's scope,
listed so they aren't lost): (1) wire this script into `scripts/verify.sh`
as a 9th check, once it's been run cleanly a few times, via its own
ADR/spec cycle since `verify.sh` changes require the full lifecycle; (2)
the reverse check (skills installed but undocumented) — explicitly
out-of-scope per RT-001; (3) resolving the "Known issue" callout's
backtick styling in `quickstart.md` so the real file actually reaches a
clean AC-2 state.

## AC → component map

| AC | Satisfied by |
|---|---|
| AC-1 | `scripts/verify-quickstart-skills.sh` (extraction + `.claude/skills/<name>` directory-existence check + exit-1 listing path); `tests/scripts/verify-quickstart-skills.test.sh` (AC-1 fixture case, `ac1/`) |
| AC-2 | `scripts/verify-quickstart-skills.sh` (dedup + all-resolved exit-0 summary path); `tests/scripts/verify-quickstart-skills.test.sh` (AC-2 fixture case, `ac2/`, including duplicate-name dedup coverage) |
| AC-3 | `scripts/verify-quickstart-skills.sh` (`[ -f "$QUICKSTART_FILE" ]` guard, exit-2 stderr path); `tests/scripts/verify-quickstart-skills.test.sh` (AC-3 nonexistent-path case) |
| NFR: read-only / no network / no new deps / sub-second | `scripts/verify-quickstart-skills.sh` (implementation constraints, see Security posture and Dependencies); verified via Stage 3/4 raw `time` output and code-inspection note in the PR, per Section 3 |
