---
name: sdd.check
description: View feature status, progress, and validation results. Use when user wants to check feature health or run validations.
model: sonnet
argument-hint: "[feature-name] [--sync]"
---

> **Shared agent instructions**: Read `development-agents/framework/_shared/agent-instructions.md` before executing this command.

# Command: /sdd.check

**Description**: View feature status, run consistency checks, and validate compliance

**Usage**:
- `/sdd.check` → Current feature status overview
- `/sdd.check [feature]` → Specific feature status (by name, number, or full name)
- `/sdd.check --sync` → Check consistency between specs/tasks/code + propose fixes
- `/sdd.check --compliance` → Check tests/lint compliance + propose fixes
- `/sdd.check --project` → Validate PROJECT.md against framework standards
- `/sdd.check --version` → Check framework version compatibility
- `/sdd.check task TASK-XXX` → Specific task details
- `/sdd.check --resume` → List all resumable sessions across features
- `/sdd.check --resume --last` → Resume last interrupted session

**Feature Reference Formats**:
- By name: `/sdd.check user-auth`
- By full name: `/sdd.check 20260120-user-auth`

---

## Quick Help

> `/sdd.check help` → Shows this summary

**Syntax**: `/sdd.check [target] [flags]`

| Flag | Description |
|------|-------------|
| (none) | Current feature status overview |
| `[feature]` | Specific feature status |
| `--sync` | Check specs/tasks/code consistency |
| `--compliance` | Check tests/lint compliance |
| `--project` | Validate PROJECT.md against standards |
| `--version` | Check framework version compatibility |
| `task TASK-XXX` | Specific task details |
| `--resume` | List resumable sessions |

**Examples**:
```bash
/sdd.check                 # Current feature status
/sdd.check --sync          # Check consistency + propose fixes
/sdd.check 003             # Check feature 003 status
```

**See also**: `/sdd.help check` for detailed documentation

---


## Subagent Delegation (MANDATORY for --sync)

> **⚠️ MANDATORY**: See [warning-hierarchy.md](../framework/standards/warning-hierarchy.md#subagent-delegation-central-principle) for the central principle.
> The `--sync` flag MUST delegate analysis to specialized subagents.

```bash
# Cross-layer analysis via GenAI Gateway (advisory)
result=$(bash development-agents/framework/tools/genai/genai-analyze-layers.sh sdd/wip/[feature])
if [ $? -ne 0 ]; then
    # Fallback to deterministic analysis
    result=$(bash development-agents/framework/tools/extraction/analyze-layers.sh sdd/wip/[feature] --json)
fi
```

**Skill for --compliance**:
| Check Type | Skill |
|------------|-------|
| Build/lint/coverage | `sdd-validator` |
| | `sdd-validator` |

---

## Purpose

Unified command for:
1. **Status** - View feature progress and metrics
2. **Sync** - Validate consistency between all framework layers (specs ↔ tasks ↔ code)
3. **Compliance** - Validate technical requirements (, tests, linting)

---

## Quick Reference

| Command | What it does |
|---------|--------------|
| `/sdd.check` | Status overview (read-only) |
| `/sdd.check --sync` | Consistency validation + fixes (y/n) |
| `/sdd.check --compliance` | Technical validation + fixes (y/n) |
| `/sdd.check --project` | PROJECT.md validation against standards |
| `/sdd.check --version` | Framework version compatibility |
| `/sdd.check task TASK-XXX` | Task details |
| `/sdd.check --resume` | List all resumable sessions |
| `/sdd.check --resume --last` | Resume last interrupted session |

---

## `/sdd.check` - Status Overview

### Express Mode

```
/sdd.check
```

Shows compact status:
```
Feature: payment-gateway
Stage: implementation (Phase 4/4)
Progress: 72% (13/18 tasks)
ETA: ~4h remaining

Next: Continue with /sdd.build
```

---

### Standard Mode (default)

```
/sdd.check
```

Shows detailed status with metrics:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 Feature Status: payment-gateway
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Feature ID: feat-042
Feature Number: 042
Created: 2025-11-20
Current Stage: implementation (Phase 4/4)
Mode: standard
Framework: v1.2.1 ✅   # or "v1.1.18 → v1.2.1 ⚠️ (run --version)"

────────────────────────────────────────
📈 Phase Progress
────────────────────────────────────────

Phase 1: Functional Spec    ✅ Completed (2025-11-20)
Phase 2: Technical Spec     ✅ Completed (2025-11-21)
Phase 3: Task Planning      ✅ Completed (2025-11-22)
Phase 4: Implementation     🔄 In Progress

────────────────────────────────────────
⚙️ Implementation Progress
────────────────────────────────────────

Progress: ████████████░░░░░░░░ 72% (13/18 tasks)

By Status:
✅ Completed:    13 tasks
🔄 In Progress:  2 tasks
⏸️ Blocked:      0 tasks
⏳ Pending:      3 tasks

────────────────────────────────────────
⏱️ Time Metrics
────────────────────────────────────────

• Time spent: 12.4h
• Estimated remaining: 4.2h
• Velocity: 8% faster than estimates

────────────────────────────────────────
📊 Quality Metrics
────────────────────────────────────────

• Tests: 67/67 passing (100%)
• Coverage: 89%
• Linter: 0 errors

────────────────────────────────────────
🎯 Next Actions
────────────────────────────────────────

1. Complete in-progress tasks (TASK-014, TASK-015)
2. Start pending tasks (TASK-016, TASK-017, TASK-018)
3. When done: /sdd.finish

────────────────────────────────────────
📋 Backlog Summary
────────────────────────────────────────

5 items in backlog:
  └── 2 High priority pending
  └── Use /sdd.backlog to view details
```

> **Note**: Backlog summary only shown if `sdd/backlog.md` exists and has items.

---

## Rare workflows (lazy-loaded)

When a flag-specific variant is invoked, read `references/check-rare-workflows.md` (matching section) plus the rules/examples in **Optional flags** below.

---

## AI Agent Instructions


### Help Flag Detection

**WHEN** the user runs `/sdd.check help`:
1. Output ONLY the "Quick Help" section (not full documentation)
2. Do NOT execute check logic
3. Keep response concise (~15 lines)

### Command Behavior Summary

| Command | Behavior |
|---------|----------|
| `/sdd.check` | Read-only status, no changes |
| `/sdd.check --sync` | Detect + propose fixes (confirm before applying) |
| `/sdd.check --compliance` | Detect + propose fixes (confirm before applying) |
| `/sdd.check --project` | Validate PROJECT.md + propose override registration |
| `/sdd.check --version` | Compare feature/framework versions + suggest migrations |
| `/sdd.check task X` | Read-only task details |
| `/sdd.check --resume` | List resumable sessions (read-only) |
| `/sdd.check --resume --last` | Resume last session (delegates to appropriate command) |

### Key Rules

1. **Auto-detect current phase** from meta.md
2. **Show relevant information** for current phase
3. **Highlight blockers** prominently
4. **Suggest next actions** clearly
5. **For --sync, --compliance, and --project**: Always ask for confirmation before applying fixes

## Optional flags (lazy-loaded)

Read the matching reference **only** when the flag is present:

| Flag / invocation | Workflow | Rules | Output examples |
|-------------------|----------|-------|-----------------|
| `--sync`, `--compliance`, `--project`, `--version`, `task`, `--resume` | `references/check-rare-workflows.md` | `references/check-flag-rules.md` | `references/check-output-examples.md` |

---

## Related Commands

- `/sdd.start` - Initialize feature
- `/sdd.spec` - Specifications phase
- `/sdd.plan` - Planning phase
- `/sdd.build` - Implementation phase
- `/sdd.finish` - Completion phase
- `/sdd.fix` - Fix specific errors

---

## Interactive Next Steps (After Status Display)

> **MANDATORY**: Always offer phase-appropriate interactive selection after showing status.
> **NOTE**: This applies to basic `/sdd.check` (status overview), not to `--sync`, `--compliance`, or `--version` flags.

**Determine options based on current phase**:

| Current Phase | Options to Offer |
|---------------|------------------|
| functional | `/sdd.spec`, `/sdd.spec --approve`, `/sdd.start --rename` |
| technical | `/sdd.spec technical`, `/sdd.spec technical --approve`, `/sdd.check --sync` |
| tasks | `/sdd.plan`, `/sdd.plan --approve`, `/sdd.check --sync` |
| implementation | `/sdd.build`, `/sdd.build --next`, `/sdd.finish` |
| complete | `/sdd.start`, `/sdd.list`, `/sdd.backlog list` |

**⛔ INVOKE TOOL (do not print this, CALL the tool)** - options vary by phase:

```
AskUserQuestion(
  questions=[{
    "question": "What would you like to do next?",
    "header": "Next",
    "options": [
      {"label": "/sdd.build", "description": "Continue implementation"},
      {"label": "/sdd.build --next", "description": "Start next task"},
      {"label": "/sdd.finish", "description": "Complete feature"}
    ],
    "multiSelect": false
  }]
)
```

> **Note**: Options above are for `implementation` phase. Use phase table above to determine actual options.

**On user selection**:

| Example Selection | Action |
|-------------------|--------|
| /sdd.spec | `Skill(skill="sdd.spec")` |
| /sdd.build | `Skill(skill="sdd.build")` |
| /sdd.build --next | `Skill(skill="sdd.build", args="--next")` |
| /sdd.finish | `Skill(skill="sdd.finish")` |
| Other | User types custom input |

---
