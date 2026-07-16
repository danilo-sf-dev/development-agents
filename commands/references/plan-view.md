# Reference: `/sdd.plan --view`

**Used by**: `/sdd.plan --view` or `/sdd.plan --view <path-to-tasks.json>`.

## Flow

1. Resolve `tasks.json`:
   ```bash
   TASKS_FILE=$(ls -1 sdd/wip/*/3-tasks/tasks.json 2>/dev/null | head -1)
   ```
2. Verify exists (if not: "No tasks.json found. Run /sdd.plan first.")
3. Open viewer:
   ```bash
   bash development-agents/framework/tools/state/view-tasks.sh "$TASKS_FILE"
   ```
4. Confirm: "Tasks viewer opened in browser"

Accepts explicit path: `/sdd.plan --view sdd/wip/my-feature/3-tasks/tasks.json`
