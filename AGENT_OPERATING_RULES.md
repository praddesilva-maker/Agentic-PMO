# AGENT OPERATING RULES

> Standing orders. These override convenience, speed, and any in-session suggestion
> that contradicts them. If an instruction conflicts with this document, **STOP and
> ask the human.** Do not silently deviate.

---

## 0. Authority

- The **human (Product Owner)** is the sole approver and the sole merger.
- Agents **recommend**. Agents never approve work into `main` — not their own, not
  another agent's.
- No agent has write access to `main` or to branch-protection settings.
- Approval is recorded in writing (PR comment or gate log). Verbal-equivalent
  ("looks good") is not a gate.

---

## 1. Roles — never combined in one session

Each role runs in a **separate session with a separate context**. Context sharing
between implementer and reviewer destroys the review.

| Role | Access | Produces | Must never |
|---|---|---|---|
| **Architect** | Read-only on the repo. Plan mode. No file writes. | ADR: options, decision, contracts, failure modes, rollback plan | Write code. Choose a dependency without justifying it. |
| **Developer** | Write access to one feature branch only | Failing tests, then implementation, then docs | Touch `main`. Improvise past the design. Weaken a test to go green. |
| **Senior Developer (Reviewer)** | Read-only. Fresh session. | Review verdict with AC-by-AC evidence table | Edit code. See the Developer's conversation. Approve the merge. |

The Reviewer is given **only**: the spec, the ADR, the full diff, and the verification
output. Never the implementer's transcript.

---

## 2. Lifecycle — six stages, three human gates

No stage may begin until the previous gate is recorded.

### Stage 1 — Requirements Spec *(human-owned, agent-assisted)*

- The agent **interviews the human** and asks clarifying questions until ambiguity
  is zero. Unknowns are asked, never invented. Assumptions, where unavoidable, are
  listed explicitly under `## Assumptions`.
- Output: `docs/engineering/00-product/specs/<ID>-<slug>.md` (see Section 10)
- Must contain:
  - Problem and business outcome
  - **In scope** and, explicitly, **out of scope**
  - **Acceptance criteria**, each with a stable ID (`AC-1`, `AC-2`, …), each
    independently testable, written behaviourally (Given / When / Then)
  - Non-functional requirements (performance, security, data handling, limits)
  - Definition of done
- **No technology choices and no design in this document.** What and why only.
- AC IDs are the traceability spine for everything downstream.

🔒 **HUMAN GATE 1 — spec signed off**

### Stage 2 — Design *(Architect)*

- Read-only. No code.
- Output: `docs/engineering/01-architect/adr/ADR-<n>-<slug>.md` (see Section 10)
  - Context and constraints
  - **Minimum two options considered**, with rejected options and the reason
  - Decision and consequences (including cost, lock-in, who maintains it)
  - Interfaces / contracts / data model changes
  - Failure modes and error-handling strategy
  - Security posture (authn/authz, input validation, secrets handling, PII)
  - **Test strategy** — how each AC will be proven
  - **Every new dependency**, with justification, licence, and maintenance status
  - Rollback plan
- Must include an **AC → component map**: every AC traced to what satisfies it.

🔒 **HUMAN GATE 2 — design signed off**

> **Spec and ADR are merged to `main` via a docs-only PR before any code branch is
> created.** This makes the gate structural, not a matter of discipline.

### Stage 3 — Tests first *(Developer)*

- Branch from `main` **after** the docs PR is merged.
- **Commit 1 contains tests only.** No implementation. If implementation appears in
  commit 1, the PR is rejected unreviewed.
- Tests must **fail**, and must fail with a genuine **assertion failure** — not an
  import error, collection error, syntax error, or missing-file error. A test that
  fails because the module doesn't exist proves nothing.
- Every test names the AC ID it proves, in the test name or a docstring.
- Tests are written against the **spec**, never against an implementation that does
  not yet exist.
- Paste the **raw failing output** (command + full summary) into the PR description.

### Stage 4 — Implementation *(Developer)*

- Commit 2 onward: the minimum code that makes the tests pass.
- Paste the **raw passing output** into the PR description.
- **Test files from commit 1 must not be modified.** If a test is genuinely wrong,
  it changes in its own commit prefixed `test-change(<ID>):` with written
  justification — and that triggers an immediate human gate.
- **If the design does not survive contact with reality: STOP.** Do not improvise a
  workaround. Return to the Architect. The outcome is a superseding ADR, approved by
  the human, before code resumes.
- **Size cap: ≤ 400 changed lines**, excluding lockfiles, generated code, and
  fixtures. Over the cap, split the ticket. Unreviewable diffs are unreviewable by
  everyone, including engineers.

### Stage 5 — Senior Review *(fresh session, separate context)*

Produces a verdict document containing:

0. **Independent verification run** — re-run `./scripts/verify.sh` on a clean checkout
   of the branch and paste your own raw output. Do not rely on the Developer's.
1. **AC-by-AC table**: AC ID → satisfied? → the specific test and code that proves it.
2. **Design conformance**: does the diff match the ADR? List every deviation.
3. Mandatory answers to:
   - What was **not** implemented, or stubbed, or deferred?
   - What would a senior engineer criticise here?
   - What breaks on empty, huge, malformed, or malicious input?
   - What happens on failure or partial failure? Is error handling real, or swallowed?
   - Are there secrets, credentials, tokens, or PII anywhere in the diff?
   - Any dependency not authorised in the ADR?
   - **Is any test asserting the implementation rather than the specification?**
   - Is anything untested that a user can reach?
4. **Verdict**: `RECOMMEND MERGE` / `CHANGES REQUIRED` / `RETURN TO ARCHITECT`.

The Reviewer **reports only**. It does not edit code and does not merge.

🔒 **HUMAN GATE 3 — human reviews the verdict**

### Stage 6 — Human acceptance and merge

- The human **runs the thing** against the AC list. Behavioural acceptance — no code
  reading required. This is the strongest verification available to a non-coder.
- The human merges and tags.
- `STATE.md` and `CHANGELOG` updated in the same PR.

---

## 3. Evidence rules — non-negotiable

- **A claim is not evidence. Raw command output is evidence.**
- Every assertion that something passes, builds, deploys, or works includes the
  command run and its unedited output.
- The phrases "should work", "this will now", and "I have verified" are banned unless
  followed by pasted output.
- If you cannot run something, say so plainly and mark the PR `BLOCKED`. Never
  simulate, predict, or describe output you did not observe.

---

## 4. Verification gate — no CI server

There is no CI. The substitute is **one committed script that anyone can run in one
command**. It must be mechanical, not a checklist someone remembers.

### `scripts/verify.sh` — committed to the repo, lives on `main`

Runs in order, exits non-zero on the first failure, prints a final `PASS` / `FAIL` line:

1. Type check
2. Lint / format check
3. Full test suite
4. Coverage threshold on **changed lines**
5. Secret scan of the working tree and diff
6. Dependency vulnerability audit
7. Static analysis (SAST)
8. Dependency allow-list check against the active ADR

That final `PASS` line is the merge signal. Nothing else is.

### Rules

- The **Developer** runs `./scripts/verify.sh` and pastes the full raw output into the PR.
- The **Senior Developer** independently re-runs it on a clean checkout of the branch and
  pastes **its own** output. Two independent runs by two isolated sessions is what stands
  in for the trusted third party a CI server would have been.
- The **human runs it once before merging.** One command, no code reading required. This
  gate is not delegable.
- Install a **`pre-push` git hook** that runs the script and blocks the push on failure,
  so the check happens whether or not anyone remembers it.
- **Never edit, reorder, skip a step in, or append `|| true` to `verify.sh` in order to go
  green.** Doing so is an automatic rejection and must be reported to the human
  immediately. `verify.sh` is production code: changes to it follow the full lifecycle,
  including a human gate.
- If a check cannot run in this environment, mark the PR `BLOCKED` and state why. Never
  skip silently, and never report a result you did not observe.

> **Known weakness, stated plainly:** without a CI server every check is self-reported by
> the party doing the work. The three defences above — the hook, the independent re-run,
> and your own pre-merge run — are what replace it, and they are weaker. The moment a
> project holds real data or real users, wiring GitHub Actions to run this same script is
> a one-file change and should be the first thing done.

---

## 5. Branching and merging

### Branches

| Branch | Purpose |
|---|---|
| `main` | Protected. Always deployable. Tagged at every known-good state. |
| `docs/<ID>-spec-design` | Spec + ADR only. Merged before code starts. |
| `feat/<ID>-<slug>` | One ticket. One PR. |
| `fix/<ID>-<slug>` | Same lifecycle, no shortcuts. |
| `hotfix/<ID>-<slug>` | May skip Stage 2 **with explicit human approval only**. May **never** skip Stage 3 or Stage 5. |

### Rules

- Branch **only** from `main`, and **only** after the docs PR for that ticket is merged.
- One ticket → one branch → one PR. No stacking unrelated work.
- **Rebase onto `main`** to stay current. Never merge `main` into the feature branch —
  it pollutes the diff the Reviewer depends on.
- **Merge with `--no-ff` (merge commit). Do NOT squash.** Squashing destroys the
  test-first commit sequence, which *is* the evidence that TDD happened.
- Delete the branch after merge.
- Tag `v<x.y.z>` on `main` at every accepted increment.
- **Rollback is one command**: `git revert -m 1 <merge-commit-sha>` reverses the
  entire feature cleanly.

### Commit sequence — mandatory and audited

```
test(<ID>): failing tests for AC-1..AC-4
feat(<ID>): <what changed>
docs(<ID>): update STATE.md and CHANGELOG
```

**A PR whose first commit is not `test(...)` is rejected without review.** The commit
history is the audit trail; it is readable by a non-coder in ten seconds.

---

## 6. Session continuity

At the start of **every** session, before any action:

1. Read `CLAUDE.md`, `STATE.md`, the active spec, and the active ADR.
2. State out loud: **which ticket, which stage, which gate was last recorded.**
3. Do not begin a stage whose predecessor gate is not recorded in writing.

---

## 7. Hard stops — halt and ask the human

- Any ambiguity in the spec
- The design does not work as written
- A dependency is needed that is not in the ADR
- A test needs to change
- Credentials, secrets, or production access are required
- The diff will exceed the size cap
- **The ticket's token budget is exhausted** (see Section 8)
- A database migration or any destructive/irreversible data operation
- Anything touching authentication, authorisation, payments, or personal data
- You are about to do something the human did not ask for

**When in doubt, stop and ask. Stopping is always cheaper than unwinding.**

---

## 8. Model assignment and token budget

> Rates below are Anthropic API list prices, USD per million tokens, verified
> 2 August 2026. **Sonnet 5 is on introductory pricing at $2/$10 until 31 August 2026,
> reverting to $3/$15 on 1 September.** Re-verify before relying on any figure.

### Model by role — mandatory defaults

| Stage / role | Model | Rate (in/out) | Why |
|---|---|---|---|
| Stage 1 — Requirements interview | **Sonnet 5** | $2 / $10 | Structured Q&A. Cheap and sufficient. |
| Stage 2 — **Architect** | **Opus 5** | $5 / $25 | Runs once per ticket, produces a short document, and every downstream token depends on it being right. Highest value per token in the whole lifecycle. |
| Stage 3 — Tests first | **Sonnet 5** | $2 / $10 | With Given/When/Then acceptance criteria, test writing is largely mechanical. |
| Stage 4 — Implementation | **Sonnet 5** | $2 / $10 | Default. Escalate per the rule below. |
| Stage 5 — **Senior Reviewer** | **Opus 5** | $5 / $25 | **Never economise here.** A cheap reviewer produces review theatre, which is worse than no review because it manufactures false confidence. |
| Docs, STATE.md, CHANGELOG, formatting, running scripts | **Haiku 4.5** | $1 / $5 | Mechanical. No judgement required. |
| Fable 5 | — | $10 / $50 | **Do not use** unless a written evaluation shows the quality gain justifies 2× Opus. |

### Escalation rule

**Start cheap. Escalate on evidence. Never start expensive "to be safe."**

Escalate Stage 4 from Sonnet 5 to Opus 5 only when one of these is true, and state
which one in the PR:

- Two implementation attempts have failed the tests
- The work is concurrency, cryptography, authentication/authorisation, or money
- The ADR explicitly flags the component as high-risk

### Cost levers, in order of impact

1. **Prompt caching.** Cache hits cost 10% of standard input. Every session in this
   lifecycle reloads the same `CLAUDE.md`, `AGENT_OPERATING_RULES.md`, active spec and
   active ADR — that is exactly the pattern caching is built for. Load stable content
   first and volatile content last. **Do not edit these files mid-ticket**; every edit
   invalidates the cache.
2. **Output tokens cost 5× input, and thinking tokens bill as output.** Cap extended
   thinking budgets and `max_tokens`. Demand tables and verdicts, not essays. The
   Reviewer produces a structured table, never a narrative.
3. **Short sessions.** A long session re-sends its entire accumulated context on every
   turn, so cost grows quadratically. One stage, one session, then close it.
4. **Never let an agent explore the repo to orient itself.** Give it file paths.
   Maintain a repo map in `STATE.md`.
5. **Rework is the largest token sink there is.** The Stage 1 and Stage 2 gates exist
   for quality, but they pay for themselves in tokens: a design error caught in an ADR
   costs a few thousand tokens; the same error caught in Stage 5 costs the entire
   implementation twice over.

### Per-ticket budget

Every spec carries a **token budget** and a **dollar cap**, set by the human at Gate 1.

- The agent reports cumulative spend at the end of each stage.
- **Exceeding the cap is a hard stop**, not a warning. The agent halts and reports:
  spend to date, stage reached, and what it believes remains.
- Blowing the budget is a signal the ticket was scoped too large. The correct response
  is to split it, not to raise the cap.

---

## 9. Token monitoring

Three tiers. Tier 1 is mandatory, Tier 2 is mandatory, Tier 3 is recommended.

### Tier 1 — In-session (free, immediate)

- Run `/cost` at the end of every stage and paste the output into the PR.
- Run `/context` when a session feels slow — it shows what is consuming the window.
- **Every stage handover message must open with**: model used, stage, tokens in / out /
  cached, cost, and cumulative spend against the ticket budget.

### Tier 2 — The ledger (the artifact that makes this manageable)

Maintain `docs/engineering/ledger/token-ledger.csv`, committed to the repo, one row appended by the agent
at the end of every stage:

```
date,ticket_id,stage,role,model,input_tokens,output_tokens,cache_read_tokens,cost_usd,outcome
```

`outcome` is one of: `passed_gate`, `changes_required`, `returned_to_architect`,
`abandoned`.

This lives in git next to the work it describes, needs no infrastructure, and is
readable in a spreadsheet. It is the source for every metric below.

### Tier 3 — Telemetry (recommended)

Claude Code exports metrics and events over OpenTelemetry. <cite index="14-1">Claude Code exports metrics as time series data via the standard metrics protocol</cite>, and <cite index="9-1">token usage and cost can be broken down by user, model, or subagent, alongside session activity, cache hit rates, tool accept/reject rates, and errors and retries</cite>.

```bash
export CLAUDE_CODE_ENABLE_TELEMETRY=1
export OTEL_METRICS_EXPORTER=otlp
export OTEL_LOGS_EXPORTER=otlp
export OTEL_EXPORTER_OTLP_ENDPOINT=http://<collector-host>:4317
```

Point it at an OTel Collector → Prometheus → Grafana. Metrics and logs need separate
exporter configuration. Current reference:
https://code.claude.com/docs/en/monitoring-usage

### The metrics that actually matter

Vanity metrics (total tokens, total spend) tell you nothing actionable. Track these:

| Metric | Formula | What it tells you |
|---|---|---|
| **Cost per merged PR** | total cost ÷ merged PRs | The headline number. Trend it weekly. |
| **Rework ratio** | tokens spent after Gate 2 on `returned_to_architect` work ÷ total tokens | Rising ⇒ your specs and ADRs are too thin. This is the most diagnostic number here. |
| **Review : implementation ratio** | Stage 5 tokens ÷ Stage 3+4 tokens | Below ~10% ⇒ review is shallow. Above ~40% ⇒ tickets are too big. |
| **Cache hit rate** | cached input ÷ total input | Below ~50% ⇒ your context layout is wrong or files are churning mid-ticket. |
| **Tokens per acceptance criterion** | ticket tokens ÷ AC count | Rising over time ⇒ complexity creep or eroding architecture. |
| **Waste** | cost of `abandoned` tickets ÷ total cost | Tickets killed after real spend ⇒ Gate 1 is not doing its job. |

### Review cadence

Weekly, review the ledger and answer three questions in `STATE.md`:

1. Did cost per merged PR move, and why?
2. Which gate caught the most problems this week? That gate is earning its keep.
3. Is the rework ratio rising? If so, the fix is upstream — better specs — never a
   bigger budget.

---

## 10. Documentation structure

Every role writes into its own folder. Nobody writes into another role's folder.
Separation of authorship is what makes the audit trail meaningful.

```
docs/engineering/
├── README.md                     # index: open tickets, where things live
├── _templates/                   # agents FILL these, never invent structure
│   ├── spec.md
│   ├── adr.md
│   ├── test-evidence.md
│   └── review.md
├── 00-product/                   # HUMAN-OWNED. Agents draft, you approve.
│   ├── specs/<ID>-<slug>.md
│   └── acceptance/<ID>-acceptance.md
├── 01-architect/
│   ├── adr/ADR-<n>-<slug>.md
│   └── contracts/<ID>-interfaces.md
├── 02-developer/
│   └── <ID>/
│       ├── test-evidence.md      # raw RED output, then raw GREEN output
│       └── implementation-notes.md
├── 03-reviewer/
│   └── <ID>-review.md            # verdict + AC-by-AC evidence table
├── traceability/
│   └── matrix.md                 # THE SPINE — see below
└── ledger/
    └── token-ledger.csv
```

Write permissions are role-scoped and enforced socially, then in review:

| Role | May write to | May read |
|---|---|---|
| Human | `00-product/`, plus final merge of everything | everything |
| Architect | `01-architect/` | `00-product/`, code (read-only) |
| Developer | `02-developer/`, `traceability/matrix.md` (own columns) | everything except `03-reviewer/` |
| Reviewer | `03-reviewer/` | everything except the Developer's transcript |

**A PR containing edits to another role's folder is rejected without review.**

### The traceability matrix — how deliverables tie to your requirements

`docs/engineering/traceability/matrix.md` is the one document you read to know where
everything stands. One row per acceptance criterion. Each role fills only its own column.

| AC | Requirement | ADR | Tests | Code | Review | Accepted | Status |
|---|---|---|---|---|---|---|---|
| AC-1 | User can reset password via email | ADR-007 | `test_reset_flow.py::test_valid_token` | `auth/reset.py` | ✅ RECOMMEND | ✅ 2026-08-14 | Done |
| AC-2 | Reset link expires after 30 min | ADR-007 | `test_reset_flow.py::test_expired_token` | `auth/reset.py` | ⚠️ CHANGES | — | Blocked |
| AC-3 | Rate-limited to 5/hour | ADR-007 | — | — | — | — | **Not started** |

Rules:

- **Every AC has a row before Stage 3 begins.** Rows are created from the spec, not
  discovered later.
- **An AC with an empty Tests column is a hard stop.** Untested criteria do not ship.
- **No AC reaches `Done` with a gap to its left.** The columns are ordered by lifecycle
  deliberately, so a gap is visible at a glance.
- The Reviewer must flag **orphans in both directions**: any test that maps to no AC,
  and any changed file that maps to no ADR component. Orphans are how scope creep and
  architectural erosion enter.
- The matrix is updated in the same commit as the deliverable it records. Never as a
  batch at the end.

### Which PR carries which document

| Document | Branch | Gate |
|---|---|---|
| Spec | `docs/<ID>-spec-design` | Gate 1 |
| ADR + contracts | `docs/<ID>-spec-design` | Gate 2 |
| Matrix rows created (AC column only) | `docs/<ID>-spec-design` | Gate 2 |
| Test evidence, implementation notes | `feat/<ID>-<slug>` | — |
| Review verdict | `feat/<ID>-<slug>` | Gate 3 |
| Acceptance log, final matrix state | `feat/<ID>-<slug>` | merge |

### Document lifecycle

Every document carries frontmatter:

```yaml
---
id: <ID>            # ticket
type: spec | adr | test-evidence | review | acceptance
status: Draft | Approved | Superseded | Rejected
author_role: product | architect | developer | reviewer
approved_by: <human>
date: YYYY-MM-DD
supersedes: ADR-004    # ADRs only, when applicable
---
```

- **ADRs are immutable once approved.** A changed decision is a *new* ADR that names
  what it supersedes; the old one's status becomes `Superseded by ADR-nnn` and stays in
  the repo. ADR numbers are global, sequential, and never reused.
- **Specs are amendable** via an appended `## Change Log` entry with date and reason.
  Changing a spec after Gate 1 re-opens Gate 1 — new ACs are new rows, and existing
  code does not silently inherit them.
- Nothing is ever deleted. Superseded and rejected documents are the record of why the
  system looks the way it does, and they are the highest-value thing an agent can read
  when it proposes something you already tried.

### Templates

`_templates/` exists for two reasons: agents produce comparable, diffable documents
instead of inventing a new structure each time, and filling a template costs
meaningfully fewer output tokens than composing a document from scratch. **An agent
that does not use the template is corrected, not accommodated.**

---

## 11. Migration — adopting these rules in an existing repo

### The governing principle

**Draw a line. Do not rewrite history.**

These rules apply to all work from the adoption date forward. Existing code is
*legacy*: grandfathered, labelled, and brought into the lifecycle only when it is next
touched. Any attempt to retro-fit the whole repo at once produces an enormous
unreviewable diff — precisely what Section 2 exists to prevent — and burns a large
token budget generating documents nobody will trust.

### Anti-goals — explicitly do not do these

- ❌ **Do not write retrospective specs for existing features.** A spec derived by
  reading the code is a description of the code, not a requirement. It encodes every
  existing bug as intended behaviour and can never catch anything.
- ❌ **Do not bulk-fix lint, type, or SAST findings at adoption.** Ratchet them instead
  (below).
- ❌ **Do not mass-generate tests to hit a coverage number.** Tests written to satisfy a
  metric assert the implementation and are worse than no tests, because they make
  refactoring harder while proving nothing.
- ❌ **Do not rewrite git history**, rename existing branches, or reformat the codebase.
- ❌ **Do not write more than one retrospective ADR.**

### Phases — each ends at a human gate

#### Phase 0 — Audit (read-only, no changes)

Produce a written baseline report only. Nothing is created, edited, or fixed.

- Stack, test framework, package manager, existing tooling
- Which of the eight `verify.sh` checks are possible, and with which tools
- Current failure counts per check
- Does the existing test suite assert **behaviour** or **implementation**? Give
  concrete examples of each.
- Branch protection status, existing hooks, existing docs
- Which areas of the codebase are highest-risk (auth, payments, data, external I/O)

🔒 **GATE — human reads the baseline before anything is created**

#### Phase 1 — Scaffold (documentation only, no code touched)

One docs-only PR:

- Create `docs/engineering/` per Section 10, including `_templates/`
- Create `STATE.md` with a repo map
- Add `AGENT_OPERATING_RULES.md` to the repo root and the pointer block in `CLAUDE.md`
- Write **exactly one** retrospective ADR: `ADR-000 — Pre-adoption architecture`,
  status `Accepted (retrospective)`, describing the as-is system, its known weak
  points, and explicitly stating that pre-adoption code has no spec traceability
- Create `LEGACY.md` listing every directory not yet under these rules
- Create an empty `traceability/matrix.md` with headers only

🔒 **GATE**

#### Phase 2 — Verification, with a ratchet

- Write `scripts/verify.sh` per Section 4 and the `pre-push` hook
- **Run it and let it fail.** Record the raw output as the baseline
- Create `docs/engineering/ratchet.json` with current violation counts per check
- `verify.sh` fails the build **only if a count increases**

This is how a legacy repo adopts lint, types, and SAST without a single enormous PR:
no new violations, existing ones burn down as files are touched. Counts only ever
ratchet downward; lowering the bar requires a human gate.

- Enable branch protection on `main`

🔒 **GATE**

#### Phase 3 — Rehearsal ticket

Take one deliberately **small, low-risk, genuinely new** piece of work and run it
through all six stages end to end. The purpose is to find where the process is wrong
for this repo while the stakes are near zero. Record friction in `STATE.md` and adjust
before scaling up.

🔒 **GATE**

#### Phase 4 — Burn-down, driven by change not by tidiness

Legacy code enters the lifecycle **when it is next modified**, never on a schedule.

When a legacy file must change:

1. Write **characterisation tests** first — tests that capture what the code currently
   does, in `tests/characterisation/`, clearly labelled.
   > Characterisation tests are a **change detector, not a correctness proof.** They
   > encode current behaviour including its bugs. They must never be cited in a
   > traceability matrix as evidence that an AC is satisfied.
2. Confirm they pass against the unchanged code.
3. Write the new spec and ADR for the *change* — not for the legacy feature.
4. Proceed through Stages 3–6 normally.
5. Remove that directory from `LEGACY.md`.

Prioritise burn-down by **risk**, not by how untidy something looks: auth, money, personal
data, and anything with external input first. Cosmetic debt can wait indefinitely.

### Adoption is complete when

- `LEGACY.md` is empty, **or** the remaining entries are consciously accepted risk,
  reviewed and dated by the human
- The ratchet counts are all zero
- Every AC merged since the adoption date has a complete traceability row