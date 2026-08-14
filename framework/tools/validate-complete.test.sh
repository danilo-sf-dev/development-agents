#!/bin/bash
# validate-complete.test.sh - Minimal regression test for validate-complete.sh's
# task-completion contract with /sdd.plan's tasks.json output.
#
# Pins the schema documented in framework/standards/task-format.md and
# commands/references/plan-tasks-json.md: each task's ID field is "id",
# formatted "TASK-NNN" -- never "task_id" or a custom prefix like "IMPL-".
# Also guards against a real regression found in this repo's history: task
# counting used to grep tasks.json (a JSON file) for a markdown "#### TASK-"
# heading, which can never match inside JSON, so total/completed were
# silently always 0/0 regardless of the actual task-id contract.
#
# Usage: bash validate-complete.test.sh
# Exit code 0 = all cases passed, 1 = at least one failure.

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VALIDATE_COMPLETE="$SCRIPT_DIR/validate-complete.sh"

TMPD=$(mktemp -d)
trap 'rm -rf "$TMPD"' EXIT

FAILURES=0

assert_task_counts() {
    local description="$1" expected_completed="$2" expected_total="$3"
    local output
    output=$(bash "$VALIDATE_COMPLETE" "$TMPD" 2>&1)
    local actual
    actual=$(echo "$output" | grep -oE "Tasks: [0-9]+ / [0-9]+ completed")
    if [ "$actual" = "Tasks: $expected_completed / $expected_total completed" ]; then
        echo "✅ PASS: $description (got: $actual)"
    else
        echo "❌ FAIL: $description (expected 'Tasks: $expected_completed / $expected_total completed', got: '$actual')"
        ((FAILURES++))
    fi
}

# --- Case 1: canonical "id": "TASK-NNN" schema, all completed ---
mkdir -p "$TMPD/3-tasks" "$TMPD/4-implementation"
cat > "$TMPD/3-tasks/tasks.json" <<'EOF'
{
  "feature": "test-feature",
  "tasks": [
    {"id": "TASK-001", "title": "Do a thing", "status": "completed"},
    {"id": "TASK-002", "title": "Do another thing", "status": "completed"}
  ]
}
EOF
cat > "$TMPD/4-implementation/progress.md" <<'EOF'
# Progress
EOF
assert_task_counts "schema canônico, todas completed" 2 2

# --- Case 2: canonical schema, one task still pending ---
cat > "$TMPD/3-tasks/tasks.json" <<'EOF'
{
  "feature": "test-feature",
  "tasks": [
    {"id": "TASK-001", "title": "Do a thing", "status": "completed"},
    {"id": "TASK-002", "title": "Do another thing", "status": "pending"}
  ]
}
EOF
assert_task_counts "schema canônico, uma pendente" 1 2

echo ""
if [ "$FAILURES" -eq 0 ]; then
    echo "✅ All validate-complete.sh task-completion tests passed"
    exit 0
else
    echo "❌ $FAILURES test(s) failed"
    exit 1
fi
