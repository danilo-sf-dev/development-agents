# Reference: Build Skill Hooks

**Used by**: `/sdd.build` when skill hooks are configured.

## Skill Hooks (Extension Points)

This skill supports external skill hooks at 3 trigger points. At each point, the agent resolves hooks from 3 layers (user override > repo config > auto-declaration) and invokes matching skills.

**Resolution steps** (at each extension point):
1. Read `.claude/skill-hooks.json` and `development-agents/framework/skill-hooks.json`
2. Scan installed skills in `~/.claude/skills/*/SKILL.md` for `metadata` with `sdd-kit-*` keys
3. Merge with precedence: user override > repo config > auto-declaration
4. For each enabled hook matching phase=`build` and the current trigger, ordered by priority:
   - If `hook.mode == "required"`: invoke `Skill("<hook.skill>")` with current feature context
   - If `hook.mode == "available"` (default): evaluate if the hook is relevant to the current feature. Only invoke if the feature context suggests it adds value. Skip silently if irrelevant.

| Trigger | When | Location in workflow |
|---------|------|---------------------|
| `before-start` | Before Step 1 | Before phase detection |
| `after-implementation` | After Step 5 | After all tasks implemented and quality gates passed |
| `before-approval` | Before Step 8 | Before interactive next steps / finish prompt |

---
