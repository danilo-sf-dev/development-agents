# Reference: Finish Validation Checks

**Used by**: `/sdd.finish` when executing detailed validation steps.

## Validation Checks

> See `standards/PREREQ-VALIDATION.md` for complete validation checklist and commands.

### Required Validations (BLOCKING)

#### 0. Phase Verification (Deterministic)

> **Use script for deterministic phase detection** - Saves ~500-1000 tokens vs manual parsing.

```bash
# Deterministic phase detection (FIRST - verify we're in correct phase)
phase_result=$(bash development-agents/framework/tools/detection/detect-phase.sh sdd/wip/[feature] --json)
current_stage=$(echo "$phase_result" | grep -o '"stage":"[^"]*"' | cut -d'"' -f4)

# Verify we're in implementation phase
if [ "$current_stage" != "implementation" ]; then
    echo "❌ Feature not in implementation phase. Run /sdd.build first."
    exit 1
fi

# Detect platform — mobile skips all platform-compliance steps
stack_result=$(bash development-agents/framework/tools/detection/detect-stack.sh . --json 2>/dev/null)
platform=$(echo "$stack_result" | grep -o '"platform":"[^"]*"' | cut -d'"' -f4)
IS_MOBILE=false
if [ "$platform" = "android" ] || [ "$platform" = "ios" ]; then
    IS_MOBILE=true
    echo "📱 Mobile project detected ($platform) — steps will be skipped"
fi
```

#### 0.5. CI Validation (MANDATORY - FIRST CHECK)

> **CRITICAL**: CI must pass first. All other validations are meaningless if pipeline fails.

> **Lazy-loaded**: When `IS_MOBILE = true`, Read `references/finish-mobile-validation.md` § CI validation.

**If `IS_MOBILE = false`** — use the project's configured CI command (same as build.md Step 6D):
- If build.md Step 6D already passed in this session → **Skip** (already validated)
- If not yet run → invoke the command configured in `PROJECT.md` or the repository's CI entry point
- If no CI command is configured → report the missing configuration and continue with available build/test checks

---

#### 1. Task Completion
- All tasks must be "completed" status
- No tasks can be "in_progress" or "blocked"

#### 1.5. Feature Completion Validation (Deterministic)

Comprehensive feature completion check before proceeding.

```bash
# Validate feature is ready for completion
completion_result=$(bash development-agents/framework/tools/validation/validate-complete.sh sdd/wip/[feature] --json)
is_complete=$(echo "$completion_result" | grep -o '"complete":[^,}]*' | cut -d: -f2)
blocking_issues=$(echo "$completion_result" | grep -o '"blocking_count":[0-9]*' | cut -d: -f2)

if [ "$is_complete" != "true" ]; then
    echo "❌ Feature not ready for completion ($blocking_issues blocking issues):"
    echo "$completion_result" | grep -o '"blocking_issues":\[[^]]*\]'
    # BLOCKING - fix issues before /sdd.finish can proceed
    exit 1
fi
```

**Completion checks include**:
- All tasks completed (none pending/blocked/in_progress)
- Required files exist (spec.md, tasks.json, meta.md)
- Technical spec approved
- Implementation files present
- No orphan tasks without implementation
- Build artifacts generated (if applicable)

#### 2. Platform compliance (MANDATORY)

> **Mobile projects (`platform = android | ios`) run mobile validation — NOT .**
> Mobile apps don't have Dockerfiles, /ping endpoints, or project services.

> **Lazy-loaded**: When `IS_MOBILE = true`, Read `references/finish-mobile-validation.md` § Platform compliance.

**If `IS_MOBILE = false`** — run platform compliance:
```bash
bash development-agents/framework/tools/validation/validate-code.sh .
```

Checks:
- [ ] Dockerfile exists with -approved image
- [ ] Dockerfile.runtime exists with -approved image
- [ ] Version consistency between Dockerfiles
- [ ] /ping endpoint implemented

**If fails**: Feature CANNOT be completed. See [mandatory-standards.md](../framework/standards/mandatory-standards.md) for requirements.

#### 2.5. Security Validation (MANDATORY)

> **MANDATORY**: Security assessment must pass before archiving. Feature CANNOT complete with security findings.

##### Security Rules & Vulnerabilities Review

Run a full security assessment via the `/security-assessment` command — executes as a subagent (Audit mode) and returns a structured verdict.

**Verdict required**: `APPROVED` — any `CANNOT_PROCEED` verdict blocks archiving.

##### Secrets Management Validation

> **BLOCKER**: Hardcoded secrets will BLOCK deployment. See [mandatory-standards.md](../framework/standards/mandatory-standards.md#6--platform-secrets---mandatory-blocker).

**Scan for hardcoded secrets**:
```bash
grep -rEn "(password|api_key|secret|token|credential)\s*[:=]\s*[\"'][^\"']+[\"']" \
  --include="*.java" --include="*.go" --include="*.ts" --include="*.js" \
  --include="*.py" --include="*.yml" --include="*.yaml" --include="*.properties" \
  src/ && echo "❌ BLOCKER: Hardcoded secrets!" && exit 1 || echo "✅ No secrets"
```

**Checklist**:
- [ ] No hardcoded passwords in code
- [ ] No API keys in source files
- [ ] No tokens in configuration
- [ ] All secrets reference `System.getenv()` or equivalent
- [ ] `platform.yml` references your org's secrets-manager paths

**If fails**: Feature CANNOT be completed. Remove hardcoded secrets and use your org's secrets manager.

---

#### 3. Test Validation (MANDATORY)
```bash
bash development-agents/framework/tools/validation/validate-tests.sh sdd/wip/[feature] .
```

Checks:
- [ ] All tests passing
- [ ] Coverage >= 80%
- [ ] Unit tests exist
- [ ] Integration tests exist

**If fails**: Feature CANNOT be completed

#### 4. Code Quality
- [ ] No linter errors
- [ ] No TypeScript/type errors
- [ ] No open TODOs in code

#### 5. Spec Conflict Re-Scan (MANDATORY)

Re-scan for conflicts that may have been introduced during implementation.

**Why re-scan?**
During implementation, specs can be modified via:
- `/sdd.fix` (changes to specs for consistency)
- `/sdd.check --sync` (sync fixes)
- Manual edits to spec files

These changes might introduce NEW conflicts that weren't present during `/sdd.plan`.

**Validation command**:
```bash
bash development-agents/framework/tools/validation/validate-spec-conflicts.sh sdd/wip/[feature] blocking
```

**If NEW conflicts found without annotations**: Feature CANNOT be completed

**Resolution**:
1. Run `/sdd.spec` to interactively resolve new conflicts
2. Retry `/sdd.finish`

---

#### 6. Spec Reference Validation (MANDATORY)

> **v2.1.0**: Validates that all spec references point to existing files and sections.

**What to validate**:
- All `<!-- overrides: path#section -->` references in both specs
- All `<!-- extends: path#section -->` references in both specs
- All `<!-- deprecates: path#section -->` references in both specs

**Files to check**:
```
sdd/wip/[feature]/1-functional/spec.md
sdd/wip/[feature]/2-technical/spec.md
```

**Validation rules**:
1. Referenced file MUST exist
2. Referenced section (after `#`) MUST exist in the target file
3. Reference type MUST be valid (`overrides`, `extends`, or `deprecates`)

**If validation fails**: Feature CANNOT be completed

> **Lazy-loaded**: During validation phase, Read `references/output-examples-by-profile.md` § Validation examples for output format reference.

**Update meta.md on completion**:
When feature completes, record affected specs in `meta.md`:

```yaml
# In meta.md
affected_specs:
  overrides:
    - sdd/features/auth-v1/functional-spec.md#login-user-story
    - sdd/features/auth-v1/technical-spec.md#authentication-flow
  extends:
    - sdd/features/auth-v1/functional-spec.md#session-rules
  deprecates: []
```

---

#### 7. Final Consistency Check (MANDATORY)

Run full sync validation before archiving to catch any accumulated drift.

Before archiving, run full sync validation:

```
/sdd.check --sync
```

**Purpose**: Final verification that all layers (Functional ↔ Technical ↔ Tasks ↔ Code) remain consistent after the entire implementation phase.

**Verdict Handling**:

| Verdict | Action |
|---------|--------|
| `APPROVED` | Proceed to archive |
| `CAN_PROCEED_WITH_WARNINGS` | Archive with documented gaps |
| `CANNOT_PROCEED` | **BLOCKING** - Do NOT archive, fix issues first |

**If sync fails with CANNOT_PROCEED**:
1. Review the inconsistencies reported
2. Use `/sdd.fix` or manual edits to resolve
3. Re-run `/sdd.check --sync`
4. Retry `/sdd.finish` when sync passes

---
