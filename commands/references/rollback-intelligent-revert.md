# Reference: Intelligent Revert (`/sdd.rollback`)

**Used by**: `/sdd.rollback --task TASK-XXX` or `/sdd.rollback --phase N`.

Git-aware reverting by logical units (Task or Phase) instead of just by phase number.

## Why Intelligent Revert?

Traditional rollback (`/sdd.rollback 3`) reverts to a phase boundary. Sometimes you need finer control:
- Revert just one task that broke something
- Undo all changes from a specific phase
- Keep earlier tasks but redo one specific task

## Commit tracking

During `/sdd.build`, each task completion records its commit(s) in `meta.md`:

```yaml
implementation:
  tasks:
    TASK-001:
      status: completed
      commits:
        - hash: "abc123"
          message: "feat(payment): TASK-001 - Create Dockerfile"
```

## `--task TASK-XXX` — revert specific task

1. Reads task commits from `meta.md`
2. Creates snapshot before reverting
3. Runs `git revert` for each commit (newest first)
4. Updates task status to `pending`
5. Updates `meta.md` with revert record

After completion: `/sdd.build task TASK-XXX` to re-implement.

## `--phase N` — revert to phase end

1. Identifies all tasks in phases > N
2. Collects their commits
3. Creates snapshot
4. Reverts all commits (newest first)
5. Updates all affected task statuses

After completion: `/sdd.plan` (re-generate tasks if needed) or `/sdd.build`.

## When to use each

| Scenario | Use |
|----------|-----|
| "Requirements changed completely" | `/sdd.rollback 1` (standard) |
| "TASK-005 broke the build" | `/sdd.rollback --task TASK-005` |
| "Need to redo implementation with different approach" | `/sdd.rollback --phase 3` |
| "Just one task needs fixes" | `/sdd.rollback --task TASK-XXX` |

## Standard vs intelligent revert

| Aspect | Standard Rollback | Intelligent Revert |
|--------|-------------------|-------------------|
| Granularity | Phase boundaries only | Task or phase level |
| Git awareness | Archives files only | Reverts actual commits |
| Re-implementation | Must redo entire phase | Can redo single task |
| Use case | Major scope changes | Bug fixes, redo specific work |
