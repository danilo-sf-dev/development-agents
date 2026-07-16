# Reference: Finish Interactive Next Steps

**Used by**: `/sdd.finish` after archive.

## What's Next?

After `/sdd.finish` completes successfully:

1. **Your feature is archived** in `sdd/features/[feature-name]/`
2. **Telemetry** captured automatically in `~/.claude/logs/` or `~/.cursor/logs/` (when supported)
3. **Documentation generated** (README.md, implementation-summary.md)

### Interactive Next Steps (After Archive Complete)

> **MANDATORY (Standard mode only)**: Offer interactive selection after archiving.
> **EXPRESS MODE**: Skip this - show brief completion message only.

**⛔ INVOKE TOOL (do not print this, CALL the tool)** (only in Standard mode):

```
AskUserQuestion(
  questions=[{
    "question": "Feature archived! What's next?",
    "header": "Next",
    "options": [
      {"label": "/sdd.start (Recommended)", "description": "Start a new feature"},
      {"label": "/sdd.start --reopen", "description": "Reopen this feature later for iteration"},
      {"label": "/sdd.backlog list", "description": "Check pending backlog items"},
      {"label": "/sdd.list", "description": "View all features"}
    ],
    "multiSelect": false
  }]
)
```

**On user selection**:

| Selection | Action |
|-----------|--------|
| /sdd.start (Recommended) | `Skill(skill="sdd.start")` |
| /sdd.start --reopen | Show: "To reopen later: `/sdd.start --reopen [feature-name]`" |
| /sdd.backlog list | `Skill(skill="sdd.backlog", args="list")` |
| /sdd.list | `Skill(skill="sdd.list")` |
| Other | User types custom input |

> **MODE BEHAVIOR**: In Express mode, just show completion message without prompting.

---
