# Reference: `/sdd.plan --refine`

**Used by**: `/sdd.plan --refine` or when the user chooses "Adjust tasks" during approval.

## Available actions

Use `AskUserQuestion` to offer:
- Add new task
- Modify existing task
- Split large task
- Delete task
- Adjust complexity/priority
- **Rewrite language** (titles/descriptions/AC → resolved `spec_language` / `language.specs`)
- Done refining

When refining or adding tasks, keep prose in the resolved spec language (`meta.md` `spec_language` → `PROJECT.md` `language.specs` → `en`). If the current `tasks.json` is in the wrong language, rewrite it before approval.

When adding tasks, generate IDs via:
```bash
bash development-agents/framework/tools/generation/generate-ids.sh task sdd/wip/[feature]
```

After refining, re-run validation checks before approval.
