# Reference: Project Vision before Spec

**Used by**: `/sdd.spec` Step 1.5 when PROJECT.md vision is missing or alignment check is needed.

### Step 1.5: Read Project Vision

> **MANDATORY**: Before starting functional spec, check for project vision.

```bash
# Check if PROJECT.md has a vision defined
vision=$(grep -A 50 "^vision:" sdd/PROJECT.md 2>/dev/null | head -50)
# Check if vision prompt was already shown
vision_prompted=$(grep "vision_prompt_shown: true" sdd/wip/*/meta.md 2>/dev/null)
```

**If vision is defined**:
- Extract: `summary`, `target_users`, `value_proposition`, `principles`, `anti_goals`
- Use to **guide** interview questions and spec content
- Validate that objectives align with value proposition
- Use `anti_goals` to inform Out of Scope decisions
- Use `principles` to guide acceptance criteria

**If vision is NOT defined AND NOT previously prompted**:

> First time only: Suggest defining vision before starting spec.

Use AskUserQuestion:
- Question: "PROJECT.md doesn't have a product vision defined. Vision helps ensure features align with your product goals. Would you like to define it now?"
- Header: "Vision"
- Options:
  1. "Define now" - Description: "Quick 3-question wizard"
  2. "Later (/sdd.project vision)" - Description: "Continue without, remind me later"
  3. "Don't need vision" - Description: "Skip permanently for this project"

**On user selection**:

| Selection | Action |
|-----------|--------|
| "Define now" | Execute inline vision mini-wizard (see below) |
| "Later" | Continue with spec, do NOT ask again for this feature |
| "Don't need vision" | Set `vision_prompt_shown: true` in meta.md, never ask again |

**Inline Vision Mini-Wizard** (if user selects "Define now"):

1. Ask: "What does your product do in one sentence?"
2. Ask: "What problem does it solve and why should users care?"
3. Ask: "Any guiding principles? (optional, can skip)"
4. Write vision to PROJECT.md
5. Continue with Step 2

**Vision Alignment Check** (during spec review):
- Before approval, verify spec aligns with vision
- If conflict detected, flag it: "This objective may conflict with project principle: [principle]"
