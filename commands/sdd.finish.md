---
name: sdd.finish
description: Complete feature implementation, run final validations, and archive. Use when all tasks are done, CI passes, and you're ready to move the feature from wip/ to features/.
model: sonnet
---

> **Shared agent instructions**: Read `development-agents/framework/_shared/agent-instructions.md` before executing this command.

# Command: /sdd.finish

**Description**: Validate, finalize, and archive completed feature

**Usage**:
- `/sdd.finish` → Validate and archive (behavior based on mode)

---

## Quick Help

> `/sdd.finish help` → Shows this summary

**Syntax**: `/sdd.finish [flags]`

| Flag | Description |
|------|-------------|
| (none) | Validate and archive completed feature |
| `--force` | Skip certain validation checks |
| `--skip-tests` | Skip test re-run (not recommended) |

**Pre-requisite**: `/sdd.build` FINAL VALIDATION must pass first.

**Example**:
```bash
/sdd.finish            # Validate, archive, move to features/
```

**See also**: `/sdd.help finish` for detailed documentation

---


## PRE-REQUISITE

`/sdd.build` final validation must already be green (compliance + Layer-3 quality + patterns + CI/tests).
If not → return to `/sdd.build`. Finish is a double-check + archive. See `standards/PREREQ-VALIDATION.md`.

---

## Validation Delegation (MANDATORY)

Use skills (all tools): `sdd-validator` → `sdd-code-reviewer` (security + final review).
Claude Code optional: `Task(sdd-layer-analyzer)` for final consistency.
Do not invent a parallel validation path.

## Context Advisory (short)

>50% context → recommend `/clear` before finish; >80% → `context-guardian`. Archive is disk-safe; validation quality suffers in a full context.

## Skill Hooks (lazy-loaded)

> **ONLY IF** skill hooks configured for `finish`:
> Read `references/finish-skill-hooks.md` at before-start / after-implementation / before-approval.

## Purpose

Final step in feature workflow. Runs comprehensive validation, generates summary documentation, and archives the feature from `sdd/wip/` to `sdd/features/`.

---

## Behavior by Mode (short)

| Mode | Behavior |
|------|----------|
| Express | Validate → auto-archive → brief success |
| Standard | Show results → confirm archive → docs → promote learnings/backlog if any |

> **ONLY IF** profile-specific output examples:
> Read `references/output-examples-by-profile.md`.

## Validation Checks (BLOCKING)

1. Phase = implementation (`detect-phase.sh`)
2. CI / project test entrypoint passed (reuse build Step 6D if already green this session)
3. All tasks completed (`validate-complete.sh`)
4. Platform compliance — backend/web via `validate-code.sh`; mobile → `references/finish-mobile-validation.md`
5. Security assessment APPROVED + no hardcoded secrets
6. Coverage / quality gates per PROJECT.md `project_type`

> **ONLY IF** needing bash snippets, checklists, or security scan commands:
> Read `references/finish-validation-checks.md`.
> Full checklist: `standards/PREREQ-VALIDATION.md`.

## Validation Failure Handling

> **Lazy-loaded**: During validation phase, Read `references/output-examples-by-profile.md` § Validation examples for output format reference.

---

### Extension point: after-implementation

> Resolve and invoke hooks for phase=`finish`, trigger=`after-implementation`.

### Extension point: before-approval

> Resolve and invoke hooks for phase=`finish`, trigger=`before-approval`.

## Generated Documentation

### README.md
Summary of what was built, components, APIs, test coverage.

### implementation-summary.md
Detailed metrics: timeline, effort, tasks, commits, velocity.

---

## Brownfield: System Spec Merge (lazy-loaded)

> **ONLY IF** brownfield and global `sdd/specs/` should merge feature learnings:
> Read `references/finish-brownfield-merge.md`.

## Archive Structure

After completion (same for greenfield and brownfield):

```
sdd/features/[YYYYMMDD-feature-name]/    #: Preserves date prefix
├── README.md                  # Feature summary
├── meta.md                    # Final metadata (NEVER DELETE)
├── functional-spec.md         # What was built (or changed)
├── technical-spec.md          # How it was built (or changed)
├── architecture.md            # Architecture diagrams
├── tasks.json                   # Task list executed
└── implementation-summary.md  # Execution metrics
```

**Feature Naming**:
- The full directory name (including date prefix) is preserved when moving from `wip/` to `features/`
- Example: `sdd/wip/20260120-user-auth/` → `sdd/features/20260120-user-auth/`

**CRITICAL**: `meta.md` must be moved INTACT from `sdd/wip/` to `sdd/features/`. It contains the complete history. NEVER delete it.

> **Telemetry**: Data is captured automatically by hooks in `~/.claude/logs/` (Claude Code) or `~/.cursor/logs/` (Cursor).
---

## Examples (lazy-loaded)

> **ONLY IF** user asks for examples of success/failure/express finish:
> Read `references/finish-examples.md`.

## Optional conditions (lazy-loaded)

| Condition | Reference |
|-----------|-----------|
| Mobile validation | `references/finish-mobile-validation.md` |
| Skill hooks | `references/finish-skill-hooks.md` |
| Detailed validation bash/checklists | `references/finish-validation-checks.md` |
| Brownfield spec merge | `references/finish-brownfield-merge.md` |
| Archive / PATTERNS details | `references/finish-archive-workflow.md` |
| Examples | `references/finish-examples.md` |
| Next-steps UX | `references/finish-next-steps.md` |

## AI Agent Instructions

1. Block unless build final validation + blocking checks pass.
2. Standard: confirm before archive; Express: auto-archive on green.
3. Atomic `mv` wip→features; verify; promote PATTERNS/backlog via AskUserQuestion.
4. Mobile / brownfield / hooks → matching lazy refs only.
5. After archive (Standard): suggest `/sdd.pr` via `references/finish-next-steps.md`.
