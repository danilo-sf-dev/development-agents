# Reference: tests-manifest case contract

**Used by**: `/sdd.test`, `sdd-small-test-writer`, `sdd-validator-runner` (Process Compliance), `--refine`.

## Why

Free-text `edge_cases: ["empty input"]` labels do not prevent hollow assertions.
Every case must declare an **observable expect** and whether it protects QA/E2E risk.

## Required schema (per test entry)

```json
{
  "id": "TEST-001",
  "file": "tests/unit/....test.ts",
  "covers": ["AC-1", "TASK-001"],
  "cases": [ /* ≥1 required */ ],
  "expected_initial_result": "fail"
}
```

### Required fields in each `cases[]` item

| Field | Type | Rule |
|-------|------|------|
| `id` | string | Unique per feature, prefer `EC-HP` / `EC-001`… |
| `title` | string | Short name |
| `expect` | string | Observable outcome (status, body, exception, persisted state). **Forbidden**: vague text like "should fail" / "works" |
| `assert_kind` | enum | `exception` \| `status` \| `state` only |
| `qa_surrogate` | boolean | `true` if missing this case is something QA would likely catch in E2E/manual |
| `risk_if_missed` | string | One line product/QA risk |

### Forbidden / legacy

- `edge_cases: ["…"]` free-text arrays — **do not write**; migrate to `cases[]`
- `assert_kind` values other than the three above
- Empty `cases` array
- Approving when any required field is missing

## Density guidance (not a skip valve)

Per AC / domain rule:
- 1 happy path (`EC-HP` or equivalent)
- 2–3 edge cases that matter (prefer `qa_surrogate: true`)
- Combinatorial noise → `test-plan.md` Out of scope

## Approval gate checks (BLOCKING)

Before `--approve` or Express auto-approve:

1. Every `tests[]` has non-empty `cases[]`
2. Every case has all six required fields
3. `assert_kind` ∈ {`exception`,`status`,`state`}
4. At least one `qa_surrogate: true` case exists for the feature (unless Out of scope documents why — rare; still prefer ≥1)
5. `red_verified: true` and failures align with missing behavior (not compile-only)

If any check fails → **do not approve**; refine.

## `qa_surrogate` definition

`true` = this unit/integration case is a **surrogate** for a risk QA would see in E2E/manual (wrong screen data, accepted invalid input, bad persistence).
`false` = useful technical case, low QA visibility — keep only if justified; prefer cutting these first when trimming volume.
