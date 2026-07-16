# Reference: /sdd.finish AI Agent Instructions

**Used by**: `/sdd.finish` extended agent rules.

## AI Agent Instructions


### Help Flag Detection

**WHEN** the user runs `/sdd.finish help`:
1. Output ONLY the "Quick Help" section (not full documentation)
2. Do NOT execute finish logic
3. Keep response concise (~15 lines)

### Mode-Specific Behavior

1. **Express**: Auto-validate, auto-archive, brief output
2. **Standard**: Show validations, confirm before archiving



### Key Rules
1. **Never skip validations** -  and tests are MANDATORY
2. **Block on failures** - Do not archive incomplete features
3. **Promote learnings** - Check for patterns to add to PATTERNS.md (see below)
4. **Generate documentation** - Always create README and summary
5. **PRESERVE meta.md** - Move INTACT to sdd/features/, NEVER delete
6. **Clean up WIP** - Only remove sdd/wip/[feature]/ AFTER moving all files

> **Telemetry**: Data is captured automatically by hooks in `~/.claude/logs/` (Claude Code) or `~/.cursor/logs/` (Cursor).
---

### Archival Workflow (CRITICAL — short)

1. Confirm validations green + user approval (Standard)
2. Generate `implementation-summary.md` (+ README touch if needed)
3. Promote learnings → `sdd/PATTERNS.md` (AskUserQuestion; dedupe)
4. Resolve backlog items if `from_backlog`
5. `mv sdd/wip/<feature> sdd/features/<feature>` (atomic move of whole dir)
6. Verify source gone + destination has `meta.md`

> **ONLY IF** needing shell snippets, duplicate-detection, or PATTERNS section format:
> Read `references/finish-archive-workflow.md`.

## Command Flow

`validate → (confirm) → docs → patterns/backlog → archive wip→features → next feature or hub`

## Related Commands

- `/sdd.build` - Previous phase (implementation)
- `/sdd.check` - View validation status
- `/sdd.start` - Start new feature
- `/sdd.backlog` - Manage backlog for next work

---

## What's Next?

Recommend `/clear` then `/sdd.start` for next feature.
> **ONLY IF** interactive next-steps AskUserQuestion:
> Read `references/finish-next-steps.md`.
