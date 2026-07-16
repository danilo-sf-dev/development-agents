# Reference: Finish Skill Hooks

**Used by**: `/sdd.finish` when hooks are configured.

## Skill Hooks (Extension Points)

This skill supports external skill hooks at 3 trigger points.

**Resolution steps** (at each extension point):
1. Read `.claude/skill-hooks.json` and `development-agents/framework/skill-hooks.json`
2. Scan installed skills in `~/.claude/skills/*/SKILL.md` for `metadata` with `sdd-kit-*` keys
3. Merge with precedence: user override > repo config > auto-declaration
4. For each enabled hook matching phase=`finish` and the current trigger, ordered by priority:
   - If `hook.mode == "required"`: invoke `Skill("<hook.skill>")` with current feature context
   - If `hook.mode == "available"` (default): evaluate if the hook is relevant to the current feature. Only invoke if the feature context suggests it adds value. Skip silently if irrelevant.

| Trigger | When | Location in workflow |
|---------|------|---------------------|
| `before-start` | Before validations | Before phase verification |
| `after-implementation` | After validations pass | After all checks pass, before archiving |
| `before-approval` | Before archive confirmation | Before asking user to confirm archive |

---

### Extension point: before-start

> Resolve and invoke hooks for phase=`finish`, trigger=`before-start`.
