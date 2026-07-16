# Reference: Fix Deep Investigation

**Used by**: `/sdd.fix` Step 2.

### Step 2: Deep Investigation ⭐ v1.7.0

> **CRITICAL**: Hypothesis-driven investigation. Never jump to a single conclusion — always generate alternatives and eliminate with evidence.

> After Steps 2.1–2.3, continue through Steps 3–4.5 (full diagnosis). The fix record draft is created at **Step 4.6** — after all analysis, before the first code change.

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔬 DEEP INVESTIGATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

**Error Type**: [Runtime/Compilation/Test/Integration]
**Location**: [File:Line if available]
**Symptoms**: [Observable behavior vs expected behavior]
```

#### Step 2.1: Generate Hypotheses

Generate at least **2 alternative hypotheses** before reading any code:

```markdown
### Hypotheses

| # | Hypothesis | What to Look For | Confidence (initial) |
|---|------------|-----------------|----------------------|
| H1 | [Possible cause A] | [File/function/pattern to check] | [Low/Medium/High] |
| H2 | [Alternative cause B] | [File/function/pattern to check] | [Low/Medium/High] |
| H3 | [Another alternative] | [File/function/pattern to check] | [Low/Medium/High] |
```

**Minimum 2 hypotheses required.** If you can only think of one, force yourself to ask:
- "What else could produce this symptom?"
- "Could this be a data problem instead of a logic problem?"
- "Could this be a timing/order problem?"

#### Step 2.2: Gather Evidence Per Hypothesis

For each hypothesis, actively read/grep/run to find evidence:

```markdown
### Evidence Gathering

**H1 — [Hypothesis A]**
- Read: [file path] → [what I found / what I expected to find]
- Grep: [pattern] → [result]
- Conclusion: [supports / eliminates H1]

**H2 — [Hypothesis B]**
- Read: [file path] → [what I found]
- Conclusion: [supports / eliminates H2]
```

#### Step 2.3: Eliminate and Confirm

```markdown
### Elimination

| Hypothesis | Status | Evidence |
|------------|--------|---------|
| H1 | ❌ ELIMINATED | "[Quote from code/log that rules it out]" |
| H2 | ✅ CONFIRMED | "[Quote from code/log that proves it]" |

### Root Cause Statement

**Root Cause**: [Precise statement of what is broken]
**Confidence**: [%]
**Evidence Chain**: [H2 confirmed because X, which causes Y, which produces the observed error Z]
```

#### Root Cause Category (after investigation)

| Category | Description | Layers Affected |
|----------|-------------|-----------------|
| **Requirement Gap** | Spec didn't account for this case | Functional → Technical → Tasks → Code |
| **Design Flaw** | Technical approach was wrong | Technical → Tasks → Code |
| **Missing Task** | Work wasn't planned | Tasks → Code |
| **Implementation Bug** | Code error only | Code only |

---
