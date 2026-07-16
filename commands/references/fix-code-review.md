# Reference: Fix Code Review

**Used by**: `/sdd.fix` Step 6.5.

### Step 6.5: Code Review (MANDATORY)

> **CRITICAL**: After applying code fixes, you MUST call the code review tool and fix ALL findings before proceeding.

See [AI_AGENT_GUIDELINES.md](../AI_AGENT_GUIDELINES.md#mandatory-code-review-protocol--v140) for full protocol.

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔍 CODE REVIEW
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Calling code review tool...

Review Results:
• Critical: 0
• Major: 0
• Minor: 2
  - src/validators/user.js:5 - Missing JSDoc comment
  - src/validators/user.js:8 - Variable 'emailRegex' could be const

Fixing minor findings...

✅ Re-running code review...
✅ All findings resolved (0 critical, 0 major, 0 minor)
```

**IMPORTANT**: Fix is NOT complete until code review shows ZERO findings (including minor).

---
