# Reference: Backlog AI Agent Instructions

**Used by**: extended.

## AI Agent Instructions


### Help Flag Detection

**WHEN** the user runs `/sdd.backlog help`:
1. Output ONLY the "Quick Help" section (not full documentation)
2. Do NOT execute backlog logic
3. Keep response concise (~15 lines)

### Key Rules

1. **Centralized file**: Always use `sdd/backlog.md`
2. **Unique IDs**: Format `{TYPE}-{NNN}` (TODO-001, DEBT-002, IDEA-003)
3. **Auto-increment**: Next ID = max(existing IDs for type) + 1
4. **Origin tracking**: Always record which feature/context the item came from
5. **Non-blocking**: Items are informational, never block `/sdd.finish`
6. **Create file if missing**: First time `/sdd.backlog` is used

### Workflow Mode Rules (for `/sdd.backlog pick`)

7. **DEBT/TODO detection**: After feature creation, detect if item is DEBT or TODO → offer 3 workflow modes
8. **IDEA always full**: IDEA items skip the workflow mode question and use full pipeline
9. **Auto-generated spec header**: Auto-generated specs MUST include `> **Auto-generated** from backlog item [ID]` at the top
10. **Functional spec format**: Auto-generated functional specs use the lite format (problem + 1-2 stories + scope)
11. **Technical spec exploration**: Auto-generated technical specs (mode 3) REQUIRE codebase exploration before generation — use `sdd-explorer` and `sdd-system-designer` subagents to analyze affected files
12. **meta.md tracking**: Both `workflow_mode` and `auto_generated` flags MUST be set in meta.md
13. **Stage history**: Auto-approved stages must set `approved_by: auto-generated` and `approved_at` with current timestamp
14. **Backward compatibility**: Features without `workflow_mode` in meta.md default to `full` mode — all existing flows remain unchanged

### Linking with Features

When creating a feature from an item:
1. Mark item as `in-progress` with link to feature
2. In feature's `meta.md` add: `from_backlog: TODO-001`
3. When feature completes (`/sdd.finish`), offer to resolve the item

### During Build

When the agent detects a potential improvement:
1. Pause and show options to user
2. If "Fix now": implement immediately, don't add to backlog
3. If backlog: add item with origin from current feature/task
4. Continue with original task

---
