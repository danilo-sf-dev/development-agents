# Reference: Fix Bidirectional Consistency

**Used by**: `/sdd.fix` Step 7.

### Step 7: Bidirectional Consistency Check (MANDATORY)

> **CRITICAL**: After applying the fix, validate all layers remain consistent.

Run the sync validation:

```
/sdd.check --sync
```

This validates:
- **Functional ↔ Technical ↔ Tasks ↔ Code** consistency
- Detects any drift introduced by the fix
- Proposes additional fixes if gaps found

**Verdict Handling**:

| Verdict | Action |
|---------|--------|
| `APPROVED` | Fix complete, proceed |
| `CAN_PROCEED_WITH_WARNINGS` | Fix complete, note warnings in task |
| `CANNOT_PROCEED` | Apply suggested fixes before marking task complete |

**If sync finds issues**: Apply the suggested fixes, then re-run `/sdd.check --sync` until it passes.

---

### Consistency Check Failure

If consistency check fails, the fix is NOT complete:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔍 CONSISTENCY CHECK
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📋 Functional Spec ↔ Technical Spec
   ✅ All acceptance criteria have corresponding API contracts

🔧 Technical Spec ↔ Tasks
   ⚠️ INCONSISTENCY FOUND:
   - Technical spec mentions INVALID_EMAIL error (400)
   - No task exists for error handling implementation

📝 Tasks ↔ Code
   ✅ All tasks have corresponding code changes

💻 Code ↔ Tests
   ⚠️ INCONSISTENCY FOUND:
   - validateEmail() function has no test coverage

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
❌ CONSISTENCY CHECK FAILED
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Issues to resolve:
1. Add task for error handling implementation
2. Add tests for validateEmail() function

Would you like me to fix these inconsistencies? (y/n)
```

---
