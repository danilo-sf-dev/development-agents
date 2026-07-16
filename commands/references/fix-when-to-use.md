# Reference: When to Use /sdd.fix

**Used by**: `/sdd.fix` routing decisions.

## When to Use /sdd.fix (Decision Guide)

> **Key Insight**: `/sdd.fix` is for errors that reveal **gaps in your specifications**, not for simple code typos.

### Decision Tree: Which Command Should I Use?

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    ERROR OCCURRED - WHAT SHOULD I DO?                        │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  Q1: Is this a spec/task/code CONSISTENCY issue?                             │
│      (e.g., code does something not in specs)                                │
│      │                                                                       │
│      ├── YES ──► /sdd.check --sync                                          │
│      │           Detects drift between layers, proposes fixes                │
│      │                                                                       │
│      └── NO ──► Q2: Is there an ERROR OUTPUT (test fail, crash, etc.)?      │
│                     │                                                        │
│                     ├── YES ──► /sdd.fix                                    │
│                     │           Analyzes error, propagates fix horizontally  │
│                     │                                                        │
│                     └── NO ──► Manual fix or /sdd.build                     │
│                                 Just make the code change                    │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### /sdd.fix vs /sdd.check --sync

| Aspect | `/sdd.fix` | `/sdd.check --sync` |
|--------|-------------|----------------------|
| **Trigger** | Error output (test fail, crash) | Suspected inconsistency |
| **Input** | Error message or output | None (scans all layers) |
| **Primary action** | Diagnose root cause, classify problem | Detect drift between layers |
| **Output** | Fix proposal for affected layers | Inconsistency report with fixes |
| **When to use** | "Tests are failing, what's wrong?" | "Did I forget to update the spec?" |

### /sdd.fix vs Manual Code Fix

| Scenario | Use `/sdd.fix` | Fix Manually |
|----------|-----------------|--------------|
| Simple typo in code | ❌ | ✅ |
| Missing semicolon | ❌ | ✅ |
| Test fails due to new behavior not in specs | ✅ | ❌ |
| API returns wrong error code | ✅ | ❌ |
| Edge case reveals missing requirement | ✅ | ❌ |
| NullPointerException in existing logic | ⚠️ Check if it reveals a spec gap | ✅ if pure code bug |

### When NOT to Use /sdd.fix

| Error Type | Why Not /sdd.fix | What To Do Instead |
|------------|-------------------|-------------------|
| Configuration/env errors | Not a spec issue | Fix config, redeploy |
| Infrastructure issues | Not a code issue | Check infra, ops |
| Typos/syntax errors | No spec impact | Fix directly |
| Import/dependency errors | Build issue | Fix dependencies |
| Authentication failures | Runtime issue | Check credentials |

---
