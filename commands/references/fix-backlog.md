# Reference: Fix Backlog Integration

**Used by**: `/sdd.fix` backlog suggestions.

## Backlog Integration ⭐ v1.7.0

After Step 8, if the fix meets ANY of these conditions, **suggest creating a backlog item**:

| Condition | Backlog Category | Why |
|-----------|-----------------|-----|
| Classification = `DESIGN_FLAW` AND brownfield fix | `DEBT` | Underlying design needs rework |
| Classification = `FEATURE_GAP` AND brownfield fix | `DEBT` | Gap in spec should be formalized |
| Recurring fix warning triggered (≥3 in 30 days) | `DEBT` | Structural problem, not a one-off |
| Fix took >2 hours OR touched >5 files | `DEBT` | Complexity suggests systemic issue |

### Suggestion Format

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 BACKLOG SUGGESTION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
This fix reveals a design debt that should be tracked.

Suggested backlog item:
  Category: DEBT
  Title: [concise title describing the underlying issue]
  Description: [what needs to be addressed properly]
  Origin: FIX-NNN (DATE)

Add to sdd/backlog.md? (y/n)
```

If the user confirms, call `/sdd.backlog add` with the suggested item.

> **Rule**: This is a suggestion, NOT mandatory. The user decides if the debt is worth tracking. Do NOT auto-add without confirmation.

---
