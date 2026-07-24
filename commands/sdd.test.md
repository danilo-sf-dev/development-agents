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
- Edge cases and error paths are **always mandatory** (happy path + relevant edges per AC/rule)
- `/sdd.build` **does not write new tests** — only runs approved tests and implements code
- **Never skip** the tests-first gate. There is no lighter feature mode that bypasses `/sdd.test`.

---

## Output Artifacts

All under `sdd/wip/[feature]/4-tests/`:

| File | Purpose |
|------|---------|
| `test-plan.md` | AC → test mapping, QA risk bridge, coverage intent |
| `tests-manifest.json` | Machine-readable test files + **mandatory** `cases[]` contract |
| `*.test.*` / `*_test.*` | Actual test files in project test dirs (per stack) |

Copy schema from `framework/templates/tests-manifest.json`.  
**Canonical field rules**: Read `references/test-manifest-contract.md` before writing the manifest.

**tests-manifest.json** (required shape):

```json
{
  "feature": "feature-name",
  "status": "pending | in-progress | approved",
  "tests": [
    {
      "id": "TEST-001",
      "file": "tests/unit/UserService.test.ts",
      "covers": ["TASK-002", "AC-1", "US-1"],
      "cases": [
        {
          "id": "EC-HP",
          "title": "happy path",
          "expect": "creates resource and returns 201",
          "assert_kind": "status",
          "qa_surrogate": true,
          "risk_if_missed": "QA cannot complete happy path"
        },
        {
          "id": "EC-001",
          "title": "empty input",
          "expect": "rejects with validation error TITLE_REQUIRED",
          "assert_kind": "exception",
          "qa_surrogate": true,
          "risk_if_missed": "QA accepts empty value in E2E"
        }
      ],
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

**Rules**:
- `cases[]` is **mandatory** (never free-text `edge_cases` labels)
- Each case requires: `id`, `title`, `expect`, `assert_kind`, `qa_surrogate`, `risk_if_missed`
- `assert_kind`: only `exception` | `status` | `state`
- Prefer `qa_surrogate: true` (unit/integration case that protects what QA would catch in E2E)

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

Create `4-tests/test-plan.md` from `framework/templates/test-plan.md`:

| Section | Content |
|---------|---------|
| Coverage map | Each AC → TEST-ID + Case IDs |
| Cases contract | Mandatory fields reminder (`expect`, `assert_kind`, `qa_surrogate`, …) |
| QA risk bridge | QA/E2E risk → Case ID (`qa_surrogate: true`) |
| Out of scope | What will NOT be tested in this gate |
| Red phase | Command + expected fail-for-right-reason |

Also create `4-tests/tests-manifest.json` from `framework/templates/tests-manifest.json` with real `cases[]` (no `edge_cases` labels).
> Contract details: Read `references/test-manifest-contract.md`.

### Step 4: Write Tests (Delegate)

Spawn test writers — **never implement production feature code**:

| Scope | Subagent |
|-------|----------|
| Unit + integration | `sdd-small-test-writer` |
| E2E (if `testing.e2e.enabled`) | `sdd-large-test-writer` |

**Prompt must include**:
- Mode: `tests-first` — write tests only, no production implementation
- Reference: functional spec AC, technical spec contracts, task acceptance criteria
- Manifest path + **mandatory `cases[]` contract** (each assertion must match a case `expect` / `assert_kind`)
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
| Cannot run tests | AskUserQuestion: fix env / abort — do **not** skip the tests-first gate |

### Step 6: Contract check + Display for Approval

**BLOCKING — validate `tests-manifest.json` before asking approval** (see `references/test-manifest-contract.md`):

1. Every `tests[]` entry has non-empty `cases[]`
2. Every case has `id`, `title`, `expect`, `assert_kind`, `qa_surrogate`, `risk_if_missed`
3. `assert_kind` ∈ {`exception`,`status`,`state`}
4. No legacy `edge_cases` free-text arrays
5. Prefer ≥1 `qa_surrogate: true` for the feature
6. `red_verified: true`

If any check fails → STOP, refine (`--refine`), do **not** approve.

```bash
# Show test plan summary
cat sdd/wip/[feature]/4-tests/test-plan.md
```

Show table:

| TEST-ID | File | Covers | Cases (id → expect) | qa_surrogate | Red? |
|---------|------|--------|---------------------|--------------|------|
| TEST-001 | ... | TASK-002, AC-1 | EC-001 → rejects TITLE_REQUIRED | true | ✓ fail |

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

**Express mode** (`execution_mode: express` in meta.md): auto-approve **only if** `red_verified: true` **and** the contract checks above pass. Never auto-approve a hollow manifest.

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
- **Manifest contract**: `references/test-manifest-contract.md`
- **Templates**: `framework/templates/test-plan.md`, `framework/templates/tests-manifest.json`
- **Stack detection**: `detect-language.sh`, `detect-stack.sh`, `sdd/PROJECT.md`
- **Context**: `context-guardian` skill
- **Next step**: `sdd.build.md` (implementation only — no new tests)

---

## Optional flags (lazy-loaded)

| Flag | Reference |
|------|-----------|
| `--refine` | `references/test-refine.md` |
| `--approve` | Standard path — Step 7 (On Approval); contract gate in Step 6 |
| `--resume` | Resume from last saved test-writing state in `meta.md` |
| Manifest/`cases[]` rules | `references/test-manifest-contract.md` |

---

## AI Agent Instructions

### Help Flag Detection

**WHEN** the user runs `/sdd.test help`:
1. Output ONLY the "Quick Help" section
2. Do NOT execute test logic
3. Keep response concise (~15 lines)
