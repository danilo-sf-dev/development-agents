#!/bin/bash
# detect-phase.test.sh - Minimal regression test for detect-phase.sh
#
# Covers the 5 real workflow states (functional -> technical -> tasks ->
# tests -> implementation), each expressed as a fresh feature would express
# it: no explicit "Current Stage" field yet (Method 2 fallback), just the
# stages: YAML block with the previous stages "approved" and the current one
# "in-progress" -- see commands/sdd.test.md Step 1 and
# commands/references/plan-approval.md for how a real feature reaches each
# of these states.
#
# Usage: bash detect-phase.test.sh
# Exit code 0 = all cases passed, 1 = at least one failure.

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DETECT_PHASE="$SCRIPT_DIR/detect-phase.sh"

TMPD=$(mktemp -d)
trap 'rm -rf "$TMPD"' EXIT

FAILURES=0

make_meta() {
    # args: func_status tech_status tasks_status tests_status impl_status
    cat > "$TMPD/meta.md" <<EOF
# Feature Metadata

**Feature Name**: detect-phase-test

---

## Stage History

\`\`\`yaml
stages:
  functional:
    status: $1
  technical:
    status: $2
  tasks:
    status: $3
  tests:
    status: $4
  implementation:
    status: $5
\`\`\`
EOF
}

assert_phase() {
    local description="$1" expected_stage="$2"
    local result
    result=$(bash "$DETECT_PHASE" "$TMPD" --json)
    local actual_stage
    actual_stage=$(echo "$result" | grep -o '"stage":"[^"]*"' | cut -d'"' -f4)
    if [ "$actual_stage" = "$expected_stage" ]; then
        echo "✅ PASS: $description (got: $actual_stage)"
    else
        echo "❌ FAIL: $description (expected: $expected_stage, got: $actual_stage, raw: $result)"
        FAILURES=$((FAILURES + 1))
    fi
}

echo "=== detect-phase.sh regression tests ==="

# 1. Brand-new feature: nothing started yet
make_meta pending pending pending pending pending
assert_phase "feature recem-criada" "functional"

# 2. Technical in progress: functional approved, technical in-progress
make_meta approved in-progress pending pending pending
assert_phase "technical em andamento" "technical"

# 3. Tasks in progress
make_meta approved approved in-progress pending pending
assert_phase "tasks em andamento" "tasks"

# 4. Tests in progress
make_meta approved approved approved in-progress pending
assert_phase "tests em andamento" "tests"

# 5. Implementation in progress
make_meta approved approved approved approved in-progress
assert_phase "implementation em andamento" "implementation"

# Extra: canonical bold "Current Stage" field takes priority over the
# stages: YAML block (Method 1 is the primary source, per
# framework/templates/meta.md's literal format).
cat > "$TMPD/meta.md" <<'EOF'
# Feature Metadata

**Feature Name**: detect-phase-test
**Current Stage**: tests

---

## Stage History

```yaml
stages:
  functional:
    status: approved
  technical:
    status: approved
  tasks:
    status: approved
  tests:
    status: pending
  implementation:
    status: pending
```
EOF
assert_phase "campo Current Stage (negrito) tem prioridade sobre o fallback" "tests"

echo ""
if [ "$FAILURES" -eq 0 ]; then
    echo "✅ All detect-phase.sh tests passed"
    exit 0
else
    echo "❌ $FAILURES test(s) failed"
    exit 1
fi
