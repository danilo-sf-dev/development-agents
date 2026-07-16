# Reference: Feature Reopen Workflow (R1-R7)

**Used by**: `/sdd.start --reopen [feature-name] [--phase N]`

Reopens a feature that was already moved to `sdd/features/` (completed via `/sdd.finish`) back into `sdd/wip/` so it can be iterated on again.

---

## R1: Locate the Feature

```bash
match=$(ls -1 sdd/features 2>/dev/null | grep -- "-${feature_name}\$" | head -1)
if [ -z "$match" ]; then
    echo "❌ Feature '$feature_name' not found in sdd/features/. Listing available:"
    ls -1 sdd/features 2>/dev/null
    exit 1
fi
```

If the exact name isn't found, offer the closest matches via `AskUserQuestion` instead of failing silently.

## R2: Validate Current State

- Confirm no feature with the same name already exists in `sdd/wip/` (would collide).
- Read the feature's `meta.md` to confirm it's actually `status: completed` — reopening an in-progress feature from `sdd/wip/` doesn't make sense (it's already open).

## R3: Determine Target Phase

| `--phase` value | Resumes at |
|-----------------|------------|
| (not passed) | Last completed phase + 1 (inferred from `meta.md` stages) |
| `1` | Functional spec |
| `2` | Technical spec |
| `3` | Tasks/plan |
| `4` | Implementation |

> Note: with the tests-first gate, phase numbering in `meta.md`/`detect-phase.sh` is `functional=1, technical=2, tasks=3, tests=4, implementation=5`. Map `--phase 4` (this command's legacy numbering) to `implementation` for backward compatibility, and prefer named phases (`--phase tests`, `--phase implementation`) going forward.

## R4: Move Directory Back to WIP

```bash
mv "sdd/features/$match" "sdd/wip/$match"
```

## R5: Update `meta.md`

- Set `status: in-progress` again (was `completed`)
- Reset the target phase's own status back to `pending`/`in-progress` (and any phases after it, if reopening to an earlier phase than where it left off)
- Append a `reopened_at` timestamp and increment a `reopen_count` field for audit purposes
- Leave completed earlier phases untouched (don't reset a technical spec that's still valid just because you're reopening at `implementation`)

## R6: Recreate/Checkout the Branch

```bash
branch_name="feature/$feature_name"
if git show-ref --verify --quiet "refs/heads/$branch_name"; then
    git checkout "$branch_name"
    git pull origin "$branch_name" 2>/dev/null || true
else
    git checkout -b "$branch_name"
fi
```

## R7: Report and Hand Off

Show the user:
- Which phase they're resuming at
- A summary of what's already approved (don't make them re-approve specs/tasks that were already signed off, unless they explicitly asked to redo that phase)
- The next command to run (e.g. `/sdd.plan` if resuming at tasks, `/sdd.test` if resuming at tests, `/sdd.build` if resuming at implementation)

**Do not** silently reset approval gates. If `--phase` targets a phase earlier than what was approved, ask for explicit confirmation before discarding later approvals (e.g. "Reopening at technical spec will require re-approving tasks and tests — continue?").
