# Reference: Build Code Review Protocol

**Used by**: `/sdd.build` per-task quality cycle.

## Mandatory Code Review Protocol

> **BLOCKING**: Code review is not optional. ALL findings must be fixed, including minor issues.

```
TASK COMPLETION CYCLE (per task):

┌─────────────────────────────────────────────────────────────────┐
│  1. IMPLEMENT → Write production code                           │
│         ↓                                                       │
│  2. TEST → Run unit/integration tests (skip for prototype)      │
│         ↓                                                       │
│  3. QUALITY → Invoke sdd-code-reviewer, performance, security  │
│         ↓                                                       │
│  4. FIX ALL → Critical, Major, AND Minor findings               │
│         ↓                                                       │
│  5. RE-CHECK → Re-run until ZERO findings                       │
│         ↓                                                       │
│  6. COMPLETE → Mark done, commit                                │
└─────────────────────────────────────────────────────────────────┘
```

**You MUST fix ALL findings** including minor - Minor findings are NOT optional. Minor issues accumulate into technical debt.

---
