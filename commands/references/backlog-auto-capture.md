# Reference: Backlog Auto-capture During Build

**Used by**: `/sdd.build` / `/sdd.fix` integration with backlog.

## Auto-capture During Build

During `/sdd.build` and `/sdd.fix`, the agent can detect potential improvements:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
💡 Potential Improvement Detected
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

While implementing TASK-005, I noticed:
"The error handling here is minimal - should add proper retry logic"
```

**⛔ INVOKE TOOL (do not print this, CALL the tool):**

```
AskUserQuestion(
  questions=[{
    "question": "What would you like to do with this improvement?",
    "header": "Action",
    "options": [
      {"label": "Fix now", "description": "Address immediately in current task"},
      {"label": "Add as TODO", "description": "Track for later implementation"},
      {"label": "Add as DEBT", "description": "Document as technical debt"},
      {"label": "Skip", "description": "Not important, ignore"}
    ],
    "multiSelect": false
  }]
)
```

Note: For "IDEA" (future improvement suggestion), user can select "Other" and specify.

### If "Fix now" is chosen:

```
User selected: Fix now

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔧 Fixing Now
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Implementing retry logic in src/services/payment-api.ts...

[Agent implements the fix as part of current task]

✅ Fixed: Added retry logic with exponential backoff
   Files modified: src/services/payment-api.ts

Continuing with TASK-005...
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### If adding to backlog:

```
Choice: T

Title suggestion: Add retry logic to payment API calls
Accept? [Y/n/custom]: Y

✅ Added TODO-004 to backlog
   Origin: feature/payment-gateway (TASK-005)

Continuing with TASK-005...
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Criteria for "Fix Now" vs "Add to Backlog"

| Criterion | Fix Now | Add to Backlog |
|----------|---------|----------------|
| Estimated effort | Low (trivial change) | Medium/High |
| Related to current task | Yes | Not directly |
| Risk if not done | High (bugs, security) | Low (improvement) |
| Complexity | Low | High |
| Scope creep | Does not expand scope | Would expand scope |

**Golden rule**: If the fix is small and directly related to what you're doing, offer "Fix Now" as the first option.

---
