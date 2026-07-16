# Reference: Fix Phase Detection

**Used by**: `/sdd.fix` Step 0.

### Step 0: Detect Current Phase (MANDATORY) ⭐ v1.6.0

> **CRITICAL**: Before analyzing any error, you MUST determine the current phase to know which layers EXIST.

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 PHASE DETECTION + PATTERN SCAN
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Reading meta.md to determine current phase...

Current Phase: [functional / technical / tasks / implementation]
```

After detecting the phase, **scan for recurring fix patterns** ⭐ v1.7.0:

```
IF fixes-log.md exists (at sdd/wip/{feature}/fixes/ OR sdd/fixes/):

  1. Count fixes per file in the last 30 days:
     - grep "Files" in all FIX-*.md files
     - group by filename, count occurrences

  2. IF any file has ≥3 fixes in 30 days:
     ⚠️  RECURRING FIX WARNING
     ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
     File [X] has been fixed N times in the last 30 days.
     This may indicate a structural design issue.
     Consider adding a DEBT item to sdd/backlog.md after this fix.
     ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  3. IF the same root cause pattern appears ≥2 times:
     (compare "Root Cause (summary)" column in fixes-log.md)
     ⚠️  SAME ROOT CAUSE SEEN BEFORE
     Last occurrence: FIX-NNN (DATE) — [summary]
     This fix may not address the underlying issue.
```

#### Layers Available by Phase

| Current Phase | Functional Spec | Technical Spec | Tasks | Code |
|---------------|-----------------|----------------|-------|------|
| **functional** | ✅ EXISTS | ❌ NOT YET | ❌ NOT YET | ❌ NOT YET |
| **technical** | ✅ EXISTS | ✅ EXISTS | ❌ NOT YET | ❌ NOT YET |
| **tasks** | ✅ EXISTS | ✅ EXISTS | ✅ EXISTS | ❌ NOT YET |
| **implementation** | ✅ EXISTS | ✅ EXISTS | ✅ EXISTS | ✅ EXISTS |

#### Phase-Aware Assessment Rules

**IF current phase = functional**:
- Only assess: Functional Spec
- DO NOT mention: Technical Spec, Tasks, Code (they don't exist yet)
- Fix can only update functional spec

**IF current phase = technical**:
- Only assess: Functional Spec, Technical Spec
- DO NOT mention: Tasks, Code (they don't exist yet)
- Fix can update functional and/or technical specs

**IF current phase = tasks**:
- Only assess: Functional Spec, Technical Spec, Tasks
- DO NOT mention: Code (it doesn't exist yet)
- Fix can update specs and/or tasks

**IF current phase = implementation**:
- Assess ALL layers: Functional, Technical, Tasks, Code
- Full horizontal fix propagation available

> **WARNING**: Suggesting updates to layers that don't exist yet is INCORRECT and confusing to users.

---
