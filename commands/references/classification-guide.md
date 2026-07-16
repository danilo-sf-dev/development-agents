# Reference: Classification Guide (Extended)

**Used by**: `/sdd.fix` Step 1.5 (Problem Classification) and Subagent Delegation.

The core decision trees (classification: FEATURE_GAP / DESIGN_FLAW / MISSING_TASK / IMPLEMENTATION_BUG, and subagent delegation) already live inline in `sdd.fix.md`. This file is the **extended edge-case catalog** — read it when the inline tree leaves you uncertain.

---

## Classification Edge Cases

| Problem Description | Classification | Why |
|---|---|---|
| "Endpoint works but response shape doesn't match the documented contract" | **DESIGN_FLAW** | The contract itself needs correcting, not just the code — spec drift |
| "Feature works for the happy path but the spec never mentioned concurrent access" | **FEATURE_GAP** | Spec silently assumed something that isn't true in production |
| "Task said 'add validation' but didn't specify which fields — dev validated the wrong ones" | **MISSING_TASK** | The task itself was underspecified, not wrong code against a clear task |
| "Off-by-one error in a loop" | **IMPLEMENTATION_BUG** | Pure code defect, spec and task were both correct |
| "Retry logic exists but doesn't have backoff, causing thundering herd" | **DESIGN_FLAW** | Whether to backoff is an architectural decision, not a typo |
| "Field is nullable in DB but code assumes non-null" | Depends — **IMPLEMENTATION_BUG** if spec says it's always populated and code just forgot a null check; **DESIGN_FLAW** if the spec never addressed the null case at all |
| "User reports slowness under load" | **DESIGN_FLAW** (if root cause is architectural, e.g. N+1 queries) or **IMPLEMENTATION_BUG** (if it's a single inefficient loop) — investigate root cause before classifying |
| "Third-party API changed and broke integration" | **IMPLEMENTATION_BUG** if a simple adapter update fixes it; **DESIGN_FLAW** if the whole integration needs restructuring to be resilient to this class of change |

## Disambiguation Rules

1. **When torn between FEATURE_GAP and DESIGN_FLAW**: ask "did the user ask for this behavior at all?" If no → FEATURE_GAP (the spec is incomplete). If yes but the approach chosen is wrong → DESIGN_FLAW.
2. **When torn between DESIGN_FLAW and IMPLEMENTATION_BUG**: ask "would a different, equally-valid implementation of the *same* design still have this problem?" If yes → DESIGN_FLAW (the design itself is at fault). If no → IMPLEMENTATION_BUG (just this implementation got it wrong).
3. **When torn between MISSING_TASK and IMPLEMENTATION_BUG**: check whether the task list explicitly called for the missing behavior. If it's not mentioned anywhere in tasks.json → MISSING_TASK. If it was in tasks.json and just not implemented correctly → IMPLEMENTATION_BUG.
4. **Never classify as IMPLEMENTATION_BUG if the fix requires adding new behavior** the spec/tasks never described — that's always at least FEATURE_GAP.

## Multi-Classification Problems

Some bugs are actually two problems bundled together (e.g. a `DESIGN_FLAW` that was then patched with an `IMPLEMENTATION_BUG` on top). When this happens:
- Split into separate FIX-NNN records, one per classification
- Fix the `DESIGN_FLAW` first — the `IMPLEMENTATION_BUG` fix may become moot or need rework once the design changes
- Cross-reference the two fix records in the fix log

## Confidence Check Before Finalizing

Before writing the classification into the fix record, verify:
- [ ] Can you point to the exact line/section in the spec, task, or code where this classification is grounded?
- [ ] Would a second reviewer with the same evidence reach the same classification?
- [ ] Have you checked whether this is a recurrence (same root cause, different symptom) of a previous fix in the fix log?
