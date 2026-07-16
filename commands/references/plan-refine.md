# Reference: `/sdd.plan --refine`

**Used by**: `/sdd.plan --refine` or when the user chooses "Adjust tasks" during approval.

## Available actions

Use `AskUserQuestion` to offer:
- Add new task
- Modify existing task
- Split large task
- Delete task
- Adjust complexity/priority
- Done refining

When adding tasks, generate IDs via:
```bash
bash development-agents/framework/tools/generation/generate-ids.sh task sdd/wip/[feature]
```

After refining, re-run validation checks before approval.
