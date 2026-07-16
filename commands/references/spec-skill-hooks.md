# Reference: Spec Skill Hooks

**Used by**: `/sdd.spec` when skill hooks are configured for `spec-functional` / `spec-technical`.

## Skill Hooks (Extension Points)

This skill supports external skill hooks at 3 trigger points per sub-phase. Hooks can target `spec-functional` and/or `spec-technical` phases independently.

**Resolution steps** (at each extension point):
1. Read `.claude/skill-hooks.json` and `development-agents/framework/skill-hooks.json`
2. Scan installed skills in `~/.claude/skills/*/SKILL.md` for `metadata` with `sdd-kit-*` keys
3. Merge with precedence: user override > repo config > auto-declaration
4. For each enabled hook matching the current phase and trigger, ordered by priority:
   - If `hook.mode == "required"`: invoke `Skill("<hook.skill>")` with current feature context
   - If `hook.mode == "available"` (default): evaluate if the hook is relevant to the current feature. Only invoke if the feature context suggests it adds value. Skip silently if irrelevant.

| Trigger | When (functional) | When (technical) |
|---------|-------------------|-----------------|
| `before-start` | Before Step 2 (interview) | Before Step 5 (technical spec) |
| `after-implementation` | After spec draft generated | After technical spec generated |
| `before-approval` | Before Step 3 (approval) | Before Step 6 (approval) |

---
