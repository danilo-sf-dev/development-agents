# Reference: Spec-Phase Database Migration Detection

**Used by**: `/sdd.spec` Step 5.5 before technical approval. (Build-time branch workflow: `database-migration.md`.)

### Step 5.5: Database Migration Detection (CONDITIONAL)

> After the technical spec is generated and **before** approval, detect if the spec includes database migrations. If detected, annotate `meta.md` so `/sdd.build` knows to handle the `migration/*` branch automatically.

**Detection Logic**:

```
SCAN the generated technical spec (sdd/wip/[feature]/2-technical/spec.md) for:
  1. A "### Migrations" section                    OR
  2. Reference to "your-migration-tool init" command     OR
  3. CREATE TABLE / ALTER TABLE in SQL code blocks  OR
  4. service-type mysql/postgresql in project services

IF any match found:
  → Extract service_name and service_type from the technical spec
  → Update meta.md with migration metadata (see below)
  → Show user notification

IF no match:
  → Set migration.detected: false in meta.md
  → Continue to Step 6 (no further action)
```

**Update meta.md** (append to the `## Database Migrations` section):

```yaml
migration:
  detected: true
  service_name: "<platform-db-service-name>"   # From technical spec  Services section
  service_type: "mysql"                     # mysql | postgresql
  branch_name: null                         # Set by /sdd.build after creation
  branch_status: pending                    # pending | created | pushed | applied
  migration_files: []                       # Populated by /sdd.build
```

**Notify User** (only when migration detected):

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🗄️ Database migration detected
   Service: <service_name> (<service_type>)
   /sdd.build will handle the migration/* branch automatically.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

> **Note**: This step is purely metadata — no git operations happen here. The actual branch orchestration is handled by `/sdd.build` Step 3.5.
