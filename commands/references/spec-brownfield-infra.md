# Reference: Brownfield Infrastructure Sections

**Used by**: `/sdd.spec` Step 5 when generating technical specs in brownfield mode.

### Brownfield Mode - Infrastructure Sections

> **CRITICAL**: Before generating technical spec, check `meta.md` for project mode.

**Step 1: Determine Project Mode**
```bash
# Read mode from meta.md
mode=$(grep "mode:" sdd/wip/[feature]/meta.md | cut -d: -f2 | tr -d ' ')
# Returns: greenfield | brownfield
```

**Step 2: Determine Feature Type** (brownfield only)

| Feature Type | Indicators |
|--------------|------------|
| **Touches Infrastructure** | Adds new project service (KeyValueStore, MessageQueue, etc.), requires new database/table, modifies Dockerfile, adds new external dependency requiring secrets, creates new scheduled job |
| **Pure Business Logic** | Adds API endpoints to existing controllers, modifies business rules, updates existing data models, integrates with already-configured services |

**Step 3: Include/Exclude Infrastructure Sections**

| Mode | Feature Type | Infrastructure Sections |
|------|--------------|------------------------|
| greenfield | Any | ✅ Include ALL (Dockerfile, /ping, ) |
| brownfield | Touches infrastructure | ✅ Include ALL |
| brownfield | Pure business logic | ❌ EXCLUDE foundational sections |

**Sections to EXCLUDE in Brownfield Pure-Logic Features:**

| Section | Action | Reason |
|---------|--------|--------|
| Dockerfile status/verification tables | ❌ EXCLUDE | App already has working Dockerfile |
| Dockerfile.runtime mentions | ❌ EXCLUDE | Runtime config already exists |
| /ping endpoint status | ❌ EXCLUDE | Health check already implemented |
| "Platform Compliance" section | ❌ SKIP | Handled by AUTO-TASK-PLATFORM-COMPLIANCE |
| Basic auth patterns (existing token/scope setup) | ❌ EXCLUDE | Auth already configured (reference only if feature needs new scopes) |

4. **Project Services** - query via your internal service directory/registry, if your org has one
5. **Dependencies** ⭐ - **MUST check platform docs for any dependency with known compliance/security requirements** (see Key Rules #11)
6. **Design Decisions** - With rationale
7. **Data Model** - Entities, schemas, migrations
8. **REST API Contracts** - Endpoints, request/response
9. **Frontend Architecture** ⭐ - **CONDITIONAL for frontend features** (see below)
10. **Testing Strategy** - Unit and integration tests only (E2E tests are external - see note below)
11. **Security** ⭐ - **MUST include Secrets Management section** (BLOCKER - see below)
12. **Performance** - Targets, optimization
13. **Deployment** - Rollout strategy

---

**Sections to INCLUDE in ALL Technical Specs:**

| Section | Always Include |
|---------|---------------|
| Architecture diagrams | ✅ Feature-specific architecture |
| API contracts | ✅ New/modified endpoints |
| Data model | ✅ New/modified entities |
| Security | ✅ If feature has auth/permission requirements |
| Dependencies | ✅ External services the feature integrates with |
| Design decisions | ✅ Feature-specific technical choices |

**Detection Heuristic for Platform AI docs Agent:**

```
IF mode == "greenfield":
    → Include full section
    → Include Dockerfile verification
    → Include /ping endpoint setup

ELIF mode == "brownfield":
    IF feature creates new project services OR new database tables OR modifies Dockerfile:
        → Include section
        → Include relevant infrastructure setup
    ELSE:
        → SKIP Dockerfile sections
        → SKIP /ping endpoint status
        → SKIP " Platform compliance" (AUTO-TASK handles it)
        → Focus on feature-specific architecture and API contracts
```

**Example - Brownfield Pure Logic Feature:**

```markdown
# ❌ DO NOT include in brownfield pure-logic spec:

## Platform compliance
| Requirement | Status | Notes |
|-------------|--------|-------|
| Dockerfile exists | ✅ | ... |
| /ping endpoint | ✅ | ... |

# ✅ DO include:

## Architecture Overview
[Feature-specific Mermaid diagram]

## API Contracts
[New endpoints being added]

## Data Model
[New/modified entities]
```

**Template Processing Script** (deterministic cleanup):

```bash
# Process template with conditional sections removed
bash development-agents/framework/tools/templates/process-template.sh \
  --template development-agents/framework/templates/technical-spec.md \
  --mode brownfield \
  --feature-type pure-logic \
  --output sdd/wip/[feature]/2-technical/spec.md

# Or auto-detect from feature path
bash development-agents/framework/tools/templates/process-template.sh \
  --template development-agents/framework/templates/technical-spec.md \
  --feature-path sdd/wip/[feature] \
  --output sdd/wip/[feature]/2-technical/spec.md
```
