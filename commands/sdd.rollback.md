---
name: sdd.rollback
description: Rollback feature to a previous workflow phase, preserving git history. Use when user needs to redo a phase.
model: sonnet
argument-hint: "[feature-name] [target-phase]"
---

> **Shared agent instructions**: Read `development-agents/framework/_shared/agent-instructions.md` before executing this command.

# Command: /sdd.rollback

**Description**: Safely revert a feature to a previous phase, preserving work history.

**Usage**:
- `/sdd.rollback [phase]` → Rollback current feature to phase
- `/sdd.rollback` → Show current phase, ask which to rollback to
- `/sdd.rollback --task TASK-XXX` → Revert changes from specific task
- `/sdd.rollback --phase N` → Revert to end of specific phase

**Phase Numbers**:
| Phase | Name |
|-------|------|
| 1 | Functional Specification |
| 2 | Technical Specification |
| 3 | Task Planning |
| 4 | Implementation |

---

## Quick Help

> `/sdd.rollback help` → Shows this summary

**Syntax**: `/sdd.rollback [target]`

| Flag | Description |
|------|-------------|
| (none) | Show current phase, ask which to rollback to |
| `[1-4]` | Rollback to specific phase number |
| `--task TASK-XXX` | Revert commits from specific task only |
| `--phase N` | Revert all commits after phase N |

**Phases**: 1=Functional, 2=Technical, 3=Tasks, 4=Implementation

**Examples**:
```bash
/sdd.rollback 2              # Rollback to end of technical spec
/sdd.rollback --task TASK-005  # Revert only TASK-005 commits
```

**See also**: `/sdd.help rollback` for detailed documentation

---

## When to Use

### Valid Rollback Scenarios

| Scenario | Rollback To | Reason |
|----------|-------------|--------|
| Requirements changed fundamentally | Phase 1 | Need new functional spec |
| Architecture needs redesign | Phase 2 | Technical approach wrong |
| Tasks don't match implementation reality | Phase 3 | Need to re-plan tasks |
| Implementation has critical issues | Phase 4 (restart) | Start implementation fresh |

### NOT Valid for Rollback

- Minor spec clarifications (use `/sdd.spec --include` instead)
- Single task failures (fix the task, don't rollback)
- Test failures (fix tests, don't rollback)
- Code review feedback (iterate, don't rollback)

---

## Rollback Rules

### What Gets Preserved

| Phase | Preserved | Archived |
|-------|-----------|----------|
| Rollback to 1 | Nothing | Tech spec, tasks, implementation |
| Rollback to 2 | Functional spec | Tasks, implementation |
| Rollback to 3 | Functional + Tech specs | Implementation |
| Rollback to 4 | All specs + tasks | Implementation progress |

### Rollback Matrix

```
Current Phase → Can Rollback To
─────────────────────────────────
Phase 5 (Impl)  → 4, 3, 2, 1
Phase 4 (Tests) → 3, 2, 1
Phase 3 (Tasks) → 2, 1
Phase 2 (Tech)  → 1
Phase 1 (Func)  → Cannot rollback
```

---

## Workflow

### Step 1: Validate Rollback Request

**Detect Current Phase from meta.md**:

The `meta.md` file uses `Current Stage:` field (not `current_phase:`). Map stage to phase number:

| Stage Name | Phase Number |
|------------|--------------|
| `functional` | 1 |
| `technical` | 2 |
| `tasks` | 3 |
| `tests` | 4 |
| `implementation` | 5 |

**Also check the `stages:` YAML section** for `status: in-progress` to confirm:

```yaml
stages:
  functional:
    status: approved        # Phase 1 complete
  technical:
    status: approved        # Phase 2 complete
  tasks:
    status: approved        # Phase 3 complete
  tests:
    status: approved        # Phase 4 complete
  implementation:
    status: in-progress     # ← Currently in Phase 5
    completed_tasks: 5
    total_tasks: 12
```

```bash
FEATURE_PATH="sdd/wip/[feature-name]"
# Read stage from meta.md (e.g., "implementation")
CURRENT_STAGE=$(grep "Current Stage:" "$FEATURE_PATH/meta.md" | cut -d: -f2 | tr -d ' ')

# Map stage name to phase number
case "$CURRENT_STAGE" in
    functional) CURRENT_PHASE=1 ;;
    technical)  CURRENT_PHASE=2 ;;
    tasks)      CURRENT_PHASE=3 ;;
    tests)      CURRENT_PHASE=4 ;;
    implementation) CURRENT_PHASE=5 ;;
    *) echo "Unknown stage"; exit 1 ;;
esac

TARGET_PHASE=$1

# Validate target is less than current
if [ "$TARGET_PHASE" -ge "$CURRENT_PHASE" ]; then
    echo "❌ Error: Can only rollback to earlier phases"
    exit 1
fi
```

### Step 2: Create Snapshot

Before making changes, snapshot current state to `.rollback-history/`.

### Step 3: Document Reason

Record rollback reason, impact assessment, and justification.

### Step 4: Archive Affected Phases

Move affected content to `.archived/` with templates reset.

### Step 5: Update meta.md

Update current phase and rollback history.

---

## Output Example

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⏪ ROLLBACK: user-preferences
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Current Phase: 4 (Implementation)
Target Phase:  2 (Technical Specification)

📸 Creating snapshot...
   Saved to: .rollback-history/20251127_143022

⚠️  This will archive:
   • Phase 3: Task list (12 tasks)
   • Phase 4: Implementation progress (5/12 tasks completed)

   This will preserve:
   • Phase 1: Functional specification ✓
   • Phase 2: Technical specification ✓

[AskUserQuestion: "Continue with rollback?"] → User: Yes

✅ Rollback Complete

Feature 'user-preferences' is now at Phase 2

Next steps:
1. Review and update technical specification if needed
2. Run: /sdd.spec technical --include
3. When ready: /sdd.spec technical --approve
```

---

## Safety Features

### Automatic Snapshot
Every rollback creates automatic snapshot - you can always restore.

### Confirmation Required
Rollbacks require explicit confirmation for destructive operations.

### Audit Trail
All rollbacks are recorded in meta.md with timestamp, user, reason, and snapshot location.

### Archive Preservation
Archived work is never deleted - moved to `.archived/` directory.

---

## Restoring from Rollback

If rollback was a mistake, restore from snapshot:

```bash
# List available snapshots
ls -la sdd/wip/[feature-name]/.rollback-history/
```

---

## Telemetry on Rollback

> **Note**: Telemetry is captured automatically by hooks in `~/.claude/logs/` (Claude Code) or `~/.cursor/logs/` (Cursor). Not available for optional Agent CLI.

---

## Optional flags (lazy-loaded)

| Flag | Reference |
|------|-----------|
| `--task TASK-XXX` | `references/rollback-intelligent-revert.md` |
| `--phase N` | `references/rollback-intelligent-revert.md` |
| `[phase]` (numeric) | Standard phase rollback (inline workflow above) |

---

## AI Agent Instructions


### Help Flag Detection

**WHEN** the user runs `/sdd.rollback help`:
1. Output ONLY the "Quick Help" section (not full documentation)
2. Do NOT execute rollback logic
3. Keep response concise (~15 lines)

### Phase Detection (MANDATORY)

**Before showing rollback options**, you MUST accurately detect the current phase:

1. **Read `meta.md`** from the feature's WIP folder
2. **Check `Current Stage:` field** for the stage name
3. **Verify with `stages:` YAML section** - look for `status: in-progress` or `status: approved`
4. **Cross-check with artifacts**:
   - Phase 1 complete: `1-functional/spec.md` exists and `stages.functional.status: approved`
   - Phase 2 complete: `2-technical/spec.md` exists and `stages.technical.status: approved`
   - Phase 3 complete: `3-tasks/tasks.json` exists and `stages.tasks.status: approved`
   - Phase 4 in progress: Any task has `status: in_progress` or `status: completed`

**Phase Detection Logic**:

```
IF stages.implementation.status = "in-progress" OR stages.implementation.completed_tasks > 0:
    CURRENT_PHASE = 4  # Implementation
ELIF stages.tasks.status = "approved":
    CURRENT_PHASE = 4  # Ready for implementation (or just started)
ELIF stages.tasks.status = "in-progress":
    CURRENT_PHASE = 3  # Task planning
ELIF stages.technical.status = "approved":
    CURRENT_PHASE = 3  # Ready for task planning
ELIF stages.technical.status = "in-progress":
    CURRENT_PHASE = 2  # Technical spec
ELIF stages.functional.status = "approved":
    CURRENT_PHASE = 2  # Ready for technical
ELSE:
    CURRENT_PHASE = 1  # Functional spec
```

**CRITICAL**: If `completed_tasks > 0` in the implementation stage, or if any task in `tasks.json` shows `status: in_progress` or `status: completed`, the feature IS in Phase 4 (Implementation).

### Rollback Options by Current Phase

| Current Phase | Available Rollback Targets | Show Options |
|---------------|---------------------------|--------------|
| Phase 4 (Implementation) | 3, 2, 1 | All 3 options |
| Phase 3 (Tasks) | 2, 1 | 2 options |
| Phase 2 (Technical) | 1 | 1 option |
| Phase 1 (Functional) | None | "Cannot rollback from Phase 1" |

### Key Rules

1. **Always create snapshot** before rollback
2. **Require confirmation** for destructive operations
3. **Document reason** in rollback record
4. **Never delete** - archive instead (applies to logs/ too!)
5. **Update telemetry** - Record rollback event and affected phases
6. **Add rollback_marker** - Never delete token log entries, add marker instead
7. **Increment runs counter** - Track re-executions in telemetry
8. **Accurate phase detection** - NEVER assume phase based on file count alone; check meta.md stages

---

> **Lazy-loaded**: When `--task TASK-XXX` or `--phase N` is present, Read `references/rollback-intelligent-revert.md` instead of standard phase rollback.

---

## Related Commands

- `/sdd.check` - View current status
- `/sdd.cancel` - Cancel feature entirely
- `/sdd.spec` - Continue after rollback

---
