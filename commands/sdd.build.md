---
name: sdd.build
description: Implement feature tasks following approved strategy. Use when tasks are approved and user is ready to code. Handles layer-by-layer execution, infrastructure creation, database migrations, frontend builds, and CI validation.
model: opus
argument-hint: "[task-id|--next|--all]"
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

---
hooks:
  TaskCompleted:
    - hooks:
        - type: command
          command: "development-agents/framework/tools/shared/check-quality-task.sh"
---

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

| Flag | Description |
|------|-------------|
| (none) | Implement all tasks based on mode |
| `task TASK-XXX` | Implement specific task only |
| `phase N` | Implement specific phase only |
| `--layer N` | Implement up to layer N |
| `--resume` | Resume interrupted session |
| `--next` | Auto-continue with next pending task |

**Examples**:
```bash
/sdd.build                 # Implement all pending tasks
/sdd.build task TASK-005   # Implement only TASK-005
/sdd.build --layer 2       # Implement layers 1 and 2 only
```

**See also**: `/sdd.help build` for detailed documentation

---

CRITICAL: USER INTERACTION RULES
When this skill shows JSON for AskUserQuestion, you MUST:
  1. CALL the AskUserQuestion TOOL with that exact JSON
  2. DO NOT print options using Bash (no echo, cat, printf)
  3. DO NOT ask "Which option?" as text
  4. Tables marked "REFERENCE ONLY" are for docs - do NOT print


## Plan Mode Integration (Opt-In)

> **CRITICAL**: Claude Code Plan Mode for complex tasks. **OPT-IN** - disabled by default.
> Most users want uninterrupted implementation flow.

### Platform Availability

| Platform | Plan Mode Available |
|----------|---------------------|
| Claude Code (CLI) | ✅ Yes (`EnterPlanMode`/`ExitPlanMode`) |
| Cursor | ❌ No (use fallback) |

### Configuration

Plan Mode is **disabled by default**. Enable via `PROJECT.md` or `development-agents/framework/config.yaml`:

```yaml
# In PROJECT.md or development-agents/framework/config.yaml
plan_mode:
  build_complex_tasks: false      # Default: false (opt-in)
  build_layer_transitions: false  # Default: false (opt-in)
  build_ci_test_recovery: false # Default: false (opt-in)
```

### Trigger Conditions

| Trigger | Condition | When `plan_mode.build_*: true` |
|---------|-----------|--------------------------------|
| **Complex Tasks** | `task.complexity == "High"` OR `files_affected > 5` OR Layer 2 task OR `acceptance_criteria > 4` | `build_complex_tasks: true` |
| **Layer Transitions** | Completing Layer N → Layer N+1, context > 50%, 10+ tasks in next layer | `build_layer_transitions: true` |
| **CI Pipeline Recovery** | First failure with ambiguous error, classification confidence < 70%, or 2+ failed fix attempts | `build_ci_test_recovery: true` |

### Plan Mode Flow

```
IF config.plan_mode.build_* AND trigger_conditions_met AND EnterPlanMode available:
    1. EnterPlanMode()

    # Exploration phase (read-only)
    - Read related files
    - Analyze patterns
    - Identify dependencies

    # Design phase
    - Create implementation approach
    - List files to modify
    - Identify risks

    # Present to user
    - Show plan summary
    - Wait for approval

    2. ExitPlanMode()

    # Implementation phase
    - Execute approved plan
ELSE:
    # Fallback: proceed without Plan Mode
    - Implement directly (Express/Standard behavior)
```

### Fallback for Non-Claude Code Platforms

When `EnterPlanMode` is not available:

```
┌─────────────────────────────────────────────────────────────────────┐
│  PLAN MODE FALLBACK (Non-Claude Code)                                │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  INSTEAD OF:                                                         │
│    EnterPlanMode → Explore → Design → ExitPlanMode                   │
│                                                                      │
│  USE:                                                                │
│    1. Explore codebase (same read-only exploration)                  │
│    2. Design implementation plan                                     │
│    3. Display plan inline in chat                                    │
│    4. Use AskUserQuestion: "Approve this approach?"                  │
│       - Options: "Approve", "Modify", "Cancel"                       │
│    5. Continue with approved plan                                    │
│                                                                      │
│  DETECTION:                                                          │
│    IF EnterPlanMode tool not available:                              │
│      → Use fallback flow automatically                               │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### Mode-Based Behavior

| Mode | Plan Mode Behavior |
|------|-------------------|
| Express | Skip Plan Mode (auto-implement) |
| Standard | Use Plan Mode if config enabled + triggers met |

---

## Quality Checks (MANDATORY)

> **BLOCKING**: Quality checks after EACH task, not just at the end.

**Per-Task Cycle**:
1. Implement → Write production code
2. Test → Run unit/integration tests (skip for prototype)
3. Quality (delegate to agent for context efficiency):
   ```python
   Task(
       subagent_type="sdd-validator-runner",
       prompt="""
       Validate files: [modified_files]
       Run Layer 3 quality gates: performance, security, code-review
       Return unified JSON verdict.
       """
   )
   ```
   This consolidates 3 quality skills (~6000 tokens) into single verdict (~300 tokens).
4. Fix → ALL findings (critical, major, AND minor)
5. Re-check → Re-run until ZERO findings
6. Complete → Mark done, commit

**Verdict Files**: Written to `sdd/wip/<feature>/verdicts/` by sdd-validator-runner. Do not commit.

> **v2.8.0 Token Optimization**: Layer 3 quality gates now delegate to `sdd-validator-runner` instead of 3 inline Skill() calls. Saves ~5700 tokens per task cycle.

### Dependency Scanning

**MANDATORY before adding any library**: Run vulnerability check via `dependency security scanner`.

```python
mcp__dependency security scanner__safe_add_dependency(
  technology="java",
  ecosystem="maven",
  name_user="<user>",
  name_repository="<repo>",
  dependencies=[{"name": "new-library", "version": "1.0.0"}]
)
```

**Action on vulnerability**: Try latest version. If still vulnerable, warn user and block.

---

## Approved Tests Are Immutable (Anti-Gaming Guard)

> **BLOCKING RULE**: Tests approved in `/sdd.test` are the frozen behavior contract for this feature. `/sdd.build` writes code to make them pass — it never edits, weakens, deletes, disables, or skips them to force a green result. This applies in **every mode**, including Express.

**Forbidden during `/sdd.build`**:
- Editing assertions, expected values, or fixtures in any file listed in `tests-manifest.json`
- Deleting or renaming an approved test file
- Disabling tests (`.skip()`, `@Disabled`, `xit()`, commenting out, etc.)
- Loosening mocks/setup in a way that changes what the test actually verifies

**Allowed** (narrow exceptions, must be logged in the task report, not silent):
- Fixing a broken import path caused by a file move/rename during implementation (mechanical fix only, no assertion change)
- Adding brand-new tests is **not** this command's job either — that belongs to `/sdd.test`

### Detection (run per task, as part of Step 5)

```bash
approved_test_files=$(jq -r '.tests[].file' sdd/wip/[feature]/4-tests/tests-manifest.json 2>/dev/null)
changed_files=$(git diff --name-only; git diff --cached --name-only)

touched_approved_tests=false
for f in $approved_test_files; do
    if echo "$changed_files" | grep -qF "$f"; then
        echo "🚫 Approved test file modified: $f"
        touched_approved_tests=true
    fi
done
```

**If `touched_approved_tests=true`** — STOP the task cycle, do not commit, do not mark task completed:

**⛔ INVOKE TOOL (do not print this, CALL the tool)**:

```
AskUserQuestion(
  questions=[{
    "question": "Um teste aprovado foi alterado durante a implementação. Isso pode indicar que o teste está sendo ajustado pra passar, em vez do código ser corrigido. Como proceder?",
    "header": "Test Integrity",
    "options": [
      {"label": "Reverter o teste e corrigir o código (Recommended)", "description": "Descarta o diff no arquivo de teste, implementação continua até bater no teste original"},
      {"label": "O teste está realmente errado — escalar para /sdd.test --refine", "description": "Pausa o build, volta ao gate de testes com novo ciclo de aprovação humana"},
      {"label": "Ver o diff antes de decidir", "description": "Mostra o diff do arquivo de teste"}
    ],
    "multiSelect": false
  }]
)
```

> **NEVER** auto-approve a test file change — this check always pauses and asks, even in Express mode. Silent edits to approved tests are the exact failure mode this gate exists to prevent.

---

## Mandatory Code Review Protocol

> **BLOCKING**: Code review is not optional. ALL findings must be fixed, including minor issues.

```
TASK COMPLETION CYCLE (per task):

┌─────────────────────────────────────────────────────────────────┐
│  1. IMPLEMENT → Write production code                           │
│         ↓                                                       │
│  2. TEST → Run unit/integration tests (skip for prototype)      │
│         ↓                                                       │
│  3. QUALITY → Invoke sdd-code-reviewer, performance, security  │
│         ↓                                                       │
│  4. FIX ALL → Critical, Major, AND Minor findings               │
│         ↓                                                       │
│  5. RE-CHECK → Re-run until ZERO findings                       │
│         ↓                                                       │
│  6. COMPLETE → Mark done, commit                                │
└─────────────────────────────────────────────────────────────────┘
```

**You MUST fix ALL findings** including minor - Minor findings are NOT optional. Minor issues accumulate into technical debt.

---

## Behavior by Mode

| Mode | Behavior |
|------|----------|
| **Express** | Implement all, minimal pauses, auto-fix errors, auto-advance |
| **Standard** | Report progress, pause on errors, ask user |

---

## Skill Hooks (Extension Points)

This skill supports external skill hooks at 3 trigger points. At each point, the agent resolves hooks from 3 layers (user override > repo config > auto-declaration) and invokes matching skills.

**Resolution steps** (at each extension point):
1. Read `.claude/skill-hooks.json` and `development-agents/framework/skill-hooks.json`
2. Scan installed skills in `~/.claude/skills/*/SKILL.md` for `metadata` with `sdd-kit-*` keys
3. Merge with precedence: user override > repo config > auto-declaration
4. For each enabled hook matching phase=`build` and the current trigger, ordered by priority:
   - If `hook.mode == "required"`: invoke `Skill("<hook.skill>")` with current feature context
   - If `hook.mode == "available"` (default): evaluate if the hook is relevant to the current feature. Only invoke if the feature context suggests it adds value. Skip silently if irrelevant.

| Trigger | When | Location in workflow |
|---------|------|---------------------|
| `before-start` | Before Step 1 | Before phase detection |
| `after-implementation` | After Step 5 | After all tasks implemented and quality gates passed |
| `before-approval` | Before Step 8 | Before interactive next steps / finish prompt |

---

## Workflow (Steps in Order)

### Extension point: before-start

> Resolve and invoke hooks for phase=`build`, trigger=`before-start`.

### Step 1: Context Check + Phase Detection (Deterministic)

> **Use script for deterministic phase detection** - Saves ~500-1000 tokens vs manual parsing.

```bash
# Verify tasks AND tests are approved (must be in phase 5 = implementation)
tests_status=$(grep -A5 "tests:" sdd/wip/[feature]/meta.md 2>/dev/null | grep "status:" | head -1 | sed 's/.*: *//' | tr -d ' ')

if [ "$tests_status" != "approved" ] && [ "$tests_status" != "skipped" ]; then
    echo "❌ Tests not approved. Run /sdd.test --approve first."
    exit 1
fi

phase_result=$(bash development-agents/framework/tools/detection/detect-phase.sh sdd/wip/[feature] --json)
current_stage=$(echo "$phase_result" | grep -o '"stage":"[^"]*"' | cut -d'"' -f4)

# Verify ready for implementation (tests approved → stage implementation)
if [ "$current_stage" != "implementation" ]; then
    echo "❌ Not ready for build. Run /sdd.test --approve first."
    exit 1
fi

# Detect platform from PROJECT.md + detect-stack (android | ios | web | backend | "")
stack_result=$(bash development-agents/framework/tools/detect-stack.sh . --json 2>/dev/null)
platform=$(echo "$stack_result" | grep -o '"platform":"[^"]*"' | cut -d'"' -f4)

# Optional mobile skills: only if PROJECT.md platform.type is android/ios AND
# the project declares a mobile skill path. Do not hard-fail the build if absent.
if [ "$platform" = "android" ] || [ "$platform" = "ios" ]; then
    echo "INFO: mobile platform detected ($platform) — use stack skills from PROJECT.md if configured"
fi
```

Then check context level:
- Normal (<40%): Proceed inline
- Elevated (40-60%): Use subagents for heavy ops
- High (60-80%): Recommend compaction
- Critical (>80%): Must compact first via `context-guardian` skill

### Step 2: Read Task Source

Read tasks from `sdd/wip/[feature]/3-tasks/tasks.json`:
```bash
jq '.tasks[] | select(.status == "pending")' tasks.json
```

### Step 3: Layer-Based Execution

Execute tasks by LAYER first, then by dependency level:

```
LAYER 1 (Local) - Parallel Execution
├─ Skill(skill="sdd-code-reviewer") → Build mode (load security rules + SDKs) [MANDATORY]
├─ Analyze task dependencies → identify independent tasks
├─ For each independent task group:
│   ├─ IF platform == "android" → Spawn sdd-implementer (isolation: "worktree")
│   ├─ IF platform == "ios"     → Spawn sdd-implementer     (isolation: "worktree")
│   ├─ ELSE                     → Spawn sdd-implementer          (isolation: "worktree")
│   └─ Each instance works on its own worktree
├─ After all complete:
│   ├─ Merge worktree changes to main branch
│   └─ Resolve any conflicts
├─ Validate gates pass (build, local tests)
├─ git commit "feat: layer 1 complete"
└─ /sdd.check --compact (if context > 50%)

LAYER 2 ()
├─ Execute all Layer 2 tasks
├─ Validate CI Pipeline (RP MCP) passes
├─ git commit "feat: layer 2 complete"
└─ /sdd.check --compact (if context > 50%)

LAYER 3 (Quality)
├─ Skill(skill="sdd-code-reviewer") → Audit mode (vulnerability review) [MANDATORY]
├─ Execute all quality tasks
├─ All experts pass (0 findings)
└─ git commit "feat: layer 3 complete"

<signal>ALL_TASKS_COMPLETE</signal>
```

#### Layer Completion Protocol

After completing all tasks in a layer:

1. **Validate layer**: All tasks pass gates
2. **Commit**: Natural checkpoint for the layer
3. **Compact context** (if needed): `/sdd.check --compact`
4. **Proceed to next layer**

**Why compact between layers**:
- Layer 1 code details not needed for Layer 2  integration
- Layer 2 service configs not needed for Layer 3 quality reviews
- Prevents context exhaustion on large features

**When to optimize context**:
- Context > 50% after completing a layer → Recommend `/clear` or compaction (show advisory below)
- Context > 70% → Strongly recommend `/clear` before next layer
- Large feature (10+ tasks per layer) → Always optimize context

**Context advisory** (when context > 50% at layer boundary):
```
╔═══════════════════════════════════════════════════════╗
║  CONTEXT ADVISORY (optional)                          ║
╠═══════════════════════════════════════════════════════╣
║                                                       ║
║  Context usage: ~[XX]%                                ║
║  Layer completed: [N]                                 ║
║                                                       ║
║  All progress is saved in specs and tasks.json.       ║
║  Options:                                             ║
║    1. /clear — fresh context (recommended if > 50%)   ║
║    2. /sdd.check --compact — compress current context║
║    3. Continue as-is                                  ║
║                                                       ║
╚═══════════════════════════════════════════════════════╝
```

#### Layer 1 Parallel Execution Strategy

When Layer 1 has multiple independent tasks, use worktree-isolated agents for parallel execution:

1. **Dependency analysis**: Identify tasks with no inter-dependencies (no shared files, no data flow between them)
2. **Parallel dispatch**: Spawn the platform-correct implementer (with `isolation: "worktree"`) for each independent task or task group:
   - `platform == "android"` → `sdd-implementer` — optional mobile docs/skills from PROJECT.md
   - `platform == "ios"` → `sdd-implementer` — optional mobile docs/skills from PROJECT.md
   - backend/web → `sdd-implementer`
3. **Merge**: After all instances complete, merge worktree changes back to the main branch and resolve conflicts
4. **Validate**: Run build + local tests on the merged result

**When NOT to parallelize**:
- Tasks that modify the same files
- Tasks with data dependencies (task B needs output from task A)
- Less than 3 independent tasks (overhead not worth it)
- Layer 2 tasks ( services have side effects — always sequential)
- Layer 3 tasks (quality reviews need full codebase context)

#### After Layer Completion - Interactive Next Steps

> **MANDATORY (Standard mode only)**: Check context, then offer interactive selection after each layer.
> **EXPRESS MODE**: Check context, show advisory only if > 70%, then auto-continue to next layer.

**Context check**: Estimate context usage. If > 50%, show advisory before presenting options (tasks.json is already up-to-date on disk from Step 5, and layer commit includes it):

```
╔═══════════════════════════════════════════════════════╗
║  CONTEXT ADVISORY                                     ║
╠═══════════════════════════════════════════════════════╣
║                                                       ║
║  Context usage: ~[XX]%                                ║
║  Layer completed: [N]                                 ║
║                                                       ║
║  All progress is saved in tasks.json (committed).     ║
║  Primary recommendation:                              ║
║    /clear then /sdd.build --resume                   ║
║  Fresh context (~187K tokens) outperforms              ║
║  compaction (~140K degraded tokens).                   ║
║                                                       ║
╚═══════════════════════════════════════════════════════╝
```

**⛔ INVOKE TOOL (do not print this, CALL the tool)** (only in Standard mode):

```
AskUserQuestion(
  questions=[{
    "question": "Layer [N] complete. What next?",
    "header": "Next",
    "options": [
      {"label": "/clear + /sdd.build --resume (Recommended)", "description": "Fresh context, resume from next layer"},
      {"label": "/sdd.build", "description": "Continue in current context"},
      {"label": "/sdd.check --compact", "description": "Compact context if /clear not possible"},
      {"label": "/sdd.check --sync", "description": "Verify spec-code consistency"}
    ],
    "multiSelect": false
  }]
)
```

> **Note**: Replace `[N]` with the actual layer number in the question.

**On user selection**:

| Selection | Action |
|-----------|--------|
| /clear + /sdd.build --resume (Recommended) | Inform user to run `/clear`, then `/sdd.build --resume` |
| /sdd.build | `Skill(skill="sdd.build")` |
| /sdd.check --compact | `Skill(skill="sdd.check", args="--compact")` |
| /sdd.check --sync | `Skill(skill="sdd.check", args="--sync")` |
| Other | User types custom input |

> **MODE BEHAVIOR**: In Express mode, check context and show advisory only if > 70%, then automatically continue to next layer.

### Step 3.3: Infrastructure Creation (CONDITIONAL)

> **WHEN**: `tasks.json` contains `INFRA-TASK-*` entries (generated by `/sdd.plan` from services marked `(NEW)` in the technical spec).
>
> **SKIP IF**: No `INFRA-TASK-*` entries in tasks.json.
>
> **RUNS BEFORE**: Step 3.5 (Database Migration Branch).

#### Generic infra protocol

Provision project services / platform services using what the **target project** declares — never assume a vendor CLI or marketplace skill.

```
FOR EACH pending INFRA-TASK in tasks.json:
  1. Read service type, name, and parameters from the task AND the technical spec
     (Infrastructure / Services sections) and sdd/PROJECT.md.
  2. Prefer automation already used in the repo (IaC, Terraform, Pulumi, CloudFormation,
     platform CLI named in PROJECT.md, or existing scripts under infra/).
  3. If PROJECT.md names an infra skill/plugin, invoke that skill; otherwise follow
     the create/verify steps written in the INFRA-TASK description.
  4. Verify the resource exists (list/describe via the same tooling).
  5. If automation is unavailable → AskUserQuestion: Retry / Mark manual / Abort.
     NEVER mark skipped without explicit user approval.
  6. "Already exists" → mark completed (idempotent).
```

**Cite in the layer commit**:
```
infra: provision <service-name> per technical spec / PROJECT.md
```

### Step 3.5: Database Migration Branch (CONDITIONAL)

> **Lazy-loaded**: When `migration.detected == true` AND `migration.branch_status == "pending"`, Read `references/database-migration.md` for database migration workflow and branch management.

### Step 4: Per-Task Implementation

> **Tests-first**: Tests were written and approved in `/sdd.test`. **Do NOT spawn `sdd-small-test-writer` for new unit/integration tests** — only run existing tests and implement production code until they pass (green).
> ⚠️ **Never edit the approved test files themselves to force a pass** — see "Approved Tests Are Immutable" above. Fix the code, not the contract.

> **Platform routing**: Read `platform.type` in `PROJECT.md` before dispatching.

For each task, delegate to subagents based on platform:

**Default routing** (`platform.type` from PROJECT.md — backend, frontend-web, android, ios, or absent):

| Task Type | Subagent | Notes |
|-----------|----------|-------|
| Production code | `sdd-implementer` | Follow detected stack + technical spec; make approved tests pass |
| Run tests (verify) | `sdd-validator` skill or project test command | Re-run after each task — no new test files |
| E2E tests (if not done in /sdd.test) | `sdd-large-test-writer` | Only if E2E was deferred and `testing.e2e.enabled` |
| Validation | `sdd-validator-runner` | Independent context |

**Optional mobile / design-system preamble** (only when `platform.type` is android/ios **and** PROJECT.md names stack docs/skills):
```
IF PROJECT.md declares mobile/design-system skills:
    Prepend a short reminder to read those skills before implementing.
ELSE:
    Use repo conventions + technical spec only.

# Extract Design Decisions relevant to this task
    task_dd_ids = current_task.get("design_decisions", [])
    decision_context = ""
    for dd_id in task_dd_ids:
        # Read DD-N section from technical spec (e.g., "### DD-1: ..." through next "### DD-" or "---")
        dd_section = extract_section(technical_spec, dd_id)
        decision_context += dd_section + "\n"

    Task(
        subagent_type="sdd-implementer",
        prompt=f"""
## Task
{task_context}

## Relevant Design Decisions
{decision_context if decision_context else "No specific design decisions apply to this task."}
> These decisions were already evaluated and approved. Do NOT propose alternatives
> to the chosen approaches. If you think a different approach would be better,
> flag it as a deviation — do not silently change the approach.

## Technical Spec Reference
File: sdd/wip/{feature}/2-technical/spec.md

## Related Files
{related_files}
"""
    )
```

> Resolve SDKs and clients from the technical spec, PROJECT.md, and existing repo patterns.
> Do not assume a vendor marketplace skill. Optional stack skills apply only when PROJECT.md names them.

### Step 5: Quality Gate and Status Persistence

After each task implementation:

1. **Check approved test files weren't touched** — run the detection in "Approved Tests Are Immutable" above. If triggered, resolve via the AskUserQuestion flow before continuing.
2. Invoke `sdd-validator-runner` (independent context)
3. Parse verdict: APPROVED / CAN_PROCEED_WITH_WARNINGS / CANNOT_PROCEED
4. If CANNOT_PROCEED: Fix and re-invoke
5. **Persist task status to disk** (always, after quality gate passes):
   ```bash
   # Update tasks.json: mark task completed
   jq '(.tasks[] | select(.id == "TASK-XXX")) .status = "completed"' \
     sdd/wip/[feature]/3-tasks/tasks.json > tmp.json && mv tmp.json sdd/wip/[feature]/3-tasks/tasks.json
   ```

> **WHY write to disk after every task**: `compact-state.sh` reads `tasks.json` to reconstruct
> state after `/clear`. Writing status to disk ensures progress survives even uncommitted.
> The git commit happens at layer boundaries or when the context check (Step 5b) triggers a
> `/clear` recommendation — at that point, code + `tasks.json` are committed together.

### Step 5b: Context Check Between Tasks

After updating task status on disk, estimate context usage before starting the next task.

| Context Level | Action |
|---------------|--------|
| < 50% | Continue to next task silently |
| 50-70% | Show advisory, recommend `/clear` |
| > 70% | Show advisory, **strongly recommend** `/clear` |
| > 80% | Show advisory: "Do `/clear` now — context is critical" |

When context >= 50%, **commit before showing advisory** (so progress is safe for `/clear`):
```bash
git add [modified files] sdd/wip/[feature]/3-tasks/tasks.json
git commit -m "feat: tasks through TASK-XXX complete"
```

Then show advisory:

```
╔═══════════════════════════════════════════════════════╗
║  CONTEXT ADVISORY                                     ║
╠═══════════════════════════════════════════════════════╣
║                                                       ║
║  Context usage: ~[XX]%                                ║
║  Completed: TASK-XXX ([N] of [M] in layer)            ║
║                                                       ║
║  Your progress is saved in tasks.json (committed).    ║
║  Primary recommendation:                              ║
║    /clear then /sdd.build --resume                   ║
║                                                       ║
║  Or continue as-is if context is manageable.           ║
║                                                       ║
╚═══════════════════════════════════════════════════════╝
```

> Skip this check if the current task is the last in the layer (layer completion handles it).

### Extension point: after-implementation

> Resolve and invoke hooks for phase=`build`, trigger=`after-implementation`.

### Step 6: Final Validation

After ALL tasks complete:

| Step | Action | On Failure |
|------|--------|------------|
| A |  Compliance (3-layer validation) | FIX |
| B | Layer 3 Quality Gates (via `sdd-validator-runner`) | FIX ALL |
| C | Code Pattern Validation (-specific patterns) | FIX |
| D | **Local CI Pipeline (RP MCP)** — full pipeline: build, test, coverage, deps, SCA | Auto-fix via RP |

**Step B - Layer 3 Quality Gates** (consolidated):
```python
# Single agent call replaces 3 skill calls, saves ~5700 tokens
Task(
    subagent_type="sdd-validator-runner",
    prompt="""
    Final validation for all modified files.
    Run Layer 3 quality gates: performance, security, code-review
    Return unified JSON verdict.
    """
)
```

**Step C: Code Pattern Validation**:

```bash
# Run deterministic code pattern scan
code_result=$(bash development-agents/framework/tools/validation/validate-code.sh . --json)
is_valid=$(echo "$code_result" | grep -o '"valid":[^,}]*' | cut -d: -f2)
critical_issues=$(echo "$code_result" | grep -o '"critical_count":[0-9]*' | cut -d: -f2)

if [ "$is_valid" != "true" ] || [ "$critical_issues" -gt 0 ]; then
    echo "❌ Code pattern validation failed:"
    echo "$code_result" | grep -o '"issues":\[[^]]*\]'
    # Show specific issues and FIX before proceeding
fi
```

**Patterns validated**:
- Security anti-patterns (SQL injection risks, unsafe deserialization)
- Performance anti-patterns (N+1 queries, missing indexes)
-  SDK/client misuse patterns (per technical spec)
- Code quality anti-patterns (god classes, deep nesting)

### Step 6D: Local CI / Build Validation

> Run the project's CI or local build+test commands from PROJECT.md / package scripts / Makefile.
> Do **not** require a vendor release-process skill or marketplace plugin.

**Preferred order**:
1. Use scripts already in the repo (
pm test, make ci, ./gradlew check, go test ./..., etc.)
2. If PROJECT.md names a release/CI skill, invoke it optionally
3. On failure after reasonable retries → STOP build; user fixes and re-runs /sdd.build

**ALL PASS?** → Proceed to Step 7

### Step 7: Final Sync Validation

After all quality gates pass, validate implementation consistency:

```
/sdd.check --sync
```

**Purpose**: Catch any drift accumulated during implementation phase.

**Verdict Handling**:

| Verdict | Action |
|---------|--------|
| `APPROVED` | Ready for `/sdd.finish` |
| `CAN_PROCEED_WITH_WARNINGS` | Proceed, document warnings |
| `CANNOT_PROCEED` | Fix gaps before finishing |

**When to skip**: If all tasks were single-file changes with no spec modifications.

**ALL PASS?** → Ready for `/sdd.finish`

### Extension point: before-approval

> Resolve and invoke hooks for phase=`build`, trigger=`before-approval`.

### Step 8: Interactive Next Steps (After All Tasks Complete)

> **MANDATORY (Standard mode only)**: Offer interactive selection after all tasks complete.
> **EXPRESS MODE**: Skip this - auto-invoke `/sdd.finish`.

**⛔ INVOKE TOOL (do not print this, CALL the tool)** (only in Standard mode):

```
AskUserQuestion(
  questions=[{
    "question": "All tasks complete and validated. Ready to finish?",
    "header": "Next",
    "options": [
      {"label": "/sdd.finish (Recommended)", "description": "Archive feature and complete"},
      {"label": "/sdd.check --sync", "description": "Final consistency check"},
      {"label": "/sdd.build --layer 3", "description": "Re-run quality checks"}
    ],
    "multiSelect": false
  }]
)
```

**On user selection**:

| Selection | Action |
|-----------|--------|
| /sdd.finish (Recommended) | `Skill(skill="sdd.finish")` |
| /sdd.check --sync | `Skill(skill="sdd.check", args="--sync")` |
| /sdd.build --layer 3 | `Skill(skill="sdd.build", args="--layer 3")` |
| Other | User types custom input |

> **MODE BEHAVIOR**: In Express mode, automatically invoke `/sdd.finish` without asking.

---

## AUTO-TASK-PLATFORM-COMPLIANCE: Generic Validation

> Validate against **project** standards in PROJECT.md, the technical spec, and
> 	imings-agent/framework/standards/. No vendor platform skill is mandatory.

### Skip / adapt by platform.type

`
IF platform.type in (android, ios) AND PROJECT.md says so:
    Prefer mobile build + unit tests (gradlew / xcodebuild or project scripts)
ELSE:
    Prefer language build + test + lint from detect-stack / package scripts
`

### Layer 1: Static Checks

`ash
bash development-agents/framework/tools/validate-code.sh . --json 2>/dev/null || true
# Also run project linters if present (eslint, ruff, golangci-lint, etc.)
`

**Validates** (when applicable to the project):
- Container / deploy manifests match PROJECT.md conventions
- Health/readiness endpoints if the app type requires them
- No hardcoded secrets
- Coding standards from development-agents/framework/standards/

### Layer 2: Stack & Service Validation

1. Detect language/stack via detect-language.sh / detect-stack.sh + PROJECT.md
2. Optionally invoke stack skills **named in PROJECT.md** (java/ts/go/python/rust experts)
3. Validate project services / platform services from the technical spec against existing config
4. Frontend: follow the project's design system and component library (from PROJECT.md), not a fixed vendor UI kit
5. Design-to-code (Figma etc.): only if the project configures it

### Layer 3: Runtime / Test Verification

Run the project's test suite (unit + integration). E2E only if configured (	esting.e2e.enabled or existing suite).

After fixes that change behavior: /sdd.check --sync.

### Verdict

| Result | Condition |
|--------|-----------|
| APPROVED | Required layers pass |
| WARNINGS | Non-blocking issues |
| FAILED | Critical errors |

## State Persistence

**Resume**: `/sdd.build --resume` loads from `state.json`
**Next**: `/sdd.build --next` finds first pending task

---

## Build Commands

### Backend Technologies

| Technology | Build | Test |
|------------|-------|------|
| Java/Maven | `mvn compile` | `mvn test` |
| Java/Gradle | `./gradlew build` | `./gradlew test` |
| Go | `go build ./...` | `go test ./...` |
| Python | N/A | `pytest` |
| **Android** | `./gradlew assembleDebug` | `./gradlew test` |
| **iOS** | `xcodebuild build` | `xcodebuild test` |

### Frontend / Web

Use the project's package scripts (examples — adapt to repo):

| Command | Purpose |
|---------|---------|
| 
pm run dev / pnpm dev | Development server |
| 
pm run build | Production build |
| 
pm test | Unit/integration tests |
| 
pm run test:e2e | E2E (only if configured) |
| 
pm run lint | Linting |

Resolve exact commands from package.json, Makefile, or PROJECT.md.

---

## Improvement Capture

During implementation, if you detect improvements outside scope:

| Option | Action |
|--------|--------|
| Fix now | Implement if trivial (low effort) and low risk |
| Add TODO | Track in `sdd/backlog.md` |
| Add DEBT | Document as technical debt |
| Skip | Ignore if not relevant |

---

## Iterative Flow

Can return to specs if discoveries require changes:

| Size | Action |
|------|--------|
| Small | Update spec inline, continue |
| Medium | `/sdd.spec --iterate` |
| Large | `/sdd.rollback --phase 2` |

---

## Command Flow

```
/sdd.plan --approve
        │
        ▼
   /sdd.test --approve
        │
        ▼
   /sdd.build
        │
   ┌────┴────┐
   │         │
   ▼         ▼
 Layer 1   Layer 2   Layer 3
 (Local)   ()    (Quality)
   │         │         │
   └────┬────┴────┬────┘
        ▼         ▼
   Final Validation
        │
        ▼
   /sdd.finish
```

---

## References

- **Quality gates**: `sdd-validator` skill
- **Layer execution**: `sdd-validator` skill
- **Context management**: `context-guardian` skill
- ****: `standards/mandatory-standards.md`
- **Coding standards**: `standards/coding-standards.md`
- **Subagents (backend)**: `sdd-implementer`, `sdd-validator-runner` (tests written in `/sdd.test`)
- **Subagents (frontend-web)**: `sdd-implementer`, `sdd-validator-runner` (tests written in `/sdd.test`)

---

## AI Agent Instructions

### Help Flag Detection

**WHEN** the user runs `/sdd.build help`:
1. Output ONLY the "Quick Help" section (not full documentation)
2. Do NOT execute build logic
3. Keep response concise (~15 lines)

### Java Implementation Check

**BEFORE generating Java code**:
1. Scan existing source files for import patterns:
   - `grep -r "import javax\.servlet\|import javax\.ws\.rs" src/`
   - `grep -r "import jakarta\.servlet\|import jakarta\.ws\.rs" src/`
2. Determine which to use:
   - IF `jakarta.*` found → Use jakarta
   - IF `javax.*` found → Use javax
   - IF no existing imports → Use **jakarta** (modern default)
3. Show: "Using {jakarta/javax} imports (detected from project)"

**NEVER mix javax and jakarta** servlet/ws APIs in the same project.
