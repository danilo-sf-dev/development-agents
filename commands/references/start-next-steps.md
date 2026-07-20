# Reference: Start Interactive Next Steps

**Used by**: `/sdd.start` Step 12.

### Step 12: Interactive Next Steps

> **MANDATORY**: Always offer interactive selection, never just show text.

**Model advisory** (before AskUserQuestion): Read `references/model-suggestion-advisory.md` and show the full box for `phase_key`: `start→spec`.

After displaying success message, use **AskUserQuestion** to offer next actions:

**Determine options based on context**:

```pseudocode
if saved_description exists in meta.md:
    option_1_label = "/sdd.spec (with saved context)"
    option_1_description = "Uses your description to seed the spec — sugere modelo forte"
else:
    option_1_label = "/sdd.spec (Recommended)"
    option_1_description = "Start spec creation interactively — sugere modelo forte"
```

**⛔ INVOKE TOOL (do not print this, CALL the tool)** - options vary by context:

```
AskUserQuestion(
  questions=[{
    "question": "Feature initialized. What would you like to do next?",
    "header": "Next",
    "options": [
      {"label": "/sdd.spec (Recommended)", "description": "Start spec creation interactively — sugere modelo forte"},
      {"label": "/sdd.spec --audio", "description": "Describe your feature by voice"},
      {"label": "/sdd.check", "description": "View feature status"}
    ],
    "multiSelect": false
  }]
)
```

> **Note**: If saved description exists in meta.md, first option label should be "/sdd.spec (with saved context)" with description "Uses your description to seed the spec — sugere modelo forte".

**On user selection**:

| Selection | Action |
|-----------|--------|
| /sdd.spec (with saved context) | `Skill(skill="sdd.spec")` - description auto-loaded from meta.md |
| /sdd.spec (Recommended) | `Skill(skill="sdd.spec")` |
| /sdd.spec --audio | `Skill(skill="sdd.spec", args="--audio")` |
| /sdd.check | `Skill(skill="sdd.check")` |
| Other | User types custom input (e.g., `/sdd.spec "nueva descripción"`, questions, etc.) |

> **NOTE**: AskUserQuestion ALWAYS includes "Other" option automatically.
> Users can write ANY text: another command, a question, feedback, etc.

---
