# Reference: `/sdd.test --refine`

**Used by**: `/sdd.test --refine` or escalation from `/sdd.build` when an approved test is flagged as incorrect.

## Triggers

- User request to adjust tests before implementation
- **Escalation from `/sdd.build`**: implementer flagged an approved test as incorrect instead of silently editing it (see "Approved Tests Are Immutable" in `sdd.build.md`)

## Unlock for edits (required first step)

Before editing any test file, set manifest back to editable state:

1. `tests-manifest.json → status: in-progress` (NOT `approved` — Process Compliance treats `approved` as immutable)
2. Increment `revision`, set `revised_reason`
3. Update `meta.md → stages.tests.status: in-progress`

Only after human re-approval does the contract lock again for `/sdd.build`.

## Allowed actions

- Add/remove/edit `cases[]` entries (keep contract fields complete)
- Add edge case test files mapped to new case IDs
- Fix test that passes incorrectly (false green) — tighten `expect` / assertion
- Split/combine test files (update `file` + `cases` in manifest)
- Update AC mapping + QA risk bridge in `test-plan.md`
- Migrate any legacy `edge_cases` labels → structured `cases[]`
- Done refining → re-run red verify (Step 5) unless escalated mid-build (see below)

## Contract reminder

Every case still requires: `id`, `title`, `expect`, `assert_kind`, `qa_surrogate`, `risk_if_missed`.  
See `references/test-manifest-contract.md`.

## When escalated from `/sdd.build`

1. Show the implementer's rationale plus the proposed test change as a diff — never apply silently
2. Human reviews: approve corrected test or reject (implementer must fix code instead)
3. If approved: fresh red-verify is **not** required (implementation may already exist) — but approval (`approved_by`, `approved_at`, incremented `revision`) is mandatory before returning to `/sdd.build`
4. Update `tests-manifest.json` with a `revision` bump and `revised_reason` for audit trail
