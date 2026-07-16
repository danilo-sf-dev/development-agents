# SDD Kit - Quick Reference Card

> One-page cheat sheet for all commands and workflow
> **Version**: 1.7.2 | Updated: 2026-05-07

---

## 🚨 READ THIS FIRST - Where to Run Commands

This framework has **TWO TYPES** of commands. **Running them in the wrong place will not work!**

| Command Type | Where to Run | Example |
|--------------|--------------|---------|
| **CLI Commands** (installation) | **Terminal/Bash** | `$ sdd-kit init claude` |
| **Framework Commands** (features) | **IDE Platform AI docs Chat** | `/sdd.start "my-feature"` |

### ✅ CLI Commands (Terminal/Bash Only)
```bash
$ sdd-kit init claude       # Install framework
$ sdd-kit status            # Check installation
$ sdd-kit upgrade           # Upgrade to latest version
$ sdd-kit help              # Show help
```

### ✅ Framework Commands (IDE Platform AI docs Chat Only)
```
/sdd.start "feature-name"       # In Claude Code, Cursor, etc.
/sdd.spec functional            # In your IDE's chat window
/sdd.plan                       # NOT in terminal/bash!
```

> 💡 **Easy way to remember**:
> - Starts with `sdd-kit` → Run in **bash**
> - Starts with `/sdd.` → Type in **IDE Platform AI docs chat**

---

## ⛔ Critical Pre-Execution Checks

**STOP** - Before ANY `/sdd.*` command, verify:

| Check | Rule | If Violated |
|-------|------|-------------|
| **Working Directory** | `pwd` must NOT contain `.sdd-kit` | `cd ..` to project root |
| **Docker base image** | Use the prefix/registry declared in `sdd/PROJECT.md` (if your org mandates one) | Build/CI will likely fail org policy checks |
| **Internal services/plugins** | Check `sdd/PROJECT.md` for org-specific skills/services before designing a new solution | Invoke the project's designated skill (e.g. `sdd-system-designer`, `sdd-implementer`) |
| **App/project registration** | If your platform requires app registration, it must exist before `/sdd.start` | Register it per your org's onboarding docs (see `sdd/PROJECT.md`) |

> Docker base images, mandatory internal services, and other org-specific policies are **not hardcoded** in this framework — declare them once in `sdd/PROJECT.md` and agents will enforce what's declared there.

---

## Workflow by Mode

> Canonical pipeline, gates, and diagram: [`framework/PIPELINE.md`](./PIPELINE.md)

### Express (1 command)
```
/sdd.go "feature description"    → Complete feature automatically
```

### Standard (6 commands)
```
/sdd.start → /sdd.spec → /sdd.plan → /sdd.test → /sdd.build → /sdd.finish
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
| Command | Description |
|---------|-------------|
| `/sdd.go "desc"` | Complete feature automatically |

### Setup
| Command | Description |
|---------|-------------|
| `/sdd.project` | Initialize PROJECT.md (team conventions) |
| `/sdd.mcp` | Configure optional MCP (Atlassian Jira read-only) |

### Core Workflow
| Command | Description |
|---------|-------------|
| `/sdd.start "name"` | Initialize feature (selects project type) |
| `/sdd.spec` | Create specifications |
| `/sdd.plan` | Generate tasks |
| `/sdd.test` | Write and approve failing tests before implementation |
| `/sdd.build` | Implement feature until approved tests pass |
| `/sdd.finish` | Validate and archive |

### Utilities
| Command | Description |
|---------|-------------|
| `/sdd.check` | View status/progress |
| `/sdd.list` | List all features |
| `/sdd.rollback` | Revert to previous phase |
| `/sdd.cancel` | Cancel feature |
| `/sdd.fix` | Fix errors (updates specs + tasks + code) |
| `/sdd.backlog` | Manage backlog (TODOs, Debt, Ideas) |
| `/sdd.help` | Show command reference |

### Import & Analysis
| Command | Description |
|---------|-------------|
| `/sdd.import` | Import external specs |
| `/sdd.reverse-eng` | Reverse engineer codebase (4 phases, 5-level confidence) |

---

## Reverse Engineering

### Phases
| Phase | Output |
|-------|--------|
| 1 | `raw/` - Extraction |
| 2 | `DOCUMENTATION_GAPS.md` - Coverage |
| 2.5 | `DISCREPANCIES_REPORT.md` - Field validation |
| 3 | Specs with confidence levels |

### 5-Level Confidence System
| Level | Icon | Meaning |
|-------|------|---------|
| VERIFIED | ✅✅ | Both sources, fields match |
| PARTIAL | ✅⚠️ | Both sources, fields differ |
| CODE_ONLY | 🔸 | Only in code (reliable) |
| DOCS_ONLY | ⚠️ | Only in  (verify) |
| UNKNOWN | ❓ | No data (DO NOT USE) |

### Extraction Capabilities (v2.1)
- API DTO Catalog (with validations), Service Layer (all including legacy)
- Controller Catalog (exhaustive), Feature Flags, Observability Metrics
- Validation Rules, Test Coverage Mapping, Dependency Graphs

### Key Protocols
- Anti-Invention (never invent), Anti-Truncation (ALL fields)

---

## Execution Modes

| Mode | Set With | Behavior |
|------|----------|----------|
| **Express** | `--express` | Minimal questions, auto-advance |
| **Standard** | (none - **DEFAULT**) | Confirmations at key points |

```bash
/sdd.start "feature"              # Uses Standard mode (default)
/sdd.start "feature" --express    # Start in express mode
```

---

## Granular Control Flags

### /sdd.spec
```bash
/sdd.spec functional              # Draft functional only
/sdd.spec technical               # Draft technical only
/sdd.spec --include "url/path"    # Add external context (Jira, Confluence, file)
/sdd.spec --iterate "change"      # Modify/update spec (refine requirements)
/sdd.spec functional --approve    # Approve functional
/sdd.spec technical --approve     # Approve technical
```

### /sdd.plan
```bash
/sdd.plan                         # Generate tasks
/sdd.plan --refine                # Interactive refinement
/sdd.plan --approve               # Approve and set strategy
```

### /sdd.build
```bash
/sdd.build                        # Build all (with pauses)
/sdd.build task TASK-001          # Single task
/sdd.build phase 2                # Single phase
/sdd.build --resume               # Resume interrupted session
/sdd.build --next                 # Auto-continue with next task
```

### /sdd.check
```bash
/sdd.check                        # Full status
/sdd.check task TASK-001          # Task details
/sdd.check --sync                 # Verify layer consistency (+ fix y/n)
/sdd.check --compliance           # Verify /tests/lint (+ fix y/n)
/sdd.check --resume               # List resumable sessions
/sdd.check --resume --last        # Resume last session
```

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
| Type | ID Format | Purpose |
|------|-----------|---------|
| **TODO** | `TODO-001` | Deferred improvements |
| **DEBT** | `DEBT-001` | Technical debt |
| **IDEA** | `IDEA-001` | Future enhancements |

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

| Mode | Functional Spec | Technical Spec | You approve |
|------|----------------|----------------|-------------|
| **Pipeline completo** | Interview | Interview | Everything |
| **Solo spec técnica** | Auto-generated | Interview | Technical + tasks |
| **Directo a tareas** | Auto-generated | Auto-generated | Tasks only |

> IDEA items always use full pipeline (need functional discovery).
> Auto-generated specs preserve full traceability — specs are never skipped.

### Feature from Backlog
```bash
/sdd.start --from-backlog TODO-001
```

---

## Directory Structure

```
sdd/
├── backlog.md              # Centralized backlog (TODOs, Debt, Ideas)
├── wip/                    # Work in progress
│   └── [YYYYMMDD-feature-name]/ #: With date prefix (e.g., 20260120-user-auth)
│       ├── 1-functional/spec.md
│       ├── 2-technical/spec.md
│       ├── 3-tasks/tasks.json
│       ├── 4-implementation/progress.md
│       └── meta.md
├── features/               # Completed features (with date prefix)
├── cancelled/              #: Cancelled features
└── extracted/              # Reverse-engineered specs
```

### Feature Reference

Reference features by name or full name:
```bash
/sdd.check user-auth              # By name
/sdd.check 20260120-user-auth     # By full name
```

---

## Telemetry (v2.0)

Telemetry is captured **automatically by hooks** - no manual logging required.

**Supported Tools**:
| Tool | Support | Data Location |
|------|---------|---------------|
| Claude Code | ✅ | `~/.claude/logs/` |
| Cursor | ✅ | `~/.cursor/logs/` |

**What's Captured** (when supported):
- Sessions with timestamps and duration
- Tool calls (Read, Write, Edit, Bash, etc.)
- User interactions

**When**:
- `session-start` → Creates session file
- `post-tool-use` → Logs tool calls
- `user-prompt` → Logs interactions
- `session-end` → Finalizes session

---

## Project Types

| Type | Tests | CI Pipeline | Coverage |
|------|-------|-------------|----------|
| **Prototype** | ❌ Disabled | Skip | 0% |
| **MVP** | ⚠️ Critical only | Run | varies |
| **Production** | ✅ Full | Required | 80%+ |

> Specs are ALWAYS 100% required regardless of project type.

---

## Mandatory Requirements

Every feature MUST have:
- ✅ Functional spec with user stories + acceptance criteria
- ✅ Technical spec with API contracts + data model
- ✅ Tests (coverage varies by project type)
- ✅ CI Pipeline passing before `/sdd.finish` (MVP/Production)
- ✅ Container/runtime compliance (Dockerfile, Dockerfile.runtime, /ping)

---

## Agent Boundaries (Three-Tier System)

> Quick reference for what agents can/cannot do. Full details: `standards/boundaries.md`

| Tier | Icon | Action | Examples |
|------|------|--------|----------|
| ✅ **Always Do** | Auto-approved | Run tests, read files, build, commit | No asking needed |
| ⚠️ **Ask First** | Require approval | Add deps, delete files, schema changes | Shows confirmation dialog |
| 🚫 **Never Do** | Hard stops | Commit secrets, `--force` push, `rm -rf /` | Blocked always |

**Quick Decision**:
- Destructive? → ⚠️ Ask First
- Standard dev operation? → ✅ Just Do It
- In "Never Do" list? → 🚫 Stop

---

## Common Patterns

### Quick Feature (Express)
```bash
/sdd.go "add password reset with email"
```

### Standard Feature
```bash
/sdd.start user-auth
/sdd.spec
/sdd.plan
/sdd.build
/sdd.finish
```

### Resume Work
```bash
/sdd.check               # See current status
/sdd.build               # Continue implementation
/sdd.build --resume      # Resume interrupted session
/sdd.build --next        # Auto-continue with next task
```

### Iterate on Completed Feature
```bash
/sdd.start --reopen 003              # Reopen by number (asks phase)
/sdd.start --reopen user-auth        # Reopen by name
/sdd.start --reopen 003 --phase 2    # Reopen directly to technical spec
# Then: /sdd.spec → /sdd.plan → /sdd.test → /sdd.build → /sdd.finish (normal flow)
```

### Need More Control
```bash
/sdd.build task TASK-005 # Implement specific task
/sdd.spec functional      # Iterate on functional spec separately
```

### Fix Issues
```bash
/sdd.check --sync             # Verify layer consistency
/sdd.check --compliance       # Verify /tests/lint
/sdd.fix "error output"       # Fix runtime errors
/sdd.rollback 2               # Rollback if needed
/sdd.rollback --task TASK-XXX # Revert specific task
/sdd.rollback --phase N       # Revert to phase N
```

---

## Migration from OpenSpec

| OpenSpec | SDD Kit |
|----------|--------------|
| `openspec init` | `/sdd.start` |
| `openspec generate` | `/sdd.spec` |
| `openspec implement` | `/sdd.build` |
| (all at once) | `/sdd.go "desc"` |

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

| Problem | Solution |
|---------|----------|
| Want simpler workflow | Use `/sdd.go` or `--express` mode |
| Want more control | Use granular flags (`/sdd.spec functional`, `/sdd.build task TASK-XXX`) |
| Validation fails | Read errors, fix, re-validate |
| Feature stuck | `/sdd.check` to diagnose |
| Need to redo phase | `/sdd.rollback [phase]` |
| Need to iterate on completed feature | `/sdd.start --reopen [NNN]` |
| Need to change spec | `/sdd.spec --iterate "change"` |
| Need external context | `/sdd.spec --include "url or path"` |
| MCP not working | Run `/sdd.mcp --status` or `/sdd.mcp`; see [MCP_SETUP_GUIDE.md](./MCP_SETUP_GUIDE.md) |
| Platform auth expired | Re-authenticate per your org's login flow |
| App/project not registered on your platform | Register it per your org's onboarding docs (see `sdd/PROJECT.md`) first |
| CI Pipeline fails | Fix issues, retry before `/sdd.finish` |

---

## Resources

| Resource | Location |
|----------|----------|
| Full Commands | `.development-agents/COMMANDS.md` |
| Workflow Guide | `.development-agents/WORKFLOW.md` |
| Governance | `~/.development-agents/standards/governance.md` |
| **Boundaries** | `~/.development-agents/standards/boundaries.md` |
| MCP Setup | `development-agents/framework/MCP_SETUP_GUIDE.md` (or hub `framework/MCP_SETUP_GUIDE.md`) |
| Templates | `~/.development-agents/templates/` |
| Standards | `~/.development-agents/standards/` |

---

*Print this page and keep it handy while using SDD Kit!*
