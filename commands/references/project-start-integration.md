# Reference: Project ↔ Start Integration

**Used by**: `/sdd.project` docs.

## Integration with /sdd.start

When `/sdd.start` is run and `sdd/PROJECT.md` doesn't exist:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚠️  PROJECT.md not found
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

PROJECT.md defines your team's conventions (architecture,
testing, code review). Without it, framework defaults will be used.

What would you like to do?

1. 🔧 Create PROJECT.md now (/sdd.project)
2. ⏭️  Continue with framework defaults
3. 📖 What is PROJECT.md?
```

**If user selects option 1**: Execute `/sdd.project` flow
**If user selects option 2**: Continue with `/sdd.start` using framework defaults
**If user selects option 3**: Show explanation:

```
📖 What is PROJECT.md?

PROJECT.md is an optional file that defines your team's
conventions for this project:

• Architecture pattern (Clean, Hexagonal, etc.)
• Testing standards (coverage %, ratios)
• Code conventions (PR size, commits, branches)
• Review requirements (code review, spec approval)

Without PROJECT.md, the framework uses default values that work
for most projects. You can create it at any time
with /sdd.project.

See more: development-agents/framework/CONFIGURATION.md
```

---
