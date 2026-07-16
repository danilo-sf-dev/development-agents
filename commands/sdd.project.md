---
name: sdd.project
description: Initialize or manage PROJECT.md configuration file. Use when user needs to set up project conventions or edit project settings.
model: sonnet
---

> **Shared agent instructions**: Read `development-agents/framework/_shared/agent-instructions.md` before executing this command.

# Command: /sdd.project

**Version**: 1.4.0-beta
**Last Updated**: 2026-01-29
**Description**: Initialize or edit PROJECT.md with team conventions via interactive wizard or prompt inference.

> **Note**: PROJECT.md defines team conventions that apply to ALL features. It's optional - without it, framework defaults apply.

**Usage**:
- `/sdd.project` → Interactive wizard (step-by-step)
- `/sdd.project "<description>"` → Deduce conventions from prompt
- `/sdd.project --audio` → Record project conventions via microphone
- `/sdd.project --edit` → Edit existing PROJECT.md
- `/sdd.project profile` → View current user profile settings
- `/sdd.project profile --edit` → Update user profile interactively
- `/sdd.project patterns` → View/manage PATTERNS.md
- `/sdd.project patterns --add` → Add new pattern interactively
- `/sdd.project patterns "<desc>"` → Infer patterns from description
- `/sdd.project patterns --edit` → Edit PATTERNS.md directly
- `/sdd.project vision` → Interactive wizard to define product vision
- `/sdd.project vision --edit` → Edit existing vision
- `/sdd.project --view` → Open framework viewer in browser

---

## Quick Help

> `/sdd.project help` → Shows this summary

**Syntax**: `/sdd.project [description] [flags]`

| Flag | Description |
|------|-------------|
| (none) | Interactive wizard (step-by-step) |
| `"<description>"` | Deduce conventions from prompt |
| `--audio` | Record project conventions via microphone |
| `--edit` | Edit existing PROJECT.md |
| `--init` | Initialize PROJECT.md (alias) |
| `--update` | Update existing conventions |
| `profile` | View current user profile and Plan Mode settings |
| `profile --edit` | Update user profile interactively |
| `patterns` | View/manage PATTERNS.md |
| `patterns --add` | Add new pattern interactively |
| `patterns "<desc>"` | Infer patterns from description |
| `patterns --edit` | Edit PATTERNS.md directly |
| `vision` | Interactive wizard to define product vision |
| `vision --edit` | Edit existing vision |
| `--view` | Open framework viewer in browser |
| `--hub` | Initialize as hub workspace (adds `## Hub members` table) |

**Examples**:
```bash
/sdd.project                     # Interactive wizard
/sdd.project "Java DDD project"  # Infer conventions
/sdd.project --audio             # Describe conventions via voice
/sdd.project --hub              # Initialize as hub workspace
/sdd.project profile             # View current user profile
/sdd.project profile --edit      # Update profile interactively
/sdd.project patterns            # View project patterns
/sdd.project patterns --add      # Add pattern interactively
/sdd.project patterns "usar LibX para transformaciones"  # Infer pattern
/sdd.project vision              # Define product vision
/sdd.project vision --edit       # Edit existing vision
/sdd.project --view              # Open framework viewer in browser
```

**See also**: `/sdd.help project` for detailed documentation

---

## Changelog

- **v1.2.8** (2026-01-29): Added `/sdd.project vision` subcommand for product vision definition
- **v1.0.0** (2025-01-05): Initial version with dual-mode (interactive wizard + prompt inference)

---

## Purpose

Initialize `sdd/PROJECT.md` with team conventions. Supports two modes:

1. **Interactive Mode**: Step-by-step wizard for teams that want guided setup
2. **Prompt Mode**: AI-powered inference from natural language description

```
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃  PROJECT.md Scope - Team Conventions ONLY                               ┃
┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┫
┃                                                                          ┃
┃  ✅ BELONGS in PROJECT.md (team decisions):                              ┃
┃                                                                          ┃
┃  📦 Backend:                                                             ┃
┃     • Architecture pattern (Clean, Hexagonal, Layered, DDD)              ┃
┃     • Testing standards (coverage %, unit:integration ratio)             ┃
┃     • PR size limits                                                     ┃
┃     • Language preferences (specs in en/es/pt)                           ┃
┃                                                                          ┃
┃  🎨 Frontend Web (Frontend framework/design system):                                         ┃
┃     • Component architecture (feature-based, atomic, module-based)       ┃
┃     • State management pattern (frontend-framework/store, context, zustand)          ┃
┃     • Accessibility level (WCAG A, AA, AAA)                              ┃
┃     • Performance budgets (bundle size, Core Web Vitals)                 ┃
┃     • Component test coverage                                            ┃
┃                                                                          ┃
┃  📌 Included as MANDATORY reference (not configurable):                  ┃
┃     • Branching Strategy — ALL branch types from GitFlow    ┃
┃       (NEVER omit entries or show only a sample — include the FULL       ┃
┃       table from the template)                                           ┃
┃                                                                          ┃
┃  ❌ DOES NOT belong ( standard or per-feature):                      ┃
┃     • Commit style (Conventional Commits -  standard)                ┃
┃     • Code review (configured per project)                         ┃
┃     • Spec/DBA/Security reviews (decided per feature)                    ┃
┃     • Tech stack (detected from pom.xml, package.json, go.mod)           ┃
┃     • external services (detected from dependencies)                         ┃
┃                                                                          ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
```

---

## Mode 1: Interactive Wizard

When user runs `/sdd.project` without arguments:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔧 Configuring PROJECT.md
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

I'll help you define your team's conventions.
Press Enter to use the default value [in brackets].
```

### Step 0: Stack Detection (Automatic)

Before starting the wizard, **automatically detect** the project stack:

```bash
# Check for frontend stack
grep '"frontend-framework"' package.json         # Frontend framework detected
grep '"@design-system/' package.json         # design system UI detected

# Check for backend stack
ls pom.xml go.mod requirements.txt   # Backend detected
```

**Detection Results**:

| Detected | Stack Type | `platform.type` | Wizard Flow |
|----------|------------|-----------------|-------------|
| `frontend-framework` + `@design-system/*` | Frontend Web (Standard) | `frontend-web` (auto-set) | Show frontend steps |
| `frontend-framework` only | Frontend Web (Custom UI) | `frontend-web` (auto-set) | **Ask about UI library** (see below) |
| `pom.xml`, `go.mod`, etc. | Backend | (not set) | Show backend steps only |
| Mixed (frontend + backend) | Full Stack | (not set) | Show all steps |

> When Frontend framework is detected, `platform.type: frontend-web` is written to `PROJECT.md` automatically. This enables routing to `project-frontend-web-*` agents in `/sdd.spec` and `/sdd.build`.

**Frontend framework-Only Detection (No design system)**:

When only `frontend-framework` is detected without `@design-system/*` packages:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚠️  Frontend framework detectado SIN design system UI
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Tu proyecto usa Frontend framework pero no tiene componentes design system instalados.
Esto significa que usarás Custom React Components para la UI.

¿Cómo deseas manejar los componentes UI?

1. 🎨 Instalar design system (recomendado) - Mantiene consistencia con project
2. ⚛️  Usar Custom React Components - UI personalizada
3. 📖 ¿Qué es design system?

Selección [1]: _
```

**If user selects option 1 (Install design system)**:
- Save `ui_library: design-system` in PROJECT.md
- Show message: "Recuerda instalar design system: `npm install @design-system/button @design-system/textfield`"
- Continue with standard frontend steps

**If user selects option 2 (Custom UI)**:
- Save `ui_library: custom` in PROJECT.md
- Skip design system-specific configuration steps
- Show warning: "Custom components deben seguir patrones de accesibilidad (WCAG)"

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔍 Detectando stack del proyecto...
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Stack detectado:
  📦 Backend: Java (pom.xml)
  🎨 Frontend: Frontend framework 9.x + design system Web

El wizard incluirá configuración para ambos stacks.
```

### Step 1: Architecture Pattern (Backend)

> **Nota**: Este paso solo se muestra si se detectó stack backend.

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
1️⃣  Arquitectura Backend
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

What architecture pattern does your team use?

1. ⚪ Use framework default (Clean Architecture)
2. 🏛️  Clean Architecture
3. 🔷 Hexagonal Architecture
4. 📦 Layered Architecture
5. 🎯 Domain-Driven Design (DDD)
6. ✏️  Custom (describe)

Selection [1]:
```

**⛔ INVOKE TOOL (do not print this, CALL the tool):**

```
AskUserQuestion(
  questions=[{
    "question": "What architecture pattern does your team use?",
    "header": "Architecture",
    "options": [
      {"label": "Use default (no configuration)", "description": "Framework default: Clean Architecture"},
      {"label": "Clean Architecture", "description": "Separation of concerns with layers"},
      {"label": "Hexagonal Architecture", "description": "Ports and adapters pattern"},
      {"label": "Layered Architecture", "description": "Traditional layered approach"},
      {"label": "Domain-Driven Design", "description": "DDD tactical patterns"}
    ],
    "multiSelect": false
  }]
)
```

### Step 2: Testing Standards

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
2️⃣  Testing Standards
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Minimum coverage:
1. ⚪ Use framework default (80%)
2. 90% (High quality)
3. 70% (Legacy/incremental)
4. ✏️  Custom

Selection [1]: _

Ratio unit:integration:
1. ⚪ Use framework default (4:1)
2. 3:1
3. 5:1
4. ✏️  Custom

Selection [1]: _
```

**⛔ INVOKE TOOL (do not print this, CALL the tool):**

```
AskUserQuestion(
  questions=[{
    "question": "What is your minimum test coverage requirement?",
    "header": "Coverage",
    "options": [
      {"label": "Use framework default (80%)", "description": "Standard coverage threshold"},
      {"label": "90%", "description": "High quality requirement"},
      {"label": "70%", "description": "Legacy/incremental projects"},
      {"label": "Custom", "description": "Enter a custom value"}
    ],
    "multiSelect": false
  }]
)
```

**⛔ INVOKE TOOL (do not print this, CALL the tool):**

```
AskUserQuestion(
  questions=[{
    "question": "What unit to integration test ratio does your team prefer?",
    "header": "Test Ratio",
    "options": [
      {"label": "Use framework default (4:1)", "description": "4 unit tests per integration test"},
      {"label": "3:1", "description": "More integration tests"},
      {"label": "5:1", "description": "More unit tests"},
      {"label": "Custom", "description": "Enter a custom ratio"}
    ],
    "multiSelect": false
  }]
)
```

### Step 3: Team Conventions

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
3️⃣  Team Conventions
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Max lines per PR:
1. ⚪ Use framework default (400)
2. 300 (Smaller PRs)
3. 500 (Larger PRs)
4. ✏️  Custom

Selection [1]: _

Language for specs:
1. ⚪ Use framework default (English)
2. Español (es)
3. Português (pt)

Selection [1]: _
```

> **Note**: Branch prefixes are standard practice but MUST be included as a mandatory reference section in PROJECT.md.
> Always copy the FULL Branching Strategy tables from the project.md template — never abbreviate or sample.
> Commit style (Conventional Commits) is also standard practice.
> See: `development-agents/framework/standards/coding-standards.md#git-standards-platform-gitflow`

---

### Step 4: Frontend Web Configuration (Frontend framework/design system)

> Only shown when Frontend framework is detected in `package.json`.

**4. Detect design system version (MANDATORY)**

```bash
# Check for installed design system packages
grep -E '"@design-system/|"design-system' package.json
```

- If `@design-system/react` found → `design_system_version: "X"` (design system X / v2 monorepo format)
- If `@design-system/[component]` (individual packages like `@design-system/button`) found → check version in package.json:
  - Version `^9` or higher → `design_system_version: "9"`
  - Version `^8` or lower → `design_system_version: "8"` + warn the user:
    > ⚠️ design system 8 or lower detected. The SDD framework does not fully support this version — some behaviors may not work as expected. Consider migrating to design system 9 or design system X.
- If **no design system packages found** → ask the user:

  ```
  ¿Qué versión de design system usa el proyecto?
  1. design system X / v2 (import { Button } from '@design-system/react') — monorepo
  2. design system 9 (import { Button } from '@design-system/button') — individual packages
  ```

  Then invoke `Skill(frontend-web-expert)` to install the selected version.

Save to PROJECT.md:
```yaml
frontend:
  design_system_version: "[detected or user-selected]"
  frontend_framework_version: "[from package.json]"
```

> **Why this matters**: `design_system_version` determines the import format used throughout the entire project. Agents and skills use this to generate correct import statements. If undefined, agents must guess — which leads to errors.

---

### Summary & Confirmation

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 Conventions Summary
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Configured (will be saved to PROJECT.md):
| Property | Value |
|----------|-------|
| platform.type | frontend-web  ← auto-detected from package.json |
| Architecture | Hexagonal |
| Coverage | 90% |

Using framework defaults (not saved):
| Property | Default |
|----------|---------|
| Ratio unit:int | 4:1 |
| Max PR size | 400 lines |
| Specs language | English |
| Core Web Vitals | LCP < 2.5s |
| Component Coverage | 80% |

Generate PROJECT.md?

1. ✅ Yes, generate (overrides only)
2. ✏️  Adjust values
3. ❌ Cancel
```

> **Note**: PROJECT.md will only contain properties the team decided to configure.
> Others will use defaults from `coding-standards.md`. For frontend-web, `Skill(frontend-web-expert)` is the source of truth.

---

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

## Mode 3: Edit Existing

When `sdd/PROJECT.md` exists and user runs `/sdd.project --edit`:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✏️  Editing existing PROJECT.md
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Current conventions:

| Category | Current Value |
|----------|---------------|
| Architecture | Clean Architecture |
| Coverage | 80% |
| Max PR size | 400 lines |
| ... | ... |

What would you like to modify?

1. Architecture
2. Testing Standards
3. Team Conventions
4. Review Requirements
5. View all and edit YAML directly
6. Exit without changes
```

---

## Mode 4: Patterns Management

When user runs `/sdd.project patterns` (with any subcommand):

### Subcommand Detection

```
IF args contains "patterns":
    IF args contains "--add":
        → Mode 4a: Add Pattern Wizard
    ELSE IF args contains "--edit":
        → Mode 4b: Direct Edit
    ELSE IF args matches "patterns "<description>"":
        → Mode 4c: Prompt Inference
    ELSE:
        → Mode 4d: View Patterns
```

---

### Mode 4a: Add Pattern Wizard (`patterns --add`)

Interactive 4-step wizard for adding a new pattern:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
➕ Adding New Pattern to PATTERNS.md
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Step 1/4: Category
```

**Step 1: Category Selection**

**⛔ INVOKE TOOL (do not print this, CALL the tool):**

```
AskUserQuestion(
  questions=[{
    "question": "Which category does this pattern belong to?",
    "header": "Category",
    "options": [
      {"label": "Go", "description": "Go language patterns with "},
      {"label": "Java", "description": "Java/Kotlin patterns with "},
      {"label": "Node.js", "description": "Node/TypeScript patterns"},
      {"label": "Database Patterns", "description": "DB, KeyValueStore, SQL patterns"},
      {"label": "Other", "description": "Custom category (will prompt for name)"}
    ],
    "multiSelect": false
  }]
)
```

> **Note**: If user selects "Other", prompt for custom category name.

**Step 2: Pattern Name**

**⛔ INVOKE TOOL (do not print this, CALL the tool):**

```
AskUserQuestion(
  questions=[{
    "question": "What should this pattern be called? (e.g., 'HTTP Client Usage', 'Prefer axios')",
    "header": "Name",
    "options": [
      {"label": "Other", "description": "Enter pattern name"}
    ],
    "multiSelect": false
  }]
)
```

**Step 3: Pattern Content**

Display guidance then request content:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Step 3/4: Pattern Content
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Describe the pattern. Include:
• What to DO
• What NOT to do
• Why (rationale)
• Example (optional)
```

**⛔ INVOKE TOOL (do not print this, CALL the tool):**

```
AskUserQuestion(
  questions=[{
    "question": "Describe the pattern. Include what to DO, what NOT to do, why (rationale), and optionally an example.",
    "header": "Content",
    "options": [
      {"label": "Other", "description": "Enter pattern content"}
    ],
    "multiSelect": false
  }]
)
```

**Step 4: Confirmation**

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Step 4/4: Confirmation
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Preview:

**[Pattern Name]**:
- [What to do]
- [What not to do]
- Why: [Rationale]
- Added: YYYY-MM-DD via /sdd.project patterns
```

**⛔ INVOKE TOOL (do not print this, CALL the tool):**

```
AskUserQuestion(
  questions=[{
    "question": "Add this pattern to PATTERNS.md?",
    "header": "Confirm",
    "options": [
      {"label": "Yes, add pattern", "description": "Append to Team Conventions section"},
      {"label": "Edit before adding", "description": "Go back and modify"},
      {"label": "Cancel", "description": "Don't add pattern"}
    ],
    "multiSelect": false
  }]
)
```

**On Confirmation**:
1. Read `sdd/PATTERNS.md` (or create from template if doesn't exist)
2. Format pattern as markdown
3. Append to "Team Conventions (Manually Added)" section
4. Add timestamp: `- Added: YYYY-MM-DD via /sdd.project patterns`
5. Write updated file

**Success Output**:
```
✅ Pattern added to sdd/PATTERNS.md

Added to "Team Conventions (Manually Added)":
   • [Pattern Name]

Total patterns: N from team conventions, M from feature learnings
```

---

### Mode 4b: Direct Edit (`patterns --edit`)

Opens PATTERNS.md for direct editing:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✏️  Editing PATTERNS.md
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Opening sdd/PATTERNS.md...
```

**Actions**:
1. If file doesn't exist, create from `development-agents/framework/templates/PATTERNS.md`
2. Read current content and display structure summary
3. Open file for editing (use Read tool to show content, user edits via IDE)
4. Validate format after edit

---

### Mode 4c: Prompt Inference (`patterns "<description>"`)

When user provides a description:

```
/sdd.project patterns "en nuestro equipo usamos axios para HTTP,
date-fns para fechas (moment.js prohibido), y siempre repository pattern"
```

**Inference Process**:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔍 Analyzing description...
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Patterns detected:

| # | Category     | Pattern              | Type        |
|---|--------------|----------------------|-------------|
| 1 | HTTP/API     | Use axios            | Preferred   |
| 2 | Utilities    | Use date-fns         | Preferred   |
| 3 | Utilities    | Forbidden: moment.js | Forbidden   |
| 4 | Architecture | Repository pattern   | Convention  |
```

**Pattern Detection Rules**:

| Text Pattern | Detected Pattern |
|--------------|------------------|
| "usar X", "use X", "siempre X" | Preferred: X |
| "prohibido X", "forbidden X", "never X", "no usar X" | Forbidden: X |
| "X pattern", "pattern X" | Architecture convention: X |
| "X en vez de Y", "X instead of Y" | Preferred: X, Forbidden: Y |

**Confirmation**:

**⛔ INVOKE TOOL (do not print this, CALL the tool):**

```
AskUserQuestion(
  questions=[{
    "question": "What would you like to do with these N patterns?",
    "header": "Action",
    "options": [
      {"label": "Add all N patterns", "description": "Append all to Team Conventions"},
      {"label": "Review individually", "description": "Confirm each pattern"},
      {"label": "Cancel", "description": "Don't add patterns"}
    ],
    "multiSelect": false
  }]
)
```

**On "Add all"**: Append all patterns to PATTERNS.md with timestamps.

---

### Mode 4d: View Patterns (`patterns`)

When user runs `/sdd.project patterns` without flags:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 Current Project Patterns
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Location: sdd/PATTERNS.md

| Category              | Count | Last Updated |
|-----------------------|-------|--------------|
| Team Conventions      | 3     | 2026-01-29   |
| Go    | 4     | 2026-01-20   |
| Database Patterns     | 2     | 2026-01-15   |

Total: 9 patterns
```

**⛔ INVOKE TOOL (do not print this, CALL the tool):**

```
AskUserQuestion(
  questions=[{
    "question": "What would you like to do?",
    "header": "Action",
    "options": [
      {"label": "Add new pattern", "description": "Interactive wizard"},
      {"label": "Edit patterns", "description": "Open PATTERNS.md for editing"},
      {"label": "Exit", "description": "Close patterns view"}
    ],
    "multiSelect": false
  }]
)
```

**If file doesn't exist**:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 No PATTERNS.md found
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

sdd/PATTERNS.md doesn't exist yet.

Create it now?
```

**⛔ INVOKE TOOL (do not print this, CALL the tool):**

```
AskUserQuestion(
  questions=[{
    "question": "Create PATTERNS.md now?",
    "header": "Create",
    "options": [
      {"label": "Create and add pattern", "description": "Create file and start wizard"},
      {"label": "Create empty", "description": "Create file from template"},
      {"label": "Cancel", "description": "Don't create file"}
    ],
    "multiSelect": false
  }]
)
```

---

### Pattern Format Validation

Before writing to PATTERNS.md, validate:

1. **Category exists**: Pattern must be under a valid section header (`## Category Name`)
2. **Name format**: Pattern name must be bold (`**Name**:`)
3. **Content present**: At least one line of content
4. **No duplicates**: Check if pattern with same name already exists

**If duplicate detected**:
```
⚠️ Pattern "[Name]" already exists in PATTERNS.md

What would you like to do?
1. Update existing pattern
2. Add as new (with suffix)
3. Cancel
```

---

### PATTERNS.md Update Rules

**Section order**:
1. Header + purpose
2. "Team Conventions (Manually Added)" - patterns from `/sdd.project patterns`
3. Technology sections (Go, Java, etc.) - patterns from `/sdd.finish`
4. Last Updated section

**Adding to "Team Conventions"**:
```markdown
## Team Conventions (Manually Added)

**[Pattern Name]**:
- [What to do]
- [What not to do]
- Why: [Rationale]
- Added: YYYY-MM-DD via /sdd.project patterns
```

**Compatibility with /sdd.finish**:
- `/sdd.finish` adds patterns to technology-specific sections
- `/sdd.project patterns` adds to "Team Conventions" section
- Both coexist without conflict

---

## Mode 5: Profile Management

When user runs `/sdd.project profile` (with or without flags):

### Subcommand Detection

```
IF args contains "profile":
    IF args contains "--edit":
        → Mode 5b: Edit Profile Interactively
    ELSE:
        → Mode 5a: View Profile
```

---

### Mode 5a: View Profile (`profile`)

When user runs `/sdd.project profile`:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
👤 Current User Profile
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Profile: technical
Selected: 2026-01-29

Plan Mode Settings:
  ✅ Complex bug fixes (fix_complex_bugs)
  ✅ Technical spec in brownfield (spec_technical_brownfield)
  ❌ Complex build tasks (build_complex_tasks)
  ❌ Layer transitions (build_layer_transitions)
  ❌  test recovery (build_ci_test_recovery)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

To update: /sdd.project profile --edit
Config file: development-agents/framework/user-profile.yaml
```

**For non-technical profile**:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
👤 Current User Profile
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Profile: non-technical (Business/Product focus)
Selected: 2026-01-29

Behavior:
  • Express mode always active
  • Agent handles all technical decisions
  • Simplified output (no layers, project services, code snippets)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

To update: /sdd.project profile --edit
Config file: development-agents/framework/user-profile.yaml
```

**If no profile exists**:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
👤 No User Profile Found
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

You haven't selected a profile yet.
A profile will be created automatically during /sdd.start.

To create one now: /sdd.project profile --edit
```

---

### Mode 5b: Edit Profile (`profile --edit`)

Interactive profile update flow:

#### Step 1: Show Current Profile (if exists)

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✏️  Editing User Profile
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Current settings:
  Profile: technical
  Plan Mode: fix_complex_bugs, spec_technical_brownfield
```

#### Step 2: Profile Type Selection

Display behavior summary (same as /sdd.start Step 5.5):

```
┌─────────────────────────────────────────────────────────────────┐
│ BUSINESS/PRODUCT FOCUS                                          │
├─────────────────────────────────────────────────────────────────┤
│ • Focus on WHAT to build, agent handles HOW                     │
│ • Simplified output (no layers, project services, code snippets)        │
│ • Agent makes all technical decisions automatically             │
│ • Express mode always active (fastest flow)                     │
│ • Time estimates instead of complexity ratings                  │
│ • Questions in plain language                                   │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│ TECHNICAL FOCUS                                                 │
├─────────────────────────────────────────────────────────────────┤
│ • Full control over architecture decisions                      │
│ • See layers, project services, code snippets                      │
│ • Choose execution mode (express/standard/expert)               │
│ • Complexity ratings (Low/Medium/High)                          │
│ • Plan Mode for complex operations (configurable)               │
│ • Detailed error messages with stack traces                     │
└─────────────────────────────────────────────────────────────────┘
```

**⛔ INVOKE TOOL (do not print this, CALL the tool):**

```
AskUserQuestion(
  questions=[{
    "question": "Which profile matches how you want to work?",
    "header": "Profile",
    "options": [
      {"label": "Business/Product focus", "description": "Focus on WHAT to build. Agent handles technical decisions."},
      {"label": "Technical focus", "description": "Full control. See layers, project services, architecture details."}
    ],
    "multiSelect": false
  }]
)
```

#### Step 3: Plan Mode Settings (Technical Only)

If user selects "Technical focus", show Plan Mode configuration:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚙️ Plan Mode Preferences
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Plan Mode pauses before complex operations for your approval.
(Only available in Claude Code CLI)
```

**⛔ INVOKE TOOL (do not print this, CALL the tool):**

```
AskUserQuestion(
  questions=[{
    "question": "Enable Plan Mode for which scenarios?",
    "header": "Plan Mode",
    "options": [
      {"label": "Complex bug fixes (Recommended)", "description": "Pause before investigating DESIGN_FLAW or FEATURE_GAP errors"},
      {"label": "Technical spec in brownfield (Recommended)", "description": "Explore existing code before architecture decisions"},
      {"label": "Complex build tasks", "description": "Pause before high-complexity tasks or Layer 2"},
      {"label": "None", "description": "Never pause - implement directly"}
    ],
    "multiSelect": true
  }]
)
```

#### Step 4: Save and Confirm

Update `development-agents/framework/user-profile.yaml` with new settings.

**Success output**:
```
✅ Profile updated: technical

📋 Your settings:
   • Full technical detail in outputs
   • Plan Mode enabled for: complex bugs, brownfield specs
   • Execution mode: your choice per feature

Config file: development-agents/framework/user-profile.yaml
```

---

### Profile File Format

**Technical profile** (`development-agents/framework/user-profile.yaml`):

```yaml
# SDD Kit User Profile
# Generated: 2026-01-29T10:30:00Z
#
# To update these settings:
#   /sdd.project profile        → View current settings
#   /sdd.project profile --edit → Interactive update
#   Delete this file            → Re-select from scratch

profile: technical  # technical | non-technical

# Plan Mode settings (technical profile only)
# These control when the agent pauses for your approval
plan_mode:
  fix_complex_bugs: true           # DESIGN_FLAW, FEATURE_GAP errors
  spec_technical_brownfield: true  # Explore code before architecture
  build_complex_tasks: false       # High complexity, >5 files, Layer 2
  build_layer_transitions: false   # L1→L2, context >50%, 10+ tasks
  build_ci_test_recovery: false  # Ambiguous project CI test failures
```

**Non-technical profile**:

```yaml
# SDD Kit User Profile
# Generated: 2026-01-29T10:30:00Z
#
# To update these settings:
#   /sdd.project profile        → View current settings
#   /sdd.project profile --edit → Interactive update
#   Delete this file            → Re-select from scratch

profile: non-technical  # technical | non-technical

# Non-technical profile: Express mode always active
# Agent handles all technical decisions automatically
```

---

## Mode 6: Vision Management

When user runs `/sdd.project vision` (with or without flags):

### Subcommand Detection

```
IF args contains "vision":
    IF args contains "--edit":
        → Mode 6b: Edit Vision
    ELSE:
        → Mode 6a: Vision Wizard
```

---

### Mode 6a: Vision Wizard (`vision`)

Interactive 3-step wizard for defining product vision:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎯 Defining Product Vision
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Product vision helps ensure all features align with your product's purpose.
I'll ask 3 quick questions to define it.
```

**Step V1: Product Summary**

**⛔ INVOKE TOOL (do not print this, CALL the tool):**

```
AskUserQuestion(
  questions=[{
    "question": "What does your product do in one sentence? (e.g., 'A CLI tool that helps developers implement features using spec-driven development')",
    "header": "Summary",
    "options": [
      {"label": "Other", "description": "Enter product summary"}
    ],
    "multiSelect": false
  }]
)
```

**Step V2: Value Proposition**

**⛔ INVOKE TOOL (do not print this, CALL the tool):**

```
AskUserQuestion(
  questions=[{
    "question": "What problem does it solve and why should users care?",
    "header": "Value",
    "options": [
      {"label": "Other", "description": "Enter value proposition"}
    ],
    "multiSelect": false
  }]
)
```

**Step V3: Guiding Principles (Optional)**

**⛔ INVOKE TOOL (do not print this, CALL the tool):**

```
AskUserQuestion(
  questions=[{
    "question": "What 2-3 principles should guide all features? (Examples: 'Simplicity over features', 'User privacy first')",
    "header": "Principles",
    "options": [
      {"label": "Enter principles now", "description": "I'll provide 2-3 guiding principles"},
      {"label": "Skip for now", "description": "I can add principles later"}
    ],
    "multiSelect": false
  }]
)
```

**If user enters principles**: Ask for free text input.

**Step V4: Confirmation**

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 Vision Summary
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

**Summary**: [user's summary]
**Value Proposition**: [user's value proposition]
**Principles**: [user's principles or "Not defined"]

Save this vision to PROJECT.md?
```

**⛔ INVOKE TOOL (do not print this, CALL the tool):**

```
AskUserQuestion(
  questions=[{
    "question": "Save this vision to PROJECT.md?",
    "header": "Confirm",
    "options": [
      {"label": "Yes, save vision", "description": "Write to PROJECT.md"},
      {"label": "Edit before saving", "description": "Go back and modify"},
      {"label": "Cancel", "description": "Don't save vision"}
    ],
    "multiSelect": false
  }]
)
```

**On Confirmation**:
1. Read `sdd/PROJECT.md` (or create if doesn't exist)
2. Find or create `## Project Vision` section
3. Uncomment/populate the vision YAML block
4. Write updated file

**Success Output**:
```
✅ Vision saved to sdd/PROJECT.md

Your features will now be guided by:
• Summary: [summary]
• Value: [value proposition]
• Principles: [principles count] defined

Vision will be used during /sdd.spec to align features with product goals.
```

---

### Mode 6b: Edit Vision (`vision --edit`)

When editing existing vision:

1. Read current vision from PROJECT.md
2. Display current values
3. Use AskUserQuestion for each field with current value as default
4. Show diff of changes
5. Confirm and save

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✏️  Editing Product Vision
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Current vision:
• Summary: [current summary]
• Value: [current value proposition]
• Principles: [current principles]

Which field would you like to edit?
```

**⛔ INVOKE TOOL (do not print this, CALL the tool):**

```
AskUserQuestion(
  questions=[{
    "question": "Which field would you like to edit?",
    "header": "Edit Vision",
    "options": [
      {"label": "Summary", "description": "Edit product summary"},
      {"label": "Value proposition", "description": "Edit value proposition"},
      {"label": "Principles", "description": "Edit guiding principles"},
      {"label": "All fields", "description": "Re-run full wizard"},
      {"label": "Exit", "description": "Keep current vision"}
    ],
    "multiSelect": false
  }]
)
```

---

### Vision Section Format in PROJECT.md

```yaml
## Project Vision

vision:
  summary: "A CLI tool that helps developers implement features using spec-driven development"
  target_users: "Developers and technical leads at your team"
  value_proposition: "Reduces cognitive load by automating spec-to-code workflow while maintaining quality"
  principles:
    - "Simplicity over features"
    - "Convention over configuration"
    - "Fail fast, recover gracefully"
  anti_goals:
    - "Not a replacement for human code review"
    - "Not for non-technical users"
```

---

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

## CLAUDE.md Sync on Language Change

> **MANDATORY**: After writing/updating PROJECT.md, sync the spec language to CLAUDE.md if it exists.

**When to execute**: After ANY write to PROJECT.md that includes `language.specs` (wizard, prompt inference, or `--edit`).

```pseudocode
IF .claude/ directory exists AND CLAUDE.md exists:
    # Resolve language from just-written PROJECT.md
    spec_lang = read language.specs from sdd/PROJECT.md (fallback: "en")
    lang_names = { "en": "English", "es": "Spanish (Español)", "pt": "Portuguese (Português)" }
    lang_name = lang_names[spec_lang] or "English"

    IF CLAUDE.md contains "## SDD Kit":
        → Replace existing "## SDD Kit" section with updated language
           (from that header to the next ## header or end of file)
    ELSE:
        → Append SDD Kit section to end of CLAUDE.md
```

**SDD Kit section** (same template as `/sdd.start` Step 9.5):
```markdown
## SDD Kit

This project uses **SDD Kit** for spec-driven development.

### Spec Language
All specifications MUST be written in **[lang_name]** (`[spec_lang]`).
Do not mix languages in specs. Technical terms (API, REST, CRUD) stay in English.

### Quick Reference
- Framework expert: `Skill("sdd-kit-expert")`
- Workflow: `/sdd.start` → `/sdd.spec` → `/sdd.plan` → `/sdd.build` → `/sdd.finish`
- Project conventions: `sdd/PROJECT.md`
- Discovered patterns: `sdd/PATTERNS.md`

### Rules
- Never create files under `sdd/specs/`, `sdd/wip/`, or `sdd/features/` manually
- Always go through the `/sdd.start` workflow
- Respect the phased workflow — don't skip phases
```

**Important**: Only replace the `## SDD Kit` section — never touch any other content in CLAUDE.md.

---

## Integration with /sdd.start

When `/sdd.start` is run and `sdd/PROJECT.md` doesn't exist:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚠️  PROJECT.md not found
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

PROJECT.md defines your team's conventions (architecture,
testing, code review). Without it, framework defaults will be used.

What would you like to do?

1. 🔧 Create PROJECT.md now (/sdd.project)
2. ⏭️  Continue with framework defaults
3. 📖 What is PROJECT.md?
```

**If user selects option 1**: Execute `/sdd.project` flow
**If user selects option 2**: Continue with `/sdd.start` using framework defaults
**If user selects option 3**: Show explanation:

```
📖 What is PROJECT.md?

PROJECT.md is an optional file that defines your team's
conventions for this project:

• Architecture pattern (Clean, Hexagonal, etc.)
• Testing standards (coverage %, ratios)
• Code conventions (PR size, commits, branches)
• Review requirements (code review, spec approval)

Without PROJECT.md, the framework uses default values that work
for most projects. You can create it at any time
with /sdd.project.

See more: development-agents/framework/CONFIGURATION.md
```

---

## Validation

Before generating PROJECT.md, validate:

1. **Directory exists**: `sdd/` directory exists (create if not)
2. **No conflicts**: If PROJECT.md exists and not using `--edit`, ask for confirmation
3. **Values in range**: Coverage 0-100, PR lines > 0, etc.

---

## Example Session: Interactive

```
User: /sdd.project

AI: 🔧 Configuring PROJECT.md for your team...

[Shows Step 1: Architecture]

User: 3 (Hexagonal Architecture)

AI: [Shows Step 2: Testing]

User: 2 (90% coverage)
User: 1 (Use default ratio 4:1)

AI: [Shows Step 3: Conventions]

User: 1 (Use default PR size 400)
User: 2 (Español)

AI: [Shows Summary]

    📋 Conventions Summary

    Configured (will be saved to PROJECT.md):
    | Property | Value |
    |----------|-------|
    | Architecture | Hexagonal |
    | Coverage | 90% |
    | Language | Español |

    Using framework defaults (not saved):
    | Property | Default |
    |----------|---------|
    | Ratio unit:int | 4:1 |
    | Max PR size | 400 lines |

    Generate PROJECT.md?

User: 1 (Yes)

AI: ✅ PROJECT.md generated at sdd/PROJECT.md

    Only the 3 configured overrides were saved.
    You can now start features with /sdd.start.
```

---

## Example Session: Prompt Mode

```
User: /sdd.project "Equipo backend, hexagonal architecture,
      coverage 85%, specs en español"

AI: 🔍 Analyzing description...

    Overrides detected (will be saved):
    | Property | Value | Confidence |
    |----------|-------|------------|
    | Architecture | Hexagonal | ✅ High |
    | Coverage | 85% | ✅ High |
    | Language | es | ✅ High |

    Using defaults (not mentioned):
    | Property | Default |
    |----------|---------|
    | Ratio | 4:1 |
    | PR max | 400 |

    Generate PROJECT.md with the 3 overrides only?

User: 1 (Yes)

AI: ✅ PROJECT.md generated at sdd/PROJECT.md

    Contains: architecture, coverage, language
```

---

## Example Session: Frontend Web Project

```
User: /sdd.project

AI: 🔧 Configurando PROJECT.md para tu equipo...

    🔍 Detectando stack del proyecto...

    Stack detectado:
      🎨 Frontend: Frontend framework 9.1.0

    ✓ Frontend framework version: 9
    ✓ design system version: no @design-system/* packages found in package.json

    ¿Qué versión de design system usa el proyecto?
    1. design system X / v2 (import { Button } from '@design-system/react') — monorepo
    2. design system 9 (import { Button } from '@design-system/button') — individual packages

User: 2

AI: [Shows backend conventions steps if applicable]

    📋 Resumen de Convenciones

    🎨 Frontend Web:
    | Propiedad | Valor |
    |-----------|-------|
    | platform.type | frontend-web ← auto-detected |
    | frontend_framework_version | 9 ← from package.json |
    | design_system_version | 9 ← user selected |

    ¿Generar PROJECT.md?

User: 1 (Sí)

AI: ✅ PROJECT.md generado en sdd/PROJECT.md

    Ahora podés iniciar features con /sdd.start.
```

---

## Example Session: Prompt Mode (Frontend)

```
User: /sdd.project "Proyecto Frontend framework con design system 9"

AI: 🔍 Detectando stack del proyecto...

    Stack detectado:
      🎨 Frontend: Frontend framework 9.1.0

    ✓ Frontend framework version: 9
    ✓ design system version: 9 ← detected from @design-system/button in package.json

    No se detectaron overrides de configuración adicionales.

    ¿Generar PROJECT.md?

User: 1 (Sí)

AI: ✅ PROJECT.md generado en sdd/PROJECT.md

    Contiene: platform.type, frontend.design_system_version, frontend.frontend_framework_version
```

---

## Error Handling

**PROJECT.md already exists**:
```
⚠️  PROJECT.md already exists at sdd/PROJECT.md

What would you like to do?
1. ✏️  Edit existing (/sdd.project --edit)
2. 🔄 Overwrite (lose current configuration)
3. ❌ Cancel
```

**Invalid values**:
```
❌ Invalid value: coverage must be between 0 and 100

Minimum coverage [80]: ___
```

---

## Related Commands

| Command | Relationship |
|---------|--------------|
| `/sdd.start` | Suggests `/sdd.project` if PROJECT.md missing |
| `/sdd.check --project` | Validates PROJECT.md against framework standards |
| `/sdd.help project` | Shows PROJECT.md documentation |

---

> **Lazy-loaded**: When `--view` is present, Read `references/project-view.md` and follow it.

---

## AI Agent Instructions


### Help Flag Detection

**WHEN** the user runs `/sdd.project help`:
1. Output ONLY the "Quick Help" section (not full documentation)
2. Do NOT execute project logic
3. Keep response concise (~15 lines)

## Optional flags (lazy-loaded)

**Before the standard wizard**, if any flag below is present, read its reference first:

| Flag | Reference | Behavior |
|------|-----------|----------|
| `--hub` | `references/project-hub.md` | Replace standard wizard |
| `--view` | `references/project-view.md` | Replace all other logic |
| `--audio` | `references/audio-capture-flow.md` | Feeds wizard interview answers |
