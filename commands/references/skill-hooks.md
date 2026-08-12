# Reference: Skill Hooks

**Used by**: `/sdd.spec`, `/sdd.plan`, `/sdd.build`, `/sdd.finish` when skill hooks are configured. Callers read this file with a `phase` parameter (`spec-functional`, `spec-technical`, `plan`, `build`, or `finish` — see the trigger table below) to resolve only the rows relevant to them.

## Skill Hooks (Extension Points)

Each SDD phase supports external skill hooks at 3 trigger points (`spec` has 2 independent sub-phases — `spec-functional` and `spec-technical` — each with its own 3 triggers). At each point, the agent resolves hooks from 3 layers (user override > repo config > auto-declaration) and invokes matching skills.

**Resolution steps** (at each extension point):

1. Read the skill-hooks config for whichever adapter(s) are installed — `.claude/skill-hooks.json` if the Claude Code adapter is installed, `.cursor/skill-hooks.json` if the Cursor adapter is installed, `.agents/skill-hooks.json` if the Codex adapter is installed — plus `development-agents/framework/skill-hooks.json` (repo config, read regardless of adapter). Generic-adapter installs have no dot-folder convention; skip the adapter-specific file and rely on the repo config only.
2. Scan installed skills for `metadata` with `sdd-kit-*` keys, in whichever skills directory the installed adapter(s) use: `~/.claude/skills/*/SKILL.md` (Claude Code, user-level) and the repo-level skills dir for the installed adapter — `.claude/skills/*/SKILL.md`, `.cursor/skills/*/SKILL.md`, or `.agents/skills/*/SKILL.md` — or, for a Generic install, `development-agents/skills/*/SKILL.md` directly.
3. Merge with precedence: user override > repo config > auto-declaration.
4. For each enabled hook matching the current `phase` (per the table below) and the current trigger, ordered by priority:
   - If `hook.mode == "required"`: invoke the hook skill via the harness's `INVOKE_PROCEDURE` capability (`Skill("<hook.skill>")` on Claude Code/Cursor; see `framework/_shared/harness-capabilities.md` for other harnesses) with current feature context.
   - If `hook.mode == "available"` (default): evaluate if the hook is relevant to the current feature. Only invoke if the feature context suggests it adds value. Skip silently if irrelevant.

## Trigger table

| Phase             | Trigger                | When                                                                |
| ----------------- | ---------------------- | ------------------------------------------------------------------- |
| `spec-functional` | `before-start`         | Before Step 2 (interview)                                           |
| `spec-functional` | `after-implementation` | After spec draft generated                                          |
| `spec-functional` | `before-approval`      | Before Step 3 (approval)                                            |
| `spec-technical`  | `before-start`         | Before Step 5 (technical spec)                                      |
| `spec-technical`  | `after-implementation` | After technical spec generated                                      |
| `spec-technical`  | `before-approval`      | Before Step 6 (approval)                                            |
| `plan`            | `before-start`         | Before Step 1 (before phase detection)                              |
| `plan`            | `after-implementation` | After Step 5 (after tasks generated)                                |
| `plan`            | `before-approval`      | Before Step 7 (task approval)                                       |
| `build`           | `before-start`         | Before Step 1 (before phase detection)                              |
| `build`           | `after-implementation` | After Step 5 (after all tasks implemented and quality gates passed) |
| `build`           | `before-approval`      | Before Step 8 (before interactive next steps / finish prompt)       |
| `finish`          | `before-start`         | Before validations (before phase verification)                      |
| `finish`          | `after-implementation` | After validations pass (after all checks pass, before archiving)    |
| `finish`          | `before-approval`      | Before archive confirmation (before asking user to confirm archive) |

---
