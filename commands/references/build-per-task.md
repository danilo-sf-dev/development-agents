# Reference: Build Per-Task Implementation

**Used by**: `/sdd.build` Step 4.

### Step 4: Per-Task Implementation

> **Tests-first**: Tests were written and approved in `/sdd.test`. **Do NOT spawn `sdd-small-test-writer` for new unit/integration tests** — only run existing tests and implement production code until they pass (green).
> ⚠️ **Never edit the approved test files themselves to force a pass** — see "Approved Tests Are Immutable" above. Fix the code, not the contract.

> **Platform routing**: Read `platform.type` in `PROJECT.md` before dispatching.

For each task, delegate to subagents based on platform:

**Default routing** (`platform.type` from PROJECT.md — backend, frontend-web, android, ios, or absent):

| Task Type | Subagent | Notes |
|-----------|----------|-------|
| Production code | `sdd-implementer` | Follow detected stack + technical spec; make approved tests pass |
| Run tests (verify) | `sdd-validator` skill or project test command | Re-run after each task — no new test files |
| E2E tests (if not done in /sdd.test) | `sdd-large-test-writer` | Only if E2E was deferred and `testing.e2e.enabled` |
| Validation | `sdd-validator-runner` | Independent context |

**Optional mobile / design-system preamble** — when `platform.type` is android/ios:

> **Lazy-loaded**: Read `references/build-mobile-preamble.md`.

```
# Extract Design Decisions relevant to this task
    task_dd_ids = current_task.get("design_decisions", [])
    decision_context = ""
    for dd_id in task_dd_ids:
        # Read DD-N section from technical spec (e.g., "### DD-1: ..." through next "### DD-" or "---")
        dd_section = extract_section(technical_spec, dd_id)
        decision_context += dd_section + "\n"

    Task(
        subagent_type="sdd-implementer",
        prompt=f"""
## Task
{task_context}

## Relevant Design Decisions
{decision_context if decision_context else "No specific design decisions apply to this task."}
> These decisions were already evaluated and approved. Do NOT propose alternatives
> to the chosen approaches. If you think a different approach would be better,
> flag it as a deviation — do not silently change the approach.

## Technical Spec Reference
File: sdd/wip/{feature}/2-technical/spec.md

## Related Files
{related_files}
"""
    )
```

> Resolve SDKs and clients from the technical spec, PROJECT.md, and existing repo patterns.
> Do not assume a vendor marketplace skill. Optional stack skills apply only when PROJECT.md names them.
