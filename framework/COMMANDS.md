# SDD Kit - Commands Reference

Complete reference for all `/sdd.` commands.

---

## Command Overview

**Total Commands**: 21

> Canonical pipeline order and gates: [`framework/PIPELINE.md`](./PIPELINE.md)

| Category | Commands |
|----------|----------|
| **Express** | `go` |
| **Setup** | `project` |
| **Core Workflow** | `start`, `spec`, `plan`, `test`, `build`, `finish`, `pr` |
| **Utilities** | `check`, `list`, `rollback`, `cancel`, `fix`, `backlog`, `help`, `doctor` |
| **Import & Analysis** | `import`, `reverse-eng` |
| **Multi-app** | `hub` |
| **Installation** | `install` |

---

## Execution Modes

Commands adapt their behavior based on the active mode:

| Mode | Flag | Behavior |
|------|------|----------|
| **Express** | `--express` | Minimal interaction, auto-advance |
| **Standard** | (none - **DEFAULT**) | Balanced control, confirmations at key points; optional granular control flags |

> **Default Mode**: When you run `/sdd.start "feature"` without flags, it uses **Standard** mode.

**Set mode**: `/sdd.start "feature" --express`

---

## Command Documentation Structure

All 17 command files follow a standard structure for consistency:

| Section | Description | Applies To |
|---------|-------------|------------|
| **Purpose** | What the command does and when to use it | All commands |
| **Usage** | Syntax, flags, and options | All commands |
| **Behavior by Mode** | How it works in Express/Standard modes | All commands |
| **Workflow** | Step-by-step execution details | All commands |
| **Examples** | Real-world usage scenarios | All commands |
| **Command Flow** | ASCII diagram showing position in workflow | Core workflow only* |
| **AI Agent Instructions** | Rules and guidelines for Platform AI docs execution | All commands |
| **Hooks (optional)** | IDE automation hooks for quality gates | Commands with quality gates only** |

**\* Command Flow Diagram**: Only the 5 core workflow commands (start, spec, plan, build, finish) include a "Command Flow" section showing:
- Prerequisites (what must be done before)
- Current command actions
- Next steps
- Blocking conditions

> **Note**: Utility commands (check, fix, backlog, help, list, cancel, rollback, import) intentionally do NOT include Command Flow sections as they operate horizontally across phases rather than linearly through the workflow.

**\*\* Hooks Section**: Hooks are **optional** IDE automation features that enable automated quality checks. Only commands with quality gates (like `/sdd.build`) include hook configurations. Hooks are:
- **Not required** for framework functionality - all commands work without hooks
- **IDE-specific** - Claude Code hooks work with Claude Code; other IDEs may have different automation mechanisms
- **For automation** - They trigger automatic validation after tool calls (e.g., run tests after code changes)

> **Contributing**: When adding new commands, follow this structure for consistency. See any existing command file as a template.

---

## Express Mode

### /sdd.go

**Complete entire workflow automatically**

```bash
/sdd.go "feature description"
```

**What it does**:
- Asks 3-5 critical questions
- Auto-generates functional + technical specs
- Auto-generates and approves tasks
- Implements all tasks
- Validates and archives

**Token Budget**: ~80K-100K tokens (depending on feature complexity)

**Best for**: Simple features, quick prototypes, OpenSpec migration

**Documentation**: [skills/sdd.go/SKILL.md](./skills/sdd.go/SKILL.md)

---

## Setup Commands

### /sdd.project

**Initialize PROJECT.md with team conventions**

```bash
/sdd.project                           # Interactive wizard
/sdd.project "description"             # Deduce from prompt
/sdd.project --edit                    # Edit existing PROJECT.md
```

**What it does**:
- Configures team conventions (architecture, testing, code review)
- Two modes: Interactive wizard OR prompt inference
- Validates and generates `sdd/PROJECT.md`

**Conventions configured**:
- Architecture pattern (Clean, Hexagonal, Layered, DDD)
- Testing standards (coverage %, ratios)
- Team conventions (PR size, branch naming, commit style)
- Review requirements (code review, spec approval)

**Best for**: First-time setup, new projects, standardizing team conventions

**Documentation**: [skills/sdd.project/SKILL.md](./skills/sdd.project/SKILL.md)

---

## Core Workflow Commands

### /sdd.start

**Initialize new feature**

```bash
/sdd.start "feature-name"             # Standard mode (default)
/sdd.start "feature-name" --express   # Express mode
/sdd.start "feature-name" --lite      # Lite template (~80 lines)
/sdd.start --reopen 003               # Reopen completed feature for iteration
/sdd.start --reopen user-auth --phase 2  # Reopen to specific phase
```

**What it does**:
- Creates folder structure in `sdd/wip/[YYYYMMDD-feature-name]/`
- **Creates feature branch** `feature/<name>` from master/main
- Sets execution mode (persists across sessions)
- Detects greenfield/brownfield mode
- Validates the repository is ready (git initialized, stack detectable)
- **Reopens completed features** back to WIP (`--reopen` flag)

**Output**: Feature initialized, ready for specifications

**Next**: `/sdd.spec`

**Documentation**: [skills/sdd.start/SKILL.md](./skills/sdd.start/SKILL.md)

---

### /sdd.spec

**Create specifications (functional + technical)**

| Mode | Usage | Behavior |
|------|-------|----------|
| Express | `/sdd.spec` | 3-5 questions, auto-generates both specs |
| Standard | `/sdd.spec` | Interactive interview, confirmations at each phase |
| All | `/sdd.spec functional` | Draft functional only |
| All | `/sdd.spec technical` | Draft technical only |
| All | `/sdd.spec functional --approve` | Approve functional |
| All | `/sdd.spec technical --approve` | Approve technical |
| All | `/sdd.spec --resume` | Resume interrupted session |

**Add external context** (Jira tickets, Confluence pages, files, inline text):
> Use when you want to: agregar contexto, incluir información externa, importar ticket

```bash
/sdd.spec --include "https://jira.example.com/browse/PROJ-123"
/sdd.spec --include "https://confluence.example.com/pages/..."
/sdd.spec --include "path/to/requirements.md"
/sdd.spec --include "inline text: olvidé mencionar X" --include "también necesitamos Y"
```

**Modify/update spec after creation** (refine requirements, change spec):
> Use when you want to: modificar spec, cambiar especificación, actualizar requisitos, refinar

```bash
/sdd.spec --iterate "add rate limiting to all endpoints"
/sdd.spec --iterate "change authentication from JWT to OAuth2"
```

**What it does**:
- Phase 1: Creates functional spec (problem, user stories, metrics)
- Phase 2: Creates technical spec (architecture, APIs, data model)
- Queries your internal service directory/registry for project services, if one exists
- Validates before approving

**Complexity**: Low-Medium (varies by spec size and mode)

**Output**: Both specs approved, ready for task planning

**Next**: `/sdd.plan`

**Documentation**: [skills/sdd.spec/SKILL.md](./skills/sdd.spec/SKILL.md)

---

### /sdd.plan

**Generate, refine, and approve implementation tasks**

| Mode | Usage | Behavior |
|------|-------|----------|
| Express | `/sdd.plan` | Auto-generate, auto-choose balanced strategy, auto-approve |
| Standard | `/sdd.plan` | Generate, review, choose strategy, approve |
| All | `/sdd.plan` | Generate only (with granular flags) |
| All | `/sdd.plan --refine` | Interactive refinement |
| All | `/sdd.plan --approve` | Approve and set strategy |
| All | `/sdd.plan --resume` | Resume interrupted session |

**What it does**:
- Generates 15-30 granular tasks from specs
- Creates dependency graph
- **AUTO-TASK-E2E**: If `testing.e2e.enabled: true` in meta.md AND functional spec contains E2E scenarios (`### E2E-N:`), generates E2E test task using E2E test framework
- Proposes 3 execution strategies:
  - Sequential: Lowest tokens (~80K)
  - Batched: Balanced (~100K tokens) - recommended
  - Parallel: Fastest time (~140K tokens)
- User chooses based on deadline/token budget

**Token Budget**: ~80K-140K tokens depending on strategy

**Output**: Tasks approved with execution strategy

**Next**: `/sdd.test`

**Documentation**: [skills/sdd.plan/SKILL.md](./skills/sdd.plan/SKILL.md)

---

### /sdd.test

**Write and approve tests before implementation (tests-first gate)**

**What it does**:
- Derives unit/integration tests from approved specs and tasks
- Verifies the new tests fail before production implementation (red phase)
- Records the approved test contract in `4-tests/`
- Requires human approval before `/sdd.build`

**Next**: `/sdd.build`

---

### /sdd.build

**Implement feature tasks**

| Mode | Usage | Behavior |
|------|-------|----------|
| Express | `/sdd.build` | Implement all without pauses, auto-fix errors |
| Standard | `/sdd.build` | Progress reports, pause on errors |
| All | `/sdd.build task TASK-001` | Single task |
| All | `/sdd.build phase 2` | Single phase |
| All | `/sdd.build --layer 1` | Execute only Layer 1 (local) |
| All | `/sdd.build --layer 2` | Execute Layers 1-2 (local + platform) |
| All | `/sdd.build --resume` | Resume interrupted session |
| All | `/sdd.build --next` | Auto-continue with next pending task |

**What it does**:
- Reads approved execution strategy from tasks.json
- **Executes by layer**:
  - Layer 1: Local (works on machine)
  - Layer 2:  (integrates services)
  - Layer 3: Quality (validations)
- Implements tasks respecting dependencies within each layer
- **Commits per layer** when all layer tasks complete
- Runs tests after each task
- Updates tasks.json continuously

**Layer-based execution**:
```
📦 Layer 1 (Local) → commit
☁️ Layer 2 (CI Pipeline) → commit
🔒 Layer 3 (Quality) → commit
<signal>ALL_TASKS_COMPLETE</signal>
```

**Complexity**: High (depends on feature size and task count)

**Output**: All tasks implemented, tested, committed by layer

**Next**: `/sdd.finish` (then optionally `/sdd.pr`)

**Documentation**: [skills/sdd.build/SKILL.md](./skills/sdd.build/SKILL.md)

---

### /sdd.finish

**Validate and archive completed feature**

```bash
/sdd.finish
```

**What it does**:
- Runs all validators:
  - Task completion
  - code compliance (MANDATORY)
  - Tests passing (MANDATORY)
  - Code quality
- Generates summary documentation
- Archives from `sdd/wip/` to `sdd/features/`
- Shows final metrics

**Token Budget**: ~5K-10K tokens

**Output**: Feature archived with documentation

**Documentation**: [skills/sdd.finish/SKILL.md](./skills/sdd.finish/SKILL.md)

**Next (optional)**: `/sdd.pr` — draft pull request, human approval, publish via `gh`

---

### /sdd.pr

**Draft and open pull request (human-gated)**

```bash
/sdd.pr
/sdd.pr [feature-name]
/sdd.pr --draft
```

**What it does**:
- Builds PR body from SDD artifacts (`spec`, `tasks`, `tests`, commits)
- Uses project `.github/pull_request_template.md` when present, else pack template
- Writes `sdd/wip/<feature>/pr-draft.md`
- **Pauses** for approve / deny / Outros (adjustments)
- Asks **target base branch** (master, main, develop, or custom)
- Runs `gh pr create` only after explicit approval

**Pre-requisite**: Feature implemented; commits on feature branch; `gh` authenticated (or copy draft manually).

**Template**: [`framework/templates/pull-request-template.md`](./templates/pull-request-template.md)

**Documentation**: [commands/sdd.pr.md](../commands/sdd.pr.md)

---

## Utility Commands

### /sdd.check

**View status, progress, validation**

| Mode | Usage | Behavior |
|------|-------|----------|
| Express | `/sdd.check` | Compact one-line status |
| Standard | `/sdd.check` | Detailed status with metrics |
| All | `/sdd.check task TASK-001` | Task details |
| All | `/sdd.check --sync` | Verify layer consistency + propose fixes (y/n) |
| All | `/sdd.check --compliance` | Verify /tests/lint + propose fixes (y/n) |
| All | `/sdd.check --project` | Validate PROJECT.md against standards |
| All | `/sdd.check --resume` | List all resumable sessions |
| All | `/sdd.check --resume --last` | Resume last interrupted session |

**What it shows**:
- Current phase and progress
- Task completion status
- Time metrics and velocity
- Quality metrics (tests, coverage)
- Blockers and next actions
- Local session stats (sessions, tokens)

**Documentation**: [skills/sdd.check/SKILL.md](./skills/sdd.check/SKILL.md)

---

### /sdd.list

**List all features**

```bash
/sdd.list             # List WIP features
/sdd.list --all       # Include completed features
```

Shows: feature name, phase, progress, blockers.

**Documentation**: [skills/sdd.list/SKILL.md](./skills/sdd.list/SKILL.md)

---

### /sdd.rollback

**Undo changes / Revert feature to previous phase / Go back**

> Use this command to: deshacer cambios, revertir, volver atrás, undo, go back, revert changes

```bash
/sdd.rollback              # Show current phase, ask target
/sdd.rollback 2            # Rollback to phase 2 (technical)
/sdd.rollback --task TASK-XXX  # Revert specific task
/sdd.rollback --phase N    # Revert to end of phase N
```

**Common use cases**:
- Want to undo implementation and go back to planning
- Need to revert a specific task's changes
- Made a mistake and want to start over from a checkpoint

**Safety features**:
- Creates snapshot before rollback
- Archives affected phases (never deletes)
- Records reason in audit trail
- **Intelligent Revert**: Git-aware rollback by task or phase

**Documentation**: [skills/sdd.rollback/SKILL.md](./skills/sdd.rollback/SKILL.md)

---

### /sdd.cancel

**Cancel feature entirely**

```bash
/sdd.cancel
```

Archives all work to `.cancelled/` folder with reason.

**Documentation**: [skills/sdd.cancel/SKILL.md](./skills/sdd.cancel/SKILL.md)

---

### /sdd.fix

**Fix errors with horizontal consistency across ALL artifacts**

```bash
/sdd.fix                           # Interactive: paste error
/sdd.fix "error message"           # Direct: pass error inline
/sdd.fix --file ./error.log        # From file
```

**What it does**:
1. Analyzes error and traces to root cause
2. Assesses impact across ALL layers (functional spec, technical spec, tasks, code)
3. Proposes horizontal fix to maintain consistency
4. Updates all affected artifacts atomically
5. Re-runs tests to confirm fix
6. **Consistency check** (mandatory) - verifies all artifacts are aligned

**Key principle**: A fix is NOT just code - it propagates to specs and tasks to keep everything consistent.

| Mode | Behavior |
|------|----------|
| Express | Auto-assess impact, auto-apply to all layers |
| Standard | Show impact assessment, confirm, apply all layers |
| Standard | Choose which layers to update, manual control |

**Documentation**: [skills/sdd.fix/SKILL.md](./skills/sdd.fix/SKILL.md)

---

### /sdd.backlog

**Manage technical backlog (TODOs, Debt, Ideas)**

```bash
/sdd.backlog                     # List all items
/sdd.backlog list                # List with filters
/sdd.backlog add                 # Add new item interactively
/sdd.backlog pick                # Create feature from backlog item
/sdd.backlog resolve <ID>        # Mark item as resolved
```

**What it does**:
- Maintains centralized backlog in `sdd/backlog.md`
- Three item types: TODO, DEBT, IDEA
- Priority levels: Critical, High, Medium, Low
- Auto-capture during `/sdd.build` when patterns detected
- Create features directly from backlog items

**Item Types**:
| Type | ID Format | Purpose |
|------|-----------|---------|
| **TODO** | `TODO-001` | Deferred improvements |
| **DEBT** | `DEBT-001` | Technical debt |
| **IDEA** | `IDEA-001` | Future enhancements |

**Auto-capture**:
During `/sdd.build`, when improvement patterns are detected (TODO comments, code smells, etc.), the agent prompts:
- `[F] Fix now` - Address immediately
- `[T] TODO` - Add to backlog
- `[D] DEBT` - Add as technical debt
- `[I] IDEA` - Add as enhancement idea
- `[S] Skip` - Ignore (intentional)

**Documentation**: [skills/sdd.backlog/SKILL.md](./skills/sdd.backlog/SKILL.md)

---

## Import & Analysis Commands

### /sdd.import

**Import existing specifications**

```bash
/sdd.import ./api.yaml        # Import single file
/sdd.import ./docs/           # Import directory
/sdd.import                   # Interactive mode
```

**Supports**: OpenAPI, Markdown, JSON Schema

**Documentation**: [skills/sdd.import/SKILL.md](./skills/sdd.import/SKILL.md)

---

### /sdd.reverse-eng

**Reverse engineer existing codebase**

```bash
/sdd.reverse-eng                      # Analyze current directory
/sdd.reverse-eng ./path               # Analyze specific path
/sdd.reverse-eng --focus api,database # Focus areas
```

**What it does** (4 phases):
- **Phase 1**: Extract raw data from existing docs/specs AND code (both mandatory)
- **Phase 2**: Basic cross-validation, calculate coverage %
- **Phase 2.5**: Deep cross-validation (field-by-field comparison)
- **Phase 3**: Synthesize specs with 5-level confidence indicators

**Output**:
- `sdd/extracted/raw/` - Raw extraction data
- `sdd/extracted/DOCUMENTATION_GAPS.md` - Coverage analysis
- `sdd/extracted/DISCREPANCIES_REPORT.md` - Field-level validation
- `sdd/extracted/functional-spec.md` - With confidence indicators
- `sdd/extracted/technical-spec.md` - With confidence indicators

**5-Level Confidence System**:
- ✅✅ VERIFIED: Found in both, fields match
- ✅⚠️ PARTIAL: Found in both, fields differ
- 🔸 CODE_ONLY: Found only in code (reliable)
- ⚠️ DOCS_ONLY: Found only in  (verify)
- ❓ UNKNOWN: Insufficient info (do not use)

**Documentation**: [skills/sdd.reverse-eng/SKILL.md](./skills/sdd.reverse-eng/SKILL.md)

---

## Command Flow by Mode

### Express (1-2 commands)

```bash
# Option 1: Single command
/sdd.go "add user authentication"

# Option 2: Resume interrupted workflow
/sdd.go --resume                       #

# Option 3: Step by step (auto-advances)
/sdd.start "user-auth" --express
/sdd.spec → /sdd.plan → /sdd.test → /sdd.build → /sdd.finish
```

### Standard (tests-first)

```bash
/sdd.start "user-auth"
/sdd.spec      # Interactive, confirmations
/sdd.plan      # Review, choose strategy
/sdd.test      # Write, verify red, and approve tests
/sdd.build     # Progress reports
/sdd.finish    # Validation summary
```

### Granular Control (optional flags)

```bash
/sdd.start "user-auth"
/sdd.spec functional
/sdd.spec functional --include
/sdd.spec functional --approve
/sdd.spec technical
/sdd.spec technical --include
/sdd.spec technical --approve
/sdd.plan
/sdd.plan --refine
/sdd.plan --approve
/sdd.build phase 1
/sdd.build task TASK-005
/sdd.build phase 2
/sdd.check --compliance
/sdd.finish
```

---

## Quick Reference

| Want to... | Use Command |
|------------|-------------|
| Complete feature automatically | `/sdd.go "description"` |
| Start new feature (standard) | `/sdd.start "name"` |
| Start MVP/prototype (lite) | `/sdd.start "name" --lite` |
| Create specifications | `/sdd.spec` |
| Generate tasks | `/sdd.plan` |
| Implement feature (all layers) | `/sdd.build` |
| Implement only local layer | `/sdd.build --layer 1` |
| Implement local +  | `/sdd.build --layer 2` |
| Finish and archive | `/sdd.finish` |
| Open pull request | `/sdd.pr` |
| Check progress | `/sdd.check` |
| List features | `/sdd.list` |
| Rollback phase | `/sdd.rollback` |
| Fix runtime errors | `/sdd.fix` |
| Manage backlog | `/sdd.backlog` |
| Create feature from backlog | `/sdd.start --from-backlog TODO-001` |
| Reopen completed feature | `/sdd.start --reopen 003` |
| Reopen to specific phase | `/sdd.start --reopen 003 --phase 2` |
| Verify layer consistency | `/sdd.check --sync` |
| Verify /tests/lint | `/sdd.check --compliance` |
| Validate PROJECT.md | `/sdd.check --project` |
| Resume interrupted session | `/sdd.check --resume --last` |
| Continue with next task | `/sdd.build --next` |
| Revert specific task | `/sdd.rollback --task TASK-XXX` |
| Import specs | `/sdd.import` |
| Analyze codebase | `/sdd.reverse-eng` |
| Manage skill hooks | `/sdd.skill list` |
| Get help | `/sdd.help` |

---

### /sdd.skill

**Manage third-party skill hooks in the SDD workflow**

```bash
/sdd.skill list                                          # List all hooks by phase
/sdd.skill connect <name> --phases build,finish          # Register hook in repo config
/sdd.skill connect <name> --phases build --user          # Register hook in user config
/sdd.skill disconnect <name>                             # Remove hook from repo config
/sdd.skill disable <name>                                # Disable without removing
/sdd.skill enable <name>                                 # Re-enable a disabled hook
```

**What it does**:
- Manages external skill integrations as hooks in the SDD workflow phases
- 3-layer hook resolution: auto-declaration (skill frontmatter), repo config (`.claude/`), user config (`~/.development-agents/`)
- Hooks attach to phases: `spec-functional`, `spec-technical`, `plan`, `build`, `finish`
- Two hook modes: `required` (always invoked) or `available` (LLM decides relevance)

**Flags**:
| Flag | Description |
|------|-------------|
| `--phases` | Comma-separated phases to attach the hook |
| `--trigger` | When to run: `before-start`, `after-implementation`, `before-approval` (default) |
| `--priority` | 0-100, lower runs first (default: 50) |
| `--mode` | `required` or `available` (default) |
| `--user` | Apply to user config instead of repo config |

**Best for**: Teams with custom validators, linters, or architectural rules that need to run at specific workflow phases

**Documentation**: [skills/sdd.skill/SKILL.md](./skills/sdd.skill/SKILL.md)

---

## Help Command

### /sdd.help

**Show command reference and help**

```bash
/sdd.help                    # Show all commands
/sdd.help [command]          # Help for specific command
/sdd.help workflow           # Show workflow diagram
```

**What it shows**:
- All 17 commands organized by category
- Usage examples for each command
- Workflow diagrams
- Links to detailed documentation

**Documentation**: [skills/sdd.help/SKILL.md](./skills/sdd.help/SKILL.md)

---

## Migration from OpenSpec

| OpenSpec | SDD Kit |
|----------|--------------|
| `openspec init` | `/sdd.start` or `/sdd.go` |
| `openspec generate` | `/sdd.spec` |
| `openspec implement` | `/sdd.build` |

---

## See Also

- [WORKFLOW.md](./WORKFLOW.md) - Complete workflow guide
- [QUICK_REFERENCE.md](./QUICK_REFERENCE.md) - One-page cheat sheet
- [Individual command docs](./skills/) - Detailed documentation per command
