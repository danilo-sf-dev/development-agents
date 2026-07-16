# Reference: Build Quality Gate Persistence

**Used by**: `/sdd.build` Step 5.

### Step 5: Quality Gate and Status Persistence

After each task implementation:

1. **Check approved test files weren't touched** — run the detection in "Approved Tests Are Immutable" above. If triggered, resolve via the AskUserQuestion flow before continuing.
2. Invoke `sdd-validator-runner` (independent context)
3. Parse verdict: APPROVED / CAN_PROCEED_WITH_WARNINGS / CANNOT_PROCEED
4. If CANNOT_PROCEED: Fix and re-invoke
5. **Persist task status to disk** (always, after quality gate passes):
   ```bash
   # Update tasks.json: mark task completed
   jq '(.tasks[] | select(.id == "TASK-XXX")) .status = "completed"' \
     sdd/wip/[feature]/3-tasks/tasks.json > tmp.json && mv tmp.json sdd/wip/[feature]/3-tasks/tasks.json
   ```

> **WHY write to disk after every task**: `compact-state.sh` reads `tasks.json` to reconstruct
> state after `/clear`. Writing status to disk ensures progress survives even uncommitted.
> The git commit happens at layer boundaries or when the context check (Step 5b) triggers a
> `/clear` recommendation — at that point, code + `tasks.json` are committed together.
