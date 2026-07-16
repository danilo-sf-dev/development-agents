# Reference: Fix Examples

**Used by**: `/sdd.fix` examples.

## Example: Full Horizontal Fix

```bash
User: /sdd.fix "Error: User created without email validation.
Production issue: invalid emails in database."

AI: 🔧 Error Analysis
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

**Error Type**: Requirement Gap (Production Issue)
**Root Cause**: Email validation was never specified or implemented

## Impact Assessment

### 📋 Functional Spec
**Status**: ⚠️ UPDATE REQUIRED
- Missing acceptance criteria for email validation
- No user story for invalid input handling

### 🔧 Technical Spec
**Status**: ⚠️ UPDATE REQUIRED
- API contract missing email format validation
- No error response defined for invalid email
- Data model should specify email constraints

### 📝 Tasks
**Status**: ⚠️ UPDATE REQUIRED
- No task existed for email validation
- Need to add validation task
- Need to add data cleanup task (existing invalid data)

### 💻 Code
**Status**: ⚠️ UPDATE REQUIRED
- No validation in UserService
- No validation in API layer
- No tests for email validation

---

## Proposed Horizontal Fix

This fix will update ALL 4 layers to ensure consistency:

1. **Functional Spec**: Add email validation acceptance criteria
2. **Technical Spec**: Add API validation rules and error responses
3. **Tasks**: Add TASK-015 (validation) and TASK-016 (data cleanup)
4. **Code**: Implement validation + tests

Estimated additional work: 4 hours

Apply this horizontal fix? (y/n)
```

---
