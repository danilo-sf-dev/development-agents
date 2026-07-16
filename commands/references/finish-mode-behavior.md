# Reference: Finish Mode Behavior

**Used by**: `/sdd.finish` Express vs Standard detailed flows.

## Behavior by Mode

### Express Mode

```
/sdd.finish
```

**What happens**:
1. Runs all validators automatically
2. Auto-generates summary documentation
3. Archives feature without confirmation
4. Shows brief success message

**Interaction**: None (unless validation fails)

---

### Standard Mode (default)

```
/sdd.finish
```

**What happens**:
1. Runs all validators
2. Shows validation results
3. Asks for confirmation before archiving
4. Generates documentation
5. Archives and shows summary

**Standard Mode Flow** (Profile-Aware):

> **Lazy-loaded**: When `PROFILE == TECHNICAL_ONLY` or `NON_TECHNICAL_ONLY`, Read `references/output-examples-by-profile.md` for profile-specific output format examples.

────────────────────────────────────────
📚 Knowledge Management
────────────────────────────────────────

Checking progress.md for generalizable learnings...

Found patterns that may apply to other features:
  • KeyValueStore TTL must be > Streams retention for CDC
  • MessageQueue events needed for data-modifying endpoints

[AskUserQuestion: "Promote these to sdd/PATTERNS.md?"] → User: Yes

✅ Learnings promoted to sdd/PATTERNS.md
   (Future features will benefit from these patterns)

[AskUserQuestion: "Ready to archive feature?"] → User: Yes

Generating documentation...
Archiving to sdd/features/...

> **Lazy-loaded**: When `PROFILE == TECHNICAL_ONLY` or `NON_TECHNICAL_ONLY`, Read `references/output-examples-by-profile.md` § Completion Output for profile-specific completion format.

```
────────────────────────────────────────
📋 Backlog Resolution
────────────────────────────────────────

This feature addressed these backlog items:
  • TODO-001: Refactor payment validation

[AskUserQuestion: "Mark as resolved?"] → User: Yes

✅ TODO-001 → RESOLVED
   Resolution: Completed
   Resolved in: payment-gateway
```

> **Note**: Backlog resolution only shown if feature has `from_backlog` in meta.md or mentions backlog items.

---
