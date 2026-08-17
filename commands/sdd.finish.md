---
name: sdd.finish
description: Complete feature implementation, run final validations, and archive. Use when all tasks are done, CI passes, and you're ready to move the feature from wip/ to features/.
model_role: STRONG
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

| Flag           | Description                            |
| -------------- | -------------------------------------- |
| (none)         | Validate and archive completed feature |
| `--force`      | Skip certain validation checks         |
| `--skip-tests` | Skip test re-run (not recommended)     |

**Pre-requisite**: `/sdd.build` FINAL VALIDATION must pass first.

**Example**:

```bash
/sdd.finish            # Validate, archive, move to features/
```

**See also**: `/sdd.help finish` for detailed documentation

**Model Routing (automatic, informational only)**: this command runs at `model_role: STRONG`, resolved and dispatched automatically — no confirmation needed. Optionally print the one-line observability format from `references/model-suggestion-advisory.md`.

---

## PRE-REQUISITE

`/sdd.build` final validation must already be green (compliance + Layer-3 quality + patterns + CI/tests).
If not → return to `/sdd.build`. Finish is a double-check + archive. See `standards/PREREQ-VALIDATION.md`.

---

## Validation Delegation (MANDATORY)

Use skills (all tools): `sdd-validator` → `sdd-code-reviewer` (security + final review).
Optional: delegate to `sdd-layer-analysis` (`OFFLOAD_READ`, `model_role: EXECUTION` — see `framework/_shared/harness-capabilities.md` and `adapters/<harness>/README.md`) for final consistency.
Do not invent a parallel validation path.

## Context Advisory (short)

> 50% context → recommend `/clear` before finish; >80% → `context-guardian`. Archive is disk-safe; validation quality suffers in a full context.

## Skill Hooks (lazy-loaded)

> **ONLY IF** skill hooks configured for `finish`:
> Read `references/skill-hooks.md`, phase=`finish`, at before-start / after-implementation / before-approval.

## Purpose

Final step in feature workflow. Runs comprehensive validation, generates summary documentation, and archives the feature from `sdd/wip/` to `sdd/features/`.

---

## Behavior by Mode (short)

| Mode     | Behavior                                                                 |
| -------- | ------------------------------------------------------------------------ |
| Express  | Validate → auto-archive → brief success                                  |
| Standard | Show results → confirm archive → docs → promote learnings/backlog if any |

> **ONLY IF** profile-specific output examples:
> Read `references/output-examples-by-profile.md`.

## Validation Checks (BLOCKING)

1. Phase = implementation (`detect-phase.sh`)
2. CI / project test entrypoint passed (reuse build Step 6D if already green this session)
3. All tasks completed (`validate-complete.sh`)
4. Platform compliance — backend/web via `validate-code.sh`; mobile → `references/finish-mobile-validation.md`
5. Security assessment APPROVED + no hardcoded secrets
6. Coverage / quality gates per PROJECT.md (`coverage`, reviews) — always enforced

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

## Code Graph Cleanup (lazy-loaded, optional)

> **ONLY IF** `graphify-out/` exists (this session or a prior one): after all gates above,
> before the final archive/conclusion, Read `framework/_shared/graphify-context.md` § 10.
> Remove `graphify-out/` **only** if `graphify-out/.sdd-managed` is present (this SDD run
> created it) — never delete a `graphify-out/` that predates this session's own `/sdd.start`
> bootstrap. Either way, re-confirm nothing under `graphify-out/` is staged before archiving.
> Cleanup failure → warn, do not block finish, re-verify nothing staged. If `graphify-out/`
> doesn't exist, skip this step entirely.

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

**CRITICAL**: See `framework/standards/boundaries.md` — B-09, `/sdd.finish` section.

> **Telemetry**: Data is captured automatically by hooks in `~/.claude/logs/` (Claude Code) or `~/.cursor/logs/` (Cursor).

---

## Examples (lazy-loaded)

> **ONLY IF** user asks for examples of success/failure/express finish:
> Read `references/finish-examples.md`.

## Optional conditions (lazy-loaded)

| Condition                           | Reference                                   |
| ----------------------------------- | ------------------------------------------- |
| Mobile validation                   | `references/finish-mobile-validation.md`    |
| Skill hooks                         | `references/skill-hooks.md`, phase=`finish` |
| Detailed validation bash/checklists | `references/finish-validation-checks.md`    |
| Brownfield spec merge               | `references/finish-brownfield-merge.md`     |
| Archive / PATTERNS details          | `references/finish-archive-workflow.md`     |
| Examples                            | `references/finish-examples.md`             |
| Code graph cleanup                  | `framework/_shared/graphify-context.md`     |
| Next-steps UX                       | `references/finish-next-steps.md`           |

## AI Agent Instructions

1. Block unless build final validation + blocking checks pass.
2. Standard: confirm before archive; Express: auto-archive on green.
3. Atomic `mv` wip→features; verify; promote PATTERNS/backlog via AskUserQuestion.
4. Mobile / brownfield / hooks → matching lazy refs only.
5. After archive (Standard): suggest `/sdd.pr` via `references/finish-next-steps.md`.
6. **Mandatory, blocking, executable — not just textual**: before ending this command (after
   archive), run
   `bash framework/tools/emit-phase-observability.sh phase --harness <claude-code|codex> --model "$RESOLVED_MODEL" [--effort "$RESOLVED_EFFORT"] [--duration-ms "$DURATION_MS"] [--stream-file "$STREAM_FILE"]`
   — omit `--stream-file` entirely if this command's own dispatch ran inline / had no capturable
   stream; the helper's own logic then prints `telemetry: unavailable (interactive session)`
   deterministically, never composed by the agent. Full contract:
   `commands/references/phase-transition-observability.md` § "Helper mechanism". This is a
   situated, concrete action — not a duplicate of the global pointer in `agent-instructions.md`.
