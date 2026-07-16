# Reference: PROJECT.md Purpose Scope

**Used by**: `/sdd.project` scope guidance.

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
