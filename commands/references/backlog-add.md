# Reference: Backlog Add Item

**Used by**: `/sdd.backlog add`.

## `/sdd.backlog add` - Add Item

Interactive flow to add a new item to the backlog:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
➕ Add Item to Backlog
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Type? [TODO / DEBT / IDEA]: TODO

Title: Add structured logging

Priority? [High / Medium / Low]: Medium

Context (why is this needed?):
> Current logging is plain text, hard to parse in DataDog

Affected files (optional, comma-separated):
> src/utils/logger.ts, src/index.ts

Complexity? [S / M / L / XL]: M

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Added: TODO-003 - Add structured logging

Item saved to: sdd/backlog.md
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Fields by Type

**TODO**:
- Title, Priority, Context, Affected Files, Complexity

**DEBT**:
- Title, Priority, Context, Affected Files, Complexity
- Risk if Ignored (what happens if not resolved)

**IDEA**:
- Title, Priority, Context
- Potential Impact (Performance, UX, Maintainability, etc.)
- Notes (additional details)

---
