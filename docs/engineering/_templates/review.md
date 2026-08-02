---
id: <ID>
type: review
status: Draft
author_role: reviewer
approved_by:
date: YYYY-MM-DD
---

# <ID> — Review verdict

## 0. Independent verification run

Re-run `./scripts/verify.sh` on a clean checkout. Paste raw output — do not
rely on the Developer's.

## 1. AC-by-AC table

| AC | Satisfied? | Test | Code |
|---|---|---|---|

## 2. Design conformance

Does the diff match the ADR? List every deviation.

## 3. Mandatory questions

- What was not implemented, stubbed, or deferred?
- What would a senior engineer criticise here?
- What breaks on empty, huge, malformed, or malicious input?
- What happens on failure or partial failure? Real error handling, or
  swallowed?
- Are there secrets, credentials, tokens, or PII anywhere in the diff?
- Any dependency not authorised in the ADR?
- Is any test asserting the implementation rather than the specification?
- Is anything untested that a user can reach?

## 4. Verdict

`RECOMMEND MERGE` / `CHANGES REQUIRED` / `RETURN TO ARCHITECT`
