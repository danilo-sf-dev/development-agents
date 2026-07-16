# Reference: Mobile CLAUDE.md Section (`/sdd.start`)

**Used by**: `/sdd.start` Step 9.5 and `/sdd.reverse-eng` CLAUDE.md integration, when `platform = android` or `platform = ios`.

Append this platform-specific section **after** the base `## SDD Kit` block in `CLAUDE.md`.
Read `$platform` from the `$IS_MOBILE` flag or `detect-stack.sh` output (already resolved in Step 2).
Do NOT append for backend, web, or empty platform.

> **CONDITIONAL — Mobile Implementation Rule** (append ONLY when `platform = android` or `platform = ios`):
>
> After the base template above, if `$platform` is `android` or `ios`, append a **platform-specific** section.
> Read `$platform` from the `$IS_MOBILE` flag or `detect-stack.sh` output (already resolved in Step 2).
> Do NOT append for backend, web, or empty platform.
>
> Generate the section by substituting `[platform]` with the actual value (`android` or `ios`),
> `[lang]` with `Kotlin/Android` or `Swift/iOS`, and `[skill]` with the exact skill name.
> Do NOT include the other platform's skill name — keep it project-specific.

**If platform = android**, append:

```markdown
## Mobile Implementation Rule

This project is **Android** — MANDATORY before any Kotlin/Android code:

1. Invoke `Skill("mobile-android-expert")`
2. Read `$SKILL_PATH/SKILL.md` — single source of truth for all documentation navigation
3. Follow the documentation navigation workflows referenced in SKILL.md for mobile SDK and design system
4. Build Confirmed Imports Registry from the skill docs before writing any code

**When it applies**: spec creation, task planning, implementation, code review — any step that touches Kotlin/Android.

**For subagents**: include as step 0 in the prompt of any subagent that works on Android code:
```
⚠️ STEP 0 — MANDATORY:
Skill("mobile-android-expert")
cat "$SKILL_PATH/SKILL.md"
Follow the documentation navigation workflows referenced in SKILL.md for mobile SDK libraries and design system components.
Build Confirmed Imports Registry. Only then read the task and write code.
```

`mobile-android-expert` is the ONLY authoritative source for mobile SDK library APIs and design system
component APIs. Pre-training knowledge about Android libraries MUST be overridden by the skill docs.
```

**If platform = ios**, append:

```markdown
## Mobile Implementation Rule

This project is **iOS** — MANDATORY before any Swift/iOS code:

1. Invoke `Skill("mobile-ios-expert")`
2. Read `$SKILL_PATH/SKILL.md` — single source of truth for all documentation navigation
3. Follow the documentation navigation workflows referenced in SKILL.md for mobile SDK and design system
4. Build Confirmed Imports Registry from the skill docs before writing any code

**When it applies**: spec creation, task planning, implementation, code review — any step that touches Swift/iOS.

**For subagents**: include as step 0 in the prompt of any subagent that works on iOS code:
```
⚠️ STEP 0 — MANDATORY:
Skill("mobile-ios-expert")
cat "$SKILL_PATH/SKILL.md"
Follow the documentation navigation workflows referenced in SKILL.md for mobile SDK libraries and design system components.
Build Confirmed Imports Registry. Only then read the task and write code.
```

`mobile-ios-expert` is the ONLY authoritative source for mobile SDK library APIs and design system
component APIs. Pre-training knowledge about iOS libraries MUST be overridden by the skill docs.
```
