# SDD Kit - Quick Reference Card

> One-page cheat sheet for all commands and workflow
> **Version**: 1.7.2 | Updated: 2026-05-07

---

## 🚨 READ THIS FIRST - Where to Run Commands

Every command in this framework — install included — is run the same way: **typed in your IDE's AI chat**, not in a terminal.

```
/sdd.install                    # One-time setup, in Claude Code, Cursor, etc.
/sdd.start "feature-name"       # In your IDE's chat window
/sdd.spec functional            # In your IDE's chat window
/sdd.plan                       # In your IDE's chat window
```

There is no separate CLI tool to install or invoke from a terminal — `/sdd.install` runs the `sdd-installer` Skill, which uses its own Read/Write/Bash tool calls internally.

---

## ⛔ Critical Pre-Execution Checks

**STOP** - Before ANY `/sdd.*` command, verify:

| Check                         | Rule                                                                                    | If Violated                                                                           |
| ----------------------------- | --------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------- |
| **Working Directory**         | `pwd` must NOT contain `development-agents` (the pack folder itself)                    | `cd ..` to project root                                                               |
| **Docker base image**         | Use the prefix/registry declared in `sdd/PROJECT.md` (if your org mandates one)         | Build/CI will likely fail org policy checks                                           |
| **Internal services/plugins** | Check `sdd/PROJECT.md` for org-specific skills/services before designing a new solution | Invoke the project's designated skill (e.g. `sdd-system-design`, `sdd-implementation`) |
| **App/project registration**  | If your platform requires app registration, it must exist before `/sdd.start`           | Register it per your org's onboarding docs (see `sdd/PROJECT.md`)                     |

> Docker base images, mandatory internal services, and other org-specific policies are **not hardcoded** in this framework — declare them once in `sdd/PROJECT.md` and agents will enforce what's declared there.

---

## Workflow by Mode

> Canonical pipeline, gates, and diagram: [`framework/PIPELINE.md`](./PIPELINE.md)

### Express (1 command)

```
/sdd.go "feature description"    → Complete feature automatically
```

### Standard (7 commands)

```
/sdd.start → /sdd.spec → /sdd.plan → /sdd.test → /sdd.build → /sdd.check → /sdd.finish
```

### Granular Control (optional flags)

```
/sdd.spec functional → /sdd.spec functional --approve
/sdd.spec technical → /sdd.spec technical --approve
/sdd.plan → /sdd.plan --refine → /sdd.plan --approve
/sdd.build task TASK-001 → /sdd.build phase 2 → ...
```

---

## Core Commands

### Express

| Command          | Description                    |
| ---------------- | ------------------------------ |
| `/sdd.go "desc"` | Complete feature automatically |

### Setup

| Command        | Description                                       |
| -------------- | ------------------------------------------------- |
| `/sdd.project` | Initialize PROJECT.md (team conventions)          |
| `/sdd.mcp`     | Configure optional MCP (Atlassian Jira read-only) |

### Core Workflow

| Command             | Description                                           |
| ------------------- | ----------------------------------------------------- |
| `/sdd.start "name"` | Initialize feature (full pipeline)                    |
| `/sdd.spec`         | Create specifications                                 |
| `/sdd.plan`         | Generate tasks                                        |
| `/sdd.test`         | Write and approve failing tests before implementation |
| `/sdd.build`        | Implement feature until approved tests pass           |
| `/sdd.finish`       | Validate and archive                                  |

### Utilities

| Command         | Description                               |
| --------------- | ----------------------------------------- |
| `/sdd.check`    | View status/progress                      |
| `/sdd.list`     | List all features                         |
| `/sdd.rollback` | Revert to previous phase                  |
| `/sdd.cancel`   | Cancel feature                            |
| `/sdd.fix`      | Fix errors (updates specs + tasks + code) |
| `/sdd.backlog`  | Manage backlog (TODOs, Debt, Ideas)       |
| `/sdd.help`     | Show command reference                    |

### Import & Analysis

| Command            | Description                                              |
| ------------------ | -------------------------------------------------------- |
| `/sdd.import`      | Import external specs                                    |
| `/sdd.reverse-eng` | Reverse engineer codebase (4 phases, 5-level confidence) |

---

## Reverse Engineering

### Phases

| Phase | Output                                       |
| ----- | -------------------------------------------- |
| 1     | `raw/` - Extraction                          |
| 2     | `DOCUMENTATION_GAPS.md` - Coverage           |
| 2.5   | `DISCREPANCIES_REPORT.md` - Field validation |
| 3     | Specs with confidence levels                 |

### 5-Level Confidence System

| Level     | Icon | Meaning                     |
| --------- | ---- | --------------------------- |
| VERIFIED  | ✅✅ | Both sources, fields match  |
| PARTIAL   | ✅⚠️ | Both sources, fields differ |
| CODE_ONLY | 🔸   | Only in code (reliable)     |
| DOCS_ONLY | ⚠️   | Only in (verify)            |
| UNKNOWN   | ❓   | No data (DO NOT USE)        |

### Extraction Capabilities (v2.1)

- API DTO Catalog (with validations), Service Layer (all including legacy)
- Controller Catalog (exhaustive), Feature Flags, Observability Metrics
- Validation Rules, Test Coverage Mapping, Dependency Graphs

### Key Protocols

- Anti-Invention (never invent), Anti-Truncation (ALL fields)

---

## Execution Modes

| Mode         | Set With                   | Behavior                        |
| ------------ | -------------------------- | ------------------------------- |
| **Express**  | `--express` (or `/sdd.go`) | Minimal questions, auto-advance |
| **Standard** | (none - **DEFAULT**)       | Confirmations at key points     |

> Full detail (comparison table, example commands): see [`framework/WORKFLOW.md`](./WORKFLOW.md#execution-modes) § Execution Modes / § Workflow Comparison

---

## Granular Control Flags

| Command      | Key Flags                                                                                |
| ------------ | ---------------------------------------------------------------------------------------- |
| `/sdd.spec`  | `functional` · `technical` · `--include "url/path"` · `--iterate "change"` · `--approve` |
| `/sdd.plan`  | `--refine` · `--approve`                                                                 |
| `/sdd.build` | `task TASK-001` · `phase 2` · `--resume` · `--next`                                      |
| `/sdd.check` | `task TASK-001` · `--sync` · `--compliance` · `--resume` · `--resume --last`             |

> Full detail with per-command usage examples: see [`framework/WORKFLOW.md`](./WORKFLOW.md#granular-control-optional-flags) § Granular Control (Optional Flags)

---

## Backlog Management (v2.2)

### Commands

```bash
/sdd.backlog                  # List all items
/sdd.backlog add              # Add new item interactively
/sdd.backlog pick             # Create feature from item
/sdd.backlog resolve TODO-001 # Mark as resolved
```

### Item Types

| Type     | ID Format  | Purpose               |
| -------- | ---------- | --------------------- |
| **TODO** | `TODO-001` | Deferred improvements |
| **DEBT** | `DEBT-001` | Technical debt        |
| **IDEA** | `IDEA-001` | Future enhancements   |

### Auto-capture During Build

When patterns detected → Agent asks:

```
[F] Fix now    → Address immediately
[T] TODO       → Add to backlog
[D] DEBT       → Add as technical debt
[I] IDEA       → Add as enhancement idea
[S] Skip       → Ignore (intentional)
```

### Workflow Modes (DEBT/TODO items)

When picking a DEBT or TODO item, choose how much interaction you need:

| Mode                  | Functional Spec | Technical Spec | You approve       |
| --------------------- | --------------- | -------------- | ----------------- |
| **Pipeline completo** | Interview       | Interview      | Everything        |
| **Solo spec técnica** | Auto-generated  | Interview      | Technical + tasks |
| **Directo a tareas**  | Auto-generated  | Auto-generated | Tasks only        |

> IDEA items always use full pipeline (need functional discovery).
> Auto-generated specs preserve full traceability — specs are never skipped.

### Feature from Backlog

```bash
/sdd.start --from-backlog TODO-001
```

---

## Directory Structure

`sdd/{backlog.md, wip/, features/, cancelled/, extracted/, specs/}` — each feature folder is `[YYYYMMDD-feature-name]/` with `1-functional/`, `2-technical/`, `3-tasks/`, `4-implementation/`, `meta.md`.

Reference features by name or full name:

```bash
/sdd.check user-auth              # By name
/sdd.check 20260120-user-auth     # By full name
```

> Full tree (all subfiles, features/cancelled/extracted/specs layout): see [`framework/WORKFLOW.md`](./WORKFLOW.md#directory-structure) § Directory Structure / § Feature Naming

---

## Telemetry

This framework does not capture token/cost/session telemetry itself. For usage/cost visibility,
use your harness's own native tooling (Claude Code, Cursor, Codex CLI each expose their own) —
outside this pipeline.

---

## Mandatory Requirements

Every feature MUST have:

- ✅ Functional spec with user stories + acceptance criteria
- ✅ Technical spec with API contracts + data model
- ✅ Tests-first gate (`/sdd.test`) with red verified + human approval
- ✅ CI / project test entrypoint passing before `/sdd.finish`
- ✅ Container/runtime compliance (Dockerfile, Dockerfile.runtime, /ping) when applicable

---

## Agent Boundaries (Three-Tier System)

> **Canonical source**: `framework/standards/boundaries.md` — read at every `/sdd.*` start (via `agent-instructions.md`).

Quick index: ✅ safe dev ops · ⚠️ delete/DB/git write/deploy · 🚫 secrets, force-push main, test gaming, prod DB wipe

---

## Common Patterns

| Pattern                      | Command(s)                                                                                                |
| ---------------------------- | --------------------------------------------------------------------------------------------------------- |
| Quick Feature (Express)      | `/sdd.go "desc"`                                                                                          |
| Standard Feature             | `/sdd.start name` → `/sdd.spec` → `/sdd.plan` → `/sdd.test` → `/sdd.build` → `/sdd.check` → `/sdd.finish` |
| Resume Work                  | `/sdd.check`, then `/sdd.build --resume` or `/sdd.build --next`                                           |
| Iterate on Completed Feature | `/sdd.start --reopen NNN [--phase N]`                                                                     |
| Need More Control            | `/sdd.build task TASK-XXX`, `/sdd.spec functional`                                                        |
| Fix Issues                   | `/sdd.check --sync`/`--compliance`, `/sdd.fix "error"`, `/sdd.rollback N`                                 |

> Full command blocks: see [`framework/WORKFLOW.md`](./WORKFLOW.md#common-patterns) § Common Patterns / § Post-Completion Iteration

---

## Migration from OpenSpec

| OpenSpec             | SDD Kit          |
| -------------------- | ---------------- |
| `openspec init`      | `/sdd.start`     |
| `openspec generate`  | `/sdd.spec`      |
| `openspec implement` | `/sdd.build`     |
| (all at once)        | `/sdd.go "desc"` |

---

## Quick Tips

### ✅ Do:

- Use `/sdd.go` for simple features
- Use `/sdd.check` frequently
- Start with `standard` mode, switch if needed
- Be specific (numbers, not "fast" or "many")

### ❌ Don't:

- Skip validation steps
- Accept vague acceptance criteria
- Ignore test failures
- Force-approve without fixing issues

---

## Common Scenarios (FAQ)

### How do I add external context to my spec? (Jira, Confluence, GitHub, inline)

Use `--include` to **import external information** like Jira tickets, Confluence pages, files, or inline text:

```bash
# From URLs (Jira, Confluence, GitHub)
/sdd.spec --include "https://jira.example.com/browse/PROJ-123"
/sdd.spec --include "https://confluence.example.com/pages/viewpage.action?pageId=12345"

# From local files
/sdd.spec --include "path/to/requirements.md"

# Inline text (multiple --include allowed)
/sdd.spec --include "User must be able to reset password via email"
/sdd.spec --include "olvidé mencionar: también necesitamos rate limiting" --include "y validación de emails"
```

> **Keywords**: agregar contexto, incluir información, importar ticket, jira, confluence, contexto externo, external context, include context, inline text, texto adicional

### How do I modify/update/change a spec after it's created?

Use `--iterate` to **refine or update specs** when requirements change or you discover gaps during implementation:

```bash
/sdd.spec --iterate "add rate limiting to all endpoints"
/sdd.spec --iterate "change authentication from JWT to OAuth2"
/sdd.spec --iterate "add new field 'status' to the response"
```

> **Keywords**: modificar spec, cambiar especificación, actualizar requisitos, refinar spec, update spec, change requirements, edit specification

### How do I undo/revert changes or go back to a previous phase?

Use `/sdd.rollback` to **revert to a previous phase** or undo changes:

```bash
/sdd.rollback              # Shows current phase, asks where to go back
/sdd.rollback 2            # Go back to phase 2 (technical spec)
/sdd.rollback --task TASK-005  # Revert specific task changes
/sdd.rollback --phase 1    # Revert to phase 1 (functional spec)
```

> **Keywords**: deshacer, revertir, volver atrás, undo, rollback, go back, revert changes, cancelar cambios

### How do I iterate on a completed feature? (tweak specs, change behavior)

Use `--reopen` to **bring a completed feature back to WIP** for iteration:

```bash
/sdd.start --reopen user-auth              # By name (asks target phase)
/sdd.start --reopen 20260120-user-auth --phase 2  # By full name, direct to technical spec
```

**Gate**: If other features reference this one via `<!-- overrides/extends/deprecates: -->` annotations, reopen is blocked. Create a new feature instead.

> **Keywords**: reabrir feature, iterar, mejorar feature completada, reopen, iterate, tweak completed feature, modify finished feature

### How do I cancel or stop working on a feature?

Use `/sdd.cancel` to **archive and stop** working on a feature:

```bash
/sdd.cancel                # Moves feature to sdd/cancelled/
```

> **Keywords**: cancelar feature, parar, detener, stop feature, abandon, discard

### How do I see what has changed or check consistency?

Use `/sdd.check --sync` to **verify consistency** between specs, tasks, and code:

```bash
/sdd.check --sync          # Shows drift between layers, offers to fix
```

> **Keywords**: verificar consistencia, ver cambios, check changes, drift, sync

---

## Troubleshooting

| Problem                                     | Solution                                                                              |
| ------------------------------------------- | ------------------------------------------------------------------------------------- |
| Want simpler workflow                       | Use `/sdd.go` or `--express` mode                                                     |
| Want more control                           | Use granular flags (`/sdd.spec functional`, `/sdd.build task TASK-XXX`)               |
| Validation fails                            | Read errors, fix, re-validate                                                         |
| Feature stuck                               | `/sdd.check` to diagnose                                                              |
| Need to redo phase                          | `/sdd.rollback [phase]`                                                               |
| Need to iterate on completed feature        | `/sdd.start --reopen [NNN]`                                                           |
| Need to change spec                         | `/sdd.spec --iterate "change"`                                                        |
| Need external context                       | `/sdd.spec --include "url or path"`                                                   |
| MCP not working                             | Run `/sdd.mcp --status` or `/sdd.mcp`; see [MCP_SETUP_GUIDE.md](./MCP_SETUP_GUIDE.md) |
| Platform auth expired                       | Re-authenticate per your org's login flow                                             |
| App/project not registered on your platform | Register it per your org's onboarding docs (see `sdd/PROJECT.md`) first               |
| CI Pipeline fails                           | Fix issues, retry before `/sdd.finish`                                                |

---

## Resources

| Resource       | Location                                                                                  |
| -------------- | ----------------------------------------------------------------------------------------- |
| Full Commands  | `development-agents/framework/COMMANDS.md`                                                |
| Workflow Guide | `development-agents/framework/WORKFLOW.md`                                                |
| Governance     | `development-agents/framework/standards/governance.md`                                    |
| **Boundaries** | `development-agents/framework/standards/boundaries.md`                                    |
| MCP Setup      | `development-agents/framework/MCP_SETUP_GUIDE.md` (or hub `framework/MCP_SETUP_GUIDE.md`) |
| Templates      | `development-agents/framework/templates/`                                                 |
| Standards      | `development-agents/framework/standards/`                                                 |

---

_Print this page and keep it handy while using SDD Kit!_
