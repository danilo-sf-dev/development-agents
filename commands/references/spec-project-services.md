# Reference: Project Services in Technical Spec

**Used by**: `/sdd.spec` Step 5 when documenting project services and optional instance discovery.

### Project Services with Code Snippets

> When documenting project services, auto-include code examples by delegating to the `sdd-implementer` skill, which fetches live documentation for the actual service/library in use.

**Workflow**:
1. After `sdd-explorer` identifies services
2. For each service, invoke: `Skill("sdd-implementer")` passing the service name and detected project language
3. The skill fetches live documentation and returns ready-to-use snippets
4. Include the returned snippet in the spec under the service entry

**Format in Technical Spec**:

```markdown
## Project Services

### Key-Value Store - User Sessions
- **Container**: `user-sessions`
- **TTL**: 3600s (1 hour)
- **Criticality**: HIGH

**Implementation Example** (via `sdd-implementer`):
[snippet returned by Skill("sdd-implementer")]

### Message Queue - Order Events
- **Topic**: `order-events`
- **Visibility**: private
- **Consumer**: `order-processor`

**Implementation Example** (via `sdd-implementer`):
[snippet returned by Skill("sdd-implementer")]
```

**Automatic Detection**:
- Detect project language from `.platform-config` file or file extensions
- Select appropriate snippet language variant
- If multiple languages detected, use primary (Java > Go > Node > Python)

**When to Skip Snippets**:
- Context budget is CRITICAL (>80%) - use concise format
- Service is simple (single-line usage)
- User explicitly requests minimal spec
- **User profile is `non-technical`** - show summary only, no code

**Non-Technical Profile Output** (instead of code snippets):

```markdown
## Platform Services

| Service | Purpose | Status |
|---------|---------|--------|
| Data storage | Store user sessions (1 hour) | ✓ Configured |
| Messaging system | Notify order events | ✓ Configured |

✓ Technical configuration ready - agent will implement automatically
```

### Project Service Instance Selection (Live Discovery, if applicable)

> When the technical spec identifies project services, and your org provides a CLI/skill for
> discovering existing instances, run live discovery to let the user choose existing instances
> or create new ones. This happens DURING spec creation, NOT during build. Skip entirely if
> your org has no such tooling — just document the service in the spec.

FOR EACH project service type identified:
  1. Check `sdd/PROJECT.md` for any declared CLI or skill used to list existing instances
     of this service type
  2. If a CLI is declared → run it to list existing instances
  3. If a discovery skill is declared instead → invoke it with the service type and app name
  4. If neither is declared → inform user: "Manage this service manually — see your org's platform console (referenced in sdd/PROJECT.md)"
  5. If CLI/skill call fails (not logged in, VPN) → inform user to fix
     and retry
  6. If instances found → AskUserQuestion: select existing or "Create new"
  7. If no instances found → auto-select "Create new"
  8. Record in spec with `(EXISTING)` or `(NEW)` marker

**Technical Spec Format**:

```markdown
### KeyValueStore - User Sessions
- **Container**: `user-sessions` **(EXISTING)**
- **TTL**: 3600s
- **Discovery**: Found via `project services keyvaluestore list`

### MessageQueue - Order Events
- **Topic**: `order-events` **(NEW)**
- **Action**: Create during /sdd.build
- **CLI**: `project services mq topics create`
```

If ANY services are marked `(NEW)`, add section to spec:

```markdown
## Infrastructure Creation

| Service | Name | CLI Command | Status |
|---------|------|-------------|--------|
| MessageQueue Topic | order-events | `project services mq topics create` | Pending |
```

**Profile-Aware Behavior**:

| Profile | Behavior |
|---------|----------|
| `technical` | Full interactive selection via AskUserQuestion |
| `non-technical` | Auto-select existing if found, create new otherwise |

**Reference**: See `project-cli-expert/SKILL.md` for the complete Service Discovery Protocol.
