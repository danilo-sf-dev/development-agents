# Reference: Plan Task Generation

**Used by**: `/sdd.plan` Step 5.

### Step 5: Generate Tasks

**Language (BLOCKING — do this first)**:

```text
Resolve: meta.md spec_language → PROJECT.md language.specs → en
```

Write every `title`, `description`, and prose `acceptance_criteria` in that language.  
If `pt` / `es`, do **not** default to English task text. See `references/plan-key-rules.md` → **Task language**.

**Design Decision Mapping**: For each task, identify which Design Decisions (DD-N) from the technical spec
directly affect its implementation. Add their IDs to the `design_decisions` field. This enables fresh agents
to load only the relevant decisions when implementing each task, preventing re-proposal of already-rejected
alternatives. If no DD applies to a task, set `design_decisions` to an empty array `[]`.

Generate tasks following these rules:

| Rule                        | Reference                                                                 |
| --------------------------- | ------------------------------------------------------------------------- |
| **Unit/integration tests**  | Always full coverage from AC + edge cases via `/sdd.test` (never skip)    |
| **Layer assignment**        | `sdd-validator` skill                                                     |
| **Quality gates (Layer 3)** | `sdd-validator` skill — always include                                    |
| **E2E detection**           | **Deterministic script first** (see below); only if `testing.e2e.enabled` |

**Mandatory Tasks (Brownfield-aware)**:

> **FIRST**: Read `platform` from `meta.md` to determine which mandatory tasks apply.
>
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

| Scope                  | Behavior                                                  |
| ---------------------- | --------------------------------------------------------- |
| **Unit / integration** | Always — full coverage from AC + edge cases (`/sdd.test`) |
| **E2E**                | Only if `testing.e2e.enabled` in PROJECT.md / meta        |
| **Layer 3 quality**    | Always include quality/validation tasks                   |

#### Frontend Task Generation (Frontend framework/design system Projects)

> **Lazy-loaded**: When `PROJECT.md -> platform.type == "frontend-web"`, Read `references/frontend-tasks.md` for frontend-specific task templates.

#### E2E Scenario Detection

> Deterministic extraction, then the agent reasons over the results directly (dependency ordering, coverage gaps) instead of an offloaded enrichment step.

```bash
# Extract E2E scenarios (deterministic)
e2e_result=$(bash development-agents/framework/tools/extraction/extract-e2e.sh sdd/wip/[feature]/1-functional/spec.md --json)
total_scenarios=$(echo "$e2e_result" | grep -o '"total_scenarios":[0-9]*' | cut -d: -f2)
```

**E2E Task Generation Flow**:

```
1. Run extract-e2e.sh --json → Get structured scenario data (IDs, descriptions)
2. Agent reviews the scenarios directly against the functional spec to determine:
   - Dependency order between scenarios (which must run/pass before others)
   - Coverage gaps (user stories/AC without a matching E2E scenario)
3. IF total_scenarios > 0 AND testing.e2e.enabled:
   a. Generate AUTO-TASK-E2E task with scenario list
   b. Task references specific E2E IDs (E2E-1, E2E-2, etc.)
   c. Include the dependency order determined above
4. IF total_scenarios == 0:
   → No E2E task needed
```
