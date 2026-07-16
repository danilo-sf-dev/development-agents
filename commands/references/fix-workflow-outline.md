# Reference: Fix Workflow Outline (verbose)

**Used by**: `/sdd.fix` when needing the long workflow narrative.

## Workflow

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                      /sdd.fix WORKFLOW (v1.7.0)                             │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  -1. MULTI-ISSUE DETECTION ⭐ v1.7.0                                        │
│      └── Count how many distinct issues were passed                        │
│      └── IF N > 1: STOP inline processing, switch to SUBAGENT MODE        │
│      └── IF N = 1: run context guard (Skill "context-guardian")            │
│                    51-70%: warn; 71-89%: ask abort; ≥90%: BLOCK            │
│                                                                             │
│  0. DETECT CURRENT PHASE (MANDATORY) ⭐ v1.6.0                              │
│     └── Read meta.md to determine current phase                            │
│     └── Only layers that EXIST can be assessed/updated                     │
│     └── Scan for recurring fix patterns (fixes-log.md)                     │
│                                                                             │
│  1. RECEIVE ERROR                                                           │
│     └── User provides error output                                          │
│                                                                             │
│  1.5. CLASSIFY PROBLEM (MANDATORY)                                          │
│       └── Determine: FEATURE_GAP / DESIGN_FLAW / MISSING_TASK / IMPL_BUG   │
│       └── This determines which layers MUST be updated                      │
│       └── ⚠️ Only consider layers that EXIST at current phase              │
│                                                                             │
│  2. DEEP INVESTIGATION ⭐ v1.7.0                                            │
│     └── Generate ≥2 hypotheses for the root cause                         │
│     └── Gather evidence for each hypothesis (read/grep/run tests)          │
│     └── Eliminate hypotheses with evidence                                 │
│     └── State confirmed root cause with confidence %                       │
│                                                                             │
│  3. ASSESS IMPACT ACROSS LAYERS                                             │
│     ├── Does functional spec need update? (requirement was wrong?)          │
│     ├── Does technical spec need update? (API/data model incorrect?)        │
│     ├── Do tasks need update? (missing task? wrong task?)                   │
│     └── Does code need fix? (implementation bug?)                           │
│                                                                             │
│  3.5. ANTI-SHORTCUT VERIFICATION (MANDATORY)                                │
│       └── For each "No Change" declaration, provide EVIDENCE (quote)        │
│       └── No evidence = must update the layer                               │
│                                                                             │
│  4. PROPOSE CHANGES (ALL LAYERS)                                            │
│     └── Show what changes in each artifact                                  │
│                                                                             │
│  4.5. IMPLEMENTATION PLAN ⭐ v1.7.0                                         │
│       └── Ordered list of changes with dependencies                        │
│       └── Test checkpoints between steps                                   │
│       └── Rollback strategy per step                                       │
│                                                                             │
│  4.6. CREATE FIX RECORD DRAFT ⭐ v1.7.0                                     │
│       └── After full diagnosis (root cause + impact + plan)               │
│       └── Create FIX-NNN-DATE.md [IN_PROGRESS] with all conclusions       │
│       └── Append row to fixes-log.md — BEFORE first code change           │
│                                                                             │
│  4.7. SPECIFICATION TESTS (RED-GREEN + MUTATION) ⭐ v1.7.0                 │
│       └── Write tests from spec (NOT from implementation)                 │
│       └── Phase 2: run before fix → must FAIL (red proof)                 │
│       └── Phase 3: apply mutation → tests must catch it                   │
│       └── Phase 4 gate: GREEN/YELLOW/RED — recorded in Fix Record         │
│                                                                             │
│  5. APPLY FIX HORIZONTALLY                                                  │
│     └── Update all affected artifacts atomically                            │
│                                                                             │
│  6. RE-RUN TESTS                                                            │
│     └── Execute tests to confirm code fix works                             │
│                                                                             │
│  6.5. CODE REVIEW (MANDATORY)                                               │
│       └── Call code review tool, fix ALL findings (including minor)        │
│                                                                             │
│  7. BIDIRECTIONAL CONSISTENCY CHECK (MANDATORY)                             │
│     └── Verify in BOTH directions:                                          │
│         ├── Direction 1: Specs → Code (is everything implemented?)          │
│         └── Direction 2: Code → Specs (is everything documented?)           │
│                                                                             │
│  8. FINALIZE FIX RECORD ⭐ v1.7.0                                           │
│     └── Update FIX-NNN-DATE.md: add result, layers, tests → RESOLVED      │
│     └── Update fixes-log.md row: IN_PROGRESS → RESOLVED                   │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

**New in v1.5.0**: Steps 1.5, 3.5, and bidirectional Step 7 address the observed issue where agents fix code without updating specs.

---
