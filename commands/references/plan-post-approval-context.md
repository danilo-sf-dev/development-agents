# Reference: Plan Post-Approval Context

**Used by**: `/sdd.plan` Step 8.

### Step 8: Post-Approval Context Check

Before presenting next steps, estimate context usage. If > 50%, show advisory:

```
╔═══════════════════════════════════════════════════════╗
║  CONTEXT ADVISORY                                     ║
╠═══════════════════════════════════════════════════════╣
║                                                       ║
║  Context usage: ~[XX]%                                ║
║  Phase completed: task planning                       ║
║                                                       ║
║  All tasks are saved in tasks.json.                   ║
║  Primary recommendation:                              ║
║    /clear then /sdd.test                             ║
║  Fresh context (~187K tokens) outperforms              ║
║  compaction (~140K degraded tokens).                   ║
║                                                       ║
╚═══════════════════════════════════════════════════════╝
```

| Context Level | Action |
|---------------|--------|
| < 50% | No advisory — proceed to Step 9 |
| 50-70% | Show advisory, recommend `/clear` |
| > 70% | Show advisory, **strongly recommend** `/clear` |
| > 80% | Show advisory: "Do `/clear` now — context is critical" |

**When to skip**: Very small feature (≤3 tasks) with context < 40%.
