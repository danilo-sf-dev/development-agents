# Reference: Backlog List

**Used by**: `/sdd.backlog` (no args).

## `/sdd.backlog` - List Backlog

### Standard Mode

```
/sdd.backlog
```

Shows all items sorted by priority:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 Technical Backlog
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Summary: 5 items (2 TODO, 1 DEBT, 2 IDEA)

HIGH PRIORITY:
  TODO-001  [High]   Refactor payment validation        (M)

MEDIUM PRIORITY:
  TODO-002  [Medium] Add retry logic to API calls       (S)
  IDEA-001  [Medium] Cache search results               (M)

LOW PRIORITY:
  DEBT-001  [Low]    Migrate callbacks to async/await   (L)
  IDEA-002  [Low]    Metrics dashboard                  (M)

IN PROGRESS:
  TODO-003  [High]   Optimize DB queries                (M)
            └── Feature: sdd/wip/db-optimization/

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Use /sdd.backlog pick to create feature from item
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### If no backlog exists:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 Technical Backlog
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

No backlog items found.

Use /sdd.backlog add to create your first item.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---
