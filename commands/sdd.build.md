---
name: sdd.build
description: Implement feature tasks following approved strategy. Use when tasks are approved and user is ready to code. Handles layer-by-layer execution, infrastructure creation, database migrations, frontend builds, and CI validation.
model_role: EXECUTION
argument-hint: "[task-id|--next|--all]"
---

> **Shared agent instructions**: Read `development-agents/framework/_shared/agent-instructions.md` before executing this command.

# Command: /sdd.build

**Description**: Implement feature tasks following approved execution strategy

**Usage**:

- `/sdd.build` → Implement all tasks (behavior based on mode)
- `/sdd.build task TASK-XXX` → Implement specific task
- `/sdd.build phase N` → Implement specific phase
- `/sdd.build --layer N` → Implement up to layer N
- `/sdd.build --resume` → Resume interrupted build session
- `/sdd.build --next` → Auto-continue with next pending task

---

## Quick Help

> `/sdd.build help` → Shows this summary

**Syntax**: `/sdd.build [target] [flags]`

| Flag            | Description                          |
| --------------- | ------------------------------------ |
| (none)          | Implement all tasks based on mode    |
| `task TASK-XXX` | Implement specific task only         |
| `phase N`       | Implement specific phase only        |
| `--layer N`     | Implement up to layer N              |
| `--resume`      | Resume interrupted session           |
| `--next`        | Auto-continue with next pending task |

**See also**: `/sdd.help build`. Prerequisites: tasks + tests approved (`stages.tests` approved).

**Model Routing (automatic, informational only)**: this command runs at `model_role: EXECUTION` (validator sub-step always `STRONG`), resolved and dispatched automatically — no confirmation needed. Optionally print the one-line observability format from `references/model-suggestion-advisory.md`.

---

## Plan Mode Integration (lazy-loaded)

> Opt-in, disabled by default. **ONLY IF** `plan_mode.build_*` enabled in PROJECT.md/config:
> Read `references/build-plan-mode.md`.
> Otherwise skip — uninterrupted implementation.

## Quality Checks (MANDATORY)

> **BLOCKING**: Quality checks after EACH task, not just at the end.

**Per-Task Cycle**: Implement → Test → `VALIDATOR_ISOLATED` Layer-3 gates (`sdd-validator`, isolated mode, always `model_role: STRONG` — see `framework/_shared/harness-capabilities.md` for the capability and `adapters/<harness>/README.md` for the concrete dispatch on the installed harness) → Fix **all** findings → Re-check → Complete/commit.
Verdicts under `sdd/wip/<feature>/verdicts/` (do not commit).

### Dependency Scanning (short)

Before adding a library: run project dependency-security scanner if configured in PROJECT.md; block on unresolved vulns.

## Approved Tests Are Immutable (Anti-Gaming Guard)

> **BLOCKING RULE**: See `framework/standards/boundaries.md` — B-07, B-08 and section **`/sdd.build`**.

**Detection (per task)**: if any file in `tests-manifest.json` appears in the working-tree diff → STOP, AskUserQuestion (always include **Outros**). Never auto-approve in Express.

> Read `references/build-anti-gaming-detection.md` for detection steps + AskUserQuestion payload.
> AskUserQuestion shape: `references/ask-user-question-outros.md`.

## Mandatory Code Review Protocol (short)

Per task: Implement → run approved tests → `sdd-validator` with **Process Compliance +** perf/security/quality → Fix **all** findings → Re-check → Complete/commit.
Process Compliance failures are BLOCKING — AskUserQuestion (incl. Outros) before continuing. Minor quality findings are NOT optional.

## Behavior by Mode

| Mode         | Behavior                                                     |
| ------------ | ------------------------------------------------------------ |
| **Express**  | Implement all, minimal pauses, auto-fix errors, auto-advance |
| **Standard** | Report progress, pause on errors, ask user                   |

---

## Skill Hooks (lazy-loaded)

> **ONLY IF** skill-hooks.json / installed skill metadata declares `build` hooks:
> Read `references/skill-hooks.md`, phase=`build`, at before-start / after-implementation / before-approval.

## Workflow (Steps in Order)

### Extension point: before-start

> Resolve and invoke hooks for phase=`build`, trigger=`before-start`.

### Step 1: Phase Detection (BLOCKING)

`stages.tests` must be `approved`; `detect-phase.sh` stage must be `implementation`. Else stop → `/sdd.test --approve`.
Detect platform; mobile → optional skills from PROJECT.md. Context >50% → consider `/clear`; >80% → `context-guardian`.

> **ONLY IF** needing bash:
> Read `references/build-phase-detect.md`.

### Step 2: Read Task Source

Read tasks from `sdd/wip/[feature]/3-tasks/tasks.json`:

```bash
jq '.tasks[] | select(.status == "pending")' tasks.json
```

### Step 3: Layer-Based Execution (lazy-loaded)

> Execute tasks by approved layer/strategy from `tasks.json` / meta.md.
> Read `references/build-layer-execution.md` when implementing layers or `--layer N`.

### Step 3.3: Infrastructure Creation (CONDITIONAL)

> **Lazy-loaded**: When `tasks.json` contains `INFRA-TASK-*` entries, Read `references/build-infra-creation.md`. Skip if no infra tasks.

### Step 3.5: Database Migration Branch (CONDITIONAL)

> **Lazy-loaded**: When `migration.detected == true` AND `migration.branch_status == "pending"`, Read `references/database-migration.md` for database migration workflow and branch management.

### Step 4: Per-Task Implementation

Do **not** write new unit/integration tests; make approved tests pass; never edit them (anti-gaming).
Route via `sdd-implementation` (+ validator). Include Design Decisions from tech spec in the prompt.
E2E only if deferred + enabled. Mobile preamble: `references/build-mobile-preamble.md` ONLY IF android/ios.

> **ONLY IF** needing prompt template / routing table:
> Read `references/build-per-task.md`.

**Code Graph (lazy-loaded, optional, not mandatory per-task)**: **ONLY IF**
`graphify-state.sh get sdd/wip/<feature>/meta.md` reports `GRAPHIFY_MODE=active` and
`GRAPHIFY_GRAPH=ready` (see `framework/_shared/graphify-context.md` § 7) AND impact isn't
already clear from `/sdd.plan` — query for extension points, callers/dependents, or
reuse-vs-new decisions before implementing (git guard first, § 2). Always still edit/read real
source afterward; the graph never substitutes for the actual diff. Read this state once per
build run, do not re-ask — disabled/impact already clear → skip, implement as before.

### Step 5: Quality Gate + Persist

1. Anti-gaming check 2) `sdd-validator` 3) Fix until APPROVED 4) Mark task `completed` in `tasks.json` on disk (survives `/clear`).

### Step 5b: Context Check Between Tasks (short)

Between tasks: if context >50% recommend `/clear` + `/sdd.build --next`; >80% invoke `context-guardian`.

### Extension point: after-implementation

> Resolve and invoke hooks for phase=`build`, trigger=`after-implementation`.

### Step 6: Final Validation

After all tasks: A compliance → B Layer-3 via `sdd-validator` → C code patterns → D local CI (`PROJECT.md` command). Fix all failures.

> **ONLY IF** needing Step 6A–6D bash/details:
> Read `references/build-final-validation.md`.
> Platform compliance details: `references/build-platform-compliance.md` (backend/web).

### Step 6.5: Code Graph — mark stale (lazy-loaded, optional)

> **ONLY IF** `graphify-state.sh get sdd/wip/<feature>/meta.md` reports `GRAPHIFY_MODE=active`
> AND actual code (not docs/spec/Markdown-only) changed during this build run: run
> `graphify-state.sh mark-stale sdd/wip/<feature>/meta.md`. This is a **state flip only** — it
> does **not** call `graphify-run.sh update .` and does **not** ask the user anything here. The
> update decision (and the one legitimate re-ask) belongs to `/sdd.check`, right before it would
> consult the graph — see `framework/_shared/graphify-context.md` § 6. Skip entirely if
> Graphify is disabled for this flow or nothing structural changed (`mark-stale` is also a
> no-op by design when mode is not `active`).

### Step 7: Final Sync (short)

Confirm tasks.json all completed, meta stage ready for finish, no pending INFRA/migration branches.

### Extension point: before-approval

> Resolve and invoke hooks for phase=`build`, trigger=`before-approval`.

### Step 8: Interactive Next Steps (lazy-loaded)

> Next step after build is ALWAYS `/sdd.check` — never `/sdd.finish` directly.
> **ONLY IF** Standard mode AskUserQuestion UX:
> Read `references/build-next-steps.md`.

## Platform Compliance Validation (lazy-loaded)

> **ONLY IF** `platform` is backend/web (not android/ios) and final validation runs:
> Read `references/build-platform-compliance.md`.
> Mobile: use stack/test commands from PROJECT.md (see `build-mobile-preamble.md`).

## State Persistence (short)

Always persist task status to `tasks.json` after each green gate. Commits at layer boundaries or before `/clear`.

## Build Commands (lazy-loaded)

> Resolve build/test commands from `sdd/PROJECT.md` + detect-stack.
> **ONLY IF** needing per-stack command examples:
> Read `references/build-commands-by-stack.md`.

## Improvement Capture & Flow (short)

Capture generalizable learnings in `4-implementation/progress.md` (canonical path — see `framework/WORKFLOW.md` and `references/start-feature-structure.md`) for `/sdd.finish` promotion.

> **MANDATORY literal lines in `progress.md`** — `validate-complete.sh` (run by `/sdd.finish`) greps for
> these exact substrings, not just their meaning, so free-form phrasing or bold markdown around them
> is invisible to it:
> - `Tests passing: N/M` (e.g. `Tests passing: 15/15`) — lowercase "passing", literal colon.
> - `Coverage: N%` (e.g. `Coverage: 92%`) if a coverage figure is available.
> - `Commit: \`<hash>\`` once per completed task (e.g. `` Commit: `a1b2c3d` ``) — plain `Commit:`, not
>   `**Commit**:`.

Iterative: one task cycle at a time unless Express/`--all`.
Flow: phase check → read tasks → layers → per-task implement+gate → final validate → next `/sdd.finish` or `/sdd.check`.

## References

`framework/PIPELINE.md` · anti-gaming above · lazy refs in table below · `framework/_shared/agent-instructions.md`.

## Optional conditions (lazy-loaded)

| Condition                         | Reference                                   |
| --------------------------------- | ------------------------------------------- |
| Plan mode enabled                 | `references/build-plan-mode.md`             |
| Skill hooks configured            | `references/skill-hooks.md`, phase=`build`  |
| Phase detect bash                 | `references/build-phase-detect.md`          |
| Layer execution / `--layer`       | `references/build-layer-execution.md`       |
| Per-task prompt/routing           | `references/build-per-task.md`              |
| Anti-gaming detection UX          | `references/build-anti-gaming-detection.md` |
| Final validation A–D              | `references/build-final-validation.md`      |
| Infrastructure creation           | `references/build-infra-creation.md`        |
| DB migration branch               | `references/database-migration.md`          |
| Mobile preamble                   | `references/build-mobile-preamble.md`       |
| Platform compliance (backend/web) | `references/build-platform-compliance.md`   |
| Stack command examples            | `references/build-commands-by-stack.md`     |
| Code graph query/refresh          | `framework/_shared/graphify-context.md`     |
| Next-steps UX                     | `references/build-next-steps.md`            |

## AI Agent Instructions

1. Block if tests not approved. Never edit approved tests (anti-gaming above).
2. Per task: implement production code only; quality via `sdd-validator`; fix all findings.
3. Flag-first rare paths: infra / migration / mobile → matching refs.
4. After all tasks + final validation → next step is ALWAYS `/sdd.check`; output pipeline progress; do NOT offer `/sdd.finish` before check.
5. **Contract, executable — report what actually happened**: before ending this command (after
   final validation), run
   `bash framework/tools/emit-phase-observability.sh phase --harness <claude-code|codex> --model "$RESOLVED_MODEL" [--effort "$RESOLVED_EFFORT"] [--duration-ms "$DURATION_MS"] [--stream-file "$STREAM_FILE"]`
   — omit `--stream-file` entirely if this command's own dispatch ran inline / had no capturable
   stream; the helper's own logic then prints `telemetry: unavailable (interactive session)`
   deterministically, never composed by the agent. Full contract:
   `commands/references/phase-transition-observability.md` § "Helper mechanism". This is a
   situated, concrete action — not a duplicate of the global pointer in `agent-instructions.md`.
