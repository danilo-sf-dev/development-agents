# Reference: Impact Assessment Templates & Workflow Safeguards

**Used by**: `/sdd.fix` — impact assessment / Plan Mode step, for complex bugs (`DESIGN_FLAW`, `FEATURE_GAP`, multi-file, or repeated-attempt cases).

The Plan Mode flow and post-plan safeguards already live inline in `sdd.fix.md`. This file provides the **concrete template** to fill in during the "Present plan to user" step, plus a couple of extra safeguards not spelled out inline.

---

## Impact Assessment Template

```markdown
## Impact Assessment — FIX-NNN

**Classification**: [FEATURE_GAP / DESIGN_FLAW / MISSING_TASK / IMPLEMENTATION_BUG]
**Complexity trigger**: [multi-component | repeated attempts | systemic symptom]

### Affected Components
| File/Module | Why it's involved |
|---|---|
| | |

### Evidence Collected
- Logs / stack traces:
- Failing test(s):
- Reproduction steps:

### Hypotheses (priority order)
1. **[Most likely]** — how to validate: [test/log to check]
2. **[Next]** — how to validate:
3. **[Least likely]** — how to validate:

### Investigation Strategy
- Order in which hypotheses will be tested:
- Read-only exploration needed before touching any code:
- Decision point: inline fix vs delegate to `sdd-debugger` (if hypothesis 1-2 fail)

### Blast Radius (if fix applied)
- Layers affected: [Functional / Technical / Tasks / Code — mark N/A for phases that don't exist yet]
- Breaking change risk: [Yes/No — if Yes, what breaks and who's affected]
- Rollback plan if the fix causes regressions:

### Approval
- [ ] User approved this investigation strategy before Step 2 (Root Cause) begins
```

## Additional Safeguards

### Safeguard: Repeated-Attempt Circuit Breaker
If this is the **3rd or later** attempt at fixing the same symptom:
1. STOP — do not try a 3rd variation of the same approach
2. Re-run Step 1.5 classification from scratch, assuming the previous classification might have been wrong
3. Explicitly ask the user whether to escalate (e.g. pair on it, bring in `sdd-debugger`, or accept a workaround instead of a full fix)

### Safeguard: Cross-Feature Impact
If the affected component is shared by other features (check `sdd/features/*/meta.md` for references to the same file/module):
1. List which other features might be affected by this fix
2. If any of those features are still in `sdd/wip/` (in progress), flag the conflict to the user before applying the fix — the fix might invalidate work already done elsewhere
