# Reference: Build Final Sync Validation

**Used by**: `/sdd.build` Step 7.

### Step 7: Final Sync Validation

After all quality gates pass, validate implementation consistency:

```
/sdd.check --sync
```

**Purpose**: Catch any drift accumulated during implementation phase.

**Verdict Handling**:

| Verdict | Action |
|---------|--------|
| `APPROVED` | Ready for `/sdd.finish` |
| `CAN_PROCEED_WITH_WARNINGS` | Proceed, document warnings |
| `CANNOT_PROCEED` | Fix gaps before finishing |

**When to skip**: If all tasks were single-file changes with no spec modifications.

**ALL PASS?** → Ready for `/sdd.finish`
