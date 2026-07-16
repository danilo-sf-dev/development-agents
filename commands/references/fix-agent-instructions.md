# Reference: Fix AI Agent Instructions (full)

**Used by**: `/sdd.fix` extended enforcement rules.

## AI Agent Instructions

> **CRITICAL**: Read [AI_AGENT_GUIDELINES.md](../AI_AGENT_GUIDELINES.md) before executing.

### Help Flag Detection

**WHEN** the user runs `/sdd.fix help`:
1. Output ONLY the "Quick Help" section (not full documentation)
2. Do NOT execute fix logic
3. Keep response concise (~15 lines)

> **Lazy-loaded**: When `--batch` is present (or Step -1 detects N > 1), Read `references/fix-batch.md`.

### Key Rules

1. **DETECT PHASE FIRST** ⭐ v1.6.0 - Run Step 0 to know which layers EXIST before any assessment
2. **ONLY ASSESS EXISTING LAYERS** - NEVER suggest updating Tasks/Code if phase < tasks/implementation
3. **Think horizontally** - Every fix must consider impact on ALL **existing** layers
4. **Trace to root cause** - Don't just patch symptoms, fix the source
5. **Update specs FIRST** - Specs are the source of truth
6. **Maintain consistency** - All artifacts must tell the same story
7. **Document the gap** - Explain what was missing and why
8. **MANDATORY CODE REVIEW** - After applying code fixes, call code review tool and fix ALL findings

9. **CLASSIFY BEFORE FIXING** - Always run Step 1.5 (Problem Classification) first
10. **NEVER SHORTCUT "No Change"** - Always provide evidence when declaring No Change
11. **VERIFY BIDIRECTIONALLY** - Check both specs→code AND code→specs (only for existing layers)
12. **INVESTIGATE WITH HYPOTHESES** ⭐ v1.7.0 - Generate ≥2 hypotheses and eliminate with evidence before concluding
13. **PLAN BEFORE APPLYING** ⭐ v1.7.0 - Define ordered implementation steps (Step 4.5) before touching any file
14. **PERSIST FIX RECORD EARLY** ⭐ v1.7.0 - Create FIX-NNN.md DRAFT at Step 4.6 (before any code). Finalize at Step 8. Even if fix is interrupted, the investigation record must exist.
15. **ONE ISSUE PER CONTEXT** ⭐ v1.7.0 - If N>1 issues, ALWAYS spawn subagents (one per fix). NEVER process multiple fixes inline. Context exhaustion = shallow analysis.

> **Telemetry**: Captured automatically by hooks - no manual logging required.

---

### Enforcement Rules (v1.5.0)

> These rules prevent the common failure pattern of fixing code without updating specs.

#### Rule 1: Classification BEFORE Analysis

```
WRONG:
  1. Read error → 2. Fix code → 3. Check if specs need update

CORRECT:
  1. Read error → 2. CLASSIFY problem type → 3. Determine required layers → 4. Update ALL required layers
```

#### Rule 2: Evidence-Based "No Change" Only

```
WRONG:
  Status: No Change (already documented)

CORRECT:
  Status: No Change
  Evidence: Section "API Contracts" line 145 states:
  > "POST /users validates email format and returns 400 INVALID_EMAIL"
  This covers the validation we're fixing.
```

#### Rule 3: Code Changes Trigger Spec Review

If you modify code to add ANY of these, specs MUST be updated:

| Code Change | Spec Update Required |
|-------------|---------------------|
| New function/method with business logic | Technical Spec + Tasks |
| New API parameter or response field | Technical Spec + Tasks |
| New error type or validation | Technical Spec + Tasks |
| New external tool/service call | Technical Spec + Tasks |
| New user-visible output or behavior | Functional Spec + Technical Spec + Tasks |
| New configuration option | Technical Spec + Tasks |

#### Rule 4: Post-Fix Verification is NOT Optional

```
WRONG:
  ✅ Code fixed, tests pass, done!

CORRECT:
  ✅ Code fixed
  ✅ Tests pass
  ✅ Code review: 0 findings
  ✅ Bidirectional consistency check:
     - Code→Specs: All new behaviors documented
     - Specs→Code: All spec requirements implemented
```

---

### Analysis Strategy

Use the classification decision tree from **Step 1.5** above, then:
1. Classify problem type
2. Determine required layers based on classification
3. For each layer: provide evidence quote (no change) or show diff (updating)
4. Verify bidirectionally: list NEW behaviors, verify each is documented

---

### Common Failure Patterns to Avoid

#### Pattern 1: "It Works So Specs Are Fine"

**WRONG**: "Tests pass, so functional spec is correct"
**WHY WRONG**: The fix may have added behavior not in specs
**CORRECT**: "Tests pass. Now verifying: does the new behavior exist in specs?"

#### Pattern 2: "Only Code Changed"

**WRONG**: Classify as IMPLEMENTATION_BUG when adding new logging/validation/behavior
**WHY WRONG**: New behavior = new specs needed, regardless of how "minor"
**CORRECT**: If fix adds ANY new capability, it's at least MISSING_TASK, not IMPLEMENTATION_BUG

#### Pattern 3: "Specs Are Vague Enough"

**WRONG**: "Spec says 'handle errors' so my new error type is covered"
**WHY WRONG**: Vague specs don't document specific behaviors
**CORRECT**: If you add a specific error type, add it to technical spec

#### Pattern 4: "I'll Update Specs Later"

**WRONG**: Fix code now, update specs in another pass
**WHY WRONG**: Specs and code drift apart, causing future confusion
**CORRECT**: Update specs IN THE SAME /sdd.fix execution, atomically

#### Pattern 5: "I'll Process Multiple Fixes Inline" ⭐ v1.7.0

**WRONG**: Receive 7 fixes → process all 7 in the same agent session
**WHY WRONG**: After fix #2–3, context is >70%. The agent can still write code, but:
- Hypothesis generation is skipped or reduced to 1
- Evidence quotes are omitted
- Fix records (Step 8) are never created (last steps dropped)
- The result LOOKS like a fix but misses root cause

**CORRECT**: Detect N>1 issues at Step -1 → spawn N subagents → each fix gets fresh context
**EVIDENCE**: Monitoring shows code files modified but zero FIX-*.md records created after a 7-fix batch session (verified 2026-04-03)

---

### Pre-Fix Checklist

Before declaring fix complete:
- [ ] Problem classified (Step 1.5)
- [ ] All required layers identified
- [ ] ≥2 hypotheses generated and eliminated with evidence (Step 2)
- [ ] Implementation plan created with ordered steps (Step 4.5)
- [ ] **Fix record DRAFT created BEFORE any code change** (Step 4.6) ⭐ v1.7.0
- [ ] For each "No Change": Evidence quote provided
- [ ] For each update: Diff shown and applied
- [ ] Code review: 0 findings
- [ ] Bidirectional consistency verified
- [ ] **Fix record finalized** (Step 8) — `FIX-NNN-DATE.md` RESOLVED + `fixes-log.md` updated ⭐ v1.7.0

---
