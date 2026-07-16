# Reference: /sdd.start AI Agent Instructions (full)

**Used by**: `/sdd.start` when needing extended agent rules beyond the short happy-path list.

## AI Agent Instructions

### Help Flag Detection

**WHEN** the user runs `/sdd.start help`:
1. Output ONLY the "Quick Help" section (not full documentation)
2. Do NOT execute start logic
3. Keep response concise (~15 lines)

### Execution Order (MANDATORY)

```
STEP 0: USER PROFILE CHECK (⛔ BLOCKING - NEVER SKIP)
├─ development-agents/framework/user-profile.yaml exists? → Read profile, continue
└─ Missing? → ⛔ STOP. Ask profile (Business vs Technical), save file, THEN continue

STEP 1: VALIDATE INPUT (BLOCKING)
├─ Is it a prompt/description? → Auto-infer name, show message, continue
├─ Is it valid kebab-case? → Continue
└─ NEVER create files until validation passes

STEP 2: REPOSITORY READINESS CHECK
├─ Existing repo with history/specs? → Continue (standard case)
└─ Fresh/empty repo? → Optional scaffold cleanup, then continue

STEP 3: CREATE STRUCTURE (only after Steps 0-2 pass)

STEP 4: OUTPUT SUCCESS MESSAGE
```

### Auto-Inference Pattern

```
✅ CORRECT (v1.2.6+):
User: /sdd.start I want a payment system with refunds
AI: ✓ Feature name inferred: `payment-refunds` (from your description)
    [Continues automatically to Step 2...]

❌ WRONG:
User: /sdd.start I want a payment system with refunds
AI: OK, creating payment service... [starts implementing without feature name]
```

### Key Rules

1. **PROFILE FIRST** - If `development-agents/framework/user-profile.yaml` is missing, ask BEFORE anything else
2. **VALIDATE FIRST** - Never skip input validation
3. **Prompt ≠ Name** - If >5 words or punctuation, it's a description → auto-infer name
4. **Auto-infer, don't ask** - Infer feature name from description and proceed automatically
5. **Delegate heavy ops** - Use `sdd-project-wizard` for PROJECT.md
6. **No external app creation** - This command never registers/creates apps in an external system; it only works inside a repo that already exists (see `references/new-app-scaffolding.md` if you need a generic pre-`/sdd.start` checklist)
