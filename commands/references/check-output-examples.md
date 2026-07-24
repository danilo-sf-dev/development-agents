# Reference: /sdd.check Output Examples

**Used by**: `/sdd.check --sync`, `--compliance`, `--project`, `--version`.

---

## --sync examples

```
🔍 Sync Check — payment-retry

Functional ↔ Technical:  ✅ Consistent
Technical ↔ Tasks:        ✅ Consistent
Tasks ↔ Code:             ⚠️  1 issue

  ⚠️ TASK-004 "Add retry backoff" marked complete but no matching
     change found in PaymentRetryService.java

Verdict: CAN_PROCEED_WITH_WARNINGS
Recommendation: Verify TASK-004 was actually implemented, or mark it
as tasks-only (no code change needed) if it was a config-only task.
```

```
🔍 Sync Check — user-auth

Functional ↔ Technical:  ❌ Drift detected
  Functional spec mentions "OAuth + SSO" but Technical spec only
  documents OAuth. SSO section missing.

Verdict: CANNOT_PROCEED
Action required: Add SSO section to technical spec, or update
functional spec if SSO was descoped.
```

## --compliance examples

```
🔍 Compliance Check — payment-retry

✅ Build: PASSED
✅ Tests: 42/42 passing, coverage 87% (threshold 80%)
✅ Linting: No errors
⚠️ Dependencies: 1 outdated (non-critical) — jackson-databind 2.14 → 2.17

Verdict: CAN_PROCEED_WITH_WARNINGS
```

```
🔍 Compliance Check — user-auth

❌ Tests: 38/42 passing (4 failing)
❌ Coverage: 61% (threshold 80%)

Failing tests:
  - UserServiceTest.testDuplicateEmail
  - UserServiceTest.testExpiredToken
  - AuthControllerTest.testMissingHeader
  - AuthControllerTest.testMalformedToken

Verdict: CANNOT_PROCEED
Action required: Fix failing tests before continuing.
```

## --project examples

```
🔍 PROJECT.md Validation

✅ Coverage target: 85% (meets 80% minimum, no override needed)
⚠️ ORM: raw SQL (no override registered — recommend documenting why
   an ORM wasn't used, or register an override in PROJECT.md)

Verdict: PASSED WITH WARNINGS
```

```
🔍 PROJECT.md Validation

❌ Coverage target: 50% but no override registered
   → Production projects require 80%+ unless an override with
     justification is added to PROJECT.md § Overrides

Verdict: FAILED
Action required: Either raise min_coverage to 80%, or add a
justified override entry.
```

## --version examples

```
🔍 Version Compatibility Check

Framework version: 2.8.0
Spec format detected: v1.1.4 (outdated)

Deprecated patterns found:
  ⚠️ `Duration: 4 hours` in tasks.json → should be `Complexity: Medium`
     (auto-fixable — run `/sdd.check --version --fix`)
  ⚠️ `sdd/backlog/` directory found → should be `sdd/backlog.md` file
     (manual migration required)

Verdict: CAN_PROCEED_WITH_WARNINGS (auto-fixable items available)
```
