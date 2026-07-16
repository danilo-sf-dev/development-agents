# Reference: Fix Implementation Plan

**Used by**: `/sdd.fix` Step 4.5.

### Step 4.5: Implementation Plan ⭐ v1.7.0

> **PURPOSE**: Before writing a single line of code, define the exact order of changes. This prevents applying code changes that depend on spec updates that haven't happened yet.

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 IMPLEMENTATION PLAN
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Steps (ordered by dependency):

[1] [SPEC/TASK/CODE] [Description] — no dependencies
[2] [SPEC/TASK/CODE] [Description] — depends on [1]
[3] [SPEC/TASK/CODE] [Description] — depends on [2]
...

Test checkpoints:
- After [N]: run [specific test command]
- After [M]: run full suite

Rollback:
- If [step N] fails: revert [which files]
- Risk level: [Low / Medium / High]
```

#### Plan Format Rules

- **Order specs before code** — specs are the source of truth; code follows
- **Order tasks before code** — tasks must exist before implementation
- **Mark dependencies explicitly** — `depends on [N]` prevents out-of-order execution
- **Add test checkpoints** — don't wait until the end to validate
- **Risk = High** if the fix changes API contracts or data models

#### Example Plan

```markdown
## Implementation Plan

[1] SPEC: Update functional spec — add email validation acceptance criteria
    → No dependencies

[2] SPEC: Update technical spec — add INVALID_EMAIL error response to API contract
    → Depends on [1]

[3] TASK: Add TASK-015 "Implement email validation"
    → Depends on [2]

[4] CODE: Create src/validators/user.js with validateEmail()
    → Depends on [3]

[5] CODE: Modify UserService.createUser() to call validateEmail()
    → Depends on [4]

[6] TEST: Add unit tests for validateEmail() + integration test for POST /users
    → Depends on [5]

Test checkpoints:
- After [4]: run `npm test src/validators/user.test.js`
- After [6]: run full suite `npm test`

Rollback:
- If [5] breaks existing tests: revert UserService.js only (keep validator)
- Risk level: Low (additive change, no existing behavior modified)
```

---
