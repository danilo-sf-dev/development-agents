---
name: sdd.plan
description: Generate implementation tasks from approved specifications. Use when both functional and technical specs are approved and user is ready to break down work into executable tasks with effort estimates.
model: opus
argument-hint: "[--approve]"
---

> **Shared agent instructions**: Read `development-agents/framework/_shared/agent-instructions.md` before executing this command.

# Command: /sdd.plan

**Description**: Generate, refine, and approve implementation tasks

**Usage**:
- `/sdd.plan` → Auto behavior based on mode
- `/sdd.plan --refine` → Refine existing tasks
- `/sdd.plan --approve` → Approve tasks and choose strategy
- `/sdd.plan --resume` → Resume interrupted planning session
- `/sdd.plan --view` → Open interactive HTML viewer for tasks

---

## Quick Help

> `/sdd.plan help` → Shows this summary

**Syntax**: `/sdd.plan [flags]`

| Flag | Description |
|------|-------------|
| (none) | Auto behavior based on mode |
| `--refine` | Refine existing tasks |
| `--approve` | Approve tasks and choose strategy |
| `--resume` | Resume interrupted planning session |
| `--view` | Open interactive HTML viewer for tasks |

**See also**: `/sdd.help plan`. Next after approve: `/sdd.test` (not `/sdd.build`).

**Model advisory (entry)**: Read `references/model-suggestion-advisory.md` — compact line for `phase_key`: `entry:plan`.


## Pre-Requisites (BLOCKING)

| Check | Tool | On Failure |
|-------|------|------------|
| Spec conflicts resolved | `validate-spec-conflicts.sh` | Run `/sdd.spec` to resolve |
| Technical spec approved | Check `meta.md` | Run `/sdd.spec technical` |
| Context < 50% | `context-guardian` skill | Show advisory, proceed |

---

## Skill Hooks (lazy-loaded)

> **ONLY IF** skill hooks configured for `plan`:
> Read `references/plan-skill-hooks.md` at before-start / after-implementation / before-approval.

## Workflow (Steps in Order)

### Extension point: before-start

> Resolve and invoke hooks for phase=`plan`, trigger=`before-start`.

### Step 1: Phase Detection (BLOCKING)

Technical spec must be approved (`detect-phase.sh`). Context >50% → advisory via `context-guardian`.
> **ONLY IF** needing bash:
> Read `references/plan-phase-detect.md`.

### Step 2: Validate Pre-Requisites

```bash
bash development-agents/framework/tools/validation/validate-spec-conflicts.sh sdd/wip/[feature] blocking
```

If conflicts exist → Block, instruct user to run `/sdd.spec`.

### Step 3: Read Specifications

Read both specs:
- `sdd/wip/[feature]/1-functional/spec.md`
- `sdd/wip/[feature]/2-technical/spec.md`

**Auto-generated spec handling**: Check `meta.md` for `auto_generated` flags:
- IF `auto_generated.functional == true` AND `auto_generated.technical == true` (tasks-only mode):
  → Use specs as-is but weight backlog item context equally
  → Read backlog item directly from `sdd/backlog.md` for additional context (use `from_backlog` ID)
  → Be extra thorough in codebase exploration (affected files from backlog item)
- IF `auto_generated.functional == true` only (technical-only mode):
  → Technical spec was human-authored — use it as primary source
  → Functional spec is minimal — supplement with backlog item context
- ELSE:
  → Standard spec reading (current behavior)

### Step 4: Services & Local Env (lazy-loaded)

> Detect local DB/services needs from tech spec; store in `tasks.json → local_config`.
> Read `references/plan-local-env.md` when configuring local env.

### Step 5: Generate Tasks

Map Design Decisions (DD-N) onto each task (`design_decisions` field).
Mandatory (backend/web): Dockerfile(s) if missing, `/ping`, validation task.
Migrations: use project migration tool from PROJECT.md — never invent Flyway/Liquibase/manual SQL paths.
Tests: always full unit/integration from AC + edges via `/sdd.test`; E2E only if `testing.e2e.enabled`.
Lazy: mobile → `plan-mobile-tasks.md`; `(NEW)` infra → `infra-tasks.md`; frontend-web → `frontend-tasks.md`.
> **ONLY IF** needing E2E script/flow, migration examples, full generation rules:
> Read `references/plan-generate-tasks.md`.

### Extension point: after-implementation

> Resolve and invoke hooks for phase=`plan`, trigger=`after-implementation`.

### Step 6: Strategy Selection (lazy-loaded)

> Choose execution strategy (layers / sequential / etc.). Read `references/plan-strategy.md`.

### Extension point: before-approval

> Resolve and invoke hooks for phase=`plan`, trigger=`before-approval`.

### Step 7: Approval & Output

Show tasks summary → AskUserQuestion approve/refine. On approve: write `3-tasks/tasks.json`, update meta (`stages.tasks`, next stage `tests`), run deterministic validation.
> **ONLY IF** needing AskUserQuestion payloads / success banner:
> Read `references/plan-approval.md`.
> Validation bash: `references/plan-task-validation.md`.

### Step 8: Post-Approval Context (short)

If context high → recommend `/clear` before `/sdd.test`.

### Step 9: Next Steps (lazy-loaded)

> Primary next: `/sdd.test` (tests-first). Read `references/plan-next-steps.md` for AskUserQuestion UX.

## Behavior by Mode

| Mode | Generate | Refine | Strategy | Approve |
|------|----------|--------|----------|---------|
| **Express** | Auto | Skip | Auto (Batched) | Auto |
| **Standard** | Auto | Ask user | Smart auto/Ask | Auto after choice |

---

## tasks.json Structure (lazy-loaded)

> Read `references/plan-tasks-json.md` when writing/validating the file shape.

## Task Layers (short)

Layer 0 infra → 1 domain → 2 application → 3 quality/tests (per validator skill; quality layer always required).

## Validation Checks (lazy-loaded)

> After generate/approve: `validate-tasks` style checks. Read `references/plan-task-validation.md`.

## Key Rules (short)

Tasks must be executable, layered, AC-linked to specs; IDs via deterministic generator; no duplicate work.
> Deterministic IDs / extended rules: `references/plan-key-rules.md` ONLY IF needed.

## Forbidden Tasks (short)

> `framework/standards/boundaries.md` — section **`/sdd.plan`**. Procedure: `references/plan-forbidden-tasks.md`.

## Command Flow

`prereqs → read specs → generate tasks → strategy → approve → /sdd.test`

## References

`framework/PIPELINE.md` · `sdd-validator` · lazy table below · `_shared/agent-instructions.md`.

## Optional flags (lazy-loaded)

| Flag / condition | Reference |
|------------------|-----------|
| `--view` | `references/plan-view.md` |
| `--refine` | `references/plan-refine.md` |
| Task generation details / E2E | `references/plan-generate-tasks.md` |
| Approval UX | `references/plan-approval.md` |
| `platform = android \| ios` | `references/plan-mobile-tasks.md` |
| `(NEW)` infra markers | `references/infra-tasks.md` |
| `frontend-web` | `references/frontend-tasks.md` |
| Skill hooks | `references/plan-skill-hooks.md` |

## AI Agent Instructions

1. Block unless technical spec approved + conflicts resolved.
2. Flag-first: `--view` / `--refine` → matching refs; do not regenerate blindly.
3. Write `tasks.json` only after approval; set next stage to **tests** (`/sdd.test`).
4. Mobile / frontend / infra → lazy refs only when conditions match.
