---
name: sdd.plan
description: Generate implementation tasks from approved specifications. Use when both functional and technical specs are approved and user is ready to break down work into executable tasks with effort estimates.
model: opus
argument-hint: "[--approve]"
---

### HOW TO READ THIS SKILL

When you see a block like this:

⛔ INVOKE TOOL (do not print this, CALL the tool):
AskUserQuestion(questions=[{...}])

This is a TOOL CALL you must execute, not content to display.

| WRONG | CORRECT |
|-------|---------|
| Bash(echo "1. Option A") | Directly call the AskUserQuestion tool |
| Print the JSON to terminal | Pass the parameters shown to the tool |

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

**Examples**:
```bash
/sdd.plan              # Generate and review tasks
/sdd.plan --approve    # Approve tasks and select strategy
```

**See also**: `/sdd.help plan` for detailed documentation

---

CRITICAL: USER INTERACTION RULES
When this skill shows JSON for AskUserQuestion, you MUST:
  1. CALL the AskUserQuestion TOOL with that exact JSON
  2. DO NOT print options using Bash (no echo, cat, printf)
  3. DO NOT ask "Which option?" as text
  4. Tables marked "REFERENCE ONLY" are for docs - do NOT print


## Pre-Requisites (BLOCKING)

| Check | Tool | On Failure |
|-------|------|------------|
| Spec conflicts resolved | `validate-spec-conflicts.sh` | Run `/sdd.spec` to resolve |
| Technical spec approved | Check `meta.md` | Run `/sdd.spec technical` |
| Context < 50% | `context-guardian` skill | Show advisory, proceed |

---

## Skill Hooks (Extension Points)

This skill supports external skill hooks at 3 trigger points.

**Resolution steps** (at each extension point):
1. Read `.claude/skill-hooks.json` and `development-agents/framework/skill-hooks.json`
2. Scan installed skills in `~/.claude/skills/*/SKILL.md` for `metadata` with `sdd-kit-*` keys
3. Merge with precedence: user override > repo config > auto-declaration
4. For each enabled hook matching phase=`plan` and the current trigger, ordered by priority:
   - If `hook.mode == "required"`: invoke `Skill("<hook.skill>")` with current feature context
   - If `hook.mode == "available"` (default): evaluate if the hook is relevant to the current feature. Only invoke if the feature context suggests it adds value. Skip silently if irrelevant.

| Trigger | When | Location in workflow |
|---------|------|---------------------|
| `before-start` | Before Step 1 | Before phase detection |
| `after-implementation` | After Step 5 | After tasks generated |
| `before-approval` | Before Step 7 | Before task approval |

---

## Workflow (Steps in Order)

### Extension point: before-start

> Resolve and invoke hooks for phase=`plan`, trigger=`before-start`.

### Step 1: Context Check + Phase Detection (Deterministic)

> **Use script for deterministic phase detection** - Saves ~500-1000 tokens vs manual parsing.

```bash
# Deterministic phase detection (FIRST - verify we're in correct phase)
phase_result=$(bash development-agents/framework/tools/detection/detect-phase.sh sdd/wip/[feature] --json)
current_stage=$(echo "$phase_result" | grep -o '"stage":"[^"]*"' | cut -d'"' -f4)

# Verify technical spec is approved (must be in phase 3+)
if [ "$current_stage" != "tasks" ] && [ "$current_stage" != "implementation" ]; then
    echo "❌ Technical spec not approved. Run /sdd.spec technical --approve first."
    exit 1
fi
```

Then invoke `Skill("context-guardian")` for context check.

| Threshold | Action |
|-----------|--------|
| < 50% | Proceed inline |
| 50-70% | Show advisory, use `genai-analyze-e2e.sh` for E2E detection |
| > 70% | Recommend compaction before `/sdd.build` |

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

### Step 4: Detect Services & Local Environment

> **SKIP for mobile** (`
Scan technical spec for project services (KeyValueStore, MessageQueue, MySQL, etc.) — **backend/web only**.

**Profile-aware behavior**:

| Profile | Database Question | Auto-Decision |
|---------|-------------------|---------------|
| `technical` | Ask: Container / Existing / Testcontainers | User chooses |
| `non-technical` | **DO NOT ASK** | Auto-select Container |

**For technical profile** - If relational DB detected (MySQL/PostgreSQL), use AskUserQuestion:
- "Spin up container (Recommended)"
- "Use existing database"
- "Testcontainers"

**For non-technical profile** - Auto-select with message:
```
✓ Base de datos local configurada automáticamente
```

Store choice in `tasks.json → local_config`.

### Step 5: Generate Tasks

**Design Decision Mapping**: For each task, identify which Design Decisions (DD-N) from the technical spec
directly affect its implementation. Add their IDs to the `design_decisions` field. This enables fresh agents
to load only the relevant decisions when implementing each task, preventing re-proposal of already-rejected
alternatives. If no DD applies to a task, set `design_decisions` to an empty array `[]`.

Generate tasks following these rules:

| Rule | Reference |
|------|-----------|
| **| **Test tasks by project type** | Read `meta.md → project_type.type` |
| **Layer assignment** | `sdd-validator` skill |
| **Quality gates (Layer 3)** | `sdd-validator` skill |
| **E2E detection** | **Deterministic script first** (see below) |

**Mandatory Tasks (Brownfield-aware)**:

> **FIRST**: Read `platform` from `meta.md` to determine which mandatory tasks apply.
> ```bash
> platform=$(grep "^\*\*Platform\*\*:" sdd/wip/[feature]/meta.md | awk '{print $2}')
> ```

**If `platform = android` or `platform = ios` (Mobile)**:
- ❌ DO NOT generate: Dockerfile task, Dockerfile.runtime task, /ping endpoint task, task
- ✅ INSTEAD generate: mobile build validation task (`./gradlew test` or `xcodebuild test`)
- ✅ INSTEAD generate: design system + mobile SDK compliance task (correct lib usage, no custom networking)

> **MOBILE TASK DESCRIPTIONS — ML LIBRARY ENFORCEMENT**:
> Every task description, title, and acceptance criterion that references a technical
> capability MUST use the mobile SDK library name taken from the technical spec
> (Section 3 — "mobile SDK Libraries"), which was itself derived from the skill's
> `mobile SDK docs from PROJECT.md`.
>
> The technical spec's "mobile SDK Libraries" section is the source of truth for task generation.
> If a capability is covered by an mobile SDK library listed there → use that library name.
> If a task description contains a generic Android/iOS ecosystem library instead of the
> mobile SDK equivalent from the spec → replace it before writing `tasks.json`.

**If `platform = backend | web**:
- IF `Dockerfile` missing → Generate creation task
- IF `Dockerfile.runtime` missing → Generate creation task
- ALWAYS: `/ping` endpoint task, validation task

**Database Migration Tasks**:

> **⚠️ CRITICAL**: When generating tasks that involve database schema changes (CREATE TABLE, ALTER TABLE, etc.), the task description MUST specify using `your-migration-tool init`. NEVER reference Flyway, Liquibase, Alembic, or manual .sql file creation.

**Correct task example**:
```json
{
  "id": "TASK-001",
  "title": "Database Schema Setup",
  "description": "Create database migration using `your-migration-tool init --service-name <db-name> --service-type mysql --file-name create_users_table`. Add table with required columns and indexes.",
  "acceptance_criteria": [
    "AC-1: Migration file created via your-migration-tool init",
    "AC-2: Table schema matches technical spec",
    "GATE: platform migration status shows pending migration"
  ]
}
```

**Incorrect (NEVER generate)**:
- ❌ "Create Flyway migration V{next}__..."
- ❌ "Add Liquibase changeset..."
- ❌ "Create migrations/mysql/.../001_create_table.sql manually"

**Reference**: Run `your-migration-tool init --help` for full flag documentation.

#### Infrastructure Tasks (from Service Selection)

> **Lazy-loaded**: When `(NEW)` infrastructure markers are present in spec, Read `references/infra-tasks.md` for infrastructure task templates. Skip entirely if no infrastructure tasks needed.

**Task Generation by Project Type**:

| Type | Unit Tests | E2E Tests |
|------|------------|-----------|
| **prototype** | Skip | Skip |
| **mvp** | Critical only | Skip |
| **production** | Full (80%+) | If `testing.e2e.enabled` |

#### Frontend Task Generation (Frontend framework/design system Projects)

> **Lazy-loaded**: When `PROJECT.md -> platform.type == "frontend-web"`, Read `references/frontend-tasks.md` for frontend-specific task templates.

#### E2E Scenario Detection (GenAI Offloaded)

> **GenAI-powered E2E analysis** - Deterministic extraction + LLM enrichment via GenAI Gateway.

```bash
# Extract AND analyze E2E scenarios via GenAI Gateway (offloaded)
e2e_result=$(bash development-agents/framework/tools/genai/genai-analyze-e2e.sh sdd/wip/[feature]/1-functional/spec.md)
genai_exit=$?

if [ "$genai_exit" -eq 0 ]; then
    # GenAI analysis succeeded - includes dependency graph and coverage gaps
    total_scenarios=$(echo "$e2e_result" | grep -o '"total_scenarios":[0-9]*' | cut -d: -f2)
    auto_task=$(echo "$e2e_result" | grep -o '"auto_task_recommended":[^,}]*' | cut -d: -f2)
    echo "E2E Scenarios Analyzed: $total_scenarios (auto_task: $auto_task)"
elif [ "$genai_exit" -eq 2 ]; then
    # Fallback to deterministic-only extraction
    e2e_result=$(bash development-agents/framework/tools/extraction/extract-e2e.sh sdd/wip/[feature]/1-functional/spec.md --json)
    total_scenarios=$(echo "$e2e_result" | grep -o '"total_scenarios":[0-9]*' | cut -d: -f2)
fi
```

**E2E Task Generation Flow**:
```
1. Run genai-analyze-e2e.sh → Get enriched scenario data (dependency graph, coverage gaps)
   ↓ if GenAI unavailable
   Run extract-e2e.sh --json → Get basic structured scenario data
2. IF total_scenarios > 0 AND testing.e2e.enabled:
   a. Generate AUTO-TASK-E2E task with scenario list
   b. Task references specific E2E IDs (E2E-1, E2E-2, etc.)
   c. Include dependency order from GenAI analysis (if available)
3. IF total_scenarios == 0:
   → No E2E task needed
```

**Benefits of GenAI offloading**:
- Adds dependency graph and coverage gap detection
- Falls back gracefully to deterministic extraction

### Extension point: after-implementation

> Resolve and invoke hooks for phase=`plan`, trigger=`after-implementation`.

### Step 6: Strategy Selection

**Profile-aware behavior**:

| Profile | Strategy Selection |
|---------|-------------------|
| `non-technical` | **AUTO-SELECT Batched** - No question asked |
| `technical` | Smart auto-select or ask user |

**For non-technical profile**:
```
✓ Execution strategy: Recommended
  (The agent will automatically optimize the task order)
```

**For technical profile** - Smart auto-select (Standard mode):

| Change Size | Criteria | Strategy |
|-------------|----------|----------|
| Small | ≤5 tasks OR all Low complexity | Auto: Sequential |
| Medium/Large | >5 tasks with Medium/High | Ask user |

**Strategy Options** (shown only to technical profile):

| Strategy | Tokens | Best For |
|----------|--------|----------|
| Sequential | ~80K | Simple features |
| Batched (Recommended) | ~100K | Most projects |
| Parallel | ~140K | Complex features |

### Extension point: before-approval

> Resolve and invoke hooks for phase=`plan`, trigger=`before-approval`.

### Step 7: Approval & Output

**BEFORE asking for approval, ALWAYS display full task list:**

1. Run display script (deterministic, ensures user sees all tasks):
   ```bash
   bash development-agents/framework/tools/state/display-tasks.sh sdd/wip/[feature]/3-tasks/tasks.json
   ```

2. Display the output **based on user profile**:

   <!-- PROFILE: TECHNICAL_ONLY -->
   **Technical Profile Display**:
   ```
   ## Tasks for Approval

   | ID | Title | Layer | Complexity | Dependencies |
   |----|-------|-------|------------|--------------|
   | TASK-001 | Setup project structure | 1 | Low | - |
   | TASK-002 | Create domain entities | 1 | Medium | TASK-001 |
   | TASK-003 | Implement REST endpoints | 1 | Medium | TASK-002 |
   | TASK-004 | Add KeyValueStore integration | 2 | Medium | TASK-003 |
   | TASK-005 | Performance review | 3 | Low | TASK-004 |
   | TASK-006 | Security review | 3 | Low | TASK-004 |

   **Total: 6 tasks**

   ### Layer Summary
   - Layer 1 (Local): 3 tasks
   -    - Layer 3 (Quality): 2 tasks
   ```

   <!-- PROFILE: NON_TECHNICAL_ONLY -->
   **Non-Technical Profile Display**:
   ```
   ## Plan de Implementación

   | Paso | Qué se hace | Esfuerzo |
   |------|-------------|----------|
   | 1 | Configuración inicial del proyecto | Sencillo |
   | 2 | Crear estructura de datos | Moderado |
   | 3 | Implementar funcionalidad principal | Moderado |
   | 4 | Conectar con servicios de plataforma | Moderado |
   | 5 | Revisión de calidad | Sencillo |

   **Total: 5 pasos**

   ✓ Estrategia: Recomendada (el agente optimizará automáticamente)
   ```

3. **THEN** ⛔ INVOKE TOOL (do not print this, CALL the tool):

   ```
   AskUserQuestion(
     questions=[{
       "question": "Approve these tasks?",
       "header": "Tasks",
       "options": [
         {"label": "Yes, approve", "description": "Approve tasks and continue"},
         {"label": "Adjust tasks", "description": "Modify task list before approving"},
         {"label": "Cancel", "description": "Cancel task generation"}
       ],
       "multiSelect": false
     }]
   )
   ```
   > **Non-technical profile**: Options simplified to "Sí, continuar" / "Ajustar" / "Cancelar"

4. If approved:
   - Validate tasks (see Validation Checks)
   - Write `tasks.json` to `sdd/wip/[feature]/3-tasks/`
   - Update `meta.md` with execution strategy
   - Set `Current Stage: tests` (next gate: `/sdd.test`)
   - Output success message

### Step 8: Post-Approval Context Check

Before presenting next steps, estimate context usage. If > 50%, show advisory:

```
╔═══════════════════════════════════════════════════════╗
║  CONTEXT ADVISORY                                     ║
╠═══════════════════════════════════════════════════════╣
║                                                       ║
║  Context usage: ~[XX]%                                ║
║  Phase completed: task planning                       ║
║                                                       ║
║  All tasks are saved in tasks.json.                   ║
║  Primary recommendation:                              ║
║    /clear then /sdd.test                             ║
║  Fresh context (~187K tokens) outperforms              ║
║  compaction (~140K degraded tokens).                   ║
║                                                       ║
╚═══════════════════════════════════════════════════════╝
```

| Context Level | Action |
|---------------|--------|
| < 50% | No advisory — proceed to Step 9 |
| 50-70% | Show advisory, recommend `/clear` |
| > 70% | Show advisory, **strongly recommend** `/clear` |
| > 80% | Show advisory: "Do `/clear` now — context is critical" |

**When to skip**: Very small feature (≤3 tasks) with context < 40%.

### Step 9: Interactive Next Steps (After Tasks Approved)

> **MANDATORY**: Always offer interactive selection after tasks are approved.

**⛔ INVOKE TOOL (do not print this, CALL the tool)**:

```
AskUserQuestion(
  questions=[{
    "question": "Tasks ready. Write tests first?",
    "header": "Next",
    "options": [
      {"label": "/clear + /sdd.test (Recommended)", "description": "Fresh context for tests-first gate"},
      {"label": "/sdd.test", "description": "Write failing tests before implementation"},
      {"label": "/sdd.test --refine", "description": "Skip if tests already exist — refine only"},
      {"label": "/sdd.check", "description": "Review task structure"}
    ],
    "multiSelect": false
  }]
)
```

**On user selection**:

| Selection | Action |
|-----------|--------|
| /clear + /sdd.test (Recommended) | Inform user to run `/clear`, then `/sdd.test` |
| /sdd.test | `Skill(skill="sdd.test")` |
| /sdd.test --refine | `Skill(skill="sdd.test", args="--refine")` |
| /sdd.check | `Skill(skill="sdd.check")` |
| Other | User types custom input |

---

## `--view` Flag

**WHEN** user runs `/sdd.plan --view`:

1. Resolve tasks.json:
   ```bash
   TASKS_FILE=$(ls -1 sdd/wip/*/3-tasks/tasks.json 2>/dev/null | head -1)
   ```
2. Verify exists (if not: "No tasks.json found. Run /sdd.plan first.")
3. Open viewer:
   ```bash
   bash development-agents/framework/tools/state/view-tasks.sh "$TASKS_FILE"
   ```
4. Confirm: "Tasks viewer opened in browser"

Accepts explicit path: `/sdd.plan --view sdd/wip/my-feature/3-tasks/tasks.json`

---

## Behavior by Mode

| Mode | Generate | Refine | Strategy | Approve |
|------|----------|--------|----------|---------|
| **Express** | Auto | Skip | Auto (Batched) | Auto |
| **Standard** | Auto | Ask user | Smart auto/Ask | Auto after choice |

---

## tasks.json Structure

**Single source of truth** - Do NOT create `tasks.md`.

```json
{
  "feature": "feature-name",
  "local_config": {
    "mysql": "container|testcontainers|existing|null",
    "keyvaluestore": "mock|null",
    "messagequeue": "mock|null"
  },
  "stats": { "total": 15, "done": 0, "by_layer": { "1": 8, "2": 5, "3": 2 } },
  "tasks": [
    {
      "id": "TASK-001",
      "title": "Short title",
      "description": "2-3 sentences max.",
      "status": "pending",
      "layer": 1,
      "depends_on": [],
      "files": ["path/to/file.go"],
      "acceptance_criteria": ["AC-1: ...", "GATE: go build passes"],
      "references": ["US-1"],
      "design_decisions": ["DD-1", "DD-3"]
    }
  ],
  "dependency_graph": {
    "by_layer": {
      "1": { "level_0": ["TASK-001"], "level_1": ["TASK-002"] }
    }
  }
}
```

---

## Task Layers

| Layer | Name | Purpose | GATEs |
|-------|------|---------|-------|
| **1** | Local | Works locally | `build`, `test`, `curl localhost` |
| **2** | Integration | project services | CI Pipeline, service configs |
| **3** | Quality | Validation | `project-*-expert` skills |

**Layer 3 MUST contain exactly 3 tasks**:
1. Code Review → `sdd-code-reviewer`
2. Performance Review → `sdd-performance-expert`
3. Security Review → `sdd-code-reviewer`

> **Security Review Task**: Invoke `Skill(skill="sdd-code-reviewer")` to run
> security rules analysis and vulnerability review for the detected technology stack.

---

## Refinement Options (--refine)

Available actions via AskUserQuestion:
- Add new task
- Modify existing task
- Split large task
- Delete task
- Adjust complexity/priority
- Done refining

---

## Validation Checks

Before approval, validate:
- [ ] Each task has complexity (Low/Medium/High)
- [ ] Each task has ≥2 acceptance criteria
- [ ] Dependencies reference valid task IDs
- [ ] No circular dependencies
- [ ] Dockerfile + /ping tasks present (ALWAYS, all project types)
- [ ] Layer 3 quality tasks present (production/mvp only)
- [ ] No deploy tasks (FORBIDDEN)
- [ ] Custom error pages present if team opted for them (frontend only, optional)

### Step 7.5: Deterministic Task Validation

Use script for comprehensive task structure validation before approval.

```bash
# Validate tasks.json structure and content
task_validation=$(bash development-agents/framework/tools/validation/validate-tasks.sh sdd/wip/[feature]/3-tasks/tasks.json --json)
is_valid=$(echo "$task_validation" | grep -o '"valid":[^,}]*' | cut -d: -f2)
error_count=$(echo "$task_validation" | grep -o '"error_count":[0-9]*' | cut -d: -f2)

if [ "$is_valid" != "true" ]; then
    echo "❌ Task validation failed with $error_count errors:"
    echo "$task_validation" | grep -o '"errors":\[[^]]*\]'
    # FIX errors before approval
fi
```

**Validation includes**:
- JSON structure integrity
- Required fields present (id, title, status, layer, acceptance_criteria)
- ID format correct (TASK-XXX)
- No orphan dependencies
- No circular dependencies
- Layer assignment valid (1, 2, or 3)
- Complexity values valid (Low/Medium/High)
- No forbidden tasks (deploy, release)

**Project Type → Layer Rules**:

| Aspect | Prototype | MVP | Production |
|---------|-----------|-----|------------|
| **Layer 1** | Implementation | Implementation | Implementation |
| **Unit Tests** | ❌ Skip | ⚠️ Critical only | ✅ Full coverage |
| **Coverage target** | 0% | Varies | 80%+ |
| **Layer 2** | project services (if any) | project services (if any) | project services (if any) |
| **CI Pipeline** | Optional | Required | Required |
| **Layer 3 Quality** | ❌ Skip | ✅ Yes | ✅ Yes |
| **E2E Tests** | ❌ Skip | ❌ Skip | ✅ Opt-in |
| **Dockerfile + /ping** | ✅ Always | ✅ Always | ✅ Always |

> **Layer 2 Explanation**: Tasks that require external platform services (key-value store, message queue,
> object storage, etc.). If your app doesn't use project services, Layer 2 will be empty.

---

## Key Rules

| Rule | Details |
|------|---------|
| **JSON only** | Generate `tasks.json`, never `tasks.md` |
| **Layer assignment** | Layer 1=local, 2=platform, 3=quality |
| **Quality gates** | `GATE:` prefix in acceptance criteria |
| **Story sizing** | Max 2-3 sentences per description |
| **No deploys** | NEVER generate deploy tasks |
| **Approver identity** | Capture via `git config user.name` |
| **Deterministic IDs** | Use `generate-ids.sh` for task IDs (see below) |

### Deterministic Task ID Generation

> **MANDATORY**: Use script for task ID generation - Ensures uniqueness and consistency.

```bash
# Generate next task ID
next_task=$(bash development-agents/framework/tools/generation/generate-ids.sh task sdd/wip/[feature])
# Returns: TASK-004 (if TASK-001, TASK-002, TASK-003 exist)

# Generate multiple task IDs at once
bash development-agents/framework/tools/generation/generate-ids.sh task sdd/wip/[feature] --count 10
# Returns: TASK-004 TASK-005 ... TASK-013

# JSON output for programmatic use
bash development-agents/framework/tools/generation/generate-ids.sh task sdd/wip/[feature] --count 5 --json
# Returns: {"type":"task","count":5,"ids":["TASK-004","TASK-005","TASK-006","TASK-007","TASK-008"]}
```

**When to use**:
1. Before generating tasks.json → Get all IDs needed upfront
2. When adding tasks via --refine → Get next sequential ID
3. Batch generation → Use --count for efficiency

> **Telemetry**: Captured automatically by hooks - no manual logging required.

---

## Forbidden Tasks

NEVER generate:
- "Deploy to environment"
- "platform deploy"
- "Release version"
- "Push to staging/production"

Agent cannot execute deployments. Focus on code, tests, and configs.

---

## Command Flow

```
/sdd.spec technical (approved)
        │
        ▼
   /sdd.plan ─────────────► /sdd.test ─────────────► /sdd.build
        │
   ┌────┴────┐
   │         │
   ▼         ▼
 --refine  --approve
```

---

## References

- ****: `standards/mandatory-standards.md`
- **Technology selection**: `standards/tech-stack.md`
- **Layer execution**: `sdd-validator` skill
- **Quality gates**: `sdd-validator` skill
- **Context management**: `context-guardian` skill
- **E2E detection**: `genai-analyze-e2e.sh` → `extract-e2e.sh`
- **E2E tests**: `sdd-large-test-writer` subagent

---

## AI Agent Instructions

### Help Flag Detection

**WHEN** the user runs `/sdd.plan help`:
1. Output ONLY the "Quick Help" section (not full documentation)
2. Do NOT execute plan logic
3. Keep response concise (~15 lines)
