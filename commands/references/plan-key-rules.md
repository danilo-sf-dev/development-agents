# Reference: Plan Key Rules

**Used by**: `/sdd.plan` ID generation and extended rules.

## Key Rules

| Rule | Details |
|------|---------|
| **JSON only** | Generate `tasks.json`, never `tasks.md` |
| **Layer assignment** | Layer 1=local, 2=platform, 3=quality |
| **Quality gates** | `GATE:` prefix in acceptance criteria |
| **Story sizing** | Max 2-3 sentences per description |
| **No deploys** | NEVER generate deploy tasks |
| **Approver identity** | Capture via `git config user.name` |
| **Deterministic IDs** | Use `generate-ids.sh` for task IDs (see below) |

### Deterministic Task ID Generation

> **MANDATORY**: Use script for task ID generation - Ensures uniqueness and consistency.

```bash
# Generate next task ID
next_task=$(bash development-agents/framework/tools/generation/generate-ids.sh task sdd/wip/[feature])
# Returns: TASK-004 (if TASK-001, TASK-002, TASK-003 exist)

# Generate multiple task IDs at once
bash development-agents/framework/tools/generation/generate-ids.sh task sdd/wip/[feature] --count 10
# Returns: TASK-004 TASK-005 ... TASK-013

# JSON output for programmatic use
bash development-agents/framework/tools/generation/generate-ids.sh task sdd/wip/[feature] --count 5 --json
# Returns: {"type":"task","count":5,"ids":["TASK-004","TASK-005","TASK-006","TASK-007","TASK-008"]}
```

**When to use**:
1. Before generating tasks.json → Get all IDs needed upfront
2. When adding tasks via --refine → Get next sequential ID
3. Batch generation → Use --count for efficiency

> **Telemetry**: Captured automatically by hooks - no manual logging required.

---
