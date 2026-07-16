# Reference: Fix Plan Mode

**Used by**: `/sdd.fix` for complex bugs when plan_mode is on.

## Plan Mode for Complex Bugs ⭐ v1.2.7

> **ENABLED BY DEFAULT**: For complex bugs (DESIGN_FLAW, FEATURE_GAP), Plan Mode helps
> plan investigation strategy before diving in.

### Platform Availability

| Platform | Plan Mode Available |
|----------|---------------------|
| Claude Code (CLI) | ✅ Yes (`EnterPlanMode`/`ExitPlanMode`) |
| Cursor | ❌ No (use fallback) |
| Windsurf | ❌ No (use fallback) |
| project CLI | ❌ No (use fallback) |

### Configuration

Plan Mode for `/sdd.fix` is **enabled by default**. Disable via `PROJECT.md`:

```yaml
# In PROJECT.md or development-agents/framework/config.yaml
plan_mode:
  fix_complex_bugs: true  # Default: true (enabled)
```

### Trigger Conditions

Enter Plan Mode when **ANY** of these are true:
- Problem classified as `DESIGN_FLAW` or `FEATURE_GAP`
- Error spans multiple components (3+ files affected)
- Previous fix attempts failed (2+ attempts)
- Symptoms indicate systemic issues (performance, concurrency, race conditions)

> **Lazy-loaded**: During impact assessment/plan mode, Read `references/fix-templates.md` for assessment templates and workflow safeguards.

### Plan Mode Flow

```
AFTER Step 1.5 (Classification), BEFORE Step 2 (Root Cause):

  IF config.plan_mode.fix_complex_bugs AND complex_bug_detected:

    IF EnterPlanMode available (Claude Code):
      1. EnterPlanMode()

      2. EXPLORE: Map affected components
         - Identify all files involved in the error path
         - Collect evidence (logs, stack traces, test failures)
         - Document current behavior vs expected behavior

      3. DESIGN: Investigation strategy
         - Hypothesis priority list
         - Test sequence to validate hypotheses
         - Delegate decision (inline vs sdd-debugger for deep issues)

      4. Present plan to user
         - Show investigation strategy
         - List hypotheses in priority order

      5. ExitPlanMode() (user approves strategy)

    ELSE (Fallback for non-Claude Code):
      1. EXPLORE: Same read-only exploration
      2. DESIGN: Same investigation planning
      3. Display plan inline in chat
      4. AskUserQuestion: "Approve this investigation approach?"
         - Options: "Approve", "Modify", "Skip planning"

    6. Continue with Step 2 using approved strategy
```

### Post-Plan Mode Safeguards (MANDATORY)

```
┌─────────────────────────────────────────────────────────────────────┐
│  POST-PLANMODE SAFEGUARDS (MANDATORY)                                │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  AFTER ExitPlanMode, BEFORE applying any fix:                        │
│                                                                      │
│  1. Plan output is READ-ONLY guidance (not executable)               │
│     → Plan Mode exploration does NOT modify files                    │
│     → Only implementation phase modifies files                       │
│                                                                      │
│  2. Any fix MUST follow horizontal consistency:                      │
│     → IF fix touches code → check if specs need update               │
│     → IF fix touches specs → check if code needs update              │
│     → ALWAYS run /sdd.check --sync after fixes                      │
│                                                                      │
│  3. Artifact validation before marking fix complete:                 │
│     → specs are internally consistent                                │
│     → code matches specs                                             │
│     → tasks.json reflects current state                              │
│     → meta.md is accurate                                            │
│                                                                      │
│  4. IF Plan Mode suggests breaking change:                           │
│     → Show warning to user                                           │
│     → Explain which artifacts will be affected                       │
│     → Get explicit approval before proceeding                        │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### When to Skip Plan Mode

Skip Plan Mode for:
- `IMPLEMENTATION_BUG` (pure code bug, no spec impact)
- `MISSING_TASK` (clear scope, just add task)
- Simple typos, missing imports, obvious logic errors
- User explicitly requests `--auto` flag

---

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔍 PROBLEM CLASSIFICATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Analyzing problem type...

┌─────────────────────────────────────────────────────────────────┐
│                    CLASSIFICATION DECISION TREE                  │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  Q1: Does the fix require NEW FUNCTIONALITY not in specs?       │
│      │                                                           │
│      ├── YES ──► FEATURE GAP                                     │
│      │           Must update: Functional + Technical + Tasks     │
│      │                                                           │
│      └── NO ──► Q2: Does the fix require changing HOW           │
│                     something works (API, data model)?           │
│                     │                                            │
│                     ├── YES ──► DESIGN FLAW                      │
│                     │           Must update: Technical + Tasks   │
│                     │                                            │
│                     └── NO ──► Q3: Does the fix add work        │
│                                    not captured in tasks?        │
│                                    │                             │
│                                    ├── YES ──► MISSING TASK      │
│                                    │           Must update: Tasks│
│                                    │                             │
│                                    └── NO ──► IMPLEMENTATION BUG │
│                                                Code only         │
└─────────────────────────────────────────────────────────────────┘

**Classification Result**: [FEATURE_GAP / DESIGN_FLAW / MISSING_TASK / IMPLEMENTATION_BUG]

**Current Phase**: [from Step 0]

**Layers that MUST be updated** (only layers that EXIST at current phase):
- [ ] Functional Spec: [Yes/No - with reason] ← Always available
- [ ] Technical Spec: [Yes/No - with reason] ← Only if phase ≥ technical
- [ ] Tasks: [Yes/No - with reason] ← Only if phase ≥ tasks
- [ ] Code: [Yes/No - with reason] ← Only if phase = implementation

⚠️ **Phase Constraint**: If current phase is "technical", Tasks and Code sections above should show "N/A - layer does not exist yet"
```

#### Classification Examples

| Problem Description | Classification | Layers to Update |
|---------------------|----------------|------------------|
| "JaCoCo reports not being generated" | **FEATURE_GAP** | Functional + Technical + Tasks + Code |
| "Severity breakdown not showing per-type counts" | **FEATURE_GAP** | Functional + Technical + Tasks + Code |
| "API returns 500 instead of 400 for validation" | **DESIGN_FLAW** | Technical + Tasks + Code |
| "Missing error handling for null input" | **DESIGN_FLAW** | Technical + Tasks + Code |
| "Test coverage not reaching threshold" | **MISSING_TASK** | Tasks + Code |
| "NullPointerException in line 45" | **IMPLEMENTATION_BUG** | Code only |

> **WARNING**: If you classify as IMPLEMENTATION_BUG but the fix adds new behavior, you have misclassified. Re-evaluate.

---
