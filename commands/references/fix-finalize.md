# Reference: Fix Finalize Record

**Used by**: `/sdd.fix` Step 8.

## Step 8: Finalize Fix Record ⭐ v1.7.0

> **MANDATORY**: After every successful fix, finalize the draft record created at Step 4.6. Update status from IN_PROGRESS → RESOLVED and fill in the result sections.
>
> **If Step 4.6 was skipped** (e.g. first run with this version of the skill): create the full record now using the template below.

### Directory Structure

```
sdd/fixes/                         ← default for brownfield / multi-feature
  fixes-log.md
  FIX-001-2026-04-03.md
  FIX-002-2026-04-10.md
  ...

sdd/wip/{feature}/fixes/           ← optional: feature-scoped fixes
  fixes-log.md
  FIX-001-2026-04-03.md
  ...
```

### Fix ID Generation

Format: `FIX-NNN` where NNN = count of existing entries in `fixes-log.md` + 1.
If `fixes-log.md` doesn't exist, start at `FIX-001`.

### FIX-NNN-DATE.md Template

```markdown
# FIX-NNN — YYYY-MM-DD

## Error Reported
[Paste or summarize the original error input from the user]

## Investigation

### Hypotheses
| # | Hypothesis | Status | Evidence |
|---|------------|--------|---------|
| H1 | [cause A] | ❌ Eliminated | "[quote]" |
| H2 | [cause B] | ✅ Confirmed | "[quote]" |

### Root Cause
[Precise statement] — Confidence: [%]

**Evidence Chain**: [H2 confirmed because X, which causes Y, which produced error Z]

## Classification
[FEATURE_GAP / DESIGN_FLAW / MISSING_TASK / IMPLEMENTATION_BUG]

## Implementation Plan Executed
[1] [SPEC/TASK/CODE] [Description]
[2] ...

## Layers Changed
- **Functional Spec**: [No change / Updated — what changed]
- **Technical Spec**: [No change / Updated — what changed]
- **Tasks**: [No change / TASK-XXX added/modified]
- **Code**: [Files modified/created]

## Result
- Tests: [N passed / N failed]
- Code review: [0 findings / N fixed]
- Consistency check: [APPROVED / CAN_PROCEED_WITH_WARNINGS]
- Status: RESOLVED
```

### fixes-log.md Template (append-only)

```markdown
# Fixes Log — {feature or "project"}

| ID | Date | Classification | Root Cause (summary) | Layers | Status |
|----|------|----------------|---------------------|--------|--------|
| FIX-001 | 2026-04-03 | DESIGN_FLAW | Missing email validation | Tech+Tasks+Code | RESOLVED |
```

### Agent Instructions for Step 8

```
After Step 7 passes (APPROVED or CAN_PROCEED_WITH_WARNINGS):

IF Step 4.6 was executed (draft exists):
  1. Open FIX-NNN-DATE.md created at Step 4.6
  2. Replace "[IN_PROGRESS]" in title with "[RESOLVED]"
  3. Fill in "## Layers Changed" and "## Result" sections
  4. Update "## Status: IN_PROGRESS" → "## Status: RESOLVED"
  5. Update fixes-log.md row: change "IN_PROGRESS" → "RESOLVED", fill Layers column

IF Step 4.6 was NOT executed (no draft — recover):
  1. Determine target path using this decision tree:

   CASE A — All modified files belong to ONE active wip feature:
     - Find sdd/wip/*/meta.md where status IN (in-progress, implemented)
     - Check each feature's tasks.json "files" list
     - If ALL modified files match one feature: Path = sdd/wip/{feature}/fixes/

   CASE B — Default fallback (use in ALL other cases):
     - Fix touches files from multiple features
     - Fix is a side-effect in unrelated code
     - Fix is brownfield (no active feature)
     - Uncertain which feature owns the fix
     - Path: sdd/fixes/  ← SAFE DEFAULT, always valid
     - Add field "Feature: (none)" or "Feature: cross-feature side-effect"

   > **Rule of thumb**: When in doubt, use sdd/fixes/. It's always correct.
   > Feature-scoped fixes/ are an optimization for traceability, not a requirement.

2. Determine fix ID:
   - If fixes-log.md exists at target path: count data rows, next ID = count + 1
   - If not: ID = 001
   - Format: FIX-001, FIX-002, ...

3. Create FIX-NNN-YYYY-MM-DD.md at target path using the template above
   - Fill all sections from the current session's analysis
   - CASE B records: add field "Feature: (none — brownfield fix)"

4. Append row to fixes-log.md at target path (create if not exists)

5. Confirm:
   ✅ Fix record created: {target_path}/FIX-NNN-DATE.md
   ✅ History updated: {target_path}/fixes-log.md
```

### When Step 8 is NOT Required

Skip Step 8 **only** when the fix was applied via `--dry-run` (nothing was actually changed).

**All other fixes — including IMPLEMENTATION_BUG — MUST produce a fix record.** Even a one-line typo fix should have a minimal record. History must be complete.

> **Why no exception for IMPLEMENTATION_BUG?** Recurring "trivial" bugs in the same file often signal a deeper design issue. The fix log makes this pattern visible over time.

---
