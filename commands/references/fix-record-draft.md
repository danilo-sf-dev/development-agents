# Reference: Fix Record Draft

**Used by**: `/sdd.fix` Step 4.6.

### Step 4.6: Create Fix Record Draft ⭐ v1.7.0

> **MANDATORY — execute this BEFORE Step 5 (before the first Edit/Write to any code or spec file).**
>
> **Why here (after 4.5, not after 2)?** The draft captures the FULL diagnosis: root cause + impact assessment + implementation plan. If context exhausts mid-implementation, you have a complete record of what was found and what was planned — enough to resume or escalate.

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📝 CREATING FIX RECORD DRAFT (pre-implementation)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. Determine target path:
   CASE A: sdd/wip/{feature}/fixes/   (if all modified files belong to one active feature)
   CASE B: sdd/fixes/                 (default — brownfield, multi-feature, uncertain)

   Rule: When in doubt, use sdd/fixes/. It is always correct.

2. Determine fix ID:
   - Read fixes-log.md → count data rows → ID = count + 1
   - If no fixes-log.md: ID = 001
   - Format: FIX-001, FIX-002, ...

3. Ensure target directory exists (create if needed):
   ```bash
   mkdir -p {target_path}
   ```

4. Create FIX-NNN-YYYY-MM-DD.md at target path:

# FIX-NNN — YYYY-MM-DD [IN_PROGRESS]

## Error Reported
[Original error input from user]

## Investigation

### Hypotheses
| # | Hypothesis | Status | Evidence |
|---|------------|--------|---------|
| H1 | [cause A] | ❌ Eliminated | "[quote from code/log]" |
| H2 | [cause B] | ✅ Confirmed | "[quote from code/log]" |

### Root Cause
[Precise statement] — Confidence: [%]
**Evidence Chain**: [H2 confirmed because X → causes Y → produces error Z]

## Classification
[FEATURE_GAP / DESIGN_FLAW / MISSING_TASK / IMPLEMENTATION_BUG]

## Impact Assessment
- **Functional Spec**: [No change / Update required — reason]
- **Technical Spec**: [No change / Update required — reason]
- **Tasks**: [No change / Task NNN added/modified]
- **Code**: [Files to be modified]

## Implementation Plan
[1] [SPEC/TASK/CODE] [Description] — no dependencies
[2] [SPEC/TASK/CODE] [Description] — depends on [1]
...
Test checkpoints: [after step N: run X]
Risk level: [Low / Medium / High]

## Status: IN_PROGRESS
_Implementation not yet started. This file will be updated when complete._

5. Append row to fixes-log.md (create if not exists):
   | FIX-NNN | YYYY-MM-DD | [Classification] | [Root cause summary] | - | IN_PROGRESS |

✅ Draft created: {path}/FIX-NNN-DATE.md
✅ Log updated: {path}/fixes-log.md

→ NOW proceed to Step 4.7 (spec-based tests — BEFORE any code change)
```

> **If the fix is interrupted** (context exhausts, crash, user cancels): the draft remains as complete evidence. Next session reads it and continues from the planned Step N.

---
