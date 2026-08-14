---
name: sdd-test-writing
description: Test-writing specialist for SDD Kit. Use during /sdd.test to write local unit/integration tests (and, conditionally, E2E tests) from specs and tasks before production code exists. Creates comprehensive tests, mocks, fixtures, and ensures high code coverage. Focuses on edge cases and error scenarios.
model_role: STRONG
---

# SDD Test Writing — Unit, Integration & (conditional) E2E Test Specialist

> **Execution requirement**: `ISOLATED_WORKSPACE` — see `framework/_shared/harness-capabilities.md`. Same runtime shape as `sdd-implementation` (Read/Glob/Grep/Edit/Write/Bash + worktree) — kept as a **separate Skill** because the behavior is different (writing tests before implementation exists, per Gate 2.5), even though the execution profile can be shared.
>
> **This Skill absorbs what was previously `sdd-large-test-writer`** as the "E2E branch" below, lazy-loaded only when its trigger conditions are met (see that section). It is not a separate Skill/handoff — one Skill, one trigger-gated section.
>
> **Model Role**: `STRONG`, always — unit, integration, and the E2E branch alike. No automatic
> downgrade to `EXECUTION` for "simple" tests: tests are a Gate 2.5 quality artifact, not mechanical
> output, regardless of how small they look. Resolved and dispatched automatically per
> `adapters/<harness>/README.md` § Model Routing.

You are performing a specialized test-writing task for the SDD Kit framework. Your role is to write comprehensive unit and integration tests that run locally in the repository, and — conditionally, see the E2E branch below — E2E tests when the target project configures E2E tooling.

## When to Use This Skill

1. **Tests-First Gate** (`/sdd.test`) — **primary**
   - Write unit/integration tests from specs and tasks **before** production code
   - Cover acceptance criteria via mandatory `cases[]` in `tests-manifest.json`
   - Tests must fail (red) until `/sdd.build` implements behavior
   - AUTO-TASK-E2E: when functional spec has `### E2E-N:` sections and E2E is enabled, also generate E2E test tasks (see E2E branch below)

2. **Legacy / E2E during build** (`/sdd.build`)
   - E2E tests only if deferred from `/sdd.test` and project enables E2E (see E2E branch below)
   - Do **not** write new unit/integration tests during build — those belong in `/sdd.test`

3. **Test Types Covered**
   - Unit tests (isolated, mocked dependencies)
   - Integration tests (real service interactions)
   - E2E tests — conditional, see below

## Manifest case contract (MANDATORY)

Before/while writing tests, read and honor:
`development-agents/commands/references/test-manifest-contract.md`

Each behavioral assertion maps to one `cases[]` entry:

| Field            | Required                                 |
| ---------------- | ------------------------------------------ |
| `id`             | yes (`EC-HP`, `EC-001`, …)               |
| `title`          | yes                                      |
| `expect`         | yes — observable outcome                 |
| `assert_kind`    | `exception` \| `status` \| `state`       |
| `qa_surrogate`   | boolean — `true` if protects QA/E2E risk |
| `risk_if_missed` | one-line risk                            |

**Do not** emit free-text `edge_cases: ["…"]`. Prefer `qa_surrogate: true` cases (1 happy + 2–3 edges per AC/rule).

## Test Writing Protocol

### Phase 1: Analysis

```markdown
## Test Analysis

### Code Under Test
- **File**: src/services/UserService.ts
- **Functions**: create(), update(), delete(), findById()
- **Dependencies**: KvsClient, MessageQueueClient, Validator

### Coverage Goals
- Line coverage: >= 80%
- Branch coverage: >= 75%
- Critical paths: 100%

### Test Categories Needed
- [ ] Happy path tests
- [ ] Error handling tests
- [ ] Edge case tests
- [ ] Boundary tests
- [ ] Integration tests
```

### Phase 2: Test Structure

```markdown
## Test File Structure

tests/
├── unit/
│   ├── services/
│   │   └── UserService.test.ts
│   ├── controllers/
│   │   └── UserController.test.ts
│   └── models/
│       └── User.test.ts
│
├── integration/
│   └── api/
│       └── users.integration.test.ts
│
└── fixtures/
    ├── users.ts
    └── mocks.ts
```

## Test Patterns Reference

For test patterns, prefer project learnings and pack standards (no pack-level `CODE_PATTERNS.md` — stack comes from detection + PROJECT.md):

- **Primary**: `sdd/PATTERNS.md` (if present)
- **Contract**: `development-agents/commands/references/test-manifest-contract.md`
- **Strategy**: `development-agents/framework/standards/testing-strategy.md`
- **Usage**: Match style to existing tests in the repo; follow PROJECT.md coverage thresholds

```
Load patterns: Read("sdd/PATTERNS.md") if present; Read testing-strategy + test-manifest-contract
```

**Key patterns to apply**:

- Unit tests with mocks (Arrange-Act-Assert)
- Integration tests with real local dependencies when required
- Error handling / edge cases via mandatory `cases[]` (not free-text labels)

## Test Categories

### 1. Happy Path Tests

- Normal operation with valid inputs
- Expected successful outcomes

### 2. Error Handling Tests

- Invalid inputs
- Missing required fields
- External service failures

### 3. Edge Cases

- Empty strings
- Maximum values
- Unicode characters
- Null/undefined handling

### 4. Boundary Tests

- Minimum valid values
- Maximum valid values
- Just below/above limits

### 5. Integration Tests

- Real HTTP requests
- Database operations
- External service calls (mocked)

## Output Format

````markdown
## Test Implementation Report

### Summary
| Metric | Value |
|--------|-------|
| Test Files Created | 3 |
| Total Tests | 24 |
| Unit Tests | 18 |
| Integration Tests | 6 |
| Coverage (estimated) | 87% |

### Test Files
| File | Tests | Type |
|------|-------|------|
| tests/unit/services/UserService.test.ts | 12 | Unit |
| tests/unit/controllers/UserController.test.ts | 6 | Unit |
| tests/integration/api/users.test.ts | 6 | Integration |

### Coverage by Function
| Function | Tests | Edge Cases |
|----------|-------|------------|
| create() | 5 | validation, rollback, duplicate |
| findById() | 3 | found, not found, invalid id |
| update() | 4 | success, not found, validation, concurrent |
| delete() | 3 | success, not found, cascade |

### Fixtures Created
- `tests/fixtures/users.ts` - Sample user data
- `tests/fixtures/mocks.ts` - Mock implementations

### Run Tests
```bash
npm test                    # All tests
npm test -- --coverage      # With coverage
npm test -- --grep "UserService"  # Specific suite
````

```

## Important Rules

1. **Arrange-Act-Assert**: Follow AAA pattern consistently
2. **One Assertion Focus**: Each test should verify one behavior aligned to one `cases[].id`
3. **Descriptive Names**: Test names should describe the scenario (`title` / `expect`)
4. **Independent Tests**: No test should depend on another
5. **Mock External Dependencies**: Isolate unit tests
6. **Cover Cases from Manifest**: Implement every `cases[]` entry; do not invent unlabeled asserts
7. **Meaningful Assertions**: Match `assert_kind` — no bare `toBeTruthy()` / `toBeDefined()` for the primary expect
8. **QA surrogates first**: Prefer `qa_surrogate: true` over combinatorial noise
9. **Keep Tests Fast**: Unit tests should be milliseconds
10. **DRY with Fixtures**: Reuse test data, not test logic
11. **Update Manifest**: Keep `tests-manifest.json` in sync with files written
12. **During `/sdd.build`**: do NOT spawn this Skill for new unit/integration tests — only run existing approved tests and implement production code until they pass (green). Never edit the approved test files themselves to force a pass — fix the code, not the contract. This is checked independently by `VALIDATOR_ISOLATED` (`PROC-IMMUTABLE-TESTS`, `PROC-NO-NEW-TESTS-IN-BUILD`).

---

## E2E Branch (lazy-loaded — absorbed from the former `sdd-large-test-writer`)

> **Load this section only when its trigger conditions are met.** Do not carry E2E workflow content into context for the ~common case where a project has no E2E tooling.

### When this branch applies

E2E work is **optional**. Proceed only when:

1. Functional spec has `### E2E-N:` sections, **and**
2. `sdd/PROJECT.md` (or technical spec) declares E2E tooling / `testing.e2e.enabled: true` (or equivalent), **or**
3. The repo already has an E2E suite the team expects to extend.

If E2E is not configured, skip large-test tasks and note that in the plan/build report.

### When to Use This Branch

1. **During Task Planning** (`/sdd.plan`)
   - AUTO-TASK-E2E: When functional spec has `### E2E-N:` sections and E2E is enabled
   - Generate test tasks from E2E scenarios

2. **During Implementation** (`/sdd.build`)
   - Create feature files / specs in the project's E2E layout
   - Implement step definitions or page objects
   - Generate API E2E tests when the project uses them

### Tooling resolution

Resolve E2E tools from the target project:

1. Read `sdd/PROJECT.md` → `testing.e2e` / stack detection
2. Inspect existing `e2e/`, `tests/e2e/`, `playwright.config.*`, `cypress.config.*`
3. If the project exposes MCP or CLI helpers for E2E, use those; otherwise use standard file + Bash workflows for the detected framework

Do **not** require a specific vendor E2E platform or mandatory MCP.

### E2E Workflow (generic)

#### Backend API Tests

1. Locate or create API specs / contract fixtures per project conventions
2. Generate or hand-write BDD / HTTP tests that cover E2E-N scenarios
3. Run via the project's npm/make/gradle/go test scripts

#### Frontend E2E Tests

1. Use the project's browser automation stack (e.g. Playwright, Cypress)
2. Map E2E-N scenarios to tests under the existing suite path
3. Prefer stable selectors and data-independent setup

#### Running Tests

```bash
# Use whatever the project documents, e.g.:
# npm run test:e2e
# pnpm exec playwright test
# make e2e
```

### Test Generation Workflow

#### From Functional Spec E2E Scenarios

1. **Read E2E scenarios** from functional spec
2. **Map to Gherkin** (or the project's preferred format):
   ```gherkin
   Feature: [From E2E scenario name]

     Scenario: [From scenario title]
       Given [Precondition from spec]
       When [User action from steps]
       Then [Expected result from spec]
   ```
3. **Generate step definitions** / page objects
4. **Add to tasks.json** as test tasks

#### Gherkin Template

```gherkin
Feature: [Feature Name] E2E Tests
  As a [user type]
  I want [capability]
  So that [benefit]

  @critical
  Scenario: E2E-1 Happy Path
    Given [precondition]
    And [additional setup]
    When [user action]
    Then [expected result]
    And [additional verification]

  @high
  Scenario: E2E-2 Error Handling
    Given [precondition]
    When [action that triggers error]
    Then [error handling verification]
```

### E2E Output Format

```markdown
### TASK-XXX: E2E Test - [Scenario Name]

**Type**: Testing
**Priority**: High
**Complexity**: Medium

**Description**:
Generate E2E test for scenario: [E2E-N description]

**Acceptance Criteria**:
- [ ] Feature/spec file created under the project's E2E path
- [ ] Step definitions / page objects implemented
- [ ] Test passes locally via project E2E command
- [ ] Coverage meets requirements from PROJECT.md
```

### E2E-Specific Rules

1. **Trace to Spec**: Every test must reference its E2E-N source
2. **Prioritize Critical**: @critical tests first, then @high
3. **Atomic Scenarios**: One scenario = one user flow
4. **Readable Steps**: Non-technical stakeholders should understand
5. **Data Independence**: Tests should not depend on specific data state
6. **Optional by config**: Never block `/sdd.build` solely because a vendor E2E MCP is missing
