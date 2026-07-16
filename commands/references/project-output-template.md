# Reference: PROJECT.md Output Template

**Used by**: `/sdd.project` when writing the file.

## Output: PROJECT.md

Generates `sdd/PROJECT.md` with **only the overrides** (properties the team explicitly configured):

```yaml
# Project Configuration
# Only contains overrides. Properties not listed use framework defaults.
# Ver defaults en: development-agents/framework/standards/coding-standards.md
# Ver frontend defaults: Skill(frontend-web-expert)

## Backend Conventions

architecture:
  pattern: hexagonal          # Override: team uses hexagonal instead of clean

## Quality Gates

coverage:
  min_coverage: 90            # Override: team requires 90% instead of 80%

## Frontend Web Configuration (Frontend framework/design system)

frontend:
  design_system_version: "9"    # "9" | "X" — set automatically by /sdd.project
  frontend_framework_version: "9"   # detected from package.json
```

### Hub section (only with `--hub`)

When `--hub` flag is used, append this section to the generated PROJECT.md:

```markdown
## Hub members

<!-- Add your app members below. Each row is an app in this workspace.
     Path is relative to the suite root. All members must be leaf apps (no nesting).
     After filling this table, run /sdd.hub start to begin a cross-app feature. -->

| Member | Path | Git URL | Stack | Summary |
|--------|------|---------|-------|---------|
<!-- | campaign-api | apps/api | git@github.com:org/campaign-api.git | Go | Campaign REST API | -->
<!-- | campaign-web | apps/web | git@github.com:org/campaign-web.git | React | Campaign frontend | -->
```

The table starts empty with commented examples. The developer fills in their real apps.

> **Example**: If the team only configured architecture and coverage, PROJECT.md only
> contains those two properties. Ratio, PR size, and language use defaults.

**Properties available for override - Backend**:

| Property | Default | Location in PROJECT.md |
|-----------|---------|-------------------------|
| architecture.pattern | clean | `architecture.pattern` |
| coverage.min_coverage | 80 | `coverage.min_coverage` |
| testing.ratio_unit_integration | 4:1 | `testing.ratio_unit_integration` |
| pr.max_lines | 400 | `pr.max_lines` |
| language.specs | en | `language.specs` |

**Properties available for override - Frontend Web**:

| Property | Default | Location in PROJECT.md |
|-----------|---------|-------------------------|
| frontend.design_system_version | auto-detected | `frontend.design_system_version` |
| frontend.frontend_framework_version | auto-detected | `frontend.frontend_framework_version` |

---
