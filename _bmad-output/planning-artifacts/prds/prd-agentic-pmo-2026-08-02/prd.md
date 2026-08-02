---
title: "Agentic PMO"
status: draft
created: 2026-08-02
updated: 2026-08-02
---

# PRD: Agentic PMO
*Working title — confirm.*

## 0. Document Purpose

This PRD is for whoever builds, approves, or depends on Agentic PMO v1:
the PM/author, the Architect who designs the tools layer next, the
Delivery Leads and PMs who'll use the first skill, and whoever owns the
company's MCP Gateway program that this product must register behind. It
builds on `../../briefs/brief-agentic-pmo-2026-08-02/brief.md` (and its
`addendum.md`, which now includes a full audit of a prior working
implementation, `Copilot-PMAgentv2`) rather than restating them — read
those first for the narrative "why"; this document turns that into
testable requirements. Glossary-anchored vocabulary (§3), features
grouped with FRs nested and globally numbered (§4), assumptions tagged
inline as `[ASSUMPTION]` and indexed (§9).

**Revision note (2026-08-02)**: this PRD was reframed after auditing
`Copilot-PMAgentv2`, a prior working MCP server the user built that
already does Jira/Confluence read, update, **and create** with real
safety engineering. The single biggest scope change: issue/page
**creation moves into v1 scope** (previously deferred) since a proven
reference implementation exists. The single biggest open risk carried
forward: that implementation's auth model (one shared credential per
local instance) does not satisfy true multi-user identity — rebuilding
that layer is real, unavoidable work, not something "reuse" shrinks away.

## 1. Vision

Agentic PMO lets Delivery Leads, PMs, and others do real project work —
reading, updating, and creating Jira issues and Confluence content —
through direct conversation with an AI agent, without personally
configuring, managing, or rebuilding a connection to those systems. It
has two layers: a **skills layer**, the PMO-specific agent workflows
people actually talk to, and a **tools layer**, a shared, reusable,
company-governed connector layer underneath every skill. Jira and
Confluence are the first tools; Microsoft Teams, SharePoint, and
OneDrive follow.

This isn't greenfield: `Copilot-PMAgentv2`, a prior prototype, already
proves the core capability set works and demonstrates real safety
engineering worth carrying forward (narrow, single-purpose write tools;
structural validation before every write; optimistic locking; idempotent
updates). What it doesn't prove — and what Agentic PMO has to build for
real — is a shared, multi-user, centrally-governed service. The prototype
runs one shared credential per person's own local instance; Agentic PMO
needs one service, many real, individually-identified users.

**Why now**: the organisation's Atlassian Rovo MCP connector — the only
current path from Claude into Jira/Confluence — is being blocked from
public-internet access within weeks, and the company's new internal MCP
Gateway will require any MCP touching company systems to be
company-specific and PII-compliant going forward. This isn't a
convenience upgrade with a flexible timeline; it's the thing that has to
exist before an access window closes, built to terms a program outside
this product's control is setting — and, per `Copilot-PMAgentv2`'s own
decision history, this organisation has already once **abandoned** a
centrally-hosted approach (Azure) for lack of subscription/admin access.
That precedent is a real risk to this timeline, not just a historical
footnote (§11 Risk and Mitigations).

## 2. Target User

### 2.1 Jobs To Be Done

- As a Delivery Lead, I want to check, update, and create Jira/Confluence
  content through conversation with Claude, so I don't have to
  context-switch out of my planning conversation into a separate tool.
- As a PM, I want the tools layer to be something I can point any
  Delivery Lead at, not something each of them has to individually set
  up or get approved for.
- As a PM, I want this to still work once Rovo is blocked — the job is
  continuity, not just convenience.
- `[ASSUMPTION]` As whoever owns the MCP Gateway program, I want a
  reference example of a company-specific, PII-compliant MCP done right,
  informed by this organisation's own prior attempt at centralized
  hosting (which didn't get off the ground).

### 2.2 Non-Users (v1)

- Anyone needing Microsoft Teams, SharePoint, or OneDrive access — named
  future direction, not v1.
- Anyone needing Jira issue **transitions** (workflow status changes via
  the transition API) — deliberately excluded, following
  `Copilot-PMAgentv2`'s own precedent (§4.1, §5 Non-Goals).
- External users / non-employees — this is an internal tool operating
  against internal Atlassian instances under company identity.
- Engineers wanting raw, general-purpose Jira/Confluence API access — the
  tools layer exposes scoped PMO capabilities, not a full API
  passthrough (§5 Non-Goals).

### 2.3 Key User Journeys

- **UJ-1. Jordan checks sprint status without leaving the conversation.**
  - **Persona + context:** Jordan, a Delivery Lead running a sprint
    review in an hour, already mid-conversation with Claude about the
    sprint plan.
  - **Entry state:** Authenticated as Jordan (not a shared identity) via
    however the tools layer establishes per-user identity — an
    architecture-stage decision; `Copilot-PMAgentv2` does not provide a
    reusable answer here (see §9 Integration and Dependencies). Already
    in a Claude session using a PMO skill.
  - **Path:** Jordan asks, in plain language, for the current status of
    three specific Jira issues. The skill resolves the request through
    the tools layer, retrieves live issue data scoped to Jordan's own
    Jira permissions, and returns it inline in the conversation.
  - **Climax:** Jordan sees accurate, current status without opening
    Jira — the answer reflects Jordan's actual visibility, not an
    over-privileged service account's.
  - **Resolution:** Jordan continues the sprint-review conversation with
    real data in hand.
  - **Edge case:** if Jordan asks about an issue they don't have Jira
    permission to view, the skill reports that plainly rather than
    silently omitting it or leaking it through a broader shared
    credential.
  - **Capability → FR mapping:** The system must retrieve Jira issue
    data scoped to the authenticated user's real permissions. → FR-1,
    FR-7

- **UJ-2. Jordan updates an issue on the spot.**
  - **Persona + context:** Same conversation, Jordan realizes an issue's
    status is stale and wants it fixed now, not after the meeting.
  - **Entry state:** Same authenticated session as UJ-1.
  - **Path:** Jordan asks Claude to update a specific issue's status
    field and add a comment explaining why. The skill confirms the
    change with Jordan in natural language before applying it — mirroring
    `Copilot-PMAgentv2`'s confirm-before-write pattern — then applies it
    through the tools layer as Jordan, not a service account.
  - **Climax:** The issue reflects the update in Jira; the comment is
    attributed to Jordan, not to "Agentic PMO" or a bot identity.
  - **Resolution:** Jordan's Jira record is accurate going into the
    sprint review; the audit trail shows a real, attributable action.
  - **Edge case:** if the update fails (permissions, field validation, a
    transient API error), the skill tells Jordan clearly what happened
    and does not silently retry with elevated privileges to force it
    through.
  - **Capability → FR mapping:** The system must apply an update to an
    existing Jira issue on behalf of the authenticated user, with
    confirmation before the write. → FR-3, FR-7, FR-13

- **UJ-3. Sam pulls a Confluence page into planning and edits it.**
  - **Persona + context:** Sam, a PM, is drafting a project plan in
    conversation and wants to update the linked Confluence page's status
    section directly, rather than copy-pasting between tools.
  - **Entry state:** Authenticated as Sam, same PMO skill session.
  - **Path:** Sam asks Claude to pull the current content of a named
    Confluence page, proposes an edit conversationally, confirms it, and
    the skill applies the edit through the tools layer, preserving the
    page's current version (optimistic locking, not a blind overwrite).
  - **Climax:** The Confluence page reflects the change; Sam never left
    the planning conversation to do it.
  - **Resolution:** Planning continues with the source of truth already
    updated.
  - **Capability → FR mapping:** The system must retrieve and update
    existing Confluence page content on behalf of the authenticated
    user. → FR-2, FR-4, FR-7

- **UJ-4. Jordan creates a follow-up Jira issue mid-conversation.**
  - **Persona + context:** Jordan, mid sprint-review conversation,
    identifies a new action item that needs its own tracked issue.
  - **Entry state:** Same authenticated session as UJ-1/UJ-2.
  - **Path:** Jordan describes the follow-up in plain language; the
    skill proposes a structured issue (project, type, summary,
    description) and confirms with Jordan before creating it.
  - **Climax:** A real Jira issue exists, correctly attributed to
    Jordan, without Jordan opening Jira to create it by hand.
  - **Resolution:** Jordan continues the review with the follow-up
    already tracked.
  - **Edge case:** if required fields can't be inferred from the
    conversation (e.g. project, issue type), the skill asks rather than
    guessing or creating a malformed issue.
  - **Capability → FR mapping:** The system must create a new Jira issue
    on behalf of the authenticated user, with confirmation before the
    write. → FR-5, FR-7, FR-15

## 3. Glossary

- **Agentic PMO** — the product this PRD specifies: a skills layer plus a
  tools layer for AI-agent-assisted project delivery work.
- **Skills layer** — the agent-facing surface: PMO-specific workflows and
  personas (each a "PMO Skill") that Delivery Leads, PMs, and others
  interact with directly.
- **PMO Skill** — a single agent-facing capability in the skills layer
  (e.g., "check, update, and create Jira/Confluence content"). Distinct
  from a generic Claude Code "skill" — a PMO Skill is a product
  capability of Agentic PMO, built on top of the tools layer.
- **Tools layer** — the shared, reusable, company-governed connector
  layer underneath the skills layer. Exposes scoped capabilities (not a
  full API passthrough) to any PMO Skill, so no skill or session has to
  rebuild connectivity itself.
- **Connector** — a tools-layer component reaching one external system
  (e.g., the Jira/Confluence connector). Additional connectors (Teams,
  SharePoint, OneDrive) are future work.
- **MCP (Model Context Protocol)** — the protocol family this product's
  tools layer is built on; see the brief's `addendum.md` for
  mechanism-level detail and prior-art findings.
- **MCP Gateway** — the company's forthcoming internal program requiring
  any MCP touching company systems to be company-specific and
  PII-compliant. Owned outside this product; this product must comply
  with, not design, its terms.
- **`Copilot-PMAgentv2`** — a prior working MCP server (not this
  product) that already implements Jira/Confluence read/update/create.
  Audited as prior art; its patterns inform this PRD, its code is not
  directly inherited. See brief's `addendum.md` for the full audit.
- **Rovo** — Atlassian's own MCP connector, the current (soon-blocked)
  path from Claude into Jira/Confluence.
- **PII** — personally identifiable information; protecting it is a
  registration condition set by the MCP Gateway program, mechanism TBD
  (§14 Open Questions).
- **Delivery Lead / PM** — primary users (§2.1). "Others" (secondary)
  intentionally left undefined pending scoping.

## 4. Features

### 4.1 Jira & Confluence Connector (Tools Layer, v1)

**Description:** The first tools-layer connector. Read, update, and
**create** for both Jira issues and Confluence pages, always acting as
the authenticated user — never a shared or service-account identity — so
permissions, attribution, and audit trail all reflect the real person.
Realizes UJ-1 through UJ-4. Write-safety patterns below are lifted
directly from `Copilot-PMAgentv2`'s proven design, not invented fresh —
see brief's `addendum.md` for the source audit.

**Functional Requirements:**

#### FR-1: Read Jira issue data

An authenticated user (via their PMO Skill session) can retrieve current
data for Jira issues they have permission to view. Realizes UJ-1.

**Consequences (testable):**
- Returned data reflects the requesting user's actual Jira permissions —
  an issue the user cannot see in Jira is not returned.
- A request for a nonexistent or inaccessible issue returns a clear,
  distinguishable response, not a silent empty result.

#### FR-2: Read Confluence page data

An authenticated user can retrieve current content of Confluence pages
they have permission to view. Realizes UJ-3.

**Consequences (testable):** Same permission-scoping guarantee as FR-1,
applied to Confluence space/page permissions.

#### FR-3: Update existing Jira issues

An authenticated user can update fields, status, and comments on an
existing Jira issue they have permission to edit, with explicit
confirmation before the write is applied. Realizes UJ-2.

**Consequences (testable):**
- The write is attributed to the authenticated user in Jira, not to a
  shared/bot identity.
- The skill surfaces a confirmation step before the write executes.
- A failed write (permission, validation, transient error) is reported
  to the user with a clear reason, not retried under elevated privilege.
- `[ASSUMPTION]` Malformed content (e.g. invalid Atlassian Document
  Format) is validated and rejected before send, not after — following
  `Copilot-PMAgentv2`'s proven pattern of a structural validator ahead of
  every write.

**Out of Scope:**
- Workflow **transitions** (status changes via the transition API, as
  opposed to editable status fields) — see §5 Non-Goals.
- Deleting issues.
- Bulk/batch updates beyond a narrow, deliberate case (see FR-9).

#### FR-4: Update existing Confluence pages

An authenticated user can update the content of an existing Confluence
page they have permission to edit, with explicit confirmation before the
write. Realizes UJ-3.

**Consequences (testable):**
- Same attribution/confirmation/failure guarantees as FR-3.
- `[ASSUMPTION]` Updates use optimistic locking (reject on version
  conflict rather than blind overwrite) — following
  `Copilot-PMAgentv2`'s proven pattern.

**Out of Scope:** Creating new pages is FR-6, not this FR. Deleting
pages.

#### FR-5: Create new Jira issues

An authenticated user can create a new Jira issue (project, type,
summary, description, and other required fields resolved from the
conversation) with explicit confirmation before the write. Realizes
UJ-4. *(Newly in scope — a working reference implementation for this
already exists; see `Copilot-PMAgentv2` audit.)*

**Consequences (testable):**
- Required fields that can't be confidently inferred from the
  conversation are asked for, not guessed (UJ-4 edge case).
- The created issue is attributed to the authenticated user.
- `[ASSUMPTION]` Content is structurally validated before send (same ADF
  discipline as FR-3).

**Out of Scope:** Bulk creation. Creating issues in projects the user
lacks create-permission for (should fail per FR-1's permission-scoping
principle, not silently succeed under a broader service identity).

#### FR-6: Create new Confluence pages

An authenticated user can create a new Confluence page (space, parent,
title, content resolved from the conversation) with explicit confirmation
before the write. *(Newly in scope, same rationale as FR-5.)*

**Consequences (testable):** Same attribution/confirmation/validation
guarantees as FR-5, applied to Confluence page creation.

#### FR-7: Per-user identity, not shared identity

Every read and write through the connector acts as the real authenticated
user's own Atlassian identity and permission set — never a shared API
token or privileged service account standing in for everyone. Realizes
UJ-1 through UJ-4.

**Consequences (testable):**
- Two different users making the same request see results scoped to
  their own, different permissions where those permissions differ.
- Every write's Jira/Confluence audit trail shows the real acting user.

**`[NOTE FOR PM]`** This is the one requirement `Copilot-PMAgentv2`
explicitly does **not** satisfy — it runs one shared credential per
local server instance, with "per-user" achieved by deployment topology
(each person runs their own instance), not by the service itself
authenticating multiple identities. Building FR-7 for real is a full
rebuild of the auth/config/client layer, not an extension of the prior
prototype's. Budget and schedule accordingly (§11 Risk).

**Feature-specific NFRs:**
- Rate-limit handling: the connector must not let one user's activity
  starve another's, given Atlassian rate limits apply per-tenant (see
  brief's `addendum.md`, Rate limits).
- `[ASSUMPTION]` Idempotency: a repeated write (e.g. a retried update)
  should not produce duplicate side effects — following
  `Copilot-PMAgentv2`'s idempotent-comment-block pattern rather than
  naive append-on-every-call.

### 4.2 Tools Layer Reusability (Skills → Tools Interface)

**Description:** The layering that makes the tools layer worth building
separately from the first skill: any current or future PMO Skill can call
the Jira/Confluence connector (and later connectors) through a stable
interface, without re-implementing or rediscovering connectivity each
session. This is the direct answer to the brief's "agents rebuild
connectors every session, burn credits" problem.
`[ASSUMPTION — see brief's Open Items]` this problem's specifics are
partially corroborated by the `Copilot-PMAgentv2` audit (tool-path
rediscovery burning credits, a client-side MCP tool-count cap forcing
session restarts) but not confirmed as a verbatim match; FR-9 below is
written to the general shape of the problem as described.

**Functional Requirements:**

#### FR-8: Skills call tools through a stable interface

Any PMO Skill invokes the tools layer's Jira/Confluence capabilities
through one consistent interface, regardless of which skill is calling.

**Consequences (testable):**
- A new PMO Skill added after v1 can call FR-1 through FR-6 without any
  connector-specific implementation work of its own.

**Out of Scope:** the interface's actual shape (protocol, schema) —
architecture-stage decision. See addendum for one option worth
evaluating (the tools layer's interface to skills being MCP-shaped too,
mirroring `Copilot-PMAgentv2`'s own MCP-tool pattern one layer up).

#### FR-9: No per-session connector rebuild

A new agent session does not need to re-establish, re-authenticate, or
re-discover the tools layer's capabilities from scratch — the connection
persists or is trivially re-established at negligible cost compared to
today's baseline.

**Consequences (testable):**
- `[ASSUMPTION]` Session-start cost (time and/or token spend) of reaching
  a ready-to-use Jira/Confluence capability is measurably lower than the
  brief's described baseline, once that baseline is confirmed (§14).
- `[ASSUMPTION]` Whatever MCP client hosts these tools handles a tool
  count comfortably below any client-side cap — `Copilot-PMAgentv2`'s
  audit found VS Code Copilot enforces a ~128-tool cap across all active
  MCP servers, silently dropping tools over budget. Worth checking early
  against whatever client(s) Agentic PMO targets.

### 4.3 Governance & Compliance Registration

**Description:** The condition on which this entire product is allowed to
run: registration behind the company's MCP Gateway with PII protections
in place. This feature is process/compliance-shaped as much as
technical — its FRs describe the outcomes the product must reach, not
the Gateway's own mechanism (owned outside this product).

**Functional Requirements:**

#### FR-10: MCP Gateway registration

The tools layer is registered and operating behind the company's internal
MCP Gateway before general availability.

**Consequences (testable):**
- The tools layer is not reachable in production except through the
  Gateway's approved path.

**`[NOTE FOR PM]`** `Copilot-PMAgentv2`'s own history is a direct warning
sign here: a centrally-hosted architecture (Azure) was considered and
abandoned once already in this organisation for lack of subscription/
admin access, not technical reasons (brief's addendum, D-001). Confirm
the Gateway program actually has hosting and access resolved before
treating FR-10 as low-risk (§11).

**Out of Scope:** the Gateway's own architecture and registration
process — this product complies with it, not designs it (§5 Non-Goals).

#### FR-11: PII protections enforced

Whatever PII-protection mechanism the MCP Gateway program specifies is
enforced by the tools layer before it handles real Jira/Confluence data.

**Consequences (testable):** `[ASSUMPTION]` — cannot be made concretely
testable until the Gateway program specifies its actual mechanism (§14
Open Questions). This FR exists as a placeholder obligation, not a
designed capability, until that input arrives.

#### FR-12: Attributable audit trail

Every read and write the tools layer performs is logged with enough
detail (who, what, when, which system) to support an audit, distinct from
Jira/Confluence's own native audit trails. Realizes UJ-2 (edge case).

**Consequences (testable):**
- A write made through the tools layer can be traced back to the
  authenticated user and the PMO Skill session that initiated it.

### 4.4 First PMO Skill

**Description:** The skills-layer instance that proves the tools layer
works for a real Delivery Lead/PM workflow — the conversational
capability to check, update, and create Jira/Confluence content,
realizing UJ-1 through UJ-4 directly. `[ASSUMPTION]` this is one skill
covering read/update/create across Jira and Confluence, not split into
separate skills per system or per verb — reasonable for v1 given the
shared underlying connector, worth confirming doesn't fight against
however the skills layer ends up being architected.

**Functional Requirements:**

#### FR-13: Conversational Jira/Confluence status check

A Delivery Lead or PM can ask, in natural conversation, for the current
status of specified Jira issues or Confluence page content, and receive
an accurate, permission-scoped answer inline. Realizes UJ-1, UJ-3.

**Consequences (testable):** Directly exercises FR-1, FR-2, FR-7.

#### FR-14: Conversational Jira/Confluence update

A Delivery Lead or PM can ask, in natural conversation, to update an
existing Jira issue or Confluence page, review a confirmation of the
intended change, and have it applied. Realizes UJ-2, UJ-3.

**Consequences (testable):** Directly exercises FR-3, FR-4, FR-7, FR-12.

#### FR-15: Conversational Jira/Confluence creation

A Delivery Lead or PM can ask, in natural conversation, to create a new
Jira issue or Confluence page, be prompted for anything required that
can't be inferred, review a confirmation, and have it created. Realizes
UJ-4.

**Consequences (testable):** Directly exercises FR-5, FR-6, FR-7, FR-12.

## 5. Non-Goals (Explicit)

- Agentic PMO v1 is **not** a general-purpose Jira/Confluence API client —
  it exposes scoped PMO capabilities (read, update, create), not the
  full Atlassian API surface.
- **Not** building Jira issue **transitions** (workflow status changes
  via the transition API) — `Copilot-PMAgentv2` deliberately excluded
  this as a safety measure ("destructive updates structurally impossible
  rather than merely discouraged"); same discipline applies here unless
  a real need displaces it.
- **Not** building Microsoft Teams, SharePoint, or OneDrive connectors —
  named future direction, not this PRD's scope.
- **Not** designing or operating the MCP Gateway itself — this product
  is a consumer/registrant of that program, not its owner.
- **Not** replacing Rovo's or Atlassian's own admin/configuration
  surfaces — this is an agent-facing capability layer, not an Atlassian
  administration tool.
- **Not** literally porting `Copilot-PMAgentv2`'s code — its auth/config/
  client layer doesn't satisfy FR-7 and needs a real rebuild; only its
  patterns (narrow write tools, validation-before-write, optimistic
  locking) carry forward.
- **Not**, in v1, a fully general skills-layer platform for arbitrary
  PMO workflows — v1 proves the pattern with one skill (§4.4); broader
  skill catalog is v2+ (brief's Vision).

## 6. MVP Scope

### 6.1 In Scope

- Jira + Confluence connector: read, update, **and create**, per-user
  identity (§4.1) — revised from the pre-audit draft, which deferred
  creation.
- Tools-layer reusability interface for skills (§4.2).
- MCP Gateway registration and whatever PII-protection mechanism that
  program specifies (§4.3).
- One PMO Skill exercising the above for real Delivery Lead/PM status-
  check, update, and creation workflows (§4.4).

### 6.2 Out of Scope for MVP

- Jira issue transitions (§5) — deliberately excluded, following prior
  precedent.
- Microsoft Teams/SharePoint/OneDrive connectors (§5) — deferred to v2+
  per the brief's Vision.
- `[NOTE FOR PM]` A broader skills catalog beyond the first skill — the
  brief's long-term vision depends on this; flag for revisit once v1
  proves the tools-layer pattern actually holds up.

## 7. Cross-Cutting NFRs

- **Security**: no shared/privileged credential stands in for individual
  users (FR-7); writes require explicit confirmation (FR-3 through FR-6).
- **Performance**: `[ASSUMPTION]` conversational read/update/create
  requests complete within a few seconds under normal load — no hard
  target set by the user; needs a real target once usage patterns exist.
- **Rate-limit resilience**: the connector must handle Atlassian's
  per-tenant rate limits gracefully (backoff/queuing) rather than failing
  hard when multiple Delivery Leads on the same Atlassian site are active
  concurrently — see brief's `addendum.md`, Rate limits.
- **Write integrity**: structural validation before every write, and
  idempotent behaviour on retried writes — both proven patterns from
  `Copilot-PMAgentv2`, now treated as hard requirements rather than
  implementation details (FR-3, FR-5, FR-7's feature-specific NFR).
- **Auditability**: FR-12's audit trail is a hard requirement, not
  optional logging.
- **Language/runtime targets**: not fixed in this PRD (capabilities, not
  implementation). **Resolved during PRD discovery**: a claimed "Node
  22.22" runtime requirement was raised and researched — no Atlassian-
  imposed constraint exists at that patch level; it turned out to be
  `Copilot-PMAgentv2`'s own internal team convention (extensively
  documented in that repo, but enforced only by prose, not by any
  `engines`/`.nvmrc`/CI mechanism). Agentic PMO does not inherit this
  constraint by default — a fresh runtime decision belongs at
  architecture stage. See brief's `addendum.md` for the full finding.

## 8. Constraints and Guardrails

**Privacy**: PII protection is a hard registration condition (FR-11), not
a nice-to-have — mechanism owned by the MCP Gateway program, currently
unspecified (see §14 Open Questions, item 5). No specific regulatory
framework (GDPR, HIPAA, etc.) has been named by the user —
`[ASSUMPTION]` do not assume one; confirm with the Gateway program rather
than inventing compliance scope here.

**Safety**: write actions (FR-3 through FR-6) require explicit user
confirmation before applying — the system should never silently commit a
change the user hasn't seen. Real Jira/Confluence data is being modified;
an erroneous write is a real-world consequence, not a sandboxed one.
`Copilot-PMAgentv2`'s own risk register names this directly: "agent
fabricates scope/requirements content that reads as authoritative" —
mitigated there by a hard grounding rule (anything not traceable to
Jira/Confluence is marked "to be confirmed," never invented). Worth
adopting the same discipline here, especially for FR-5/FR-6 creation
flows where there's no existing content to anchor against.

**Cost**: Atlassian API rate limits are moving to a points-based system
(OAuth apps, effective March 2026) and already carry burst limits on raw
tokens (since Nov 2025) — see brief's `addendum.md`. Concurrent users on
one Atlassian tenant share that tenant's quota — a real operating
constraint, not just an implementation detail.

## 9. Integration and Dependencies

- **MCP Gateway** (internal program) — hard dependency for FR-10, FR-11.
  Timeline risk: this product's own deadline (Rovo block, within weeks)
  may arrive before the Gateway program's own terms are fully specified,
  **and** this organisation has already once abandoned a comparable
  centrally-hosted approach for resourcing reasons (§11 Risk).
- **Atlassian Cloud (Jira, Confluence)** — the systems of record this
  product reads/writes; subject to Atlassian's own API changes, rate
  limits, and auth-model constraints (brief's `addendum.md`).
- **`Copilot-PMAgentv2`** — prior art, audited, not a runtime dependency.
  Informs FR-3 through FR-6's write-safety patterns directly. Its
  auth/client/config layer is explicitly **not** reused (FR-7's `[NOTE
  FOR PM]`).
- **`[ASSUMPTION]`** A possible further-along parallel rewrite
  (`PM-Agent-Service` / `Transformation-PM-Agent-Service`) was flagged
  during the `Copilot-PMAgentv2` audit but not confirmed to exist or be
  accessible — see §14 Open Questions, item 9. If real, it may be more
  directly relevant to this product's architecture than
  `Copilot-PMAgentv2`.
- **`[ASSUMPTION]`** This organisation's existing BMAD Method agent-
  persona investment — the skills layer may build on this pattern rather
  than inventing a new one; not confirmed, an architecture-stage
  decision.
- **Rovo MCP connector** — being replaced, not integrated with; its
  blocking deadline is this product's forcing function.

## 10. Stakeholders and Approvals

`[ASSUMPTION]` Not confirmed by the user — inferred from context, needs
real names/roles:
- Whoever owns the MCP Gateway program: approval gate for FR-10/FR-11,
  timeline-critical, and the party who needs to confirm hosting/access is
  actually resolved this time (§11).
- Delivery Leads/PMs as primary users: informal validation that UJ-1
  through UJ-4 actually match their real workflow.
- Whoever currently owns Rovo's usage in the organisation: awareness of
  the cutover, to avoid a gap in access.
- Whoever owns/owned `Copilot-PMAgentv2` and any related rewrite
  (§14, item 9) — likely the same person as this PRD's author, but worth
  naming explicitly given the reuse decision depends on their knowledge.

## 11. Risk and Mitigations

- **Risk**: the MCP Gateway program's terms (auth mechanism, PII
  protection requirements) aren't finalized before Rovo's block date —
  **and this organisation has direct precedent for this exact failure
  mode**: `Copilot-PMAgentv2`'s decision log shows a prior centrally-
  hosted (Azure) approach was abandoned for lack of subscription/admin
  access, not technical reasons. **Mitigation**: `[ASSUMPTION]` confirm
  the Gateway program's hosting/access story explicitly and early, rather
  than assuming company sponsorship alone resolves what killed the last
  attempt; flagged as the single biggest timeline risk to §1's "why now."
- **Risk**: a write action (FR-3 through FR-6) applies an unintended
  change to real Jira/Confluence data. **Mitigation**: explicit
  confirmation before every write, full attribution (FR-7), audit trail
  (FR-12), structural validation before send — all patterns proven in
  `Copilot-PMAgentv2`, now required rather than optional (§7, §8 Safety).
- **Risk**: concurrent Delivery Leads on one Atlassian tenant exhaust
  shared rate-limit quota during peak use (e.g., sprint planning day).
  **Mitigation**: rate-limit resilience NFR (§7); needs a real load
  profile once usage exists.
- **Risk**: FR-7 (true per-user identity) is underestimated as "mostly
  done" because a prior prototype exists. **Mitigation**: this PRD states
  explicitly, more than once, that `Copilot-PMAgentv2`'s auth model does
  not satisfy FR-7 — treat the auth/client/config layer as net-new work
  at estimation time, not a port.
- **Risk**: a possible more-advanced parallel rewrite
  (`PM-Agent-Service`) goes unaudited, and this PRD's reuse assessment
  ends up based on the less-advanced of two available references.
  **Mitigation**: resolve §14 Open Questions item 9 before architecture
  work locks in `Copilot-PMAgentv2` as the primary reference.

## 12. Rollout and Change Management

`[ASSUMPTION]` Not specified by the user:
- How a Delivery Lead or PM gets access to the first PMO Skill once it
  exists — self-serve, or provisioned by the PM/product owner? Affects
  whether "available to any delivery lead" (brief's framing) is literally
  self-serve or administratively granted.
- No training/communication plan specified — reasonable for a first
  internal skill with a small initial user base, but worth a real plan
  before wider rollout past v1.

## 13. Success Metrics

**Primary**
- **SM-1**: Tools layer is live, PII-compliant, and MCP-Gateway-
  registered before Rovo's public-internet access is blocked. Binary,
  date-driven. Validates FR-10, FR-11.
- **SM-2**: A Delivery Lead or PM completes a real status-check, update,
  or creation task (UJ-1 through UJ-4) using the first PMO Skill, with
  zero individual connector setup on their part. Validates FR-8, FR-13,
  FR-14, FR-15.

**Secondary**
- **SM-3**: `[ASSUMPTION]` Measurable drop in redundant "rebuild the
  connector" token/credit spend across agent sessions, once a real
  baseline exists. Validates FR-9.

**Counter-metrics (do not optimize)**
- **SM-C1**: Volume of writes made (FR-3 through FR-6) should **not** be
  optimized as a usage/adoption signal in isolation — a high write count
  correlated with error/rollback rates would mean the confirmation step
  is being rubber-stamped, not genuinely reviewed. Counterbalances SM-2.
- **SM-C2**: Speed of reaching SM-1's Gateway-registration deadline
  should **not** be optimized by narrowing PII-protection scope (FR-11)
  to hit the date. Counterbalances SM-1.

## 14. Open Questions

1. Is the "reuse problem" (agents rebuilding connectors every session,
   burning credits) confirmed as the specific driver, given the
   `Copilot-PMAgentv2` audit found only partially-corroborating evidence
   (tool-path rediscovery, a client tool-count cap), not a verbatim
   match?
2. ~~Where did the "Node 22.22" requirement originate?~~ **Resolved**:
   confirmed as `Copilot-PMAgentv2`'s own internal team convention, not
   an Atlassian requirement — see §7.
3. Does the skills layer build on this organisation's existing BMAD
   Method agent-persona pattern, or something new? (Architecture-stage
   decision.)
4. Who specifically is "others" in the primary user base beyond Delivery
   Leads and PMs?
5. What is the MCP Gateway program's actual integration contract — auth
   mechanism, PII-protection mechanism, registration process, and
   timeline relative to Rovo's block date? Owned by that program, not
   this PRD — but currently unknown and the single biggest schedule risk
   (§11), made more concrete by `Copilot-PMAgentv2`'s Azure-hosting
   precedent.
6. What's the real baseline for SM-3 (today's redundant connector-rebuild
   cost)?
7. Who are the actual named stakeholders/approvers (§10)?
8. How do Delivery Leads/PMs actually get access to the first PMO Skill
   (§12) — self-serve or provisioned?
9. **New**: Does `PM-Agent-Service` / `Transformation-PM-Agent-Service`
   exist as a real, further-along TypeScript rewrite of
   `Copilot-PMAgentv2`, referenced by stray build/test output found
   during the audit but unverifiable from within that checkout? If real
   and its `mcp-adapter`/`engines`/Program-Registry pattern is genuine,
   it may be significantly more relevant to this PRD's architecture than
   `Copilot-PMAgentv2` itself — should be resolved before architecture
   work begins.

## 15. Assumptions Index

- §2.1 — MCP Gateway program owner as an implicit stakeholder wanting a
  reference-quality example.
- §2.3 (UJ-1) — the per-user identity mechanism is unresolved;
  `Copilot-PMAgentv2` doesn't provide a reusable answer.
- §4.1 (FR-3, FR-4, FR-5, FR-6) — structural validation before write,
  optimistic locking, and idempotent behaviour are assumed as
  requirements by analogy to `Copilot-PMAgentv2`'s proven patterns, not
  independently re-derived from first principles here.
- §4.2 (FR-9) — the reuse-problem's specifics assumed to match the
  general shape found in the audit, pending Open Question 1; the
  128-tool client cap assumed relevant without confirming which MCP
  client(s) Agentic PMO will actually target.
- §4.4 — one unified skill across Jira+Confluence read/update/create,
  rather than split per-system or per-verb skills.
- §7 — No hard performance target set; a placeholder "a few seconds"
  assumption pending real usage data.
- §8 — No named regulatory framework (GDPR/HIPAA/etc.) assumed; deferred
  to the Gateway program rather than invented.
- §9 — Skills layer possibly building on existing BMAD Method
  agent-persona investment (Open Question 3); `PM-Agent-Service`'s
  existence and relevance entirely unconfirmed (Open Question 9).
- §10 — Stakeholder/approver list inferred, not confirmed (Open
  Question 7).
- §11 — Gateway-timeline risk mitigation is a recommendation to confirm
  early, not a resolved plan.
- §12 — Rollout/access-provisioning mechanism not specified (Open
  Question 8).
- §13 — SM-3's baseline and exact definition pending confirmation (Open
  Question 6).
