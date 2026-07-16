# Reference: Fix Failure and Recovery

**Used by**: `/sdd.fix` when fix doesn't stick.

## Failure Scenarios and Recovery

### What If Fix Doesn't Work?

| Scenario | Symptom | Recovery |
|----------|---------|----------|
| **Wrong Classification** | Problem persists after fix | `/sdd.rollback --task` → Re-run `/sdd.fix` with fresh analysis |
| **Incomplete Fix** | Tests still fail | Run `/sdd.fix` again (builds on previous), consider `sdd-debugger` |
| **Code Review Issues** | Critical findings | Address ALL findings before proceeding - this is a quality gate |
| **Consistency Fails** | Layer inconsistencies | Update specs/tasks for new behaviors, re-run check |
| **Too Complex** | Multiple attempts fail | Delegate to `sdd-debugger` subagent for deep analysis |

### Exit Criteria: When Is a Fix Complete?

A fix is complete when ALL of the following are true:

| Checkpoint | Verification |
|------------|--------------|
| ✅ Tests pass | Run test suite, 100% pass |
| ✅ Code review clean | code review tool shows 0 findings |
| ✅ Specs updated | All new behavior documented |
| ✅ Tasks updated | All new work captured in tasks |
| ✅ Consistency verified | Bidirectional check passes |
| ✅ **Fix record persisted** ⭐ v1.7.0 | `sdd/fixes/FIX-NNN-DATE.md` (or `sdd/wip/{feature}/fixes/`) exists AND `fixes-log.md` has a new row |

**⛔ DO NOT declare the fix complete without the fix record file.** If the `fixes/` directory does not exist yet, CREATE IT and the fix record before marking done.

If ANY checkpoint fails, the fix is NOT complete. Return to the relevant step and iterate.

---
