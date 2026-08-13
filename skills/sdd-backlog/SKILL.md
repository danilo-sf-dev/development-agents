---
name: sdd-backlog
description: Backlog management specialist for SDD Kit. Use for CRUD operations on sdd/backlog.md during /sdd.backlog command. Handles TODO, DEBT, and IDEA categorization, priority ranking, and backlog-to-feature conversion.
---

# SDD Backlog — Backlog Operations Specialist

> **Execution requirement**: none for the normal case — runs inline (`INVOKE_PROCEDURE`). `DELEGATE_OFFLOAD` only for large backlogs, where reading/rewriting the whole file would otherwise dominate the calling session's context — see `framework/_shared/harness-capabilities.md`. This is a generic offload (no integrity/isolation requirement), not `OFFLOAD_READ` — this Skill **writes** to `sdd/backlog.md` as part of normal operation.

You are performing backlog-management operations for the SDD Kit framework. Your role is to efficiently manage the centralized backlog file with CRUD operations.

**Schema note**: The backlog-item schema in this file is the same schema `/sdd.backlog` uses in practice, documented canonically in `commands/references/backlog-file-format.md`. If the two ever disagree, `backlog-file-format.md` wins — treat it as ground truth and update this file to match.

## When to Use This Skill

1. **Backlog Command** (`/sdd.backlog`)
   - List backlog items
   - Add new items
   - Update existing items
   - Resolve completed items

   `/sdd.backlog` handles small/normal-sized backlogs inline via its own lazy-loaded references. Offloading is a context-saving choice for large backlogs, not a requirement.

2. **Feature Start** (`/sdd.start --from-backlog`)
   - Convert backlog item to feature
   - Update backlog status

3. **During Build** (`/sdd.build`)
   - Auto-capture discovered TODOs
   - Flag technical debt

## Backlog File Location

```
sdd/backlog.md
```

## Backlog Structure

```markdown
# Technical Backlog

> Items captured during development. Use `/sdd.backlog` to manage.

**Last Updated**: YYYY-MM-DD
**Total Items**: N (X TODO, Y DEBT, Z IDEA)

---

## 📋 TODOs

### TODO-001: [Title]
- **Priority**: High | Medium | Low
- **Status**: pending | resolved
- **Created**: YYYY-MM-DD
- **Origin**: [feature-name] (during /sdd.build) | manual
- **Context**: [Brief description of why this is needed]
- **Affected Files**: [paths]
- **Complexity**: Low | Medium | High

---

## 🔧 Technical Debt

### DEBT-001: [Title]
- **Priority**: High | Medium | Low
- **Status**: pending | resolved
- **Created**: YYYY-MM-DD
- **Origin**: [feature-name] (during /sdd.build) | manual
- **Context**: [What needs refactoring and why]
- **Affected Files**: [paths]
- **Complexity**: Low | Medium | High
- **Risk if Ignored**: [What happens if not addressed]

---

## 💡 Ideas

### IDEA-001: [Title]
- **Priority**: High | Medium | Low
- **Status**: pending | resolved
- **Created**: YYYY-MM-DD
- **Origin**: [feature-name] (during /sdd.build) | manual
- **Context**: [The idea]
- **Potential Impact**: [Performance, UX, Maintainability, etc.]
- **Notes**: [Additional context]

model_role: EXECUTION
---

## ✅ Resolved Items

### TODO-002: [Title]
- **Priority**: High | Medium | Low
- **Status**: resolved
- **Created**: YYYY-MM-DD
- **Resolved**: YYYY-MM-DD
- **Resolution**: Completed | Won't Do | Duplicate
- **Resolved In**: [feature name, if applicable]
```

## Operations

### 1. List Items

```markdown
## Backlog Summary

| Type | Count | High Priority |
|------|-------|----------------|
| TODO | 5 | 1 |
| DEBT | 3 | 2 |
| IDEA | 8 | - |

### TODOs by Priority
| ID | Title | Priority | Complexity |
|----|-------|----------|------------|
| TODO-001 | Add caching | High | Medium |
| TODO-002 | Fix login | Medium | Low |

### DEBT by Priority
| ID | Title | Priority | Affected Files |
|----|-------|----------|-----------------|
| DEBT-001 | Legacy auth | High | auth/ |
```

### 2. Add Item

**Input**: Type, Title, Priority, Context, Affected Files (TODO/DEBT), Complexity, plus type-specific fields (`Risk if Ignored` for DEBT; `Potential Impact` / `Notes` for IDEA)
**Output**: New item added with auto-generated ID and `Status: pending`

```markdown
### TODO-006: [New Title]
- **Priority**: [assigned: High | Medium | Low]
- **Status**: pending
- **Created**: [today]
- **Origin**: manual
- **Context**: [provided]
- **Affected Files**: [provided]
- **Complexity**: [estimated: Low | Medium | High]
```

### 3. Update Item

**Input**: ID, Field, New Value
**Output**: Item updated

```markdown
Updated TODO-003:
- Priority: Medium → High
- Complexity: Medium → High
```

### 4. Resolve Item

**Input**: ID, Resolution (`Completed` | `Won't Do` | `Duplicate`), Resolved In (optional)
**Output**: Item's `Status` flips to `resolved`, item moves to the `## ✅ Resolved Items` section, original fields (Priority, Created, Context, Affected Files, Complexity, etc.) are preserved as-is

```markdown
Resolving TODO-003...
- Status: pending → resolved
- Resolved: [today]
- Resolution: Completed
- Resolved In: feature/db-optimization

Moved TODO-003 to "## ✅ Resolved Items" section
```

### 5. Convert to Feature

**Input**: Item ID
**Output**: Feature initialization data

```markdown
Converting TODO-001 to feature...

Feature Name: refactor-payment-validation
Based On: TODO-001

Initial Functional Spec Content:
- Problem Statement: from item's Context field
- Suggested Files: from item's Affected Files field
- Complexity: from item's Complexity field

Backlog Item:
- Status remains "pending" until the feature is finished and the item is
  explicitly resolved (there is no separate "in-progress" status or
  "linked feature" field in the real schema — see
  commands/references/backlog-file-format.md). If you want the link
  recorded, note the feature name in the item's Context field.
- Once the feature ships, run `/sdd.backlog resolve TODO-001` with
  Resolution: Completed and Resolved In: refactor-payment-validation.
```

## Auto-Capture Format

When `/sdd.build` discovers issues:

```markdown
### DEBT-XXX: [Auto-captured] [Issue description]
- **Priority**: [inferred: High | Medium | Low]
- **Status**: pending
- **Created**: [today]
- **Origin**: [feature-name] (during /sdd.build)
- **Context**: [details from build]
- **Affected Files**: [file path]
- **Complexity**: [inferred: Low | Medium | High]
- **Risk if Ignored**: [inferred impact of not addressing it]
```

## ID Generation

- **TODO**: TODO-001, TODO-002, ... (sequential)
- **DEBT**: DEBT-001, DEBT-002, ... (sequential)
- **IDEA**: IDEA-001, IDEA-002, ... (sequential)

IDs are permanent: a resolved item keeps its original ID and type prefix — it
only moves to the `## ✅ Resolved Items` section with `Status: resolved`.
When generating a new ID, find the max existing number for that prefix
across BOTH the active sections and the Resolved section, then increment.
Never reuse an ID that appears anywhere in the file.

## Priority Definitions

| Priority | Meaning                                               | Timeline                   |
| ---------- | -------------------------------------------------------- | ----------------------------- |
| High     | Critical/urgent — blocks work or causes real problems | This sprint                |
| Medium   | Important, should be scheduled                        | Next sprint / this quarter |
| Low      | Nice to have, no urgency                               | Someday                    |

Priority is the single field that expresses urgency/severity for every item
type (TODO, DEBT, IDEA). The real schema has no separate Severity field —
for DEBT items, use Priority itself to reflect how severe the debt is.

## Complexity Definitions

| Complexity | Meaning                               | Scope                            |
| ------------ | ---------------------------------------- | ----------------------------------- |
| Low        | Simple fix, minimal changes           | Single file or small change      |
| Medium     | Multiple components, moderate scope   | Several files, some coordination |
| High       | Cross-cutting or architectural impact | Major feature, significant scope |

## Output Format

### Operation Result

```markdown
## Backlog Operation: [operation type]

### Result: SUCCESS | FAILED

### Changes Made
- [Change 1]
- [Change 2]

### Current Stats
| Type | Before | After |
|------|--------|-------|
| TODO | 5 | 6 |
| DEBT | 3 | 3 |
| IDEA | 8 | 8 |

### Next Actions
- [Suggestion based on operation]
```

## Important Rules

1. **Preserve Format**: Maintain exact markdown structure and field names from `backlog-file-format.md`
2. **Sequential IDs**: Never reuse IDs, always increment (scanning active + Resolved sections)
3. **Date Stamps**: Always use YYYY-MM-DD format
4. **Auto-capture Attribution**: Set `Origin` clearly (e.g. `feature/payment-gateway (during /sdd.build)`)
5. **Archive, Don't Delete**: Move resolved items to the `## ✅ Resolved Items` section, never delete them
6. **Validation**: Ensure required fields are present — `Priority`, `Status`, `Created`, `Origin`, `Context`, `Complexity` for every item, plus `Affected Files` for TODO/DEBT, `Risk if Ignored` for DEBT, and `Potential Impact`/`Notes` for IDEA
