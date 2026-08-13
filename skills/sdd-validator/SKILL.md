---
name: sdd-validator
description: Build, compliance, and independent-verdict validator for SDD Kit. Covers two modes — quick inline checks (build/test/coverage/compliance) and full isolated validation (VALIDATOR_ISOLATED — unbiased, process-compliance, structured verdict). Use during /sdd.build and /sdd.finish. **TRIGGER ON** build validation, test execution, coverage, code compliance, CI pipeline, unbiased validation, process compliance, independent verdict.
---

# SDD Validator

> **Two invocation shapes, one Skill.** Quick inline checks (build/test/coverage) run via `INVOKE_PROCEDURE` — `Skill("sdd-validator")` — directly in the calling session. Full independent validation runs under the `VALIDATOR_ISOLATED` execution requirement (see `framework/_shared/harness-capabilities.md`) — same Skill content, executed in a fresh, scrubbed-prompt context. This merged shape replaces the former split between this Skill and a separate `sdd-validator-runner` agent; nothing in this Skill's behavior was removed in the merge — see "Isolated Mode" below for everything that used to live in that agent file.
>
> `Skill(...)` is this pack's `INVOKE_PROCEDURE` capability — see `framework/_shared/harness-capabilities.md` for how it translates on non-Claude-Code harnesses. `VALIDATOR_ISOLATED` is a distinct, stricter capability — see that entry in the same file for its 9 mandatory properties and per-harness translation.

---

## When to Use

1. **After Task Implementation** (`/sdd.build`) - Build and test
2. **Final Validation** (`/sdd.build` end) - Full validation suite
3. **Before Archive** (`/sdd.finish`) - Compliance verification

---

## Validation Steps

### 0. Platform Detection (FIRST — gates all subsequent steps)

```bash
# Use detect-stack.sh — mobile detection runs before language detection
stack_result=$(bash development-agents/framework/tools/detect-stack.sh . --json 2>/dev/null)
platform=$(echo "$stack_result" | grep -o '"platform":"[^"]*"' | cut -d'"' -f4)
```

**Mobile projects (`platform = android | ios`) skip code compliance entirely:**

| Check                               | Android | iOS     | Backend/Web |
| ----------------------------------- | ------- | ------- | ----------- |
| code compliance (Dockerfile, /ping) | ❌ Skip | ❌ Skip | ✅ Run      |
| CI Pipeline                         | ❌ Skip | ❌ Skip | ✅ Run      |
| Mobile build validation             | ✅ Run  | ✅ Run  | ❌ Skip     |
| design system/mobile SDK compliance | ✅ Run  | ✅ Run  | ❌ Skip     |

**Mobile build commands:**

| Platform | Build                                                                                                             | Test                                                                                                             |
| -------- | ----------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------- |
| Android  | `./gradlew assembleDebug`                                                                                         | `./gradlew test`                                                                                                 |
| iOS      | `xcodebuild build -workspace *.xcworkspace -scheme <scheme> -destination 'platform=iOS Simulator,name=iPhone 16'` | `xcodebuild test -workspace *.xcworkspace -scheme <scheme> -destination 'platform=iOS Simulator,name=iPhone 16'` |

**Mobile compliance** (only when `platform.type` is android/ios **and** PROJECT.md lists banned/required libraries):

```bash
# Follow PROJECT.md mobile.constraints — do not assume a vendor SDK.
# Example pattern: scan for libraries the project forbids, then build+test.
```

**Mobile validation output format:**

```markdown
## Mobile Validation Results — Android | iOS

### Build
- [x] project build command — PASSED

### Tests
- [x] project unit tests — passing

### Constraints (from PROJECT.md)
- [x] No forbidden libraries
- [x] Uses required mobile SDK / design system if declared

### Verdict: PASSED ✅
```

> **After mobile validation passes** → proceed to spec sync / finish. Dockerfile/ping checks remain skipped for native apps.

---

### 1. Technology Detection (backend/web only)

> **SKIP if `platform = android | ios`** — mobile detection already handled in Step 0.

Detect stack by checking for:

| File             | Technology    | Build              | Test                  |
| ---------------- | ------------- | ------------------ | --------------------- |
| `pom.xml`        | Java (Maven)  | `mvn compile`      | `mvn test`            |
| `build.gradle`   | Java (Gradle) | `./gradlew build`  | `./gradlew test`      |
| `package.json`   | Node.js       | `npm run build`    | `npm test`            |
| `go.mod`         | Go            | `go build ./...`   | `go test -race ./...` |
| `pyproject.toml` | Python        | `pip install -e .` | `pytest`              |
| `Cargo.toml`     | Rust          | `cargo build`      | `cargo test`          |

### CI Pipeline Validation

> Build, tests, coverage, and CI are validated by the project's local CI pipeline (whatever tool your org uses — a CI-as-a-service MCP, a Makefile target, or plain `mvn verify`/`npm run ci`/etc.).
> This runs as build.md Step 6D. The sdd-validator skill no longer runs these checks independently.

The CI pipeline should cover: compilation, test execution, coverage analysis (>=80%), dependency scan, and static analysis.

See `build.md` Step 6D for invocation details.

### 4. Platform Compliance Checks (project-dependent)

| Check           | How to Verify                                  | Expected                             |
| --------------- | ---------------------------------------------- | ------------------------------------ |
| Dockerfile(s)   | Match existing repo / PROJECT.md               | Follow project conventions           |
| Health endpoint | If required by app type                        | Implemented                          |
| Secrets         | No hardcoded secrets                           | Env / secret manager from PROJECT.md |
| Config          | Platform/config files if the project uses them | Present when required                |

**Dockerfile Validation**:

```bash
# Prefer patterns already used in the repo; do not assume a vendor registry.
grep -E "^FROM\s+" Dockerfile Dockerfile.runtime 2>/dev/null || echo "CHECK: Dockerfiles per PROJECT.md"
```

### 5. Dependency Validation (Tech-Specific)

Validate against **detected stack** and PROJECT.md (Maven repos, npm registries, go modules, etc.).
Do not hard-require a corporate Nexus/BOM version unless PROJECT.md says so.
---

## Output Format

```markdown
## Validation Results

### Summary
| Check | Status | Details |
|-------|--------|---------|
| CI Pipeline | PASSED/FAILED | build, test, coverage, deps, SCA |
| Runtime compliance | PASSED/FAILED | X/5 checks |

### Runtime Compliance
- [x] Dockerfile exists (org-approved base image, per `sdd/PROJECT.md`)
- [x] Dockerfile.runtime exists (org-approved base image, per `sdd/PROJECT.md`)
- [ ] Health check endpoint - MISSING (if required by your org)
- [x] Health check configured
- [x] Org-specific platform config file present (if applicable)

### Verdict
[ ] PASSED - All validations passed
[ ] WARNING - Non-critical issues found
[ ] FAILED - Critical issues must be fixed
```

---

## Important Rules

1. **Be Fast**: Run only necessary checks
2. **Be Clear**: Report pass/fail unambiguously
3. **Be Specific**: Show exact errors and locations
4. **No False Positives**: Verify findings before reporting
5. **CI Pipeline is MANDATORY**: Cannot skip for `/sdd.finish` when required by PROJECT.md
6. **Iterate until passing**: Pipeline failures must be fixed

---

## Go-Specific Requirements

> **CRITICAL**: Go projects require race detection for CI/CD parity.

### Race Detection is MANDATORY

| Requirement | Command                      | Rationale                                                     |
| ----------- | ---------------------------- | ------------------------------------------------------------- |
| Tests       | `go test -race ./...`        | Detects data races that cause flaky tests and production bugs |
| Coverage    | `go test -race -cover ./...` | Race detection during coverage analysis                       |

**Why?** CI/CD pipelines run with `-race` flag. Tests that pass locally without `-race` may fail in CI/CD when races are detected.

### Coverage Must Be Measurable

Coverage validation is **BLOCKING** (not a warning):

- If coverage cannot be determined, validation **FAILS**
- Coverage must be >= 80% threshold
- Use `-coverprofile=coverage.out` for reliable measurement

### Common Go Concurrency Issues Caught

| Issue           | Symptom                 | Fix                                    |
| --------------- | ----------------------- | -------------------------------------- |
| Map write race  | `concurrent map writes` | Use `sync.Map` or `sync.Mutex`         |
| Shared variable | `DATA RACE` on variable | Use channels or mutexes                |
| Goroutine leak  | Memory growth over time | Use `context.Context` for cancellation |

---

## Layer Execution Guide

> **Disambiguation**: this is the "Task Execution Layers" system (System A). The pack has 4
> unrelated "Layer N" systems total — see `framework/_shared/layers-and-gates.md` if you need to
> tell them apart.

Tasks execute in layers. This validator runs at specific layers:

### Layer 1: Local (Code Implementation)

| Step        | Validator Role           |
| ----------- | ------------------------ |
| Write code  | None (implementation)    |
| Build check | **Run build validation** |
| Unit tests  | **Run test execution**   |

### Layer 2: Platform

| Step               | Validator Role                               |
| ------------------ | -------------------------------------------- |
| Runtime compliance | **Run project-configured compliance checks** |
| CI Pipeline        | **Run the project's configured CI pipeline** |
| Dependencies       | **Run dependency validation**                |

### Layer 3: Quality Gates

| Step        | Validator Role | Subagent                 |
| ----------- | -------------- | ------------------------ |
| Performance | Report only    | `sdd-performance-expert` |
| Security    | Report only    | `sdd-code-reviewer`      |
| Code Review | Report only    | `sdd-code-reviewer`      |

**Note**: Layer 3 uses specialized subagents. This validator only reports if they were invoked.

---

## Quality Gates Workflow

Quality gates are **MANDATORY** after each task implementation:

### Gate Execution Order

```
Per-Task Completion:
1. sdd-validator → Build + Tests (Layer 1-2)
2. sdd-performance-expert → Performance check (Layer 3)
3. sdd-code-reviewer → Security check (Layer 3)
4. sdd-code-reviewer → Code review (Layer 3)
```

### Quality Gate Status

| Gate        | Pass Criteria                                  | Blocking? |
| ----------- | ---------------------------------------------- | --------- |
| CI Pipeline | Build, tests, coverage (>=80%), deps, SCA pass | YES       |
| Performance | No critical findings                           | YES       |
| Security    | No HIGH/CRITICAL vulns                         | YES       |
| Code Review | No blocking comments                           | NO        |

### Reporting Quality Gates

After all gates run, report:

```markdown
## Quality Gates Summary

| Gate | Status | Details |
|------|--------|---------|
| Build | PASSED | Clean compile |
| Tests | PASSED | 15/15 passing |
| Coverage | WARNING | 72% (threshold: 80%) |
| CI Pipeline | PASSED | Project CI pipeline passed |
| Performance | PASSED | No N+1 queries found |
| Security | PASSED | No vulnerabilities |
| Code Review | PASSED | 2 suggestions (non-blocking) |

**Verdict**: PASSED (1 warning)
```

---

## Validation Timing

| Command               | When to Validate               |
| --------------------- | ------------------------------ |
| `/sdd.build` per-task | After each task implementation |
| `/sdd.build` end      | Full validation suite          |
| `/sdd.finish`         | Final compliance verification  |

---

## Coordination with Other Skills

This validator coordinates with other specialized Skills:

| Skill                     | Purpose                         | When    |
| -------------------------- | -------------------------------- | ------- |
| `sdd-performance-expert` | N+1 queries, memory leaks       | Layer 3 |
| `sdd-code-reviewer`      | OWASP, injections, code quality | Layer 3 |

**When to use Isolated Mode** (below) instead of quick inline checks:

- Context budget is constrained (main session context usage is high)
- Need unbiased validation (validator must not have knowledge of implementation decisions)
- Full validation suite, including Layer 3 quality gates

---

## Isolated Mode (`VALIDATOR_ISOLATED`)

> This section carries everything that previously lived in the separate `sdd-validator-runner` agent file. The behavior is unchanged by the merge — only the packaging (Skill content + a named execution requirement, instead of a dedicated agent identity) changed. See `framework/_shared/harness-capabilities.md` § `VALIDATOR_ISOLATED` for the full capability contract (9 mandatory properties) and the per-harness translation table.

You are, in this mode, performing independent validation of code changes **without any knowledge of implementation decisions**. You receive only file paths and validation rules, ensuring unbiased assessment.

### Critical Principle: Context Independence

**You do NOT receive and should NOT consider:**

- Why the code was written this way
- Implementation decisions or trade-offs
- Previous conversation about the feature
- The implementer's reasoning

**You ONLY receive:**

- File paths to validate
- Validation rules to apply
- Test commands to run

This isolation ensures you cannot rationalize failures based on knowing "why" something was done.

> **Honest limit** (established by direct testing, not assumed): the "no mutation of production" property is enforced today as a **behavioral + audited** guarantee, not a filesystem sandbox — an execution context without `Write`/`Edit` tools can still mutate files via `Bash` if instructed to. What actually protects production code here is: this prompt gives you no rationale to want to change anything, your own instructions (below) tell you to report rather than act, and any accidental mutation would surface as an unexplained diff on the next Process Compliance pass. Do not claim a stronger technical guarantee than this.

### When This Mode Is Used

Triggered automatically after any code change during `/sdd.build`, and for the final Gate 3 check in `/sdd.finish`, whenever:

1. Unbiased validation is needed (no knowledge of implementation decisions should influence judgment)
2. A full validation suite (including Layer 3 quality gates) is required
3. Context budget in the calling session is constrained

The calling command builds a **scrubbed prompt** (file paths + rules only, never implementation rationale) and requests execution under `VALIDATOR_ISOLATED`. The concrete mechanism (which worker/session type, on which harness) is an adapter decision — see `adapters/claude-code/README.md` § "VALIDATOR_ISOLATED" for the Claude Code implementation. This Skill's content (below) is what that execution context is given as its instructions.

---

### Validation Protocol

#### Phase 1: File Discovery

```bash
# Identify all files to validate
git diff --name-only HEAD~1  # If committed
git diff --name-only         # If uncommitted

# Or use provided file list from prompt
```

#### Phase 2: Run Validation Checks

Execute these checks in order:

##### Check 1: Build Validation

```bash
# Detect technology and run build
if [ -f "pom.xml" ]; then
    mvn compile -q
elif [ -f "package.json" ]; then
    npm run build 2>&1
elif [ -f "go.mod" ]; then
    go build ./...
elif [ -f "pyproject.toml" ]; then
    python -m py_compile **/*.py
fi
```

##### Check 2: Test Execution

```bash
# Run tests with coverage
if [ -f "pom.xml" ]; then
    mvn test -q
elif [ -f "package.json" ]; then
    npm test 2>&1
elif [ -f "go.mod" ]; then
    go test -race -cover ./...
elif [ -f "pyproject.toml" ]; then
    pytest --cov
fi
```

##### Check 3: Security Scan

> **When `sdd-code-reviewer` skill is available**, delegate to it for comprehensive security validation against Security Rules and security scanner.
>
> **Fallback** (basic patterns) — this is the **canonical Security check table** referenced elsewhere in this file (Anti-Patterns Detected, Layer 3 Extended Check Categories):

| Issue                      | Pattern                                             | Severity |
| --------------------------- | ----------------------------------------------------- | -------- |
| SQL Injection              | Raw SQL / string concatenation in query             | critical |
| Hardcoded Secrets          | `password=`, `api_key=`, `secret=` in code          | critical |
| XSS                        | `innerHTML`, `dangerouslySetInnerHTML`              | critical |
| Command Injection          | `Runtime.exec()`, `os.system()` with user input     | critical |
| Path Traversal             | `../` in file paths / string concatenation          | critical |
| Weak Crypto                | MD5, SHA1 for passwords                             | major    |
| IDOR                       | Missing authorization check on resource access      | major    |
| Sensitive Logging          | Secrets/passwords in log statements                 | major    |
| Missing Input Validation   | User input consumed without validation/sanitization | major    |
| Disabled Security Features | Security middleware/checks turned off or bypassed   | major    |

##### Check 4: Performance Scan

Scan for common performance issues — this is the **canonical Performance check table** referenced elsewhere in this file:

| Issue                            | Pattern                                                             | Severity |
| ---------------------------------- | ---------------------------------------------------------------------- | -------- |
| N+1 Query                        | Loop / repository call with DB call inside                          | critical |
| Memory Leak                      | Event listener without cleanup, or static collection without bounds | critical |
| Missing Index                    | WHERE / query on non-indexed column or field                        | major    |
| Unbounded Query                  | `SELECT` without `LIMIT`, or `findAll()` without pagination         | major    |
| String Concat in Loop            | `+=` on strings inside loop                                         | major    |
| Regex in Hot Path                | `Pattern.compile()` in method (repeated compilation)                | major    |
| Missing Pagination               | Endpoint/list returns unbounded results                             | major    |
| Synchronous I/O in Async Context | Blocking I/O call inside async function                             | major    |
| Unbounded Collections            | Collection grows without bound or eviction                          | major    |
| Inefficient Regex                | Catastrophic backtracking patterns                                  | minor    |
| Missing Caching                  | Repeated expensive calls without caching                            | minor    |

##### Check 5: Code Quality

Check for common issues — this is the **canonical Quality/Code-Review check table** referenced elsewhere in this file (Layer 3 mode also calls this category `code_review`):

| Issue                     | Pattern                                                                            | Severity |
| --------------------------- | -------------------------------------------------------------------------------------- | -------- |
| Empty Catch Block         | `catch { }` or `catch: pass`                                                       | major    |
| Missing Error Handling    | Unhandled promise/exception, or exception caught without being handled (swallowed) | major    |
| Missing Null Checks       | Dereference without null/undefined check                                           | major    |
| Console.log in Production | `console.log`, `print()` debug statements                                          | minor    |
| Dead Code                 | Unused imports/variables                                                           | minor    |
| Function Too Long         | Function > 50 lines                                                                | minor    |
| Too Many Parameters       | > 4 parameters                                                                     | minor    |
| Magic Numbers             | Numeric literals without named constants                                           | minor    |
| TODO/FIXME                | `TODO:`, `FIXME:`, `HACK:`                                                         | warning  |

##### Check 6: Process Compliance (SDD pipeline integrity)

> **Always run** when a WIP feature path is known (`sdd/wip/<feature>/`). This is **not** code-quality review — it answers: "Is this change allowed at this stage?"
>
> Use Read / Glob / Grep / git diff only. **Do not require** `bash`, `jq`, or project hooks. If a shell command fails, fall back to reading files with tools.

| Rule ID                    | Check                                                                                                                                                                                                 | Severity |
| ---------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------- |
| PROC-IMMUTABLE-TESTS       | If `4-tests/tests-manifest.json` → `status` is `approved`, any listed test file must **not** appear in git diff (working tree or staged)                                                              | critical |
| PROC-IMMUTABLE-SPEC        | If `meta.md` shows functional/technical `status: approved`, do not allow unapproved edits to those approved spec files unless stage is explicitly refine/reopen                                       | critical |
| PROC-IMMUTABLE-TASKS       | If `tasks.json` / tasks stage is `approved`, structural task contract must not be silently rewritten during `/sdd.build`                                                                              | major    |
| PROC-PHASE-ORDER           | `Current Stage` / stages must allow the invoking command (e.g. implementation only if `stages.tests` is `approved`)                                                                                   | critical |
| PROC-NO-IMPL-IN-TEST       | During tests stage (`Current Stage: tests` or manifest not approved): production feature paths must not gain real implementation (stubs/mocks only)                                                   | critical |
| PROC-NO-NEW-TESTS-IN-BUILD | During implementation: no **new** unit/integration test files beyond those already listed in `tests-manifest.json` (E2E only if deferred/enabled)                                                     | major    |
| PROC-MANIFEST-CONSISTENCY  | Every `tests[].file` in manifest exists on disk when status is approved/in-progress; `meta.md` stages.tests aligns with manifest `status`                                                             | major    |
| PROC-MANIFEST-CASES        | Every `tests[]` entry has non-empty `cases[]`; each case has `id`, `title`, `expect`, `assert_kind` (`exception`\|`status`\|`state`), `qa_surrogate`, `risk_if_missed`; no legacy `edge_cases` arrays | major    |

**Process vs quality**: Code review asks "is this code good?". Process Compliance asks "may this diff exist in this phase?". Do not merge the two into one vague opinion.

Process failures → include in `issues` with `category: "process"` and force verdict `CANNOT_PROCEED` (critical/major process issues are never warnings).

---

### Isolated-Mode Output Format

**CRITICAL**: You MUST output this exact JSON structure at the end of your response:

```json
<!-- VALIDATION_RESULT_START -->
{
  "validator": "sdd-validator",
  "mode": "isolated",
  "timestamp": "2026-01-12T10:30:00Z",
  "files_checked": [
    "src/services/UserService.ts",
    "src/controllers/UserController.ts"
  ],
  "checks_run": ["build", "tests", "security", "performance", "quality", "process"],
  "results": {
    "build": { "status": "passed", "message": "Build successful" },
    "tests": { "status": "passed", "message": "15/15 tests passed", "coverage": 85 },
    "security": { "status": "failed", "issues_found": 1 },
    "performance": { "status": "passed", "issues_found": 0 },
    "quality": { "status": "warning", "issues_found": 2 },
    "process": { "status": "passed", "issues_found": 0 }
  },
  "summary": {
    "critical": 0,
    "major": 1,
    "minor": 0,
    "warnings": 2
  },
  "issues": [
    {
      "id": "SEC-001",
      "severity": "major",
      "category": "security",
      "file": "src/services/UserService.ts",
      "line": 42,
      "rule": "security/sql-injection",
      "message": "Potential SQL injection: use parameterized queries",
      "code_snippet": "const query = `SELECT * FROM users WHERE id = ${userId}`"
    },
    {
      "id": "QUAL-001",
      "severity": "warning",
      "category": "quality",
      "file": "src/controllers/UserController.ts",
      "line": 15,
      "rule": "no-console",
      "message": "Remove console.log before production"
    }
  ],
  "verdict": "CANNOT_PROCEED"
}
<!-- VALIDATION_RESULT_END -->
```

---

### Verdict Rules

**Compute verdict based on issue counts.** This maps the four-tier `critical/major/minor/warning` severity used in the checks above onto the pipeline's canonical BLOCKER/WARNING/INFO model (`standards/warning-hierarchy.md`): `critical`/`major`/blocking `process` issues are BLOCKER-equivalent and stop the gate; `minor` and `warning` are WARNING-equivalent and are surfaced but never block on their own.

| Condition                                                     | Verdict                     | Description                                                                   |
| ---------------------------------------------------------------- | ------------------------------- | ------------------------------------------------------------------------------- |
| Any `category: process` critical/major                        | `CANNOT_PROCEED`            | SDD pipeline integrity violated                                               |
| `critical > 0`                                                | `CANNOT_PROCEED`            | Critical security/functionality issue                                         |
| `major > 0`                                                   | `CANNOT_PROCEED`            | Significant issue must be fixed                                               |
| `minor > 0` or `warnings > 0` (and no critical/major/process) | `CAN_PROCEED_WITH_WARNINGS` | Non-blocking — minor issues and warnings are reported but don't stop the gate |
| All zero                                                      | `APPROVED`                  | All checks passed                                                             |

**Important**: The verdict is computed in isolated mode and returned to the calling command/orchestrator. **The orchestrator MUST obey this verdict without interpretation or reinterpretation** — it may not soften, override, or second-guess a `CANNOT_PROCEED` verdict. On `CANNOT_PROCEED` for process, the orchestrator MUST use `ASK_USER` (always include **Outros**) — see `commands/references/ask-user-question-outros.md`. `CAN_PROCEED_WITH_WARNINGS` still means the minor/warning findings must be reported to the human — it only means the gate itself doesn't stop.

---

### Isolated-Mode Response Structure

Your complete response should be:

```markdown
# Validation Report

## Summary
- **Files Checked**: 5
- **Checks Run**: build, tests, security, performance, quality
- **Verdict**: CANNOT_PROCEED

## Check Results

### Build: PASSED
Build completed successfully in 12.3s

### Tests: PASSED
- 15/15 tests passed
- Coverage: 85%

### Security: FAILED
Found 1 issue:
- [MAJOR] SQL injection risk in UserService.ts:42

### Performance: PASSED
No issues found

### Quality: WARNING
Found 2 warnings:
- [WARN] console.log in UserController.ts:15
- [WARN] TODO comment in UserService.ts:78

## Issues to Fix

| ID | Severity | File:Line | Issue |
|----|----------|-----------|-------|
| SEC-001 | major | UserService.ts:42 | SQL injection risk |

## JSON Verdict

<!-- VALIDATION_RESULT_START -->
{ ... full JSON ... }
<!-- VALIDATION_RESULT_END -->
```

---

### Isolated-Mode Important Rules

1. **No Rationalization**: Never say "this is probably fine" or "this might be intentional"
2. **Strict Severity**: Apply severity levels consistently, don't downgrade
3. **Complete Scan**: Check ALL files provided, don't skip any
4. **JSON Required**: ALWAYS include the JSON block at the end
5. **No Context Leakage**: If you somehow receive implementation context, IGNORE it
6. **Fail Safe**: If uncertain, mark as issue (false positive is better than false negative)
7. **Process over convenience**: Never skip Check 6 to "help the build pass"
8. **No OS hard deps**: Prefer Read/Grep/git via available tools; missing `jq`/bash is not a reason to skip Process Compliance

---

### Anti-Patterns Detected

> **When `sdd-code-reviewer` skill is available**, delegate security validation to it
> (`skills/sdd-code-reviewer/SKILL.md`). It covers the security checklist and scanner guidance
> in that skill — there is no per-technology `rules/` subtree.

The full Security, Performance, and Quality pattern/severity tables are defined once, under
**Validation Protocol → Phase 2 → Check 3 (Security), Check 4 (Performance), Check 5 (Code Quality)**
above — see those tables for the complete list of anti-patterns detected in each category.

---

### Layer 3 Quality Gate Mode (Extended)

When invoked with a quality-gate prompt, isolated mode consolidates checks that would otherwise
require 3 separate inline Skill invocations (~6000 tokens) into a single isolated execution (~300
token result).

#### Extended Check Categories

When "Layer 3 quality gates" is mentioned in the prompt, run the same **Performance**, **Security**, and
**Quality** checks defined in the canonical tables under Validation Protocol above (Check 3: Security, Check 4:
Performance, Check 5: Code Quality) — no separate pattern list. In Layer 3 mode the Quality category is
reported under the JSON key `code_review` instead of `quality` (see Extended Output Format below); the
patterns and severities detected are identical to Check 5.

#### Extended Output Format

When running Layer 3 quality gates, the JSON verdict follows the exact schema shown under
**Isolated-Mode Output Format** above, with two differences:

1. An added top-level field: `"mode": "layer3_quality_gates"`.
2. `checks_run` / `results` use the key `code_review` in place of `quality` for the third quality
   category (same Check 5 patterns, different label).

A fully clean Layer 3 run — all categories pass, no issues — looks like the canonical example but with
every `results.*.status` set to `"passed"`, `issues: []`, and `verdict: "APPROVED"` (the `CAN_PROCEED`
counterpart to the `CANNOT_PROCEED` example shown above; see Verdict Rules for when each applies).

#### Token Cost Comparison

| Approach                      | Token Cost   | Notes                                                |
| -------------------------------- | -------------- | ------------------------------------------------------- |
| 3 separate inline Skills      | ~6000 tokens | performance + security + code-review in main context |
| Isolated mode (quality gates) | ~300 tokens  | Unified result from isolated execution                |
| **Savings**                   | ~5700 tokens | Per task cycle                                       |

**Recommendation**: For Layer 3 quality gates, ALWAYS run under `VALIDATOR_ISOLATED` with quality-gate framing to preserve the calling session's context.
