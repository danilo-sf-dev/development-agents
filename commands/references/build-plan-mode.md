# Reference: Build Plan Mode Integration

**Used by**: `/sdd.build` when plan_mode is enabled.

## Plan Mode Integration (Opt-In)

> **CRITICAL**: Claude Code Plan Mode for complex tasks. **OPT-IN** - disabled by default.
> Most users want uninterrupted implementation flow.

### Platform Availability

| Platform | Plan Mode Available |
|----------|---------------------|
| Claude Code (CLI) | ✅ Yes (`EnterPlanMode`/`ExitPlanMode`) |
| Cursor | ❌ No (use fallback) |

### Configuration

Plan Mode is **disabled by default**. Enable via `PROJECT.md` or `development-agents/framework/config.yaml`:

```yaml
# In PROJECT.md or development-agents/framework/config.yaml
plan_mode:
  build_complex_tasks: false      # Default: false (opt-in)
  build_layer_transitions: false  # Default: false (opt-in)
  build_ci_test_recovery: false # Default: false (opt-in)
```

### Trigger Conditions

| Trigger | Condition | When `plan_mode.build_*: true` |
|---------|-----------|--------------------------------|
| **Complex Tasks** | `task.complexity == "High"` OR `files_affected > 5` OR Layer 2 task OR `acceptance_criteria > 4` | `build_complex_tasks: true` |
| **Layer Transitions** | Completing Layer N → Layer N+1, context > 50%, 10+ tasks in next layer | `build_layer_transitions: true` |
| **CI Pipeline Recovery** | First failure with ambiguous error, classification confidence < 70%, or 2+ failed fix attempts | `build_ci_test_recovery: true` |

### Plan Mode Flow

```
IF config.plan_mode.build_* AND trigger_conditions_met AND EnterPlanMode available:
    1. EnterPlanMode()

    # Exploration phase (read-only)
    - Read related files
    - Analyze patterns
    - Identify dependencies

    # Design phase
    - Create implementation approach
    - List files to modify
    - Identify risks

    # Present to user
    - Show plan summary
    - Wait for approval

    2. ExitPlanMode()

    # Implementation phase
    - Execute approved plan
ELSE:
    # Fallback: proceed without Plan Mode
    - Implement directly (Express/Standard behavior)
```

### Fallback for Non-Claude Code Platforms

When `EnterPlanMode` is not available:

```
┌─────────────────────────────────────────────────────────────────────┐
│  PLAN MODE FALLBACK (Non-Claude Code)                                │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  INSTEAD OF:                                                         │
│    EnterPlanMode → Explore → Design → ExitPlanMode                   │
│                                                                      │
│  USE:                                                                │
│    1. Explore codebase (same read-only exploration)                  │
│    2. Design implementation plan                                     │
│    3. Display plan inline in chat                                    │
│    4. Use AskUserQuestion: "Approve this approach?"                  │
│       - Options: "Approve", "Modify", "Cancel"                       │
│    5. Continue with approved plan                                    │
│                                                                      │
│  DETECTION:                                                          │
│    IF EnterPlanMode tool not available:                              │
│      → Use fallback flow automatically                               │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### Mode-Based Behavior

| Mode | Plan Mode Behavior |
|------|-------------------|
| Express | Skip Plan Mode (auto-implement) |
| Standard | Use Plan Mode if config enabled + triggers met |

---
