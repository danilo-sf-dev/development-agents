---
name: sdd-kit-expert
description: Expert on SDD Kit framework for Spec-Driven Development. This is a SKILL (invoke via Skill tool, NOT Task/subagent). Use when user invokes /sdd.* commands, asks about spec-driven development, functional/technical specifications, task planning, or feature implementation workflow. **TRIGGER ON** project, spec, functional spec, technical spec, SDD, feature workflow.
---

# SDD Kit Expert

> **SKILL**: Framework knowledge base for SDD workflow. Invoke with `Skill("sdd-kit-expert")`. Do NOT use `Task(subagent_type=...)` — this is a Skill, not a subagent.

You are an expert on the SDD Kit framework for Spec-Driven Development (SDD).

---

## ⛔ CRITICAL: Structure Requirements (NEVER VIOLATE)

> **These rules are MANDATORY for ALL commands. Violating them = broken workflow.**

### 1. Folder Structure (EXACT)

```
sdd/
├── wip/                              # Work In Progress (active features)
│   └── YYYYMMDD-feature-name/             # Feature folder with date prefix
│       ├── 1-functional/             # Phase 1: WHAT
│       │   └── spec.md               # Functional spec file
│       ├── 2-technical/              # Phase 2: HOW
│       │   └── spec.md               # Technical spec file
│       ├── 3-tasks/                  # Phase 3: Tasks
│       │   └── tasks.json            # Task list
│       ├── 4-tests/                   # Phase 4: Tests-first gate
│       │   └── test-plan.md           # Approved test contract
│       ├── 5-implementation/          # Phase 5: Code
│       │   └── progress.md           # Progress tracking
│       └── meta.md                   # Feature metadata
├── features/                         # Completed features (archived)
├── PROJECT.md                        # Project configuration
└── backlog.md                        # TODO/DEBT/IDEA items
```

### 2. Feature Naming (MANDATORY)

- Format: `YYYYMMDD-feature-name` where YYYYMMDD is the creation date
- Example: `20260120-payment-gateway`, `20260203-user-auth`, `20260325-notifications`
- Date prefix is organizational (for ordering), feature name is the identifier
- `/sdd.start` MUST create: `sdd/wip/YYYYMMDD-feature-name/`

### 3. File Naming (EXACT)

| Phase | File Path | File Name |
|-------|-----------|-----------|
| Functional | `sdd/wip/YYYYMMDD-feature/1-functional/` | `spec.md` |
| Technical | `sdd/wip/YYYYMMDD-feature/2-technical/` | `spec.md` |
| Tasks | `sdd/wip/YYYYMMDD-feature/3-tasks/` | `tasks.json` |
| Progress | `sdd/wip/YYYYMMDD-feature/4-implementation/` | `progress.md` |
| Metadata | `sdd/wip/YYYYMMDD-feature/` | `meta.md` |

**❌ WRONG**: `functional-spec.md`, `technical-spec.md`, `feature-spec.md`
**✅ CORRECT**: `spec.md` inside the numbered phase folder

### 4. Branch Creation (MANDATORY)

- `/sdd.start` MUST create branch: `feature/feature-name`
- Branch created BEFORE any file creation
- Example: `git checkout -b feature/payment-gateway`

### 5. Language (Respect PROJECT.md)

- Read `sdd/PROJECT.md` field `language.specs`
- If `es` → Generate specs in Spanish
- If `en` → Generate specs in English
- If `pt` → Generate specs in Portuguese
- If missing → Default to English (`en`)

### 6. Phased Workflow (NEVER SKIP)

**Standard Mode** (manual control):
> Canonical pipeline, gates, and diagram: `framework/PIPELINE.md`

```
/sdd.start → /sdd.spec functional → /sdd.spec technical → /sdd.plan → /sdd.test → /sdd.build → /sdd.finish → /sdd.pr (optional)
```

**Express Mode** (orchestrated):
```
/sdd.go "feature-name"  ← Orchestrates ALL phases automatically
```

**❌ WRONG**: Doing everything in `/sdd.start` (start only creates folder + branch)
**✅ CORRECT**: Each command does ONE phase, then waits for next command
**✅ ALSO CORRECT**: `/sdd.go` orchestrates all phases in express mode

---

## Framework Overview

SDD Kit is a command-based framework that helps teams build software predictably with AI coding assistants. It enforces a tests-first workflow:

1. **Functional Spec** (WHAT) - User experience, user stories, acceptance criteria
2. **Technical Spec** (HOW) - Architecture, APIs, data models, project services
3. **Tasks** - Granular implementation tasks with dependencies (tasks.json)
4. **Tests-first** - Approved tests fail before implementation
5. **Implementation** - Code generation with mandatory quality gates

## Key Commands

| Command | Purpose |
|---------|---------|
| `/sdd.go` | **Express mode** - orchestrates start→spec→plan→test→build→finish |
| `/sdd.start` | Initialize new feature (also `--reopen` for completed features) |
| `/sdd.spec` | Create functional/technical specs |
| `/sdd.plan` | Generate implementation tasks |
| `/sdd.test` | Write and approve tests (tests-first gate) |
| `/sdd.build` | Implement tasks until approved tests pass |
| `/sdd.finish` | Validate and archive |
| `/sdd.pr` | Draft PR → human approve → open on GitHub |
| `/sdd.check` | View progress and consistency |
| `/sdd.fix` | Fix errors across all layers |
| `/sdd.list` | List all features |
| `/sdd.cancel` | Cancel current feature |
| `/sdd.rollback` | Rollback to previous state |
| `/sdd.backlog` | Manage TODO/DEBT/IDEA backlog |
| `/sdd.import` | Import existing specs |
| `/sdd.reverse-eng` | Document existing codebase |
| `/sdd.help` | Get framework help |
| `/sdd.project` | View/edit PROJECT.md, `--view` opens framework viewer |
| `/sdd.hub` | Multi-app hub orchestrator (start, spec, plan, build, check, list, finish, cancel, go, sync) |

## Execution Modes

- **Express** (`/sdd.go` or `--express`): Minimal interaction, auto-advance, 3-5 critical questions
- **Standard** (default): Balanced control, confirmations at key points

## Layer-Based Execution

Tasks are organized into layers for proper sequencing:

| Layer | Name | What | When |
|-------|------|------|------|
| 1 | Local | Code, unit tests | First |
| 2 | Integration | Service integration, project CI | After L1 |
| 3 | Quality | Code review, security, performance | After L2 |

## Platform / stack resolution

Stack, language, and infra come from the **target project**:

1. `development-agents/framework/tools/detect-language.sh` + `detect-stack.sh`
2. `sdd/PROJECT.md` (platform.type, conventions, optional skills)
3. Technical spec services / infra sections

Do **not** require vendor marketplace plugins or a fixed service catalog.

### Optional integrations (only if PROJECT.md / repo configures them)

- Stack expert skills (Java, Node, Go, Python, Rust, frontend, mobile)
- Code review / security scanner MCPs
- E2E tooling (optional — never mandatory)
- Project infra CLI or IaC already used in the repo

### STACK-FROM-PROJECT

Prefer services and libraries already declared in PROJECT.md and the technical spec.
Never invent a corporate platform stack when the repo uses something else.
| `sdd-code-reviewer` | Security rules and vulnerability review |
| `sdd-validator` | Build validation, test execution, code compliance |

### Subagents (Task Delegation)

| Subagent | Purpose | Used By |
|----------|---------|---------|
| `sdd-validator-runner` | Isolated quality gates execution | `/sdd.build`, `/sdd.finish` |
| `sdd-layer-analyzer` | Cross-layer consistency validation | `/sdd.check --sync`, `/sdd.fix` |
| `sdd-debugger` | Deep debugging and root cause analysis | `/sdd.fix` for complex bugs |
| `sdd-project-wizard` | Interactive PROJECT.md creation | `/sdd.start` when PROJECT.md missing |
| `sdd-mcp-setup` | Host-agnostic MCP setup (Atlassian read-only) | `/sdd.mcp` |
| `context-guardian` | Context and tool delegation for efficiency | All specs requiring external documentation |
| `sdd-system-designer` | Architecture decisions, multi-stack options | `/sdd.spec technical` |
| `sdd-explorer` | Project service discovery and configuration | `/sdd.spec technical` |
| `sdd-large-test-writer` | E2E test generation via E2E | `/sdd.test` or `/sdd.build` if E2E deferred |
| `sdd-small-test-writer` | Unit and integration tests | `/sdd.test` (tests-first) |
| `sdd-implementer` | Code implementation from specs | `/sdd.build` for implementation tasks |
| `sdd-backlog-manager` | Backlog CRUD operations | `/sdd.backlog` |
| `sdd-explorer` | Codebase exploration + code ownership mapping | `/sdd.reverse-eng` |

### GenAI Offloaded Tools

| Tool | Purpose | Used By |
|------|---------|---------|
| `genai-detect-gaps.sh` | Detect missing spec info by feature type | `/sdd.spec` Completeness Check |
| `genai-check-compliance.sh` | Pre-process code compliance validation | `sdd-explorer` |
| `genai-select-arch-pattern.sh` | Pre-select architecture pattern | `sdd-system-designer` |
| `genai-analyze-e2e.sh` | Analyze E2E test scenarios | `/sdd.plan` E2E planning |
| `genai-analyze-layers.sh` | Task layer classification | `/sdd.plan` layer assignment |
| `genai-compact-state.sh` | Context compaction (MINIMAL/STANDARD/FULL) | Context Budget Protocol |
| `genai-resolve-conflicts.sh` | Resolve spec cross-reference conflicts | `/sdd.spec` conflict detection |
| `genai-validate-project.sh` | Validate PROJECT.md conventions | `/sdd.project` validation |

## Quality Gates

Mandatory validations at every phase:

1. **Per-Task Code Review** - code review tool after EVERY file written
2. **Container Compliance** - Dockerfile must use the project container registry (from PROJECT.md) images
3. **CI Pipeline** - Must pass before finish
4. **Performance Analysis** - sdd-performance-expert on full codebase
5. **Security Analysis** - sdd-code-reviewer on full codebase

## Key Features

- **External API Auto-Discovery** - Automatically look up API docs/contracts when third-party APIs are mentioned (via whatever internal service directory or API catalog the project has configured)
- **E2E Testing** - Opt-in E2E test generation via the project's E2E test framework
- **Scaffolding Cleanup** - Auto-cleanup example/boilerplate code left over from project scaffolding tools
- **Greenfield/Brownfield Detection** - Adapts workflow based on project state
- **tasks.json** - Single source of truth for task tracking
- **LOCAL-SETUP Tasks** - Mock project services during local development
- **Secrets Management** - Mandatory section in technical specs
- **Spec Gap Detection** - Context-aware gap detection via `genai-detect-gaps.sh`
- **Audio Capture** - Record voice specs via `/sdd.spec --audio` with Whisper transcription
- **Compression Levels** - MINIMAL/STANDARD/FULL context compaction via `genai-compact-state.sh`
- **Agent Boundaries** - 3-tier system in `standards/boundaries.md`
- **Spec Reference Annotations** - Cross-feature references for brownfield projects (see below)
- **Feature Reopen** - `/sdd.start --reopen` brings completed features back to WIP (reverse dependency checking as gate)
- **Feature Rename** - `/sdd.start --rename` renames current feature (folder + meta.md)
- **Framework Viewer** - Interactive HTML viewer for project state (`/sdd.project --view`), outputs to `/tmp/project-viewer/`
- **Multi-Stack Architecture Options** - During `/sdd.spec technical`, `sdd-system-designer` presents 2-3 architecture options with ASCII diagrams and pros/cons via `AskUserQuestion` (Standard mode + technical profile). Selected option recorded as ADR.
- **ASCII Architecture Diagrams** - Mandatory in technical spec approval: distinctive shapes per component type (cylinders for databases, segmented tubes for queues)
- **Database Migration Branch** - Auto-detects DB migrations in technical spec (Step 5.5), `/sdd.build` creates `migration/*` branch from master, runs `your-migration-tool init`, then returns to feature branch
- **Code Ownership Mapping** - During `/sdd.reverse-eng`, maps each component to primary/supporting/shared files with confidence scores (0.2-1.0) for brownfield development
- **Smart Backlog Workflow Modes** - `/sdd.backlog pick` supports 3 modes for DEBT/TODO items: full pipeline, technical-only (auto-generates functional), or tasks-only (auto-generates both specs)

### Spec Reference Annotations (v2.1.0)

For brownfield projects where features modify existing behavior:

| Annotation | Purpose | Example |
|------------|---------|---------|
| `<!-- overrides: path#section -->` | Completely replaces existing behavior | New login flow replaces old |
| `<!-- extends: path#section -->` | Adds to existing behavior (backward compatible) | New refund rules added |
| `<!-- deprecates: path#section -->` | Marks existing behavior as obsolete | Old endpoint deprecated |

**Usage in specs**:
```markdown
## User Stories

<!-- overrides: sdd/features/auth-v1/functional-spec.md#login-user-story -->
As a user, I can now log in using Google OAuth in addition to email/password.
```

**When to use**: Only when this feature intentionally modifies, extends, or deprecates functionality defined in another feature's spec. `/sdd.spec` conflict detection will suggest annotations when conflicts are found.

## Hub Workflow (Multi-app)

For teams with multiple apps collaborating in a domain, `/sdd.hub` coordinates specs, planning, and build across apps from a central hub repo.

- **Detection**: `sdd/PROJECT.md` with `## Hub members` table → hub mode
- **Flow**: `/sdd.hub start` → `spec functional` → `spec technical` → `plan` → `build` → `finish`
- **Child specs**: Hub tech spec sections exported as standard kit specs into each app
- **Coordination manifest**: `tasks.json` with `type: coordination` and dependency layers
- **Compatibility**: App-level commands (`/sdd.start`, `/sdd.build`, etc.) work unchanged inside member apps
- **Guard**: `/sdd.go` detects hubs and redirects to `/sdd.hub`

> **Detailed reference**: Read `hub-guide.md` in this skill directory for complete hub documentation.

## Core Principles

1. **Functional = WHAT**: User experience, no technology details
2. **Technical = HOW**: Architecture, technology choices, implementation details
3. **Single Source of Truth**: Specs and tasks.json define what gets built
4. **Quality Gates**: Validation at every phase transition
5. **Horizontal Consistency**: Changes propagate across all layers
6. **Context Budget Protocol**: Monitor usage, delegate at 60%, compact at 85%
7. **Validator Independence**: Validation runs in isolated context (sdd-validator-runner)

## When to Use This Skill

- User asks about `/sdd.*` commands
- User wants to create functional or technical specs
- User needs help with spec-driven development workflow
- User asks about feature implementation phases
- User wants to understand the framework structure
- User needs guidance on project services selection

For detailed command documentation, read the skill files in `~/.development-agents/skills/sdd.*/SKILL.md` or the framework package.
