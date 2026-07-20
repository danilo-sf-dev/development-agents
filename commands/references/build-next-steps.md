# Reference: Build Interactive Next Steps

**Used by**: `/sdd.build` Step 8.

### Step 8: Interactive Next Steps (After All Tasks Complete)

> **MANDATORY (Standard mode only)**: Offer interactive selection after all tasks complete.
> **EXPRESS MODE**: Skip this - auto-invoke `/sdd.finish`.

**Model advisory** (Standard mode): Read `references/model-suggestion-advisory.md` — full box for `phase_key`: `build→finish`.

**⛔ INVOKE TOOL (do not print this, CALL the tool)** (only in Standard mode):

```
AskUserQuestion(
  questions=[{
    "question": "All tasks complete and validated. Ready to finish?",
    "header": "Next",
    "options": [
      {"label": "/sdd.finish (Recommended)", "description": "Archive feature and complete — sugere modelo barato"},
      {"label": "/sdd.check --sync", "description": "Final consistency check"},
      {"label": "/sdd.build --layer 3", "description": "Re-run quality checks"}
    ],
    "multiSelect": false
  }]
)
```

**On user selection**:

| Selection | Action |
|-----------|--------|
| /sdd.finish (Recommended) | `Skill(skill="sdd.finish")` |
| /sdd.check --sync | `Skill(skill="sdd.check", args="--sync")` |
| /sdd.build --layer 3 | `Skill(skill="sdd.build", args="--layer 3")` |
| Other | User types custom input |

> **MODE BEHAVIOR**: In Express mode, automatically invoke `/sdd.finish` without asking.

---
