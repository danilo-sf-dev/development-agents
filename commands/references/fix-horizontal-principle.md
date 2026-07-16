# Reference: Horizontal Consistency Principle

**Used by**: `/sdd.fix` terminology / phase-aware details.

## Core Principle: Horizontal Consistency

Fix the **cause across layers** (functional ↔ technical ↔ tasks ↔ code). Never leave specs lying after a code-only patch.

**CRITICAL**: `/sdd.fix` is NOT just a code fix. It ensures the ENTIRE solution remains consistent:

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                     HORIZONTAL FIX PROPAGATION                               │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  Error Found ──► Analyze Impact ──► Update ALL Affected Layers             │
│                                                                             │
│  ┌─────────────┐   ┌─────────────┐   ┌─────────────┐   ┌─────────────┐    │
│  │ FUNCTIONAL  │   │  TECHNICAL  │   │    TASKS    │   │    CODE     │    │
│  │    SPEC     │◄──│    SPEC     │◄──│             │◄──│             │    │
│  └─────────────┘   └─────────────┘   └─────────────┘   └─────────────┘    │
│        │                 │                 │                 │             │
│        ▼                 ▼                 ▼                 ▼             │
│  [Update if      [Update API       [Update task      [Fix code]           │
│   requirement     contracts,        descriptions,                          │
│   was wrong]      data model]       add new tasks]                        │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### ⚠️ Phase-Aware Constraint (v1.6.0)

> **IMPORTANT**: You can only fix layers that EXIST at the current phase. See [Step 0: Detect Current Phase](#step-0-detect-current-phase-mandatory--v160) for the full reference table.

### Terminology: Horizontal vs Bidirectional

| Term | What It Means | When It Applies |
|------|---------------|-----------------|
| **Horizontal Consistency** | All layers tell the same story | During fix propagation (Step 5) |
| **Horizontal Fix Propagation** | Update ALL affected layers atomically | When applying fixes |
| **Bidirectional Consistency** | Verify in BOTH directions | During verification (Step 7) |

**Horizontal = Propagation** (Action)
- "I changed code, so I update specs+tasks too"
- Direction: Code → Tasks → Technical → Functional (backwards propagation)
- Goal: Ensure all layers reflect the fix

**Bidirectional = Verification** (Check)
- "Does Spec→Code match AND does Code→Spec match?"
- Direction 1: Specs → Code (is everything implemented?)
- Direction 2: Code → Specs (is everything documented?)
- Goal: Catch any drift in either direction

---
