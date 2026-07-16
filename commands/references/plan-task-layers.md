# Reference: Plan Task Layers

**Used by**: `/sdd.plan` layer assignment detail.

## Task Layers

| Layer | Name | Purpose | GATEs |
|-------|------|---------|-------|
| **1** | Local | Works locally | `build`, `test`, `curl localhost` |
| **2** | Integration | project services | CI Pipeline, service configs |
| **3** | Quality | Validation | `project-*-expert` skills |

**Layer 3 MUST contain exactly 3 tasks**:
1. Code Review → `sdd-code-reviewer`
2. Performance Review → `sdd-performance-expert`
3. Security Review → `sdd-code-reviewer`

> **Security Review Task**: Invoke `Skill(skill="sdd-code-reviewer")` to run
> security rules analysis and vulnerability review for the detected technology stack.

---

> **Lazy-loaded**: When `--refine` is present (or user chooses "Adjust tasks"), Read `references/plan-refine.md`.

---
