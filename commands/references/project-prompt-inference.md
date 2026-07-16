# Reference: Project Prompt Inference

**Used by**: `/sdd.project "…"`.

## Mode 2: Prompt Inference

When user provides a description:

```
/sdd.project "Somos un equipo que usa clean architecture, preferimos
coverage alto del 90%, PRs chicos de max 300 líneas, y specs en español"
```

### Inference Process

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔍 Analyzing description...
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Overrides detected (will be saved to PROJECT.md):

| Property | Value | Source |
|----------|-------|--------|
| Architecture | Clean Architecture | "uses clean architecture" |
| Coverage | 90% | "high coverage of 90%" |
| Max PR size | 300 lines | "small PRs of max 300" |
| Language | Español | "specs in Spanish" |

Not mentioned (will use defaults, not saved):

| Property | Default |
|----------|---------|
| Ratio unit:int | 4:1 |

What would you like to do?

1. ✅ Generate PROJECT.md (4 overrides only)
2. ✏️  Adjust values
3. 🔄 Switch to interactive mode
4. ❌ Cancel
```

### Inference Rules

**High Confidence Extraction - Backend**:

| Pattern in Text | Inferred Value |
|-----------------|----------------|
| "clean architecture" | architecture: clean |
| "hexagonal" | architecture: hexagonal |
| "layered" | architecture: layered |
| "DDD", "domain driven" | architecture: ddd |
| "coverage XX%" | coverage: XX |
| "PR de XX líneas", "max XX lines" | pr_max_lines: XX |
| "specs en español", "spanish" | language: es |
| "português" | language: pt |
| "ratio X:Y" | test_ratio: X:Y |

**High Confidence Extraction - Frontend Web**:

> `design_system_version` and `frontend_framework_version` are detected automatically from `package.json` (see Step 4) — not inferred from descriptions.

**Framework Defaults** (used when property is not in PROJECT.md):

```yaml
# Defined in coding-standards.md (backend)
defaults:
  architecture: clean
  coverage: 80
  test_ratio: "4:1"
  pr_max_lines: 400
  language: en

```

> **Behavior**:
> - If property is in PROJECT.md → use that value (override)
> - If property is NOT in PROJECT.md → use framework default
>
> **Not configurable in PROJECT.md** (but some are included as mandatory reference):
> - Branching Strategy → Included as read-only reference (ALL branch types from template — never omit)
> - Commit style, code review → standard (not included)
> - Spec/DBA/Security reviews → Decided per feature
> - Frontend framework/design system versions → Detected from package.json
> - Styling approach → SCSS with BEM (Frontend framework standard)

---
