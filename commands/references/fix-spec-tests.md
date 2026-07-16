# Reference: Fix Specification Tests

**Used by**: `/sdd.fix` Step 4.7.

### Step 4.7: Specification Tests (Red-Green + Mutation Validation)

> **MANDATORY before Step 5** — unless the applicability gate below marks it as N/A.

#### Applicability Gate

```
IF fix_classification == "MISSING_TASK" (tasks.json only, no code change):
    → SKIP Step 4.7. Document in Fix Record: "N/A — task-only fix, no executable tests"
    → Continue to Step 5.

IF current phase != "implementation" (e.g., spec-only fix, no runnable code yet):
    → SKIP Step 4.7. Document in Fix Record: "N/A — pre-implementation phase"
    → Continue to Step 5.

IF no test runner available locally (missing env, Docker required, infra unavailable):
    → SKIP phases 2–3. Document reason in Fix Record under "Specification Tests".
    → Write spec-based tests (Phase 1) and note: "Red phase deferred — run in CI"
    → Continue to Step 5 with YELLOW gate status.

OTHERWISE: proceed through all 4 phases below.
```

The existing test suite is often biased — tests were written to pass the current (buggy) implementation, so they encode the bug, not the spec. This step breaks that cycle by writing tests against the **spec** first, verifying they fail against the current code, then validating their sensitivity via targeted mutation.

#### Phase 1 — Write Spec-Based Tests

Write new tests based on the **confirmed root cause** and the **spec** (functional/technical). These tests encode what SHOULD happen, not what currently happens.

Rules for spec-based tests:
- Derived from the spec, NOT from reading the current implementation
- At minimum: 1 test for the correct behavior (happy path per spec), 1 test that directly triggers the bug scenario
- Do NOT look at the existing test file while writing — read the spec section that the bug violates
- Place in the same test file, clearly marked: `// SPEC-TEST: FIX-NNN`

#### Phase 2 — Red Validation (run BEFORE fix)

Run ONLY the new spec-based tests against the current (unmodified) code:

```
IF tests FAIL (red):
  ✅ Tests are real and non-biased → proceed to Phase 3

IF tests PASS (green):
  🚨 ALERT: tests do not catch the bug
  Options:
    A) Hypothesis was wrong → return to Step 2
    B) Tests are still biased → rewrite and retry Phase 2
    C) Acknowledge with justification → document in Fix Record and proceed (exceptional)
```

> **The red phase is a proof**: a test that passes before the fix is not testing the fix. Never skip it.

#### Phase 3 — Mutation Validation (targeted)

Validate that the new tests are **sensitive** to the specific code path being fixed. Apply a **targeted mutation** — a deliberate wrong change to the root cause location (different from the fix, but in the same code area):

```
1. Identify exact root cause location (from Step 2):
   e.g., src/validators/input.go:142

2. Apply a targeted mutation (do NOT apply the fix):
   Bug:      missing nil check → code panics on nil
   Mutation: add a check that always returns early (hides the problem differently)
   —— OR ——
   Bug:      wrong operator `>` instead of `>=`
   Mutation: change to `<` (opposite wrong, not the fix)

3. Run spec-based tests against the mutation:
   IF tests FAIL (catch mutation):
     ✅ High quality — tests are sensitive to this code path
   IF tests PASS (miss mutation):
     ⚠️  Weak coverage — tests don't reach the path
     → Add a more targeted test, then retry Phase 3

4. Revert mutation (restore original buggy code)
```

> **Mutation is not exhaustive** — only 1-2 targeted mutations per fix. Goal is confidence, not completeness.

#### Phase 4 — Quality Gate + Fix Record Update

```
GREEN LIGHT  → red phase = FAIL  AND mutation caught = FAIL  ✅  proceed to Step 5
YELLOW LIGHT → red phase = FAIL  AND mutation missed = PASS  ⚠️  proceed with caution (tests may miss edge cases)
RED LIGHT    → red phase = PASS                              🚨  BLOCK Step 5 — resolve Phase 2 first
```

Update Fix Record draft (`FIX-NNN.md`) with:
```
## Specification Tests (Step 4.7)
Tests created: [list of test names]
Red phase:     FAIL ✅ / PASS 🚨 (reason: ...)
Mutation:      CAUGHT ✅ / MISSED ⚠️  (mutation applied: ...)
Gate:          GREEN / YELLOW / RED
```

---
