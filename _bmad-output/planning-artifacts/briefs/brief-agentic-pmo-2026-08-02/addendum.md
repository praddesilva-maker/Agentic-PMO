---
title: "Addendum: Agentic PMO"
status: draft
created: 2026-08-02
updated: 2026-08-02
---

# Addendum: Agentic PMO

Depth captured during the brief conversation that belongs to a downstream
document (PRD, architecture, solution design) rather than the brief
itself. Not a substitute for re-researching at the point those documents
get written — treat as a head start, verify currency before relying on
specifics. Meant to be read alongside `brief.md`, which defines terms
like "tools layer" and "Delivery Lead" used here without re-introduction.

## Atlassian API / connector landscape (research digest, Aug 2026)

### Current REST API state

Jira Cloud REST API v3 is current (v2 still works, but new development is
focused on v3); covers issues, workflows/transitions, comments, worklogs,
projects, custom fields. Confluence Cloud REST API v2 is current, covering
pages, spaces, comments, blogposts — but v2 has real gaps vs v1: no
endpoints for databases, whiteboards, folders, or smart links, and
page-list endpoints don't return properties/children (extra calls
needed).

Two notable 2025 changes, plus one standing requirement worth flagging
alongside them: (a) Jira's legacy `/search` endpoint was shut down by the
end of October 2025, replaced by `/search/jql` with token-based
(`nextPageToken`) pagination instead of offset — no more `total` count,
defaults to returning only `id` unless fields are requested; (b)
comment/description bodies use Atlassian Document Format (ADF), a
structured JSON format, not plain text/markdown — a real
parsing/rendering burden for any tool round-tripping content. Separately
(not a 2025 change, a standing fact): JQL requires `accountId`, not
username.

### Auth models — options considered for a shared, multi-user tool

- *API tokens (basic auth)*: simplest, tied to one personal account —
  wrong fit for shared/multi-user (all actions appear as one identity,
  revocation is all-or-nothing). **Rejected** for this use case.
- *OAuth 2.0 (3LO, three-legged OAuth)*: per-user, browser consent flow —
  the standard fit for "portable, multi-user." Access tokens last ~1hr;
  refresh tokens are *rotating* (each use invalidates the old one — must
  persist the new one every time) and expire after 90 days of inactivity,
  requiring re-auth. Nontrivial token-lifecycle engineering surface.
  **Likely direction**, pending architecture-stage confirmation.
- *Atlassian Connect*: legacy iframe/webhook app model, no longer
  publishable to Marketplace, being sunset in favor of Forge. **Rejected**
  — deprecated path.
- *Forge*: Atlassian-hosted apps, automatically isolated per tenant —
  viable if an installed Atlassian "app" with UI is wanted, but a heavier
  build model than a pure API client. Not evaluated in depth here.

### MCP servers — build vs. buy reference point

Atlassian shipped an official Remote MCP Server (General Availability
Feb 4, 2026, `mcp.atlassian.com`), covering Jira, Confluence, Jira Service
Management (JSM), Bitbucket, Compass with 72+ tools. Supports OAuth 2.1
per-user (permissions inherit each user's actual Atlassian roles) plus an
admin-gated shared API-token mode for headless automation. **This is the
most direct point of comparison for "build vs. use Atlassian's own
official server"** — the reason to build rather than adopt it directly is
almost certainly the MCP Gateway/PII-compliance requirement (a
company-specific MCP is required regardless of how good Atlassian's own
offering is — see `brief.md`'s Open Items on this program, which isn't
otherwise documented here), not a capability gap in Atlassian's server.
Worth an explicit build-vs-adopt-vs-wrap decision at architecture stage
rather than assuming build-from-scratch is the only path — e.g., whether
the company-specific layer could front/wrap Atlassian's official server
rather than reimplementing API calls directly.

The well-known community alternative, `sooperset/mcp-atlassian`, supports
single-user (fixed token) and multi-user (OAuth per user, or Personal
Access Token for Server/Data Center) modes, but its HTTP/shared-deployment
multi-user story is still maturing — open GitHub issues (#380, #610,
#850) show per-request auth headers aren't fully wired for true concurrent
multi-tenant HTTP deployments as of this research.

### Rate limits / scaling

Atlassian is moving from flat per-second caps to a points-based system for
Forge/Connect/OAuth 3LO apps, enforced from March 2, 2026. Separately,
burst rate limits on raw API tokens started November 22, 2025, enforced
per-tenant-per-API (429s on burst). For a multi-user tool, concurrent
Delivery Leads hitting the same tenant share that tenant's quota, which
needs client-side backoff/queuing, not just per-user throttling.

### Multi-tenant/shared-build gotchas

- **Token storage/rotation at scale**: a secure per-user refresh-token
  vault, not shared secrets.
- **Permission scoping**: respect each user's real Jira/Confluence role —
  don't run everything under one privileged service account, or audit
  trail and exposure both suffer.
- **Admin consent/installation flows**: just-in-time (JIT) install lets
  non-admins self-authorize once an admin enables the app site-wide.
- **Quota contention**: across users on one Atlassian site (see Rate
  limits, above).

Sources: [Atlassian Remote MCP Server announcement](https://www.atlassian.com/blog/announcements/remote-mcp-server) ·
[atlassian/atlassian-mcp-server](https://github.com/atlassian/atlassian-mcp-server) ·
[Jira Cloud rate limiting](https://developer.atlassian.com/cloud/jira/platform/rate-limiting/) ·
[Evolving API rate limits](https://www.atlassian.com/blog/development/evolving-api-rate-limits) ·
[Confluence Cloud REST API v2](https://developer.atlassian.com/cloud/confluence/rest/v2/intro/) ·
[OAuth 2.0 (3LO) apps](https://developer.atlassian.com/cloud/jira/software/oauth-2-3lo-apps/) ·
[sooperset/mcp-atlassian issue #850](https://github.com/sooperset/mcp-atlassian/issues/850) ·
[Jira REST API search endpoint deprecation](https://docs.adaptavist.com/sr4jc/latest/release-notes/breaking-changes/atlassian-rest-api-search-endpoints-deprecation) ·
[Rotating refresh token expiry discussion](https://community.developer.atlassian.com/t/expiry-of-refresh-token-jira-cloud-oauth2-3lo-grants/28294)

## Prior implementation audit — Copilot-PMAgentv2 (Aug 2026)

Full codebase audit of `/home/praddesilva/ProjectTeams/SRG-Apps/Apps/Copilot-PMAgentv2`,
the "vibe coded" prior app referenced during PRD discovery. `.env` contents
were never read or printed during this audit — only variable names.

### Architecture

A genuine MCP server (`@modelcontextprotocol/sdk`, `McpServer` +
`StdioServerTransport`), Node.js ESM, package name `mcp-spike` v0.0.1.
Four internal layers, explicitly named in the repo's own
`docs/project/architecture.md`: `src/clients/` (thin fetch-based Jira/
Confluence HTTP wrappers — the closest analogue to "tools layer"),
`src/tools/` (22 MCP tool definitions: zod schemas + handlers calling
into clients), `src/lib/` (cross-cutting: error formatting, stderr-only
logging, custom-field-by-name discovery), and `src/analysis/` (pure
business-logic engines — status reporting, timeline creation, sprint
capacity planning — no network calls). A top-level `skills/` directory
holds markdown-only playbooks (YAML frontmatter + natural-language
procedure) that the AI client reads and follows — **not code**, a much
looser "skills layer" than what Agentic PMO is speccing. Documented flow:
`MCP tools (read-only) → Analysis engine → Skills → Confluence output`.

### Jira/Confluence capabilities (verified by reading code, not names)

Both Jira and Confluence support **read, update, and create**. No delete
anywhere (confirmed by repo-wide grep). Jira issue **transitions**
deliberately excluded — `docs/project/decisions.md` D-003: "destructive
updates are structurally impossible rather than merely discouraged,"
tracked as unbuilt backlog item B-06. `updateJiraIssue` touches only
description + Acceptance Criteria fields, with a hand-rolled ADF
structural validator refusing malformed writes, and an idempotent
"AI-suggested" comment block that replaces itself on repeat runs rather
than stacking. Confluence updates use optimistic locking
(`version.number + 1`), erroring on conflict rather than blind-retrying.
`moveJiraIssuesToSprint` is the one narrow bulk operation (≤50, one
field only). Design philosophy, D-002: "every write tool is create-only
or update-only, operating on one page/issue at a time... bulk operations
are deliberate loops with per-item approval rather than one opaque call."

### Auth model — the one thing that can't carry forward as-is

Single shared Basic-Auth credential (one email + one Atlassian API token
from `.env`), loaded once per server process, used for every call for
that process's lifetime. "Per-user" in this repo's own docs
(`docs/project/decisions.md` D-001) means *each team member runs their
own local server instance with their own token* — isolation by
deployment topology, not by the server supporting multiple identities.
This does not satisfy a shared/hosted service authenticating each caller
individually (true multi-user OAuth-shaped identity) — the architecture
Agentic PMO needs. Rebuilding `src/clients/` + `src/config/` for real
per-user auth is a genuine, sizable piece of net-new work, not a
port.

### Runtime — Node 22.22, now fully resolved

Extensively documented throughout `Copilot-PMAgentv2` (`CLAUDE.md`,
`README.md`, `.vscode/mcp.json`, `INSTALL.md`) as "the ONLY approved
Node.js runtime," pinned to a specific portable install
(`C:\Apps\tools\node22.22\node.exe`) invoked by hardcoded absolute path
in both VS Code's `.vscode/mcp.json` and the Claude Code MCP registration
command in `INSTALL.md`. **This is a team convention specific to that
one prior project, communicated entirely in prose** — no `engines` field,
`.nvmrc`, `Dockerfile`, or CI config anywhere in the repo enforces it
mechanically. `CHANGELOG.md` shows it was formalized 2026-07-29,
tightening an earlier looser "Node 18+" era. **Conclusion: "Node 22.22"
is not an Atlassian requirement and not inherited by Agentic PMO by
default** — it was this one prior project's own convention, worth
knowing about but not binding on a fresh architecture decision.

### MCP transport and the Gateway precedent

Stdio transport only, no HTTP/SSE, no gateway/registry concept anywhere.
Client spawns the server process directly (VS Code via `.vscode/mcp.json`,
Claude Code via `claude mcp add`). Notably, `docs/project/decisions.md`
D-001 explicitly **rejected** an Azure-hosted MCP server (Container Apps
+ Key Vault + a Copilot Studio custom connector) because "Azure
subscription access, Power Platform licensing and admin rights [were]
not available to the team" — chose local-first specifically to avoid
that dependency. This is the single most important precedent for
Agentic PMO's MCP Gateway plan: a shared/hosted architecture was tried
in concept and abandoned once already in this organisation, for
resourcing reasons unrelated to technical merit. Worth confirming early
that the MCP Gateway program actually has the hosting/access sorted, not
assuming it does because it's now company-sanctioned.

Separately, a real operational constraint worth carrying forward:
`docs/TROUBLESHOOTING-MCP-TOOLS.md` documents VS Code + GitHub Copilot
enforcing a client-side cap (~128) on total active tools across *all*
enabled MCP servers, silently dropping a scattered subset when over
budget — causing intermittent "no such tool" errors that look like
server bugs. Relevant if Agentic PMO's tools layer will run alongside
other MCP servers behind one client.

### Reuse assessment

**Pattern reference, not a dependency to extend.** Genuine strengths:
consistent code style, JSDoc on every tool, a real (if narrow) automated
test suite — `npm test` runs 8 scripts covering pure business-logic
functions (JQL builders, ADF conversion, allocation algorithms, intake
parsers), all passing, including 34 sprint-planner edge-case tests. A
documentation discipline (D-005: README/CHANGELOG/CLAUDE.md/agent-
prompts.md all update together) mostly honored across a 30-entry
changelog. But: zero integration/API-mocked tests (all Atlassian
verification was manual, e.g. "verified end-to-end on a disposable CET601
Task" in the changelog), no CI, single-tenant/single-credential/stdio-
only, business logic partly embedded in tool handlers rather than fully
separated. **Carry forward conceptually**: the narrow-tool-per-verb
philosophy, ADF-validate-before-write, optimistic locking, custom-field-
by-name lookup (survives site reconfiguration, no hardcoded IDs),
dry-run/confirm-before-write UX. **Do not carry forward as literal code**:
the auth/config/client layer (needs a full per-user-identity rebuild) and
the transport layer (stdio-only has no path to a shared Gateway-registered
service).

### Unresolved — a possible more-advanced parallel rewrite

The audited checkout contains several **untracked, stray output files**
at repo root (`unit.out`, `push.err`, `log.out`, `branch.out`, etc.) that
don't belong to this repo's git history but reference a seemingly
different, more disciplined **TypeScript rewrite**: `unit.out` shows a
passing Vitest run of `pm-agent-service@0.1.0` (102 tests / 20 files,
including `tests/unit/mcp-adapter/tools.test.ts` and
`tests/unit/engines/status-report-engine.test.ts`) at Windows path
`C:/Apps/PM-Agent-Service`; `push.err` references a push to
`github.com/super-retail-group/Transformation-PM-Agent-Service.git` — a
different repo name than `Copilot-PMAgentv2`'s actual origin
(`Transformation-Enablement-PMO-Agent`). Commit messages visible in the
stray files (`feat(mcp): S1 read-only MCP slice`,
`refactor(status-report): externalise skill-owned business rules to
Program Registry`) describe an `engines` (pure business logic) +
`mcp-adapter` + `Program Registry` pattern — structurally similar to what
Agentic PMO calls tools-layer/skills-layer. **These referenced commits do
not exist in `Copilot-PMAgentv2`'s local git object database** (confirmed:
`git cat-file -e <sha>` fails) — cannot verify provenance or content from
within this checkout. **Ask the user directly** whether `PM-Agent-Service`
/ `Transformation-PM-Agent-Service` is real and further along — if its
Vitest-covered `mcp-adapter` layer is genuine, it may be significantly
more relevant to Agentic PMO's architecture than `Copilot-PMAgentv2`
itself.

### The "rebuild connectors every session" claim — partially corroborated

No literal match found in `Copilot-PMAgentv2`'s docs/changelog/git
history. Closely adjacent, found: a CHANGELOG entry
("2026-07-30 — CLAUDE.md: record tool paths... so sessions stop
re-discovering them... wastes turns/credits") about CLI tool-path
rediscovery (not MCP connector setup specifically); the VS Code 128-tool
cap forcing mid-session MCP server restarts (a different but related
friction); and a documented, live organisational concern about
Copilot-credit ROI (`docs/project/decisions.md` D-007: a "Run Receipt"
JSON block every skill emits, feeding a usage-metrics dashboard because
"leadership needs evidence to justify Copilot-credit spend"). Credit-cost
awareness is a real, live theme in this program's history — the specific
"rebuild connectors" framing may be a generalization of these, or may
come from elsewhere entirely. Still an open item (see main brief).

## Parked context — resolved / still open

- ~~A prior "vibe coded" repo exists with related material to this
  vision.~~ **Resolved 2026-08-02**: `Copilot-PMAgentv2`, shared and
  audited — see "Prior implementation audit" above.
- The "agents rebuild connectors every session, burn credits" problem
  statement — **partially corroborated**, not confirmed verbatim (see
  audit above, "The 'rebuild connectors every session' claim"). Still an
  open item.
- **New, still open**: the possible `PM-Agent-Service` /
  `Transformation-PM-Agent-Service` TypeScript rewrite referenced by
  stray files in the `Copilot-PMAgentv2` checkout — existence and
  relevance unconfirmed (see audit above, "Unresolved").

## Open items for architecture/PRD stage (not decided here)

- Build-vs-wrap decision against Atlassian's official Remote MCP Server
  (see above) — a real option, not just build-from-scratch.
- Exact shape of the skills layer / tools layer boundary as an actual
  interface contract (the brief only asserts the layering exists and
  why).
- Whether/how the skills layer reuses this organisation's existing BMAD
  Method agent-persona investment — flagged as an assumption in the
  brief, not confirmed.
- MCP Gateway's own integration contract (auth, PII-protection mechanism,
  registration process) — owned by that program; needs direct input from
  whoever runs it, not guessed here.
