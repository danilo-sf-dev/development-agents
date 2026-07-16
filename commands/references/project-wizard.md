# Reference: Project Interactive Wizard

**Used by**: `/sdd.project` Mode 1.

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
