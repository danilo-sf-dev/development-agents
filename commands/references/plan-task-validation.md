# Reference: Plan Task Validation

**Used by**: `/sdd.plan` Step 7.5 / validation.

## Validation Checks

Before approval, validate:
- [ ] Each task has complexity (Low/Medium/High)
- [ ] Each task has ≥2 acceptance criteria
- [ ] Dependencies reference valid task IDs
- [ ] No circular dependencies
- [ ] Dockerfile + /ping tasks present (ALWAYS, all project types)
- [ ] Layer 3 quality tasks present (production/mvp only)
- [ ] No deploy tasks (FORBIDDEN)
- [ ] Custom error pages present if team opted for them (frontend only, optional)

### Step 7.5: Deterministic Task Validation

Use script for comprehensive task structure validation before approval.

```bash
# Validate tasks.json structure and content
task_validation=$(bash development-agents/framework/tools/validation/validate-tasks.sh sdd/wip/[feature]/3-tasks/tasks.json --json)
is_valid=$(echo "$task_validation" | grep -o '"valid":[^,}]*' | cut -d: -f2)
error_count=$(echo "$task_validation" | grep -o '"error_count":[0-9]*' | cut -d: -f2)

if [ "$is_valid" != "true" ]; then
    echo "❌ Task validation failed with $error_count errors:"
    echo "$task_validation" | grep -o '"errors":\[[^]]*\]'
    # FIX errors before approval
fi
```

**Validation includes**:
- JSON structure integrity
- Required fields present (id, title, status, layer, acceptance_criteria)
- ID format correct (TASK-XXX)
- No orphan dependencies
- No circular dependencies
- Layer assignment valid (1, 2, or 3)
- Complexity values valid (Low/Medium/High)
- No forbidden tasks (deploy, release)

**Project Type → Layer Rules**:

| Aspect | Prototype | MVP | Production |
|---------|-----------|-----|------------|
| **Layer 1** | Implementation | Implementation | Implementation |
| **Unit Tests** | ❌ Skip | ⚠️ Critical only | ✅ Full coverage |
| **Coverage target** | 0% | Varies | 80%+ |
| **Layer 2** | project services (if any) | project services (if any) | project services (if any) |
| **CI Pipeline** | Optional | Required | Required |
| **Layer 3 Quality** | ❌ Skip | ✅ Yes | ✅ Yes |
| **E2E Tests** | ❌ Skip | ❌ Skip | ✅ Opt-in |
| **Dockerfile + /ping** | ✅ Always | ✅ Always | ✅ Always |

> **Layer 2 Explanation**: Tasks that require external platform services (key-value store, message queue,
> object storage, etc.). If your app doesn't use project services, Layer 2 will be empty.

---
