---
title: "Product Brief: Agentic PMO"
status: draft
created: 2026-08-02
updated: 2026-08-02
---

# Product Brief: Agentic PMO

## Executive Summary

Agentic PMO is a platform that lets Project Managers, Delivery Leads, and
others run the day-to-day work of initiating, planning, and delivering
projects with the direct assistance of AI agents — starting with Claude.
It has two layers: a **skills layer**, the agent-facing workflows and
personas PMs and Delivery Leads actually interact with, and a **tools
layer**, a shared, reusable set of connectors into the systems delivery
work already lives in — Jira and Confluence first, Microsoft Teams,
SharePoint, and OneDrive after. The tools layer exists so that every
skill, and every session, can reach those systems without rebuilding the
connection from scratch each time.

This isn't a hypothetical efficiency play, and it isn't starting from
zero. The organisation's Atlassian Rovo MCP connector — the thing
currently making Jira/Confluence reachable from Claude at all — is being
blocked from public-internet access within weeks, and it's also likely
that Atlassian will start charging for it. In parallel, the company is
standing up an internal MCP Gateway that will require any MCP serving
company systems to be purpose-built, company-specific, and PII-compliant.
And there's already a working prior implementation — a "vibe coded" MCP
server (`Copilot-PMAgentv2`) that reads, updates, **and creates**
Jira issues and Confluence pages today, with real safety engineering
(narrow write tools, structural validation before writes, optimistic
locking) worth carrying forward — but built single-user, single-credential,
local-only, with no path to the shared, governed, multi-user service this
product needs to be. Agentic PMO is what replaces both the closing Rovo
path and the prior prototype's architecture: an internally governed tools
layer built to the Gateway's terms, informed by real lessons already
learned, with a PMO skills layer built on top of it.

## Open Items — resolve before this brief is considered move-ready

- **`Copilot-PMAgentv2`'s successor**: audit turned up strong signals of a
  possibly further-along parallel rewrite (`PM-Agent-Service` /
  `Transformation-PM-Agent-Service`, referenced by stray build/test output
  in the checkout, with its own Vitest suite and an `mcp-adapter` +
  `engines` + `Program Registry` pattern) that could not be verified from
  within the audited checkout. **Ask the user directly** whether this
  exists and is more relevant than `Copilot-PMAgentv2` before treating the
  reuse assessment below as final.
- **Reuse-problem provenance**: partially corroborated (see addendum) but
  not confirmed verbatim — the specific "rebuild connectors every session"
  framing wasn't found as a literal statement in `Copilot-PMAgentv2`'s
  history, only closely adjacent friction (tool-path rediscovery burning
  credits, a client-side MCP tool-count cap causing session restarts).
- **Skills layer / BMAD reuse**: the brief assumes the skills layer likely
  builds on this organisation's existing BMAD Method agent-persona
  investment. Not confirmed — a real architecture-stage decision, not a
  brief-level fact.
- **"Who this serves — others"**: left intentionally loose, per the
  original framing.
- **Success metric definition**: "a measurable drop in redundant
  connector-rebuild token spend" is a plausible metric, not a confirmed
  one — needs a real baseline.

## The Problem

Delivery Leads and PMs already want to use Claude (and agents like it) to
do real project work — read, update, and create Jira issues and
Confluence pages, and eventually touch the Microsoft surface where much
of this organisation's planning and comms actually happen. Three problems
stand in the way:

**The access problem.** The only current path from Claude into
Jira/Confluence — Atlassian's Rovo MCP connector — is closing within
weeks. Whatever replaces it needs to exist before that window closes, or
agent-assisted delivery work stops being possible at all, not just
becomes less convenient.

**The reuse problem.** `[ASSUMPTION — see Open Items]` Even where a
connector exists, each agent session currently has to establish its own
way of reaching these tools — there's no persistent, shared layer a skill
can just call. That costs real credits in rebuilding what was already
built, session after session, and it means every team solving this
problem solves it alone, instead of it being solved once for everyone. A
real prior instance of this organisation building exactly this kind of
tool (`Copilot-PMAgentv2`) already shows adjacent symptoms — burned
credits rediscovering tool paths each session, an MCP client tool-count
cap forcing mid-session server restarts — even if the precise framing the
brief opened with isn't a verbatim match.

**The governance problem.** The organisation's forthcoming internal MCP
Gateway means any MCP touching company systems will need to be
company-specific and carry PII protections — not optional compliance
theatre, but the mechanism that gates whether an integration is allowed
to run at all. Worth naming plainly: this organisation has been here
before. `Copilot-PMAgentv2`'s own decision log shows a centrally-hosted
(Azure-based) MCP server was considered and **rejected** — not for
technical reasons, but because the team lacked Azure subscription access
and Power Platform admin rights. The MCP Gateway program removes that
specific excuse by being a company-sanctioned path, but the underlying
risk — a shared/hosted architecture needing resourcing and access this
team doesn't unilaterally control — is a real, precedented risk, not a
hypothetical one.

## The Solution

Agentic PMO is a layered agentic application, and it doesn't start from a
blank page:

- **Skills layer** — the agent-facing surface PMs, Delivery Leads, and
  others actually use: workflows and personas for initiating, planning,
  and delivering projects with agent assistance. `[ASSUMPTION]` Likely
  builds on the agent-persona pattern this organisation has already
  invested in via BMAD Method adoption, rather than inventing a new
  interaction model from scratch.
- **Tools layer** — a shared, reusable, company-governed connector layer.
  Jira and Confluence first — read, update, **and create**, matching what
  `Copilot-PMAgentv2` already proves works — built to the incoming MCP
  Gateway's terms with true multi-user identity (the one thing the prior
  prototype doesn't have: it runs one shared credential per local
  instance, not per-user auth behind a shared service). Microsoft Teams,
  SharePoint, and OneDrive follow. Built once, called by every skill and
  every session.

What carries forward from `Copilot-PMAgentv2`, concretely: the
narrow-tool, one-verb-per-tool safety philosophy (separate create-only and
update-only tools, never a broad "do anything" write); structural
validation before every write (it hand-rolls an Atlassian Document Format
validator so malformed content is never sent); optimistic locking on
updates; idempotent behaviour on repeated writes; dry-run/confirm-before-
write patterns. What does **not** carry forward as-is: the auth model
(single shared API token, not per-user), the transport (local stdio only,
no hosted/gateway path), and the deployment model (one instance per
person's laptop, not a shared service).

## What Makes This Different

Being honest about the actual advantage: this is not a technical moat
over Atlassian's own connector, and it's not even greenfield technical
work — a prior prototype already proves the core Jira/Confluence
capability set is buildable and can be done safely. The advantage is
**organisational fit, timing, and informed execution**. This is the one
path that still exists once Rovo is blocked, that's compliant with a
governance requirement about to become mandatory, that's reusable across
every future skill instead of rebuilt per session or per team, and that
learns from a real prior attempt's genuine safety engineering instead of
re-deriving it from scratch or repeating its architectural
mistakes (single-credential auth, no shared hosting path). The unfair
advantage, if there is one, is starting this already informed rather than
naive.

## Who This Serves

**Primary**: Delivery Leads and Project Managers who want to use Claude
directly against real project systems — reading, updating, and creating
Jira issues, working in Confluence — without personally managing their
own integration setup.

**Secondary**: "Others" `[ASSUMPTION — see Open Items]` — likely includes
engineers, other agent-tool builders inside the org, and eventually anyone
whose delivery work touches these systems.

**Also served, differently**: whoever owns the org's MCP Gateway
program — Agentic PMO is one of what's likely to be several
company-specific MCPs that program needs to onboard, and it should aim to
be a reference example of doing that well, informed by this
organisation's own prior (rejected) attempt at centralized hosting.

## Success Criteria

- The Jira/Confluence tools layer is live, PII-compliant, and registered
  behind the company's MCP Gateway **before** Rovo's public-internet
  access is blocked — the hard deadline this whole effort exists to meet.
- Delivery Leads and PMs can use a PMO skill to read, update, and create
  Jira/Confluence content with no individual connector setup.
- The tools layer achieves true per-user identity — a gap the prior
  prototype explicitly does not close — verifiable by two different
  users' actions showing up attributed to them individually in
  Jira/Confluence's own audit trail, not a shared identity.
- `[ASSUMPTION]` A measurable drop in redundant "rebuild the connector"
  token/credit spend across agent sessions, once a real baseline exists.
- The tools layer is built so that adding the next connector (Teams,
  SharePoint, OneDrive) is materially cheaper than building the first
  one was.

## Scope

**In, for the first version** *(revised: creation is now in scope, since
a working reference implementation already exists)*:
- The tools layer's architectural shape (skills layer / tools layer
  separation).
- A Jira + Confluence connector: read, update, and **create**, built
  company-specific, PII-compliant, true per-user identity, compatible
  with the incoming internal MCP Gateway.
- A first PMO skill (or small set) exercising the tools layer for real
  Delivery Lead / PM workflows.

**Explicitly out, for now:**
- Microsoft Teams, SharePoint, and OneDrive connectors — future
  direction.
- Jira issue **transitions** (workflow status changes via the transition
  API, as opposed to updating the status field where permitted) —
  `Copilot-PMAgentv2` deliberately excluded this as a safety measure
  ("destructive updates structurally impossible rather than merely
  discouraged"); worth the same discipline here unless a real need
  displaces it.
- Bulk/batch operations beyond narrow, deliberate cases.
- Specifics of the MCP Gateway's own architecture and PII-protection
  mechanism — owned by that program.

## Vision

In two to three years, Agentic PMO is the standard way Delivery Leads and
PMs in this organisation work with AI agents on real project delivery —
not just Jira and Confluence, but the full Microsoft surface too, all
reachable through the same governed tools layer, all built on safety
patterns proven out in this organisation's own earlier work rather than
reinvented per connector. New PMO skills get built in days, not weeks,
because the connector work is already done and already trusted by the MCP
Gateway. What started as an urgent replacement for a soon-to-be-blocked
connector — and a rebuild of a promising but architecturally-limited
prototype — becomes the reusable foundation every future agent-assisted
delivery capability in this organisation builds on.
