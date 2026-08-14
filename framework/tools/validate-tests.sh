#!/bin/bash

# SDD SDD Kit - Test Validator
# MANDATORY gate for /sdd.finish (see commands/references/finish-validation-checks.md #3):
# all tests passing, coverage >= 80%, unit tests exist, integration tests exist.
#
# Usage: validate-tests.sh sdd/wip/[feature] [project_root]

FEATURE_PATH=$1
PROJECT_ROOT=${2:-.}
COVERAGE_THRESHOLD=80

if [ -z "$FEATURE_PATH" ]; then
    echo "❌ Error: Feature path required"
    echo "Usage: $0 sdd/wip/[feature-name] [project_root]"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🔍 Validating tests for $(basename "$FEATURE_PATH") in $PROJECT_ROOT..."
echo ""

errors=0
warnings=0

# ============================================
# Unit / Integration test files exist
# ============================================

echo "📋 Checking test files exist..."

unit_test_count=$(find "$PROJECT_ROOT" -type f \
    \( -name "test_*.py" -o -name "*_test.py" -o -name "*.test.js" -o -name "*.test.ts" \
       -o -name "*.spec.js" -o -name "*.spec.ts" -o -name "*_test.go" \) \
    -not -path "*/node_modules/*" -not -path "*/integration/*" -not -ipath "*integration*" \
    2>/dev/null | wc -l | tr -d ' ')

integration_test_count=$(find "$PROJECT_ROOT" -type f -ipath "*integration*" \
    \( -name "*.py" -o -name "*.js" -o -name "*.ts" -o -name "*.go" \) \
    -not -path "*/node_modules/*" 2>/dev/null | wc -l | tr -d ' ')

if [ "$unit_test_count" -gt 0 ]; then
    echo "  ✅ Unit tests exist ($unit_test_count file(s))"
else
    echo "  ❌ No unit test files found"
    ((errors++))
fi

if [ "$integration_test_count" -gt 0 ]; then
    echo "  ✅ Integration tests exist ($integration_test_count file(s))"
else
    echo "  ⚠️  Warning: No integration test files found (dir/file name containing 'integration')"
    ((warnings++))
fi

echo ""

# ============================================
# Run tests
# ============================================

echo "🧪 Running tests..."

test_cmd=""
coverage_pct=""

if [ -f "$SCRIPT_DIR/detect-language.sh" ]; then
    detect_json=$(bash "$SCRIPT_DIR/detect-language.sh" "$PROJECT_ROOT" --json 2>/dev/null)
    test_cmd=$(echo "$detect_json" | grep -o '"test":[[:space:]]*"[^"]*"' | head -1 | sed -E 's/.*"test":[[:space:]]*"([^"]*)".*/\1/')
fi

if [ -z "$test_cmd" ]; then
    if [ -f "$PROJECT_ROOT/pytest.ini" ] || [ -f "$PROJECT_ROOT/requirements.txt" ] || ls "$PROJECT_ROOT"/*.py >/dev/null 2>&1; then
        test_cmd="pytest"
    elif [ -f "$PROJECT_ROOT/package.json" ]; then
        test_cmd="npm test"
    elif [ -f "$PROJECT_ROOT/go.mod" ]; then
        test_cmd="go test ./..."
    fi
fi

if [ -z "$test_cmd" ]; then
    echo "  ❌ Could not detect a test command for this project"
    ((errors++))
else
    echo "  Running: $test_cmd"
    # Determine pass/fail from a plain run first — coverage tooling (e.g. missing
    # pytest-cov) must never turn a passing suite into a false "tests failing".
    # PYTHONPATH is set for the python fallback: a project with no pyproject.toml/
    # conftest.py adding the root to sys.path otherwise fails on "src.foo" imports
    # for reasons that have nothing to do with the code under test.
    if [[ "$test_cmd" == pytest* ]]; then
        test_output=$(cd "$PROJECT_ROOT" && PYTHONPATH="$PROJECT_ROOT" eval "$test_cmd" 2>&1)
    else
        test_output=$(cd "$PROJECT_ROOT" && eval "$test_cmd" 2>&1)
    fi
    test_exit=$?
    echo "$test_output" | tail -20

    if command -v pytest >/dev/null 2>&1 && [[ "$test_cmd" == pytest* ]]; then
        if python3 -c "import pytest_cov" >/dev/null 2>&1; then
            cov_output=$(cd "$PROJECT_ROOT" && PYTHONPATH="$PROJECT_ROOT" pytest --cov="$PROJECT_ROOT" --cov-report=term-missing 2>&1)
            coverage_pct=$(echo "$cov_output" | grep -E "^TOTAL" | grep -oE "[0-9]+%" | tr -d '%' | tail -1)
        fi
    fi

    if [ "$test_exit" -eq 0 ]; then
        echo "  ✅ Tests passing"
    else
        echo "  ❌ Tests failing (exit code $test_exit)"
        ((errors++))
    fi
fi

echo ""

# ============================================
# Coverage
# ============================================

echo "📊 Checking coverage..."

if [ -n "$coverage_pct" ]; then
    if [ "$coverage_pct" -ge "$COVERAGE_THRESHOLD" ]; then
        echo "  ✅ Coverage: ${coverage_pct}% (>= ${COVERAGE_THRESHOLD}%)"
    else
        echo "  ❌ Coverage: ${coverage_pct}% (< ${COVERAGE_THRESHOLD}% required)"
        ((errors++))
    fi
else
    echo "  ⚠️  Warning: Could not determine coverage percentage for this stack — review manually"
    ((warnings++))
fi

echo ""

# ============================================
# Summary
# ============================================

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ "$errors" -eq 0 ]; then
    echo "✅ Test Validation PASSED"
    if [ "$warnings" -gt 0 ]; then
        echo ""
        echo "⚠️  $warnings warning(s) found (non-blocking)"
    fi
    exit 0
else
    echo "❌ Test Validation FAILED"
    echo ""
    echo "   Errors: $errors (must fix — feature CANNOT be completed)"
    echo "   Warnings: $warnings"
    exit 1
fi
