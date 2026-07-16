# Reference: Plan Strategy Selection

**Used by**: `/sdd.plan` Step 6.

### Step 6: Strategy Selection

**Profile-aware behavior**:

| Profile | Strategy Selection |
|---------|-------------------|
| `non-technical` | **AUTO-SELECT Batched** - No question asked |
| `technical` | Smart auto-select or ask user |

**For non-technical profile**:
```
✓ Execution strategy: Recommended
  (The agent will automatically optimize the task order)
```

**For technical profile** - Smart auto-select (Standard mode):

| Change Size | Criteria | Strategy |
|-------------|----------|----------|
| Small | ≤5 tasks OR all Low complexity | Auto: Sequential |
| Medium/Large | >5 tasks with Medium/High | Ask user |

**Strategy Options** (shown only to technical profile):

| Strategy | Tokens | Best For |
|----------|--------|----------|
| Sequential | ~80K | Simple features |
| Batched (Recommended) | ~100K | Most projects |
| Parallel | ~140K | Complex features |
