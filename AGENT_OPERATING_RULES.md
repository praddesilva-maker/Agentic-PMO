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
- Output: `/docs/specs/<ID>-<slug>.md`
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
- Output: `/docs/adr/ADR-<n>-<slug>.md`
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
- A database migration or any destructive/irreversible data operation
- Anything touching authentication, authorisation, payments, or personal data
- You are about to do something the human did not ask for

**When in doubt, stop and ask. Stopping is always cheaper than unwinding.**
