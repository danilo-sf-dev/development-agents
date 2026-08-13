# Reference: Fix Subagent Delegation

**Used by**: `/sdd.fix` when delegating investigation/fixes.

## Subagent Delegation

> **💡 RECOMMENDED**: See [warning-hierarchy.md](../framework/standards/warning-hierarchy.md#subagent-delegation-central-principle) for the central principle.
> For complex bugs, delegate analysis to specialized subagents.

> **Lazy-loaded**: During problem classification/delegation, Read `references/classification-guide.md` for decision trees and classification rules.

### Decision Tree: When to Delegate

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    SHOULD I DELEGATE TO A SUBAGENT?                          │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  Q1: Is the bug OBVIOUS (typo, missing import, clear logic error)?          │
│      │                                                                       │
│      ├── YES ──► Fix directly (no subagent needed)                          │
│      │                                                                       │
│      └── NO ──► Q2: Is this about SPEC/CODE INCONSISTENCY?                  │
│                     (e.g., code does X but spec says Y)                      │
│                     │                                                        │
│                     ├── YES ──► Use sdd-layer-analysis                      │
│                     │           Purpose: Detect drift, align layers          │
│                     │                                                        │
│                     └── NO ──► Q3: Is this a DEEP TECHNICAL BUG?            │
│                                    (race condition, memory leak, perf)       │
│                                    │                                         │
│                                    ├── YES ──► Use sdd-debugger             │
│                                    │           Purpose: Deep root cause      │
│                                    │                                         │
│                                    └── NO ──► Fix with /sdd.fix directly   │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Subagent Reference

| Subagent               | When to Use                | Example Error                            |
| ---------------------- | -------------------------- | ---------------------------------------- |
| **sdd-debugger**       | Race conditions, deadlocks | "Request hangs intermittently"           |
| **sdd-debugger**       | Memory leaks               | "OOM after running for 2 hours"          |
| **sdd-debugger**       | Performance regressions    | "API now takes 10s instead of 100ms"     |
| **sdd-debugger**       | Subtle logic errors        | "Wrong result only for edge case X"      |
| **sdd-layer-analysis** | Spec/code mismatch         | "Code returns 400 but spec says 422"     |
| **sdd-layer-analysis** | Undocumented features      | "This API parameter isn't in specs"      |
| **sdd-layer-analysis** | Missing tasks              | "This code exists but no task covers it" |

### Invocation

`DELEGATE_OFFLOAD` (context-saving delegation to a specialist agent — no bias-protection/isolation
requirement here, unlike the Validator Independence Protocol; see
`framework/_shared/harness-capabilities.md`):

```
Task(subagent_type="general-purpose", prompt="Follow skills/sdd-debugger/SKILL.md — Analyze: [error details]", model=resolve-model.sh claude-code STRONG)
Task(subagent_type="general-purpose", prompt="Follow skills/sdd-layer-analysis/SKILL.md — Check: [feature name]", model=resolve-model.sh claude-code EXECUTION)
```

There is no registered `sdd-debugger`/`sdd-layer-analysis` subagent type — both are Skills, dispatched
via a `general-purpose` worker given the Skill's content as its task (see
`docs/adr/0001-agent-skill-execution-architecture.md`).

---
