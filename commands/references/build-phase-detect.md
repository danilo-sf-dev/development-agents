# Reference: Build Phase Detection

**Used by**: `/sdd.build` Step 1.

### Step 1: Context Check + Phase Detection (Deterministic)

> **Use script for deterministic phase detection** - Saves ~500-1000 tokens vs manual parsing.

```bash
# Verify tasks AND tests are approved (must be in phase 5 = implementation)
tests_status=$(grep -A5 "tests:" sdd/wip/[feature]/meta.md 2>/dev/null | grep "status:" | head -1 | sed 's/.*: *//' | tr -d ' ')

if [ "$tests_status" != "approved" ] && [ "$tests_status" != "skipped" ]; then
    echo "❌ Tests not approved. Run /sdd.test --approve first."
    exit 1
fi

phase_result=$(bash development-agents/framework/tools/detection/detect-phase.sh sdd/wip/[feature] --json)
current_stage=$(echo "$phase_result" | grep -o '"stage":"[^"]*"' | cut -d'"' -f4)

# Verify ready for implementation (tests approved → stage implementation)
if [ "$current_stage" != "implementation" ]; then
    echo "❌ Not ready for build. Run /sdd.test --approve first."
    exit 1
fi

# Detect platform from PROJECT.md + detect-stack (android | ios | web | backend | "")
stack_result=$(bash development-agents/framework/tools/detect-stack.sh . --json 2>/dev/null)
platform=$(echo "$stack_result" | grep -o '"platform":"[^"]*"' | cut -d'"' -f4)

# Optional mobile skills: only if PROJECT.md platform.type is android/ios AND
# the project declares a mobile skill path. Do not hard-fail the build if absent.
if [ "$platform" = "android" ] || [ "$platform" = "ios" ]; then
    echo "INFO: mobile platform detected ($platform) — use stack skills from PROJECT.md if configured"
fi
```

Then check context level:
- Normal (<40%): Proceed inline
- Elevated (40-60%): Use subagents for heavy ops
- High (60-80%): Recommend compaction
- Critical (>80%): Must compact first via `context-guardian` skill
