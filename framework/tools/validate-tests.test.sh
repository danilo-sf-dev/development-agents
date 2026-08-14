#!/bin/bash
# validate-tests.test.sh - Minimal regression test for validate-tests.sh's
# PYTHONPATH handling across the two Python import layouts observed in real
# specs during E2E validation, both legitimate:
#   - "from src.foo import ..."  (foo.py inside src/, imported as src.foo)
#     -> needs the project root on PYTHONPATH
#   - "from foo import ..."      (foo.py inside src/, imported as foo)
#     -> needs src/ itself on PYTHONPATH
# validate-tests.sh must pass in both cases without the caller having to
# guess which convention a given project uses.
#
# Usage: bash validate-tests.test.sh
# Exit code 0 = all cases passed, 1 = at least one failure.

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VALIDATE_TESTS="$SCRIPT_DIR/validate-tests.sh"

TMPD=$(mktemp -d)
trap 'rm -rf "$TMPD"' EXIT

FAILURES=0

assert_pass() {
    local description="$1" project_root="$2" feature_path="$3"
    local output exit_code
    output=$(bash "$VALIDATE_TESTS" "$feature_path" "$project_root" 2>&1)
    exit_code=$?
    if [ "$exit_code" -eq 0 ] && echo "$output" | grep -q "Test Validation PASSED"; then
        echo "✅ PASS: $description"
    else
        echo "❌ FAIL: $description (exit=$exit_code)"
        echo "$output" | sed 's/^/    /'
        ((FAILURES++))
    fi
}

# --- Layout 1: "from src.foo import ..." (project root on path) ---
L1="$TMPD/layout1"
mkdir -p "$L1/src" "$L1/tests" "$L1/sdd/wip/feat/3-tasks" "$L1/sdd/wip/feat/4-implementation"
cat > "$L1/src/__init__.py" <<'EOF'
EOF
cat > "$L1/src/calc.py" <<'EOF'
def add(a, b):
    return a + b
EOF
cat > "$L1/tests/test_calc.py" <<'EOF'
from src.calc import add

def test_add():
    assert add(2, 3) == 5
EOF
assert_pass "layout 1: from src.foo import ... (root on path)" "$L1" "$L1/sdd/wip/feat"

# --- Layout 2: "from foo import ..." with foo.py inside src/ (src/ on path) ---
L2="$TMPD/layout2"
mkdir -p "$L2/src" "$L2/tests" "$L2/sdd/wip/feat/3-tasks" "$L2/sdd/wip/feat/4-implementation"
cat > "$L2/src/__init__.py" <<'EOF'
EOF
cat > "$L2/src/calc.py" <<'EOF'
def add(a, b):
    return a + b
EOF
cat > "$L2/tests/test_calc.py" <<'EOF'
from calc import add

def test_add():
    assert add(2, 3) == 5
EOF
assert_pass "layout 2: from foo import ... (src/ on path)" "$L2" "$L2/sdd/wip/feat"

echo ""
if [ "$FAILURES" -eq 0 ]; then
    echo "✅ All validate-tests.sh PYTHONPATH layout tests passed"
    exit 0
else
    echo "❌ $FAILURES test(s) failed"
    exit 1
fi
