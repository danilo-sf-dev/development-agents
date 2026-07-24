# Reference: /sdd.check Rare Workflows

**Used by**: `/sdd.check --sync`, `--compliance`, `--project`, `--version`, `task TASK-XXX`, `--resume`.

For rules and output examples, also read `references/check-flag-rules.md` and `references/check-output-examples.md`.

---

## `/sdd.check --sync` - Consistency Validation

Validates bidirectional consistency between all framework layers based on current phase.

### Phase-Aware Validation

| Current Phase | Layers Checked |
|---------------|----------------|
| `functional` | Only Functional Spec (nothing to compare) |
| `technical` | Functional ↔ Technical |
| `tasks` | Functional ↔ Technical ↔ Tasks |
| `implementation` | Functional ↔ Technical ↔ Tasks ↔ Code |

### Workflow

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         /sdd.check --sync                                   │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  1. DETECT CURRENT PHASE                                                    │
│     └── Read meta.md to determine phase                                     │
│                                                                             │
│  2. IDENTIFY EXISTING LAYERS                                                │
│     └── functional, technical, tasks, code (based on phase)                 │
│                                                                             │
│  3. VALIDATE BIDIRECTIONAL CONSISTENCY (per layer pair)                     │
│     ├── Functional → Technical: Every requirement has implementation?       │
│     ├── Technical → Functional: Everything traced to requirement?           │
│     ├── Technical → Tasks: Every contract has task?                         │
│     ├── Tasks → Technical: Every task maps to spec?                         │
│     ├── Tasks → Code: Every AC is implemented?                              │
│     └── Code → Tasks: Every code is documented?                             │
│                                                                             │
│  4. GENERATE INCONSISTENCY REPORT                                           │
│     └── List gaps with evidence                                             │
│                                                                             │
│  5. PROPOSE FIXES                                                           │
│     └── Specific changes to restore consistency                             │
│                                                                             │
│  6. APPLY FIXES (with y/n confirmation)                                     │
│     └── Update documents atomically                                         │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Deterministic Pre-Validation (Step 0)

Run deterministic validators before subagent analysis for efficiency.

```bash
# Step 0a: Validate spec alignment (functional ↔ technical)
alignment_result=$(bash development-agents/framework/tools/validation/validate-spec-alignment.sh sdd/wip/[feature] --json)
alignment_valid=$(echo "$alignment_result" | grep -o '"aligned":[^,}]*' | cut -d: -f2)
drift_count=$(echo "$alignment_result" | grep -o '"drift_count":[0-9]*' | cut -d: -f2)

if [ "$alignment_valid" != "true" ]; then
    echo "⚠️ Spec alignment issues detected ($drift_count drifts):"
    echo "$alignment_result" | grep -o '"drifts":\[[^]]*\]'
fi

# Step 0b: Run cross-layer analysis via GenAI Gateway (offloaded)
layers_result=$(bash development-agents/framework/tools/genai/genai-analyze-layers.sh sdd/wip/[feature])
genai_exit=$?

if [ "$genai_exit" -eq 0 ]; then
    # GenAI analysis succeeded - use enriched results
    verdict=$(echo "$layers_result" | grep -o '"verdict":"[^"]*"' | cut -d'"' -f4)
    echo "📊 Cross-layer analysis: $verdict"
elif [ "$genai_exit" -eq 2 ]; then
    # GenAI unavailable - fallback to subagent
    echo "🤖 Delegating to sdd-layer-analyzer for deep analysis..."
    # Use subagent for complex analysis
fi
```

**Deterministic checks**:
- **validate-spec-alignment.sh**: Detects drift between functional and technical specs
- **analyze-layers.sh**: Cross-layer consistency (functional → technical → tasks → code)

**Benefits**:
- Saves ~2,000-3,000 tokens vs LLM parsing
- Provides structured input for subagent
- Fast feedback on common issues

### Consistency Checks by Layer Pair

#### Functional ↔ Technical

**Functional → Technical:**
- Each User Story has endpoint/service implementing it
- Each Acceptance Criteria has technical validation/behavior
- Each NFR has implementation strategy

**Technical → Functional:**
- Each endpoint traces to a User Story (detect scope creep)
- Each data model traces to a requirement
- Each external integration is mentioned in functional

#### Technical ↔ Tasks

**Technical → Tasks:**
- Each endpoint has task(s) to implement it
- Each model has task to create it
- Each integration has configuration task

**Tasks → Technical:**
- Each task has technical spec backing it
- No orphan tasks without spec

#### Tasks ↔ Code (implementation phase only)

**Tasks → Code:**
- Each acceptance criteria has implementing code
- Each completed task has modified files

**Code → Tasks:**
- Each new function/class is documented in tasks
- No undocumented code

> **Lazy-loaded**: When `--sync` flag is used, Read `references/check-output-examples.md` section "## --sync examples" for output format reference.

---

## `/sdd.check --compliance` - Technical Validation

Validates technical compliance (build, tests, linting, dependencies) and proposes fixes.

### What It Checks

1. **Platform Compliance** (type-aware, based on `sdd/PROJECT.md` conventions and any org-specific config file the project uses)
   - Dockerfile exists and uses the base image declared in `sdd/PROJECT.md` (if your org mandates one)
   - Dockerfile.runtime exists (only for web services, NOT for CLIs)
   - Version consistency across files
   - Health check endpoint implemented (only for web services, NOT for CLIs, and only if required)

   > **IMPORTANT**: Read the project's app-type config (if one exists, per `sdd/PROJECT.md`) to determine application type. If `type: cli`, skip Dockerfile.runtime and health-check checks.

2. **🔐 Secrets Compliance** (BLOCKER)
   - No hardcoded secrets in source code
   - No secrets in configuration files
   - No credentials in Dockerfiles
   - Secrets documented in technical spec

   #### Dockerfile Image Validation (only if `sdd/PROJECT.md` declares a mandatory base-image prefix)

   **Validation Rule**: ALL `FROM` statements MUST start with the prefix declared in `sdd/PROJECT.md`.

   ```bash
   # Check: Extract FROM statements and verify against the prefix declared in sdd/PROJECT.md
   BASE_IMAGE_PREFIX="$(grep -A1 'base_image' sdd/PROJECT.md 2>/dev/null | tail -1 | xargs)"
   if [ -n "$BASE_IMAGE_PREFIX" ]; then
     grep -E "^FROM " Dockerfile Dockerfile.runtime 2>/dev/null | \
       grep -v "$BASE_IMAGE_PREFIX" && echo "❌ INVALID IMAGE" || echo "✅ OK"
   else
     echo "ℹ️ No mandatory base-image prefix declared in sdd/PROJECT.md — skipping"
   fi
   ```

   **Example Error Output** (when `sdd/PROJECT.md` declares a prefix):
   ```
   ❌ Dockerfile: INVALID BASE IMAGE
      Found: FROM eclipse-temurin:21-jdk
      Required: Image MUST start with the prefix declared in sdd/PROJECT.md

      Fix: Use the org-approved base image
   ```

3. **Tests**
   - All tests passing
   - Coverage meets threshold (default: 80%)
   - No skipped tests without justification

4. **Linting**
   - No linter errors
   - No linter warnings (configurable)

5. **Dependencies**
   - No vulnerable dependencies
   - No outdated critical dependencies

> **Lazy-loaded**: When `--compliance` flag is used, Read `references/check-output-examples.md` section "## --compliance examples" for output format reference.

---

## `/sdd.check --project` - PROJECT.md Validation

Validates `sdd/PROJECT.md` against framework standards and manages override registration.

```bash
# Validate PROJECT.md via GenAI Gateway
result=$(bash development-agents/framework/tools/genai/genai-validate-project.sh .)
if [ $? -ne 0 ]; then
    # Fallback to deterministic validation
    result=$(bash development-agents/framework/tools/validation/validate-project.sh sdd/PROJECT.md --json)
fi
```

### What It Checks

1. **Coverage vs testing-strategy.md**
   - If `min_coverage < 80`: Requires registered override

2. **Technology vs tech-stack.md**
   - If `forbidden` contains framework-recommended libs: Requires override
   - If `orm` differs from the project's declared default ORM: Warning for compatibility

3. **Coding Standards Compliance vs coding-standards.md**
   - Mandatory requirements cannot be overridden

> **Lazy-loaded**: When `--project` flag is used, Read `references/check-output-examples.md` section "## --project examples" for output format reference.

---

## `/sdd.check --version` - Framework Version & Spec Compatibility

Scans ALL specs in the project and validates them against current framework standards.

### Purpose

When users upgrade the framework mid-project, existing specs (system specs, completed features, WIP features) may have:
- Missing required sections (added in newer versions)
- Deprecated formats or patterns
- Incompatible structure with current templates

This check **scans the entire project** and validates all specs against current standards.

### What Gets Scanned

```
sdd/
├── PROJECT.md                ← Validated (project config)
├── PATTERNS.md               ← Validated (cross-feature patterns)
├── backlog.md                ← Validated (TODO/DEBT/IDEA items)
├── specs/                    # System specs (brownfield base)
│   ├── architecture.md       ← Validated
│   ├── api-contracts/*.yaml  ← Validated
│   └── components.md         ← Validated
├── features/                 # Completed features
│   ├── 20250101-user-auth/
│   │   ├── 1-functional/spec.md  ← Validated
│   │   ├── 2-technical/spec.md   ← Validated
│   │   ├── 3-tasks/tasks.json      ← Validated
│   │   └── meta.md               ← Version checked
│   └── 20250115-payments/
│       └── ...               ← Validated
└── wip/                      # Work in progress
    └── 20250203-refunds/
        └── ...               ← Validated
```

### Workflow

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         /sdd.check --version                                │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  1. READ CURRENT FRAMEWORK VERSION                                          │
│     └── cat development-agents/framework/VERSION                                         │
│                                                                             │
│  2. SCAN ALL SPEC LOCATIONS                                                 │
│     ├── sdd/PROJECT.md                                                     │
│     ├── sdd/PATTERNS.md (if exists)                                        │
│     ├── sdd/backlog.md (if exists)                                         │
│     ├── sdd/specs/**/*.md, *.yaml                                          │
│     ├── sdd/features/*/1-functional/spec.md                                │
│     ├── sdd/features/*/2-technical/spec.md                                 │
│     ├── sdd/features/*/3-tasks/tasks.json                                    │
│     ├── sdd/features/*/meta.md                                             │
│     ├── sdd/wip/*/1-functional/spec.md                                     │
│     ├── sdd/wip/*/2-technical/spec.md                                      │
│     ├── sdd/wip/*/3-tasks/tasks.json                                         │
│     └── sdd/wip/*/meta.md                                                  │
│                                                                             │
│  3. VALIDATE EACH SPEC AGAINST CURRENT TEMPLATES                            │
│     ├── Load current template from development-agents/framework/templates/               │
│     ├── Extract required sections from template                             │
│     ├── Check if spec has all required sections                             │
│     ├── Detect deprecated patterns (from CHANGELOG breaking changes)        │
│     └── Record issues per file                                              │
│                                                                             │
│  4. CHECK VERSION METADATA                                                  │
│     ├── Read framework.version_created from each meta.md                    │
│     ├── Flag features without version (pre-v1.2.1)                          │
│     └── Calculate version drift per feature                                 │
│                                                                             │
│  5. GENERATE COMPATIBILITY REPORT                                           │
│     ├── Group issues by severity (Critical/Warning/Info)                    │
│     ├── List affected files with specific issues                            │
│     └── Provide actionable fixes                                            │
│                                                                             │
│  6. OFFER AUTOMATED FIXES (where possible)                                  │
│     ├── Add missing sections with placeholders                              │
│     ├── Update deprecated patterns                                          │
│     └── Add version tracking to legacy meta.md files                        │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Validation Rules

#### Functional Spec Validation

| Section | Required Since | Check |
|---------|---------------|-------|
| `## Problem Statement` | v1.0.0 | Must exist, non-empty |
| `## User Stories` | v1.0.0 | At least one story |
| `## Acceptance Criteria` | v1.0.0 | At least one AC per story |
| `## Out of Scope` | v1.0.0 | Must exist |
| `## E2E Scenarios` | v1.1.0 | Required if `testing.e2e.enabled: true` |
| `## Spec Reference Annotations` | v1.0.2 | Required for brownfield |

#### Technical Spec Validation

| Section | Required Since | Check |
|---------|---------------|-------|
| `## Architecture` | v1.0.0 | Must exist |
| `## API Contracts` | v1.0.0 | Must exist if feature has endpoints |
| `## Data Model` | v1.0.0 | Must exist if feature has persistence |
| `## Project Services` | v1.1.4 | Must exist if the feature uses project services |
| `## Security Considerations` | v1.0.0 | Must exist |
| `## Environment Variables` | v1.2.1 | Separate from Secrets |

#### meta.md Validation

| Field | Required Since | Check |
|-------|---------------|-------|
| `framework.version_created` | v1.2.1 | Should exist |
| `testing.e2e.enabled` | v1.1.0 | Must be true/false |

#### tasks.json Validation (per feature)

| Field | Required Since | Check |
|-------|---------------|-------|
| Task ID format | v1.0.0 | `TASK-XXX` or `AUTO-TASK-*` |
| `layer` field | v1.1.0 | Must be 1, 2, or 3 |
| `complexity` field | v1.1.4 | Must be Low/Medium/High (not Duration) |
| `depends_on` | v1.0.0 | Referenced tasks must exist |
| `acceptance_criteria` | v1.0.0 | At least one AC per task |
| No `duration` or `hours` | v1.1.4 | Deprecated: use Complexity |

#### PROJECT.md Validation

| Section | Required Since | Check |
|---------|---------------|-------|
| `## Project Overview` | v1.0.0 | Must exist |
| `## Tech Stack` | v1.0.0 | Must define language, framework |
| `## Team Conventions` | v1.1.0 | Should exist |
| `## Repository` | v1.0.0 | Must have repo URL |

#### PATTERNS.md Validation (if exists)

| Section | Required Since | Check |
|---------|---------------|-------|
| `## Patterns` | v1.1.17 | At least one pattern if file exists |
| Pattern format | v1.1.17 | Each must have: title, context, decision |
| `source_feature` | v1.1.17 | Must reference originating feature |

#### backlog.md Validation (if exists)

| Section | Required Since | Check |
|---------|---------------|-------|
| `## TODOs` | v1.1.10 | Valid section header |
| `## DEBT` | v1.1.10 | Valid section header |
| `## IDEAS` | v1.1.10 | Valid section header |
| Item format | v1.1.10 | ID format: `TODO-XXX`, `DEBT-XXX`, `IDEA-XXX` |
| No `sdd/backlog/` directory | v1.1.10 | Deprecated: use file, not directory |

> **Lazy-loaded**: When `--version` flag is used, Read `references/check-output-examples.md` section "## --version examples" for output format reference.

### Deprecated Patterns Detection

The scan also detects deprecated patterns from previous versions:

| Pattern | Deprecated In | Current Standard | Auto-Fix |
|---------|--------------|------------------|----------|
| `Duration: X hours` in tasks | v1.1.4 | `Complexity: Low/Medium/High` | Yes |
| MySQL endpoint in Secrets table | v1.2.1 | Environment Variables table | Yes |
| `sdd/backlog/` directory | v1.1.10 | `sdd/backlog.md` file | Manual |
| Local `development-agents/framework/` folder | v1.1.15 | Global `development-agents/framework/` | Manual |
| Legacy `project_type` / prototype\|mvp modes in meta | — | Remove field; single full pipeline | Yes |

### Integration with Default Check

The version check shows a compact summary in the default `/sdd.check` output:

```
Feature: payment-gateway
Stage: implementation (Phase 4/4)
Progress: 72% (13/18 tasks)
Framework: v1.2.1 ✅ (3 specs need updates - run --version)
```

---

## `/sdd.check task TASK-XXX` - Task Details

Shows detailed information about a specific task.

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 Task Details: TASK-007
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Title: Frontend components
Status: ✅ completed
Phase: 3 (Frontend)

Estimation: 2.0h
Actual: 1.8h
Variance: -10% (under estimate)

Dependencies:
• TASK-001 ✅ (setup)
• TASK-003 ✅ (project structure)

Blocks:
• TASK-009 (integration)
• TASK-012 (E2E tests)

────────────────────────────────────────
Acceptance Criteria
────────────────────────────────────────

✅ PaymentForm component created
✅ PaymentList component created
✅ Unit tests passing (12/12)
✅ Storybook stories added

────────────────────────────────────────
Files Created/Modified
────────────────────────────────────────

+ src/components/PaymentForm.tsx
+ src/components/PaymentForm.test.tsx
+ src/components/PaymentList.tsx
+ src/components/PaymentList.test.tsx

Commit: xyz789 (2025-11-23 14:30)
```

---

## Status by Phase

Output adapts based on current phase:

### Phase 1 (Functional)
```
Current Stage: functional (Phase 1/4)

Progress:
• Spec drafted: ✅
• Sections: 6/7 complete
• Missing: Success Metrics

Next: Complete spec, then /sdd.spec --approve
```

### Phase 2 (Technical)
```
Current Stage: technical (Phase 2/4)

Progress:
• Functional: ✅ approved
• Technical drafted: ✅
• project services: 3 identified

Next: Review technical, then /sdd.spec --approve
```

### Phase 3 (Tasks)
```
Current Stage: tasks (Phase 3/4)

Progress:
• Tasks generated: ✅ (18 tasks)
• Refined: 2 iterations
• Strategy: Not chosen

Next: /sdd.plan --approve
```

### Phase 4 (Implementation)
Full implementation progress as shown above.

---

## Multiple Features

If multiple features in WIP:

```
User: /sdd.check

AI: Multiple features in progress:

    #     Feature                 Phase              Progress
    ───────────────────────────────────────────────────────────
    003   payment-gateway         implementation     72%
    004   user-auth               technical          Spec draft
    005   dark-mode               functional         Draft complete

    Specify feature by name:
      /sdd.check payment-gateway
      /sdd.check 20260120-payment-gateway
```

### Feature Resolution Logic

When user provides a feature reference:

```bash
# Resolution order:
# 1. Exact match on full name (e.g., "20260120-user-auth")
# 2. Name suffix match (e.g., "user-auth" → finds "20260120-user-auth")

resolve_feature() {
    local ref="$1"

    # Try exact match first (handles full names like "20260120-user-auth")
    if [ -d "sdd/wip/$ref" ]; then
        echo "sdd/wip/$ref"
        return
    fi

    # Try name suffix match (e.g., "user-auth" → "20260120-user-auth")
    local match=$(ls -1 sdd/wip/ 2>/dev/null | grep -E "^[0-9]{8}-.*${ref}$" | head -1)
    if [ -n "$match" ]; then
        echo "sdd/wip/$match"
        return
    fi

    # Fallback: legacy NNN- prefix
    match=$(ls -1 sdd/wip/ 2>/dev/null | grep -E "^[0-9]{3}-.*${ref}$" | head -1)
    if [ -n "$match" ]; then
        echo "sdd/wip/$match"
        return
    fi

    # Not found
    return 1
}
```

---

## Telemetry Section

Shows in standard mode:

```
────────────────────────────────────────
📊 Telemetry
────────────────────────────────────────

Feature Started: 2025-11-20
Elapsed: 3d 4h

Phase Breakdown:
• Functional:     8 interactions (complete)
• Technical:      6 interactions (complete)
• Tasks:          4 interactions (complete)
• Implementation: in progress

Session History:
• Session 1: 2025-11-20 (12 interactions)
• Session 2: 2025-11-21 (15 interactions)
• Session 3: 2025-11-23 (22 interactions)
```

---

## Alerts and Warnings

Shows issues requiring attention:

```
⚠️ Alerts
────────────────────────────────────────

🔴 TASK-010 blocked for 2 days
   Action: Follow up on DevOps ticket

🟡 2 tests failing
   Files: PaymentService.test.ts

🟡 Coverage dropped to 78%
   Action: Add tests for new code
```

---

## `/sdd.check --resume` - Session Management

View and manage all resumable sessions across features.

### List Resumable Sessions

```bash
/sdd.check --resume
```

Shows all features with interrupted sessions:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 Resumable Sessions
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Feature              Command              Interrupted          Progress
─────────────────────────────────────────────────────────────────────────
payment-gateway      /sdd.build          2 hours ago          TASK-003 (5/8)
user-auth            /sdd.spec technical 1 day ago            Section 3/5
notification-service /sdd.go             3 days ago           Step 4/5

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔄 To Resume
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Resume specific feature:
  /sdd.build --resume           (payment-gateway - most recent)
  /sdd.spec technical --resume  (user-auth)
  /sdd.go --resume              (notification-service)

Or resume last session:
  /sdd.check --resume --last    (payment-gateway)
```

### Resume Last Session

```bash
/sdd.check --resume --last
```

Immediately resumes the most recently interrupted session:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔄 RESUMING: Last Session
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Feature: payment-gateway
Command: /sdd.build
Interrupted: 2 hours ago

Loading context...
Resuming from TASK-003...

[Continues with /sdd.build --resume behavior]
```

### State File Location

Each feature's state is stored in:
```
sdd/wip/<feature-name>/state.json
```

### When Sessions are Cleared

State files are automatically deleted when:
- Feature is completed (`/sdd.finish`)
- Feature is cancelled (`/sdd.cancel`)
- Session completes successfully
