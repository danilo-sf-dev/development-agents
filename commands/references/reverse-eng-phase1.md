# Reference: Reverse-Eng Phase 1 — Parallel Extraction

**Used by**: `/sdd.reverse-eng` Phase 1.

### Phase 1: Parallel Extraction

Extract data from **both sources simultaneously**. No interpretation, just facts.

```
┌─────────────────────────────────────────────────────────────────┐
│                    PARALLEL EXTRACTION                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   Queries ─────────────┐                                 │
│    • get_app_documentation    ├──► mcp-platform/                     │
│    • search_api_specs         │                                 │
│                               │                                 │
│  Code Analysis ───────────────┼──► code-analysis/               │
│    • Stack detection          │                                 │
│    • API extraction           │                                 │
│    • Database extraction      │                                 │
└───────────────────────────────┴─────────────────────────────────┘
```

**Step 0: Determine App Name** (CRITICAL)

```bash
# ALWAYS read from .platform-config file first (100% reliable)
APP_NAME=$(grep "^application_name:" .platform-config | sed 's/application_name: *//')
```

** Queries**:
1. `get_app_documentation(app_name)` - General documentation
2. `search_api_specs(app_name)` - OpenAPI specs
3. Conditional queries if coverage < 70%

**Code Analysis** (delegate to sdd-explorer):
1. Stack Detection - Java, Node, Go, Python
2. API Extraction - Endpoints from annotations/routes
3. Database Extraction - Entities, migrations
4.  Services Extraction - SDK usage, integrations
5. **Actor Discovery** - System consumers and integrations

> **Reference**: See `sdd-explorer` agent for stack-specific extraction commands.

---

#### Actor Discovery (v2.6.1)

> **PURPOSE**: Identify real system actors using authoritative architecture data.

**Source Hierarchy** (use in order):

| Priority | Source | What it provides | Reliability |
|----------|--------|------------------|-------------|
| 1. PRIMARY | **ProjectSystemMCP** (if configured — an example internal service-graph MCP; replace with whatever your org uses) | Clients, Dependencies, Platform Services | Authoritative |
| 2. SECONDARY | API docs search | Documentation, message-queue consumers | High |
| 3. FALLBACK | Code analysis | Inferred from patterns | Medium |

---

**Step 1: Query ProjectSystemMCP (PRIMARY)**

> **REQUIRES**: `ProjectSystemMCP` configured in `.mcp.json` (org-specific; not shipped by this pack). See [MCP_SETUP_GUIDE.md](../../framework/MCP_SETUP_GUIDE.md#other-mcp-servers-org-specific).

```
# Inbound clients (who calls this app)
mcp__ProjectSystemMCP__clients(app_name)

# Outbound dependencies (what this app calls)
mcp__ProjectSystemMCP__dependencies(app_name)

# Platform services owned by this app
mcp__ProjectSystemMCP__platform_services(app_name)
```

**What each returns**:

| Tool | Returns | Use for |
|------|---------|---------|
| `clients` | Services that call this app (inbound) | Actor identification |
| `dependencies` | Services + datastores this app calls (outbound) | Integration discovery |
| `platform_services` | KeyValueStore, MessageQueue, OS resources owned | Platform resource mapping |

**If ProjectSystemMCP unavailable**: Skip to Step 2. Note in `DOCUMENTATION_GAPS.md`:
```markdown
## Actor Discovery Limitations

- ProjectSystemMCP unavailable - actors discovered via fallback methods
- Recommended: Configure ProjectSystemMCP for authoritative data
```

---

**Step 2: Supplement with API docs and org-specific infra tooling (SECONDARY, if available)**

```
# API documentation (example MCP call — replace with whatever your org's docs MCP exposes)
mcp__platform__search_api_docs(app_name, query="architecture consumers integrations")

# Message-queue consumer discovery (if your org has a skill/CLI for this — check sdd/PROJECT.md)
```

Use these to:
- Fill gaps not covered by ProjectSystemMCP
- Get documentation context for discovered actors (via `search_api_docs`)
- Identify message-queue consumers, if your org provides tooling for this

---

**Step 3: Code Analysis (FALLBACK)**

Scan for known actor patterns in code:

| Actor Type | Detection Pattern |
|------------|-------------------|
| **API Callers** | Swagger consumers, API gateway configs |
| **Message Consumers** | MessageQueue/Streams subscribers |
| **Scheduled Jobs** | Cron configs,  Jobs, Director |
| **External Integrations** | REST client configs, external URLs |
| **Internal Services** | Service-to-service calls |

---

**Step 4: Consolidate in functional-spec.md**

```markdown
## System Context

### Inbound Clients (who calls us)

| Client | Type | Interaction | Source |
|--------|------|-------------|--------|
| [name] | Internal/External | [description] | ProjectSystemMCP / API docs / code |

### Outbound Dependencies (what we call)

| Dependency | Type | Purpose | Source |
|------------|------|---------|--------|
| [name] | Service/Datastore | [description] | ProjectSystemMCP / API docs / code |

### Platform Services Owned

| Service | Type | Purpose |
|---------|------|---------|
| [name] | KeyValueStore/MessageQueue/OS/etc | [description] |

## Actors

| Actor | Type | Interaction | Evidence |
|-------|------|-------------|----------|
| [name] | Internal/External/System | [description] | [source] |

### Actor Details

#### [Actor Name]
- **Type**: [Human | System | External Service]
- **Authentication**: [How they authenticate]
- **Endpoints Used**: [Which endpoints they call]
- **Frequency**: [If known - high/medium/low volume]
```

---

**Step 5: Handle Missing Actor Data**

If all sources fail to provide complete actor data:
1. Note gap in `DOCUMENTATION_GAPS.md`:
   ```markdown
   ## Missing Actor Information

   - ProjectSystemMCP: [unavailable / no data returned]
   - API docs search: [no architecture data found]
   - Code analysis: [limited patterns detected]
   - Recommended: Verify application is registered in your org's systems/service catalog, if one exists
   ```
2. Use code analysis to infer actors from:
   - Access log patterns (if available)
   - Security/auth configurations
   - API documentation comments

---

### Exhaustive Endpoint Discovery

> **CRITICAL**: Do NOT rely solely on . You MUST scan ALL controllers in code.

**Verification Rule**: If code has N controllers, output MUST document N controllers.

**Endpoint Categories**:

| Category | Marker | Criteria |
|----------|--------|----------|
| **Verified** | ✅✅ | In docs/ProjectSystemMCP AND code, schemas match |
| **Partial** | ✅⚠️ | In both, but schemas differ |
| **Code Only** | 🔸 | In code only (undocumented) |
| **Docs Only** | ⚠️ | In docs/ProjectSystemMCP only (PHANTOM - verify!) |
| **Internal** | 🔸 INTERNAL | `/internal/*`, `/admin/*` paths |

---
