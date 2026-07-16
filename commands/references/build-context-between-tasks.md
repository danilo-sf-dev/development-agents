# Reference: Build Context Check Between Tasks

**Used by**: `/sdd.build` Step 5b.

### Step 5b: Context Check Between Tasks

After updating task status on disk, estimate context usage before starting the next task.

| Context Level | Action |
|---------------|--------|
| < 50% | Continue to next task silently |
| 50-70% | Show advisory, recommend `/clear` |
| > 70% | Show advisory, **strongly recommend** `/clear` |
| > 80% | Show advisory: "Do `/clear` now — context is critical" |

When context >= 50%, **commit before showing advisory** (so progress is safe for `/clear`):
```bash
git add [modified files] sdd/wip/[feature]/3-tasks/tasks.json
git commit -m "feat: tasks through TASK-XXX complete"
```

Then show advisory:

```
╔═══════════════════════════════════════════════════════╗
║  CONTEXT ADVISORY                                     ║
╠═══════════════════════════════════════════════════════╣
║                                                       ║
║  Context usage: ~[XX]%                                ║
║  Completed: TASK-XXX ([N] of [M] in layer)            ║
║                                                       ║
║  Your progress is saved in tasks.json (committed).    ║
║  Primary recommendation:                              ║
║    /clear then /sdd.build --resume                   ║
║                                                       ║
║  Or continue as-is if context is manageable.           ║
║                                                       ║
╚═══════════════════════════════════════════════════════╝
```

> Skip this check if the current task is the last in the layer (layer completion handles it).
