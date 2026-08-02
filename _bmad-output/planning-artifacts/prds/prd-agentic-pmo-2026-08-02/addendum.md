---
title: "Addendum: PRD — Agentic PMO"
status: draft
created: 2026-08-02
updated: 2026-08-02
---

# Addendum: PRD — Agentic PMO

Technical-how and options-considered material that doesn't belong in the
PRD itself (capabilities, not implementation). Most of this ground was
already covered during the product-brief stage —
see `../../briefs/brief-agentic-pmo-2026-08-02/addendum.md` for the full
Atlassian API/auth/MCP-landscape research **and** the full
`Copilot-PMAgentv2` prior-implementation audit (architecture, verified
Jira/Confluence capabilities, auth-model gap, the Node 22.22 resolution,
the MCP Gateway/Azure historical precedent, reuse assessment, and the
unresolved `PM-Agent-Service` rewrite lead). This file only adds what's
new or PRD-specific since then.

## Runtime/language requirement — "Node 22.22" (RESOLVED)

Raised during PRD discovery as a stated constraint ("for atlassian api we
have to use node22.22"). **Resolved** via the `Copilot-PMAgentv2` audit —
see brief's `addendum.md` for full detail. Summary: no Atlassian
documentation ties a requirement to that specific patch version;
Node.js 22.22.0 is simply the current security-patched release on the
Node 22 LTS branch as of this research (Jan 2026 CVE fixes). It turned
out to be `Copilot-PMAgentv2`'s own internal team convention — pinned
extensively in that repo's docs and a hardcoded launch path
(`C:\Apps\tools\node22.22\node.exe`), but enforced only by prose, not by
any `engines`/`.nvmrc`/CI mechanism. **Practical implication for Agentic
PMO**: this constraint is not inherited by default. Atlassian's REST APIs
are language-agnostic HTTP — Node dependency only exists at all if a
Node-based implementation path is chosen, which remains an
architecture-stage decision (§4.1's build-vs-adopt `[ASSUMPTION]` is the
closest related open point). If Agentic PMO does end up Node-based, there
is no obligation to inherit `Copilot-PMAgentv2`'s specific patch pin —
worth a fresh, machine-enforced (`engines` + `.nvmrc` + CI) decision
rather than a prose convention repeated by habit.

## Interface shape — Skills → Tools layer (FR-8, FR-9)

Not designed here (architecture-stage), but worth flagging the shape of
the decision for whoever does: FR-8 requires "a stable interface" without
specifying protocol or schema. Given the tools layer is itself built on
MCP-family protocol per the brief, the most direct option is that the
tools layer's interface to skills *is* an MCP server/tool-set the skills
layer calls — i.e., skills-layer-to-tools-layer and
Agentic-PMO-to-Atlassian could plausibly be the same kind of interface,
one layer removed. `Copilot-PMAgentv2` is a real, if partial, precedent
for this shape: its `src/tools/` (MCP tool definitions) calling
`src/clients/` (thin HTTP wrappers) is structurally similar to
"skills-layer calls tools-layer," just collapsed into one process/repo
rather than two independently deployed layers. Not decided or assumed as
fact — just the option worth evaluating first, since it would avoid
inventing a second, bespoke interface pattern alongside the MCP one
already justified for the Atlassian side.

## `Copilot-PMAgentv2` reuse — what specifically transfers, PRD-to-architecture handoff

For whoever picks this PRD up next, the concrete carry-forward list (all
sourced from the brief's addendum audit, restated here as an
architecture-facing checklist):

**Carries forward as a pattern to re-implement (not literal code):**
- Narrow, single-verb tools: separate create-only and update-only tools
  per content type, never one broad "do anything" write tool (FR-3
  through FR-6 are written this way deliberately).
- Structural validation before every write (the reference implementation
  hand-rolls an ADF validator for Jira content — same discipline needed
  wherever this product writes structured content).
- Optimistic locking on updates (version-conflict errors, never blind
  overwrite) — FR-4.
- Idempotent write behavior on retries (no duplicate side effects) —
  FR-7's feature NFR.
- Confirm-before-write UX, surfaced to the user in conversation, not just
  logged — every write FR (FR-3 through FR-6).
- Custom-field discovery by display name rather than hardcoded field IDs
  (survives Atlassian site reconfiguration) — worth carrying into
  whatever Jira client gets built.
- The "to be confirmed" grounding discipline for anything not directly
  traceable to Jira/Confluence data, especially relevant for FR-5/FR-6
  creation flows where there's no existing content to anchor a proposed
  write against.

**Does NOT carry forward — real, unavoidable new work:**
- The entire auth/config/client layer. `Copilot-PMAgentv2` uses one
  shared Basic-Auth credential per local server process; FR-7 requires a
  shared service authenticating many individual users. This is a
  different architecture, not a refactor.
- The transport layer. Stdio-only, spawned per-client, no hosted/gateway
  path — FR-10 requires the opposite.
- The deployment model. One instance per person's laptop vs. one shared,
  MCP-Gateway-registered service.

**Unresolved before this checklist can be treated as complete**: whether
`PM-Agent-Service` / `Transformation-PM-Agent-Service` (the possible
parallel TypeScript rewrite flagged in the brief's audit, referenced by
stray build output but unverified) already solves some of the "does NOT
carry forward" list above — its `mcp-adapter` + `engines` +
Program-Registry pattern, if real, sounds architecturally closer to what
this PRD wants than `Copilot-PMAgentv2` itself. See PRD §14, Open
Question 9.
