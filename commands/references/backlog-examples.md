# Reference: Backlog Examples

**Used by**: `/sdd.backlog` help/examples.

## Examples

### Example 1: Add TODO during development

```
User: /sdd.backlog add

AI: ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    ➕ Add Item to Backlog
    ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    Type? [TODO / DEBT / IDEA]:

User: TODO

AI: Title:

User: Implement API rate limiting

AI: Priority? [High / Medium / Low]:

User: High

AI: Context (why is this needed?):

User: Without rate limiting, API is vulnerable to abuse

AI: Affected files (optional):

User: src/middleware/rateLimit.ts

AI: Complexity? [S/M/L/XL]:

User: M

AI: ✅ Added: TODO-005 - Implement API rate limiting
```

### Example 2: Create feature from backlog

```
User: /sdd.backlog pick

AI: [Shows list of items]

User: 1

AI: Feature name suggestion: implement-rate-limiting
    Accept? [Y/n/custom]:

User: Y

AI: ✅ Feature created!
    Run /sdd.spec to continue.
```
