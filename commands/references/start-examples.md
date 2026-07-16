# Reference: `/sdd.start` Output Examples

**Used by**: `/sdd.start` (optional UX reference — not required for the standard path).

### Example 1: Standard Mode (default)
```
User: /sdd.start payment-gateway

AI: ✅ Feature #003 'payment-gateway' initialized
    📁 Location: sdd/wip/20260325-payment-gateway/

    📋 Standard Mode Active

    [AskUserQuestion displayed]:
    ┌─ Next ─────────────────────────────────────────────┐
    │ Feature initialized. What would you like to do    │
    │ next?                                             │
    │                                                   │
    │ ○ /sdd.spec (Recommended)                        │
    │   Start spec creation interactively               │
    │                                                   │
    │ ○ /sdd.spec --audio                              │
    │   Describe your feature by voice                  │
    │                                                   │
    │ ○ /sdd.check                                     │
    │   View feature status                             │
    │                                                   │
    │ ○ Other...                                        │
    └───────────────────────────────────────────────────┘

User: [Selects "/sdd.spec (Recommended)"]

AI: [Invokes Skill(skill="sdd.spec")]
    [/sdd.spec starts automatically...]
```

### Example 2: Description Auto-Inferred
```
User: /sdd.start I want to create a REST API that handles user authentication

AI: ✓ Feature name inferred: `user-authentication-api` (from your description)
    📝 Description saved for /sdd.spec context

    [Continues to Step 2:  App Verification...]

    ✅ Feature #003 'user-authentication-api' initialized
       📁 Location: sdd/wip/20260325-user-authentication-api/

    [AskUserQuestion displayed]:
    ┌─ Next ─────────────────────────────────────────────┐
    │ Feature initialized. What would you like to do    │
    │ next?                                             │
    │                                                   │
    │ ○ /sdd.spec (with saved context)                 │
    │   Uses your description to seed the spec          │
    │                                                   │
    │ ○ /sdd.spec --audio                              │
    │   Describe your feature by voice                  │
    │                                                   │
    │ ○ /sdd.check                                     │
    │   View feature status                             │
    │                                                   │
    │ ○ Other...                                        │
    └───────────────────────────────────────────────────┘

User: [Selects "/sdd.spec (with saved context)"]

AI: [Invokes Skill(skill="sdd.spec") - description auto-loaded from meta.md]
```

### Example 3: Fresh/Empty Repository
```
User: /sdd.start new-feature
# (user is in a freshly git-init'd folder, no commits yet)

AI: [Detects freshly_scaffolded=true — no history, no sdd/specs]
    [Runs stack detection: language=java framework=spring]
    [No known scaffold-sample patterns matched — nothing to clean up]

    ✅ Feature #001 'new-feature' initialized
       📁 Location: sdd/wip/001-new-feature/
       🏭 Project mode: greenfield

    [AskUserQuestion: "Feature initialized. What would you like to do next?"]
    Options: /sdd.spec (Recommended), /sdd.spec --audio, /sdd.check

User: [Selects "/sdd.spec (Recommended)"]

AI: [Invokes Skill(skill="sdd.spec")]
```

---

## Command Flow

```
/sdd.start ─────► Validate Input ─────►  Verification
                        │                       │
                        ▼                       ▼
                   Create Structure ◄───── Clone/Scaffold
                        │
                        ▼
                   Output Success
                        │
                        ▼
              /sdd.spec (standard)
              /sdd.go (express)
```

---
