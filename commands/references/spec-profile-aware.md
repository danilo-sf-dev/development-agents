# Reference: Profile-Aware Spec Creation

**Used by**: `/sdd.spec` when adapting interview questions and technical output by user profile.

## 👤 Profile-Aware Spec Creation

> **RULE**: Adapt interview questions and output based on user profile.

### Check Profile First

```bash
# Read from meta.md or global config
profile=$(grep "type:" sdd/wip/*/meta.md | grep -o 'technical\|non-technical')
[ -z "$profile" ] && profile=$(cat development-agents/framework/user-profile.yaml | grep "^profile:" | cut -d: -f2 | tr -d ' ')
[ -z "$profile" ] && profile="non-technical"  # Default
```

### Functional Spec: Profile Differences

| Aspect | Technical | Non-Technical |
|--------|-----------|---------------|
| **Data source questions** | Ask about MessageQueue, Streams, scheduled jobs | Ask "Where does this data come from? (user input, other system, automatic)" |
| **Integration details** | Ask specific service names, API contracts | Ask "Does this need data from other systems?" |
| **Technical constraints** | Ask about performance, SLAs | Skip (agent infers from PROJECT.md / codebase) |

### Technical Spec: Profile Differences

| Aspect | Technical | Non-Technical |
|--------|-----------|---------------|
| **Code snippets** | Show full implementation examples via `sdd-implementer` skill | Hide code, show "Configuration ready ✓" |
| **Project services** | Show service names, containers, TTLs | Show "Data storage configured" |
| **Architecture diagrams** | Show full Mermaid diagrams | Show simplified flow: "Input → Processing → Output" |
| **API contracts** | Show full REST contracts with schemas | Show "API structure: N endpoints" |

### Simplified Questions (Non-Technical)

**Instead of**:
```
Q: "Where does the data originate? (MessageQueue event, Streams CDC, REST API, scheduled job, user input)"
```

**Ask**:
```
Q: "Where does [X] come from?"
   1. User enters it (form, upload)
   2. Another system sends it
   3. It's calculated/generated automatically
```

### Frontend Web Skills (Frontend framework/design system Projects) ⭐ v1.2.0

> **Lazy-loaded**: When the project has a Frontend framework/design system Web stack (`package.json` with `frontend-framework` or `@design-system/*`), Read `references/spec-frontend-web-agents.md` for agent routing.

---
