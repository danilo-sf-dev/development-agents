# Reference: Finish Examples

**Used by**: `/sdd.finish` help/examples only.

## Examples

### Example 1: Standard Mode - Success
```
User: /sdd.finish

AI: Running validations...

    ✅ All tasks completed
    ✅ passed
    ✅ Tests passing (91% coverage)

    [AskUserQuestion: "Ready to archive?"]

User: Y

AI: 🎉 Feature complete!
    Archived to: sdd/features/payment-gateway/
```

### Example 2: Validation Failure
```
User: /sdd.finish

AI: Running validations...

    ✅ All tasks completed
    ❌ : Missing /ping endpoint
    ❌ Coverage: 78% (below 80%)

    Feature cannot be completed until issues fixed.

    How to fix:
    1. Implement /ping endpoint
    2. Add tests for coverage

    Then retry: /sdd.finish
```

### Example 3: Express Mode
```
User: /sdd.finish

AI: ⚡ Express Mode - Auto-finalizing

    ✅ Validations passed
    ✅ Documentation generated
    ✅ Feature archived

    🎉 Complete! → sdd/features/user-auth/
```

---
