# Reference: Backlog File Format

**Used by**: `/sdd.backlog` when editing `sdd/backlog.md`.

## Backlog File Format

### Location: `sdd/backlog.md`

```markdown
# Technical Backlog

> Items captured during development. Use `/sdd.backlog` to manage.

**Last Updated**: 2025-12-10
**Total Items**: 5 (2 TODO, 1 DEBT, 2 IDEA)

---

## 📋 TODOs

### TODO-001: Refactor payment validation
- **Priority**: High
- **Status**: pending
- **Created**: 2025-12-01
- **Origin**: feature/payment-gateway (during /sdd.build)
- **Context**: Current validator uses fragile regex, should use library
- **Affected Files**: src/validators/payment.ts
- **Complexity**: Medium

---

## 🔧 Technical Debt

### DEBT-001: Migrate from callbacks to async/await
- **Priority**: Low
- **Status**: pending
- **Created**: 2025-11-20
- **Origin**: feature/legacy-import
- **Context**: Import module uses legacy callbacks
- **Affected Files**: src/importers/*.ts
- **Complexity**: High
- **Risk if Ignored**: Degraded maintainability

---

## 💡 Ideas

### IDEA-001: Search results cache
- **Priority**: Medium
- **Status**: pending
- **Created**: 2025-12-03
- **Origin**: feature/search-optimization
- **Context**: Could improve performance 10x
- **Potential Impact**: Performance
- **Notes**: Evaluate Redis vs in-memory

---

## ✅ Resolved Items

### TODO-002: Add structured logging
- **Priority**: Medium
- **Status**: resolved
- **Created**: 2025-11-25
- **Resolved**: 2025-12-08
- **Resolution**: Completed
- **Resolved In**: feature/observability-upgrade
```

---
