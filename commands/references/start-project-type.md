# Reference: Project Type Selection

**Used by**: `/sdd.start` Step 5.

### Step 5: Project Type Selection (MOVED UP)

> **WHY FIRST**: Prototypes skip PROJECT.md prompt, saving time for quick POCs

**⚠️ MUST SHOW this comparison table before asking:**

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    📋 PROJECT TYPE COMPARISON                               │
├─────────────┬───────────────┬───────────────┬───────────────────────────────┤
│   Aspect    │   Prototype   │      MVP      │         Production            │
├─────────────┼───────────────┼───────────────┼───────────────────────────────┤
│ Unit Tests  │ ❌ Skip       │ ⚠️ Critical   │ ✅ Full coverage              │
│ Coverage    │ 0%            │ Varies        │ 80%+                          │
│ CI Pipeline │ Optional      │ Required      │ Required                      │
│ Code Review │ ❌ Skip       │ ✅ Yes        │ ✅ Yes                        │
│ E2E Tests   │ ❌ Skip       │ ❌ Skip       │ ✅ Opt-in                     │
│ Best for    │ Quick POC,    │ Internal      │ Customer-facing,              │
│             │ experiments   │ tools, MVPs   │ compliance required           │
└─────────────┴───────────────┴───────────────┴───────────────────────────────┘
```

**⛔ INVOKE TOOL (do not print this, CALL the tool)**:

```
AskUserQuestion(
  questions=[{
    "question": "What type of project is this?",
    "header": "Type",
    "options": [
      {"label": "Prototype", "description": "Demo app, no tests, quick validation"},
      {"label": "MVP", "description": "Tests for critical paths only"},
      {"label": "Production (Recommended)", "description": "Full coverage 80%+, quality checks"}
    ],
    "multiSelect": false
  }]
)
```
