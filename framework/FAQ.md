# SDD Kit - FAQ

Frequently Asked Questions about Specification-Driven Development and the SDD Kit framework.

---

## General Questions

### What is SDD (Specification-Driven Development)?

SDD is a methodology where development follows a structured flow:
1. **Spec** - Define what to build (functional & technical specifications)
2. **Plan** - Break down into tasks
3. **Build** - Implement with Platform AI docs assistance
4. **Finish** - Validate, test, and prepare for deployment

It emphasizes documentation-first development, ensuring features are well-defined before coding begins.

### Why use SDD instead of just coding directly?

- **Clarity**: Specifications catch misunderstandings early
- **Traceability**: Each line of code traces back to a requirement
- **AI-Friendly**: AI agents work better with clear specifications
- **Team Alignment**: Everyone understands what's being built
- **Quality**: Built-in validation at each phase

### Is SDD only for new projects?

No. SDD works for:
- **Greenfield**: New projects from scratch
- **Brownfield**: Existing projects (use `/sdd.reverse-eng` to document first)
- **Features**: Individual features in any project

### Can I use the kit for purely technical work (no functional requirements)?

Yes! When you register a DEBT or TODO item (e.g., adding an adapter, updating dependencies, migrating a provider) and run `/sdd.backlog pick`, the framework detects it's purely technical work and offers 3 workflow modes:

| Mode | What it does | Best for |
|------|-------------|----------|
| **Pipeline completo** | Full spec interviews | Complex changes needing discovery |
| **Solo spec técnica** | Auto-generates functional spec, you do technical interview | Most technical work |
| **Directo a tareas** | Auto-generates both specs, you only approve tasks | Simple, well-defined changes |

The key principle: **specs are never skipped, just auto-generated**. This preserves full traceability — `/sdd.check`, `/sdd.finish`, and all validation scripts work normally. The difference is how much interaction is needed from you.

> **Note**: IDEA items always get the full pipeline because they need functional discovery.

---

## Reverse Engineering

### What is `/sdd.reverse-eng` and when should I use it?

`/sdd.reverse-eng` analyzes existing code and generates specifications from it. Use it when:
- Joining a project without documentation
- Starting SDD on an existing codebase (brownfield)
- Need to understand legacy code before modifying it
- Want to create specs for code that was written without SDD

### How does reverse engineering work?

The agent:
1. Scans the codebase structure
2. Identifies patterns, APIs, data models
3. Generates functional and technical specs
4. Assigns confidence levels (1-5) to each finding

### What are confidence levels?

| Level | Meaning | Action |
|-------|---------|--------|
| 5 | Certain (from code/tests) | Trust as-is |
| 4 | High confidence (clear patterns) | Minor review |
| 3 | Moderate (inferred) | Verify with team |
| 2 | Low (assumptions) | Needs validation |
| 1 | Speculation | Requires confirmation |

### Should I review the generated specs?

Yes, always. Reverse engineering is a starting point, not the final truth. Review with someone who knows the codebase to validate assumptions.

### Can I reverse-engineer only part of a project?

Yes. You can scope it:
```
/sdd.reverse-eng --scope src/payments/
```

This focuses on a specific module instead of the entire codebase.

### After reverse-eng, what's next?

1. Review generated specs in `sdd/specs/`
2. Validate with team members
3. Use `/sdd.start` for new features (now brownfield mode)

---

## Execution Modes

### What modes are available?

| Mode | Command | Best For |
|------|---------|----------|
| **Express** | `/sdd.go` | Quick prototypes, familiar patterns |
| **Standard** | `/sdd.start "feature"` | Most features, balanced control (DEFAULT) |

### When should I use Express mode (`/sdd.go`)?

Use Express when:
- Building a quick prototype or POC
- The feature is straightforward and well-understood
- You trust the Platform AI docs to make reasonable decisions
- Speed is more important than control
- You're experienced with SDD and the codebase

Express mode runs autonomously with minimal interaction.

### Can I switch modes mid-feature?

No. Mode is set at `/sdd.start` and is immutable. If you need to switch:
1. `/sdd.cancel` the current feature
2. Restart with the desired mode

### What about project types (Prototype/MVP/Production)?

Project type affects **testing**, not workflow mode:

| Type | Tests | E2E E2E | Code Review |
|------|-------|---------|-------------|
| Prototype | None | No | Optional |
| MVP | Critical path only | No | Yes |
| Production | Full (80%+) | Opt-in | Mandatory |

You can use any project type with any mode.

### Which combination should I use?

| Scenario | Mode | Project Type |
|----------|------|--------------|
| Quick demo for stakeholders | Express | Prototype |
| Feature for beta users | Standard | MVP |
| Production release | Standard | Production |
| Exploring an idea | Express | Prototype |
| Complex integration | Standard | Production |

---

## Installation & Setup

### How do I install the framework?

```bash
pip install sdd-kit
sdd-kit init claude  # or cursor, codex, project
```

### What Platform AI docs tools are supported?

| Tool | Command | Skills Location |
|------|---------|-----------------|
| Claude Code | `sdd-kit init claude` | `~/.claude/skills/` |
| Cursor | `sdd-kit init cursor` | `~/.cursor/skills/` |

### Do I need to be on VPN?

Only if your organization's internal MCP servers (code review tool, E2E test framework, dependency security scanner, service directory, etc.) require it. This framework has no opinion on network setup — check with your platform/infra team about what's needed to reach whatever internal MCP servers your project uses.

### How do I configure MCP servers?

Configure the specific MCP servers your project actually uses (if any) following your MCP client's documentation (Claude Code, Cursor, etc.) and your organization's internal MCP endpoint URLs. Example shape:

```bash
claude mcp add --scope project --transport stdio <your-mcp-name> -- mcp-remote-proxy <your-org-mcp-endpoint> --transport http
```

None of these MCP servers are required by the framework itself — they're optional integrations you wire up if your org has them.

---

## Commands

### What's the difference between `/sdd.start` and `/sdd.go`?

| Command | Mode | Use Case |
|---------|------|----------|
| `/sdd.start` | Standard | Balanced control, phase-by-phase |
| `/sdd.go` | Express | Autonomous, minimal interaction |

Use `/sdd.start` when you want to review each phase. Use `/sdd.go` for quick prototypes.

### What's the difference between `/sdd.project` and `/sdd.check --project`?

| Command | Purpose | When to use |
|---------|---------|-------------|
| `/sdd.project` | **Create/initialize** PROJECT.md | When it doesn't exist or you want to configure team conventions |
| `/sdd.check --project` | **Validate** existing PROJECT.md | Verify configuration is valid and consistent |

They are complementary, not overlapping:
```
/sdd.project          → Creates PROJECT.md (interactive wizard)
/sdd.check --project  → Validates it's properly configured
```

### I ran `/sdd.start` but nothing happened

Check:
1. Are you in the project root? (not inside `.development-agents/`)
2. Is the  app created? (`project platform info`)
3. Are you logged in? (``)
4. Is VPN connected?

### How do I see my current features?

```
/sdd.list
```

Shows features in:
- `sdd/wip/` - Work in progress
- `sdd/features/` - Completed features
- `sdd/cancelled/` - Cancelled features

Also shows technical backlog summary from `sdd/backlog.md` (TODOs, DEBT, IDEAS).

### Can I work on multiple features at once?

Yes, but one at a time in your session. Each feature has its own folder in `sdd/wip/`.

### How do I cancel a feature?

```
/sdd.cancel <feature-name>
```

This moves it to `sdd/cancelled/` with a cancellation report.

---

## Specifications

### What goes in the functional spec?

- **User Stories**: Who, what, why
- **Acceptance Criteria**: Testable conditions
- **UI/UX Requirements**: If applicable
- **Business Rules**: Logic and constraints
- **Out of Scope**: What this feature does NOT do

### What goes in the technical spec?

- **Architecture**: System design
- **API Contracts**: OpenAPI specs
- **Data Models**: Database schemas
- **Dependencies**: Services, libraries
- **Security**: Auth, encryption
- **Performance**: SLOs, limits

### What knowledge sources does the framework use for specs

This is one of the most common questions. The framework uses **different sources depending on the phase and project type** (greenfield vs brownfield).

#### Functional spec — primarily user-driven

The functional spec is built through a **structured Platform AI docs interview** (4-6 questions). In this phase:

- **Greenfield projects**: the framework does not read code or previous specs. It relies entirely on your answers.
- **Brownfield projects**: `sdd.start` pre-analyzes the codebase structure with `analyze-structure.sh` and stores the result in `meta.md`, which provides context during the interview.

#### Technical spec — reads both code and previous specs

The technical spec phase is where the framework actively consults **both sources**:

1. **Existing code** (brownfield only): the Plan Mode step (Step 4.5) launches the `sdd-explorer` agent to scan endpoints, data models, architectural patterns,  SDK imports, and service configurations.
2. **Previous feature specs**: in the same step, the framework reads all specs in `sdd/features/` and `sdd/wip/` to extract data models, business rules, services, and endpoints — and to detect potential conflicts (duplicate tables, overlapping endpoints, etc.).
3. **Post-approval conflict detection**: after you approve the technical spec, `genai-resolve-conflicts.sh` cross-checks the new spec against all existing specs.

#### Summary of knowledge sources by phase

| Phase | Reads existing code | Reads previous specs | Mechanism |
|-------|:-------------------:|:--------------------:|-----------|
| Functional spec (greenfield) | No | No | AI interview only |
| Functional spec (brownfield) | Yes (structure) | No | `analyze-structure.sh` via `sdd.start` |
| Technical spec — Plan Mode | **Yes** (full scan) | **Yes** (all features) | `sdd-explorer` agent |
| Technical spec — generation | No | Yes (current feature) | `sdd-system-designer` agent |
| Post technical approval | No | **Yes** (cross-check) | `genai-resolve-conflicts.sh` |
| `/sdd.reverse-eng` | **Yes** (8-phase scan) | **Yes** (all sources) | `sdd-explorer` +  |

#### Source priority when conflicts exist

When the framework finds contradictions between sources, the priority order is:

**Code > Previous specs >  documentation > README**

#### Bootstrapping brownfield projects

For projects with existing code but no specs, run `/sdd.reverse-eng` first. This command performs an exhaustive 8-phase analysis that reads code,  documentation, and any existing documentation to generate initial functional and technical specs. Those generated specs then serve as "previous specs" for future features.

### My spec is too long, is that a problem?

Long specs are fine. The framework handles them. However, consider:
- Breaking into smaller features
- Using ADRs for complex decisions
- Referencing external docs instead of copying

---

## Configuration

### What's the difference between PROJECT.md and governance.md?

| File | Location | Purpose | Editable? |
|------|----------|---------|-----------|
| `governance.md` | `~/.development-agents/standards/` | Framework **principles** (philosophy) | No |
| `PROJECT.md` | `sdd/` | Project **configuration** (values) | Yes |

**governance.md** defines the *philosophy*: spec-first, testing mandatory, AI-human collaboration, etc.

**PROJECT.md** defines your *preferences*: coverage threshold, tech choices, team conventions, etc.

> **Coming from SpecKit?** `PROJECT.md` is equivalent to SpecKit's `constitution.md`.

See [CONFIGURATION.md](./CONFIGURATION.md) for the full explanation.

### Do I need to configure PROJECT.md?

No. The framework uses **convention over configuration**. If you don't configure anything, sensible defaults apply (80% coverage, mandatory reviews, etc.).

Only uncomment and edit the sections you want to change.

### Can I override framework defaults?

Yes. Configure the value in `sdd/PROJECT.md` and register an override:

```yaml
coverage:
  min_coverage: 50

overrides:
  - standard: testing-strategy.md
    rule: "Minimum coverage 80%"
    project_value: 50
    reason: "Legacy codebase with gradual improvement plan"
```

Run `/sdd.check --project` to validate your configuration.

---

## Building

### `/sdd.build` is taking too long

The agent validates specs before coding. If stuck:
1. Check for spec ambiguities
2. Run `/sdd.check` to diagnose
3. Ensure dependencies are clear

### How do I skip tests during prototype?

When starting, select "Prototype" mode:
```
/sdd.start feature-name
> Select project type: [1] Prototype
```

Or add to `meta.md`:
```yaml
mode: prototype
testing: false
```

### Build failed, how do I recover?

```
/sdd.fix
```

This analyzes the failure and attempts to fix it. If it persists:
```
/sdd.rollback build
```

Then review specs and try again.

---

##  Integration

### "App not found in " error

The app must exist in  before using the framework:
1. Go to https://the project platform console (from PROJECT.md)/
2. Create the application
3. Run `/sdd.start` again

### "Not logged in" error

```bash

```

This opens a browser for authentication. After login, retry your command.

### How does the framework discover existing project services?

During `/sdd.spec technical`, when the architecture recommends project services
(KeyValueStore, MessageQueue, Cache, etc.), the framework:
1. Runs `project services <type> list` (CLI first,  for services without CLI list)
2. Shows you existing instances
3. Lets you choose: use existing or create new
4. If "create new": `/sdd.build` runs the creation automatically

Requirements: platform CLI installed, logged in, VPN connected.
If platform CLI unavailable, falls back to manual service naming.

### Which project services should I use?

Use the **project-services-architect** skill which classifies your needs and loads expert reference data for 6 service families:

| Service Family | Services |
|----------------|----------|
| Database | KeyValueStore, QKVS, Cache, MySQL, PostgreSQL, NoSQL, NewSQL, GraphDB, TSMetrics, Oracle, BigQuery, DS (12) |
| Communication | MessageQueue, Streams, Workqueues, Director, Jobs, Schedule Engine, Verdi Flows, Mails, Template Processing (9) |
| Storage | Object Storage, Audits, Media Storage, Entity Tracing (4) |
| Config | Config, Secrets, Feature Flags, Experiments, Rules Engine, Business Configs (6) |
| Runtime | Lock, Quotas, Rate Limit, CKaaS,  Schemas, Sequences ⚠️, Event Sourcing (7) |
| AI | GenIA Gateway (LLM inference), VectorDB (RAG/embeddings) (2) |

For code implementation snippets, the **project-snippets-expert** provides ready-to-use examples.

The architect classifies your needs first, then loads the appropriate reference domain.
Always query  for current documentation.

### How do I run tests in ?

```bash
project CI test
```

This runs tests in a container matching production environment.

---

## Troubleshooting

### Framework files are missing

```bash
sdd-kit init <tool> --force
```

This reinstalls the framework.

### "Working directory inside .sdd-kit" error

You're inside the framework folder. Run:
```bash
cd ..
```

Then retry your command.

### Specs were edited manually, now validation fails

Run:
```
/sdd.check
```

This validates and reports issues. Fix them or use:
```
/sdd.fix
```

### AI is hallucinating or making wrong assumptions

1. Make specs more explicit
2. Add constraints and rules
3. Use "MUST", "MUST NOT", "NEVER" for critical requirements
4. Reference existing code patterns

---

## Best Practices

### How detailed should specs be?

Rule of thumb:
- **Prototype**: Minimal, just user stories
- **MVP**: Moderate, key acceptance criteria
- **Production**: Detailed, full technical specs

### Should I commit `sdd/` folder?

Yes! The `sdd/` folder contains:
- Specifications (documentation)
- Progress tracking
- Feature history

It's valuable project documentation.

### How often should I run `/sdd.check`?

- Before `/sdd.build` (runs automatically)
- After manual spec edits
- When something feels wrong
- Before `/sdd.finish`

### Can I use SDD for bug fixes?

Yes, for complex bugs. For simple fixes:
1. Quick fix directly, or
2. Create a mini-spec for traceability

---

## Integration

### Does SDD work with CI/CD?

Yes. The framework generates:
- Test files (unit, integration)
- OpenAPI specs
- Deployment configs

These integrate with standard CI/CD pipelines.

### Can I use SDD with existing tests?

Yes. The framework:
- Respects existing test structure
- Adds new tests alongside
- Doesn't modify existing tests without asking

### How does SDD interact with code reviews?

1. Specs serve as PR context
2. Reviewers can validate against specs
3. Use code review tool for automated checks

---

## Getting Help

### Where can I get support?

1. `/sdd.help` - In-tool help
2. This FAQ
3. `RECOVERY.md` - Error recovery
4. **Slack Channels**:
   - `#open-beta-sdd-kit` - Framework usage and testing
   - `#spec-driven-development` - SDD methodology discussions
5. **[ AI](https://the project platform console (from PROJECT.md)/platform-ai)**: Ask questions about the documentation interactively

### How do I report bugs?

1. GitHub Issues: `github.com/your-org/sdd-kit`
2. Include: error message, steps to reproduce, framework version

### How do I request features?

Same as bugs - GitHub Issues with `[FEATURE]` prefix.

---

## Version Information

- **Current Version**: 1.7.2
- **Last Updated**: 2026-05-07
- **Changelog**: See `CHANGELOG.md`
