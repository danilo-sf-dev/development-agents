# Reference: Project Example Sessions

**Used by**: `/sdd.project` help/examples.

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
