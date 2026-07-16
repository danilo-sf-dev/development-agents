# Reference: Fix Propose Horizontal Fix

**Used by**: `/sdd.fix` Step 4.

### Step 4: Propose Horizontal Fix

```markdown
## Proposed Fix (All Layers)

### Option A: [Fix Description] (Recommended)

**1. Functional Spec Changes** (`1-functional/spec.md`):
```diff
### Acceptance Criteria
- User can submit form with valid data
+ - User can submit form with valid data
+ - System validates email format before submission
+ - Invalid email shows error message
```

**2. Technical Spec Changes** (`2-technical/spec.md`):
```diff
### API Contract
POST /users
Request:
  - name: string (required)
  - email: string (required)
+   - email must match RFC 5322 format
+   - Returns 400 if email invalid

### Error Responses
+ | 400 | INVALID_EMAIL | Email format is invalid |
```

**3. Task Changes** (`3-tasks/tasks.json`):
```diff
+ ### TASK-015: Add email validation
+ **Description**: Implement email format validation
+ **Acceptance Criteria**:
+ - Validate email on form submission
+ - Show user-friendly error message
+ **Estimate**: 2h
```

**4. Code Changes**:
```diff
// src/validators/user.js
+ function validateEmail(email) {
+   const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
+   if (!emailRegex.test(email)) {
+     throw new ValidationError('INVALID_EMAIL', 'Email format is invalid');
+   }
+ }

// src/services/UserService.js
async createUser(data) {
+  validateEmail(data.email);
   return this.repository.create(data);
}
```

**Confidence**: High
**Risk**: Low

---

Apply this fix? (y/n)
```

---
