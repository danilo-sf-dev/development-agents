# Reference: Plan Task Generation

**Used by**: `/sdd.plan` Step 5.

### Step 5: Generate Tasks

**Design Decision Mapping**: For each task, identify which Design Decisions (DD-N) from the technical spec
directly affect its implementation. Add their IDs to the `design_decisions` field. This enables fresh agents
to load only the relevant decisions when implementing each task, preventing re-proposal of already-rejected
alternatives. If no DD applies to a task, set `design_decisions` to an empty array `[]`.

Generate tasks following these rules:

| Rule | Reference |
|------|-----------|
| **Unit/integration tests** | Always full coverage from AC + edge cases via `/sdd.test` (never skip) |
| **Layer assignment** | `sdd-validator` skill |
| **Quality gates (Layer 3)** | `sdd-validator` skill — always include |
| **E2E detection** | **Deterministic script first** (see below); only if `testing.e2e.enabled` |

**Mandatory Tasks (Brownfield-aware)**:

> **FIRST**: Read `platform` from `meta.md` to determine which mandatory tasks apply.
> ```bash
> platform=$(grep "^\*\*Platform\*\*:" sdd/wip/[feature]/meta.md | awk '{print $2}')
> ```

> **Lazy-loaded**: When `platform = android` or `platform = ios`, Read `references/plan-mobile-tasks.md` for mobile mandatory task rules and SDK library enforcement.

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

**Task Generation — Tests (single path)**:

| Scope | Behavior |
|------|----------|
| **Unit / integration** | Always — full coverage from AC + edge cases (`/sdd.test`) |
| **E2E** | Only if `testing.e2e.enabled` in PROJECT.md / meta |
| **Layer 3 quality** | Always include quality/validation tasks |

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
