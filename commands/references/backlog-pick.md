# Reference: Backlog Pick → Feature

**Used by**: `/sdd.backlog pick`.

## `/sdd.backlog pick` - Create Feature from Item

Interactive selection to create a feature from a backlog item:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎯 Pick Item to Create Feature
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Select item (enter number or ID):

  [1] TODO-001  Refactor payment validation  (High, M)
  [2] TODO-002  Add retry logic              (Medium, S)
  [3] DEBT-001  Migrate callbacks to async   (Low, L)
  [4] IDEA-001  Search cache                 (Medium, M)
  [5] IDEA-002  Metrics dashboard            (Low, M)

Choice: 1

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Creating feature from TODO-001...
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Feature name suggestion: refactor-payment-validation
Accept? [Y/n/custom]: Y

✅ Feature created: sdd/wip/refactor-payment-validation/

Pre-populated context:
  • Problem Statement: from TODO-001 context
  • Affected Files: src/validators/payment.ts
  • Complexity: Medium

TODO-001 marked as: in-progress
  └── Linked to: sdd/wip/refactor-payment-validation/
```

### Workflow Mode Detection (DEBT/TODO only)

> **Lazy-loaded**: When processing DEBT/TODO items (not IDEA), Read `references/workflow-modes.md` for detailed workflow mode definitions and processing rules.

### Auto-Generated Functional Spec Template

> **Lazy-loaded**: When using modes 2/3 (auto-generation), Read `references/auto-spec-template.md` for the auto-specification generation template.

### What Gets Pre-populated

When creating a feature from backlog:

1. **meta.md** includes:
   ```yaml
   from_backlog: TODO-001
   workflow_mode: full | technical-only | tasks-only
   auto_generated:
     functional: false | true
     technical: false | true
   ```

2. **Initial context** for `/sdd.spec`:
   - Problem Statement: from item's Context field
   - Suggested Files: from item's Affected Files field
   - Complexity: from item's Complexity field

---
