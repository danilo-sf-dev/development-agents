# Reference: Plan Phase Detection

**Used by**: `/sdd.plan` Step 1.

### Step 1: Context Check + Phase Detection (Deterministic)

> **Use script for deterministic phase detection** - Saves ~500-1000 tokens vs manual parsing.

```bash
# Deterministic phase detection (FIRST - verify we're in correct phase)
phase_result=$(bash development-agents/framework/tools/detection/detect-phase.sh sdd/wip/[feature] --json)
current_stage=$(echo "$phase_result" | grep -o '"stage":"[^"]*"' | cut -d'"' -f4)

# Verify technical spec is approved (must be in phase 3+)
if [ "$current_stage" != "tasks" ] && [ "$current_stage" != "implementation" ]; then
    echo "❌ Technical spec not approved. Run /sdd.spec technical --approve first."
    exit 1
fi
```

Then invoke `Skill("context-guardian")` for context check.

| Threshold | Action |
|-----------|--------|
| < 50% | Proceed inline |
| 50-70% | Show advisory, use `genai-analyze-e2e.sh` for E2E detection |
| > 70% | Recommend compaction before `/sdd.build` |
