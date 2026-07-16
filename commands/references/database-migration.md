# Reference: Database Migration Branch Workflow

**Used by**: `/sdd.build` Step 3.5, when `migration.detected == true` AND `migration.branch_status == "pending"` (a task touches the schema and no migration branch has been created yet).

---

## Why a separate branch/step

Schema migrations are riskier to bundle with feature-code commits: they need to be reviewable on their own, applied in the right order relative to deploys, and (for some engines) forward/backward compatible during rolling deploys. Isolating them lets CI run migration-specific checks (dry-run apply, lint of the migration file) independently from the feature's test suite.

## Workflow

### 1. Detect Migration Need
Look for signals in the technical spec / tasks.json: new/altered tables, columns, indexes, constraints. Confirm with the migration tool already used in this repo (check `PROJECT.md` → `database` field and any `migrations/` folder convention: Flyway, Liquibase, Alembic, Prisma Migrate, Rails/ActiveRecord, golang-migrate, etc.). Don't assume a tool — use whatever the project already has.

### 2. Create/Reuse Migration Branch
```bash
migration_branch="migration/$(date +%Y%m%d)-<short-description>"
if ! git show-ref --verify --quiet "refs/heads/$migration_branch"; then
    git checkout -b "$migration_branch"
else
    git checkout "$migration_branch"
fi
```
Some teams prefer migrations directly on the feature branch instead of a dedicated one — check `PROJECT.md` for a `migration_strategy` convention before assuming a separate branch is wanted.

### 3. Write the Migration File
- Follow the naming/versioning convention already present in the migrations folder (timestamp prefix, sequential number, etc.) — don't invent a new scheme.
- Prefer **additive, backward-compatible** changes when the deploy strategy is rolling/zero-downtime: add nullable columns before backfilling, avoid dropping columns in the same migration that stops writing to them.
- Include the down/rollback migration if the tool supports it and the project convention expects one.

### 4. Dry-Run / Validate
```bash
# Example shape — replace with the project's actual migration tool invocation
<migration-tool> validate
<migration-tool> migrate --dry-run
```
If the tool has no dry-run mode, apply against a local/throwaway database first, never directly against a shared environment.

### 5. Apply Locally and Run Tests
Apply the migration to the local dev database, then run the approved tests from `/sdd.test` that depend on the new schema.

### 6. Mark `migration.branch_status = "applied"` (or equivalent) in the task tracking, and continue with Step 4 (per-task implementation) using the now-migrated schema.

### 7. Merge Timing
Note in the task/commit whether this migration must merge/deploy **before** the feature code (common when adding a required column) or can ride together — call this out explicitly in the PR description so reviewers know the deploy order matters.
