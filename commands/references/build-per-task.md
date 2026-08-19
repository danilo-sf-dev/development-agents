# Reference: Build Per-Task Implementation

**Used by**: `/sdd.build` Step 4.

### Step 4: Per-Task Implementation

> **Tests-first**: Tests were written and approved in `/sdd.test`. **Do NOT spawn `sdd-test-writing` for new unit/integration tests** — only run existing tests and implement production code until they pass (green).
> ⚠️ **Never edit the approved test files themselves to force a pass** — see "Approved Tests Are Immutable" above. Fix the code, not the contract.

> **Platform routing**: Read `platform.type` in `PROJECT.md` before dispatching.

For each task, delegate to subagents based on platform:

**Default routing** (`platform.type` from PROJECT.md — backend, frontend-web, android, ios, or absent):

| Task Type                            | Subagent                                      | Notes                                                            |
| ------------------------------------ | --------------------------------------------- | ---------------------------------------------------------------- |
| Production code                      | `sdd-implementation`                             | Follow detected stack + technical spec; make approved tests pass |
| Run tests (verify)                   | `sdd-validator` skill or project test command | Re-run after each task — no new test files                       |
| E2E tests (if not done in /sdd.test) | `sdd-test-writing`                       | Only if E2E was deferred and `testing.e2e.enabled`               |
| Validation                           | `sdd-validator`                        | Independent context                                              |

**Optional mobile / design-system preamble** — when `platform.type` is android/ios:

> **Lazy-loaded**: Read `references/build-mobile-preamble.md`.

`DELEGATE_OFFLOAD` (context-saving delegation to the `sdd-implementation` Skill, `model_role:
EXECUTION` — no isolation requirement; see `framework/_shared/harness-capabilities.md` for the
capability and `adapters/<harness>/README.md` for the concrete dispatch on the installed harness):

1. Extract the Design Decisions relevant to this task: for each `design_decisions` ID on the current
   task, pull the matching `### DD-N: ...` section from the technical spec (through the next `### DD-`
   header or `---`).
2. Delegate to `sdd-implementation` with:
   - the task context
   - the relevant Design Decisions (or a note that none apply) — these were already evaluated and
     approved; the Skill must not propose alternatives to the chosen approach. If it believes a
     different approach would be better, it flags that as a deviation, it does not silently change
     the approach.
   - the technical spec reference (`sdd/wip/<feature>/2-technical/spec.md`)
   - the related files for this task

> Resolve SDKs and clients from the technical spec, PROJECT.md, and existing repo patterns.
> Do not assume a vendor marketplace skill. Optional stack skills apply only when PROJECT.md names them.
