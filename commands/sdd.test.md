---
name: sdd.test
description: Write and approve tests before implementation (tests-first gate). Use after tasks are approved and before /sdd.build. Tests must fail first — production code comes later.
model: opus
argument-hint: "[--approve|--refine|--resume]"
---

> **Shared agent instructions**: Read `development-agents/framework/_shared/agent-instructions.md` before executing this command.

# Command: /sdd.test

**Description**: Write tests from approved specs and tasks **before** implementation. Human gate — tests must exist and fail (red) before `/sdd.build`.

**Usage**:
- `/sdd.test` → Generate tests from specs + tasks
- `/sdd.test --refine` → Adjust existing test plan or test files
- `/sdd.test --approve` → Approve tests and unlock `/sdd.build`
- `/sdd.test --resume` → Resume interrupted test-writing session

---

## Quick Help

> `/sdd.test help` → Shows this summary

**Syntax**: `/sdd.test [flags]`

| Flag | Description |
|------|-------------|
| (none) | Generate tests from specs + tasks |
| `--refine` | Adjust test plan or test files |
| `--approve` | Approve tests (Gate 2.5) |
| `--resume` | Resume interrupted session |

**Examples**:
```bash
/sdd.test              # Write failing tests
/sdd.test --approve    # Approve tests, then /sdd.build
```

**See also**: `/sdd.help test` for detailed documentation

**Model advisory (entry)**: Read `references/model-suggestion-advisory.md` — compact line for `phase_key`: `entry:test`.

---

## Pre-Requisites (BLOCKING)

| Check | On Failure |
|-------|------------|
| Tasks approved (`stages.tasks.status: approved`) | Run `/sdd.plan --approve` |
| `tasks.json` exists | Run `/sdd.plan` |
| Functional + technical specs approved | Run `/sdd.spec` |
| Context < 50% (advisory) | `context-guardian` skill |

```bash
phase_result=$(bash development-agents/framework/tools/detect-phase.sh sdd/wip/[feature] --json)
current_stage=$(echo "$phase_result" | grep -o '"stage":"[^"]*"' | cut -d'"' -f4)

# Allowed: tasks approved (stage=tasks) or tests in progress
if [ "$current_stage" = "implementation" ]; then
    echo "❌ Already in implementation. Use /sdd.build or /sdd.rollback if you need to redo tests."
    exit 1
fi
```

---

## Tests-First Principle

```
Spec + Tasks (approved)
        │
        ▼
   /sdd.test  ──► write tests + edge cases
        │
        ▼
   [Gate humano: aprovar testes]
        │
        ▼
   /sdd.build ──► implementar até testes passarem (green)
```

**Rules**:
- Tests are written **from acceptance criteria** — not from imagined implementation
- Tests **must fail** before `/sdd.build` (red phase) — no production code for the feature yet
- Stubs/mocks/fakes are allowed; **no feature implementation** in production paths
- Edge cases and error paths are mandatory for `mvp` and `production`
- `/sdd.build` **does not write new tests** — only runs approved tests and implements code

---

## Skip by Project Type

Read `meta.md → project_type.type`:

| Type | Behavior |
|------|----------|
| **prototype** | Skip test generation — auto-mark `stages.tests.status: approved` with note `skipped: prototype` |
| **mvp** | Critical-path tests only (happy path + main errors) |
| **production** | Full coverage from AC + edge cases |

For **prototype**, show message and offer `/sdd.build` directly:

```
✓ Prototype: gate tests-first ignorado (sem testes obrigatórios).
  Próximo: /sdd.build
```

---

## Output Artifacts

All under `sdd/wip/[feature]/4-tests/`:

| File | Purpose |
|------|---------|
| `test-plan.md` | AC → test mapping, edge cases, coverage intent |
| `tests-manifest.json` | Machine-readable list of test files + status |
| `*.test.*` / `*_test.*` | Actual test files in project test dirs (per stack) |

**tests-manifest.json** (minimal schema):

```json
{
  "feature": "feature-name",
  "status": "pending | in-progress | approved",
  "project_type": "prototype | mvp | production",
  "tests": [
    {
      "id": "TEST-001",
      "file": "tests/unit/UserService.test.ts",
      "covers": ["TASK-002", "AC-1", "US-1"],
      "edge_cases": ["empty input", "invalid id"],
      "expected_initial_result": "fail"
    }
  ],
  "red_verified": false,
  "approved_by": null,
  "approved_at": null,
  "revision": 0,
  "revised_reason": null
}
```

---

## Workflow (Steps in Order)

### Step 1: Context + Phase Check

Invoke `Skill("context-guardian")` if context > 40%.

Update `meta.md`:
- `Current Stage: tests`
- `stages.tests.status: in-progress`
- `stages.tests.started: <ISO-8601>`

### Step 2: Read Inputs

- `sdd/wip/[feature]/1-functional/spec.md`
- `sdd/wip/[feature]/2-technical/spec.md`
- `sdd/wip/[feature]/3-tasks/tasks.json`
- `sdd/PROJECT.md` + `detect-stack.sh` / `detect-language.sh`

### Step 3: Generate Test Plan

Create `4-tests/test-plan.md`:

| Section | Content |
|---------|---------|
| Coverage map | Each AC → planned test(s) |
| Edge cases | Boundaries, nulls, auth, concurrency, errors |
| Task mapping | Which TASK-XXX each test validates |
| Out of scope | What will NOT be tested in this gate (E2E → `/sdd.build` if enabled) |

### Step 4: Write Tests (Delegate)

Spawn test writers — **never implement production feature code**:

| Scope | Subagent |
|-------|----------|
| Unit + integration | `sdd-small-test-writer` |
| E2E (if `testing.e2e.enabled`) | `sdd-large-test-writer` |

**Prompt must include**:
- Mode: `tests-first` — write tests only, no production implementation
- Reference: functional spec AC, technical spec contracts, task acceptance criteria
- Requirement: tests must compile/run and **fail** for the right reason (missing behavior)

### Step 5: Verify Red Phase

Run the project's test command (from PROJECT.md / package scripts / Makefile):

```bash
# Examples — resolve from detect-stack
npm test
./gradlew test
go test ./...
pytest
```

**Expected**: new tests **fail** (red). Record in `tests-manifest.json`:

```json
"red_verified": true,
"red_run_at": "<ISO-8601>",
"red_summary": "N failed, M passed — failures expected"
```

| Result | Action |
|--------|--------|
| New tests fail | Proceed to approval |
| New tests pass | **BLOCK** — tests are not testing missing behavior; refine |
| Tests don't compile | Fix test code only, re-run |
| Cannot run tests | AskUserQuestion: fix env / skip gate (prototype only) / abort |

### Step 6: Display for Approval

```bash
# Show test plan summary
cat sdd/wip/[feature]/4-tests/test-plan.md
```

Show table:

| TEST-ID | File | Covers | Edge cases | Red? |
|---------|------|--------|------------|------|
| TEST-001 | ... | TASK-002, AC-1 | empty input | ✓ fail |

**⛔ INVOKE TOOL** (Standard mode):

```
AskUserQuestion(
  questions=[{
    "question": "Aprovar estes testes antes da implementação?",
    "header": "Tests",
    "options": [
      {"label": "Sim, aprovar", "description": "Desbloqueia /sdd.build"},
      {"label": "Ajustar testes", "description": "Refinar plano ou arquivos"},
      {"label": "Cancelar", "description": "Voltar sem aprovar"},
      {"label": "Outros", "description": "Descreva o que você vai fazer ou sugira outro caminho (texto livre)"}
    ],
    "multiSelect": false
  }]
)
```

> Gate AskUserQuestion **always** includes **Outros** — see `references/ask-user-question-outros.md`.

**Express mode** (`execution_mode: express` in meta.md): auto-approve if `red_verified: true`.

### Step 7: On Approval (`--approve` or user confirms)

1. Set `tests-manifest.json → status: approved`
2. Update `meta.md`:
   ```yaml
   stages:
     tests:
       status: approved
       approved_by: <git config user.name>
       approved_at: <ISO-8601>
       red_verified: true
   Current Stage: implementation
   ```
3. **Do NOT** start implementation — user runs `/sdd.build`

> **Process enforcement**: Approval is recorded in `meta.md` / manifest. During `/sdd.build`, `sdd-validator-runner` (Process Compliance) + anti-gaming AskUserQuestion enforce immutability — no OS hard hooks. See `framework/HARD_GATES.md`.

### Step 8: Interactive Next Steps

**Model advisory**: Read `references/model-suggestion-advisory.md` — full box for `phase_key`: `test→build` (troca crítica para modelo barato).

**⛔ INVOKE TOOL**:

```
AskUserQuestion(
  questions=[{
    "question": "Testes aprovados. Iniciar implementação?",
    "header": "Next",
    "options": [
      {"label": "/clear + /sdd.build (Recommended)", "description": "Contexto limpo para implementar — sugere modelo barato"},
      {"label": "/sdd.build", "description": "Implementar no contexto atual — sugere modelo barato"},
      {"label": "/sdd.test --refine", "description": "Ajustar testes antes de codar"},
      {"label": "/sdd.check", "description": "Revisar estrutura da feature"},
      {"label": "Outros", "description": "Descreva o que você vai fazer ou sugira outro caminho (texto livre)"}
    ],
    "multiSelect": false
  }]
)
```

---

## Behavior by Mode

| Mode | Generate | Refine | Red verify | Approve |
|------|----------|--------|------------|---------|
| **Express** | Auto | Skip | Auto | Auto if red OK |
| **Standard** | Auto | Ask user | Mandatory | Ask user |

---

> **Lazy-loaded**: When `--refine` is present (or escalated from `/sdd.build`), Read `references/test-refine.md`.

---

## Command Flow

```
/sdd.plan --approve
        │
        ▼
   /sdd.test ─────────────► /sdd.build
        │
   ┌────┴────┐
   │         │
   ▼         ▼
 --refine  --approve
```

---

## References

- **Test Writer**: `sdd-small-test-writer`, `sdd-large-test-writer` agents
- **Stack detection**: `detect-language.sh`, `detect-stack.sh`, `sdd/PROJECT.md`
- **Context**: `context-guardian` skill
- **Next step**: `sdd.build.md` (implementation only — no new tests)

---

## Optional flags (lazy-loaded)

| Flag | Reference |
|------|-----------|
| `--refine` | `references/test-refine.md` |
| `--approve` | Standard path — Step 7 (On Approval) |
| `--resume` | Resume from last saved test-writing state in `meta.md` |

---

## AI Agent Instructions

### Help Flag Detection

**WHEN** the user runs `/sdd.test help`:
1. Output ONLY the "Quick Help" section
2. Do NOT execute test logic
3. Keep response concise (~15 lines)
