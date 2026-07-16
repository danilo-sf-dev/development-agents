# Reference: Fix Multi-Issue Detection

**Used by**: `/sdd.fix` Step -1.

### Step -1: Multi-Issue Detection ⭐ v1.7.0

> **CRITICAL**: This step runs BEFORE anything else. It is the architectural guard that prevents context exhaustion.

#### Why This Exists

When an agent processes multiple fixes inline, context fills after fix #2–3. Subsequent fixes get progressively less investigation depth — hypothesis generation stops, evidence quotes are skipped, fix records aren't created. The result is **superficial fixes that mask the real issue**.

The fix: each issue MUST run in a fresh context via a subagent.

#### Execution

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🛡️ MULTI-ISSUE DETECTION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Count how many distinct issues/fixes are in the input:

IF N > 1:
  ⛔ STOP. Do NOT process any fix inline.
  ⛔ Do NOT use TodoWrite to list issues and process them sequentially in this session.
  ⛔ Do NOT start investigating Issue 1 in this context.

  The ONLY correct action is:

    for each issue in issues (sequentially, one at a time):
      Task(
        subagent_type="general-purpose",
        description="Fix: [short name]",
        prompt="Working dir: {DIR}\nInvoke Skill('sdd.fix') for this single issue:\n{ISSUE_DESCRIPTION}\nReport: classification, root cause, layers, fix record path, status."
      )
      → wait for Task result before spawning next

  After all Tasks complete → show consolidated batch summary.

  ❌ WRONG: TodoWrite with N items + process each inline in this session
  ✅ CORRECT: N × Task() calls, one per fix, each subagent gets fresh context
  → Full template: see `references/fix-batch.md`

IF N = 1:
  Check context: Skill("context-guardian")
  → IF context 51–70%: warn user: "Context at X%. Investigation may be limited. Consider a fresh session for complex bugs." Proceed.
  → IF context 71–89%: warn user: "Context at X% — deep investigation WILL be compromised." Ask to abort or continue with reduced depth.
  → IF context ≥ 90%: BLOCK, refuse to proceed: "Context exhausted. Start a new session."
  → IF context ≤ 50%: continue to Step 0
```

#### What Counts as "Multiple Issues"?

| Input Pattern | Count |
|---------------|-------|
| `"Fix X"` (single string) | 1 issue |
| `"Fix X" / "Fix Y"` (two separate descriptions) | 2 issues |
| A numbered list: `1. Fix X\n2. Fix Y\n3. Fix Z` | 3 issues |
| Multiple `/sdd.fix` calls in one message | N calls = N issues |
| `--batch` flag | Triggers subagent mode immediately |

> **Rule**: When in doubt, treat as multiple issues and use subagent mode. A single subagent for one issue costs nothing extra; inline processing of many issues costs quality.

---
