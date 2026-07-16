# Reference: `/sdd.test --refine`

**Used by**: `/sdd.test --refine` or escalation from `/sdd.build` when an approved test is flagged as incorrect.

## Triggers

- User request to adjust tests before implementation
- **Escalation from `/sdd.build`**: implementer flagged an approved test as incorrect instead of silently editing it (see "Approved Tests Are Immutable" in `sdd.build.md`)

## Unlock hard gate (required first step)

Before editing any test file, set manifest back to editable state:

1. `tests-manifest.json → status: in-progress` (NOT `approved` — hard guard blocks while approved)
2. Increment `revision`, set `revised_reason`
3. Update `meta.md → stages.tests.status: in-progress`

Only after human re-approval + fresh snapshot does the hard guard re-lock files.

## Allowed actions

- Add edge case test
- Fix test that passes incorrectly (false green)
- Split/combine test files
- Update AC mapping in `test-plan.md`
- Done refining → re-run Step 5 (red verify)

## When escalated from `/sdd.build`

1. Show the implementer's rationale plus the proposed test change as a diff — never apply silently
2. Human reviews: approve corrected test or reject (implementer must fix code instead)
3. If approved: fresh red-verify is **not** required (implementation may already exist) — but approval (`approved_by`, `approved_at`, incremented `revision`) is mandatory before returning to `/sdd.build`
4. Update `tests-manifest.json` with a `revision` bump and `revised_reason` for audit trail
