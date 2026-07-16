# Reference: Finish Validation Delegation

**Used by**: `/sdd.finish` when needing full delegation ASCII/details.

## Validation Delegation (MANDATORY)

> **CRITICAL**: Validation MUST use Skills (universal) and Subagents (Claude Code).

```
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃  🔧 MANDATORY VALIDATIONS FOR /sdd.finish                               ┃
┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┫
┃                                                                          ┃
┃  SKILLS (Work on ALL tools: Claude Code, Cursor, Codex):           ┃
┃    sdd-validator       → Build, tests, coverage, ┃
┃    sdd-code-reviewer → Security Rules & Vulns Review                          ┃
┃    sdd-code-reviewer   → Final code review verification (BLOCKING)      ┃
┃                                                                          ┃
┃  SUBAGENTS (Claude Code only):                                           ┃
┃    sdd-layer-analyzer  → Final spec-task-code consistency check         ┃
┃    NOTE: /sdd.finish uses subagent (NOT GenAI) for blocking validation  ┃
┃                                                                          ┃
┃  WORKFLOW:                                                               ┃
┃  1. Skill(skill="sdd-validator")         → Run all validations          ┃
┃  2. Skill(skill="sdd-code-reviewer")   → Security Rules & Vulns Review ┃
┃  3. Skill(skill="sdd-code-reviewer")     → Final code review            ┃
┃  4. Task(subagent_type="sdd-layer-analyzer", ...) → Final consistency   ┃
┃     (Skip step 4 if not on Claude Code)                                  ┃
┃                                                                          ┃
┃  STEPS 1-3 MUST PASS before archiving.                                   ┃
┃  Step 4 is additional validation on Claude Code.                         ┃
┃                                                                          ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
```

---
