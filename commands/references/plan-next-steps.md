# Reference: Plan Interactive Next Steps

**Used by**: `/sdd.plan` Step 9.

### Step 9: Interactive Next Steps (After Tasks Approved)

> **MANDATORY**: Always offer interactive selection after tasks are approved.

**⛔ INVOKE TOOL (do not print this, CALL the tool)**:

```
AskUserQuestion(
  questions=[{
    "question": "Tasks ready. Write tests first?",
    "header": "Next",
    "options": [
      {"label": "/clear + /sdd.test (Recommended)", "description": "Fresh context for tests-first gate"},
      {"label": "/sdd.test", "description": "Write failing tests before implementation"},
      {"label": "/sdd.test --refine", "description": "Skip if tests already exist — refine only"},
      {"label": "/sdd.check", "description": "Review task structure"}
    ],
    "multiSelect": false
  }]
)
```

**On user selection**:

| Selection | Action |
|-----------|--------|
| /clear + /sdd.test (Recommended) | Inform user to run `/clear`, then `/sdd.test` |
| /sdd.test | `Skill(skill="sdd.test")` |
| /sdd.test --refine | `Skill(skill="sdd.test", args="--refine")` |
| /sdd.check | `Skill(skill="sdd.check")` |
| Other | User types custom input |

---

> **Lazy-loaded**: When `--view` is present, Read `references/plan-view.md` and follow it instead of the standard workflow.

---
