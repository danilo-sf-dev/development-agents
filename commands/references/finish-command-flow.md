# Reference: Finish Command Flow Diagram

**Used by**: `/sdd.finish` when needing ASCII flow.

## Command Flow

```
┌─────────────────────────────────────────────────────────────────────┐
│                         /sdd.finish FLOW                            │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  PREREQUISITES (from /sdd.build FINAL VALIDATION):                  │
│    ✅ Step A: Platform compliance (backend OR mobile build)          │
│    ✅ Step B: Layer 3 Quality Gates (zero findings)                  │
│    ✅ Step C: Code Pattern Validation passed                         │
│    ✅ Step D: CI Pipeline (backend pipeline; gradlew/xcode mobile)   │
│                                                                      │
│  THIS COMMAND:                                                       │
│    → Validates platform compliance (backend or mobile)              │
│    → Validates test coverage ≥80%                                   │
│    → Re-scans for spec conflicts (v2.2.0)                           │
│    → Validates spec references                                       │
│    → Generates documentation                                         │
│    → Archives feature to sdd/features/                              │
│                                                                      │
│  NEXT STEPS (after completion):                                      │
│    📁 Feature archived → sdd/features/[name]/                       │
│    🆕 Start new feature → /sdd.start                               │
│    📋 Work on backlog → /sdd.backlog pick                            │
│    🔍 Review completed → /sdd.list                                 │
│                                                                      │
│  BLOCKING CONDITIONS:                                                │
│    ❌ Any FINAL VALIDATION step not passed in /sdd.build           │
│    ❌ Build/tests failing                                           │
│    ❌ Coverage <80%                                                  │
│    ❌ missing (backend/web only)                     │
│    ❌ Mobile build/test failing (Android/iOS only)                  │
│    ❌ Banned libs detected (Material, Coil, Hilt, etc.) for mobile  │
│    ❌ Unresolved spec conflicts (v2.2.0)                            │
│    ❌ Performance/Security Rules and Vulnerabilities/Code review not run or findings remain │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

---
