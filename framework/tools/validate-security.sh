#!/bin/bash

# SDD SDD Kit - Security Spec Validator
# Validates the technical spec's Security section against OWASP Top 10 concerns (Step 6a.1)
# Usage: validate-security.sh sdd/wip/[feature] --spec

FEATURE_PATH=$1
MODE=$2

if [ -z "$FEATURE_PATH" ]; then
    echo "❌ Error: Feature path required"
    echo "Usage: $0 sdd/wip/[feature-name] --spec"
    exit 1
fi

if [ "$MODE" != "--spec" ]; then
    echo "❌ Error: this validator only supports spec-level review today"
    echo "Usage: $0 sdd/wip/[feature-name] --spec"
    exit 1
fi

SPEC_FILE="$FEATURE_PATH/2-technical/spec.md"

if [ ! -f "$SPEC_FILE" ]; then
    echo "❌ Error: Technical spec not found at $SPEC_FILE"
    exit 1
fi

echo "🔒 Validating security (OWASP Top 10) for $(basename "$FEATURE_PATH")..."
echo ""

errors=0
warnings=0

SECURITY_BLOCK=$(sed -n '/^## Security$/,/^## /p' "$SPEC_FILE")

if [ -z "$SECURITY_BLOCK" ]; then
    echo "❌ No '## Security' section found — security review requires one"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "❌ Security Validation FAILED"
    echo "   Errors: 1 (must fix)"
    exit 1
fi

# ============================================
# Secrets (mandatory — see commands/sdd.spec.md Key Rules)
# ============================================

echo "🔑 Checking Secrets coverage..."

if echo "$SECURITY_BLOCK" | grep -qi "secret"; then
    echo "  ✅ Secrets addressed"
else
    echo "  ❌ Security section does not mention Secrets (mandatory)"
    ((errors++))
fi

echo ""

# ============================================
# OWASP Top 10-adjacent coverage (spec-level, informational)
# ============================================

echo "🛡️  Checking OWASP-relevant coverage..."

declare -A owasp_checks=(
    ["Authentication"]="authenticat"
    ["Authorization / Access Control"]="authoriz|access control|rbac|permission"
    ["Input Validation"]="input validat|sanitiz|injection"
    ["Sensitive Data / Encryption"]="encrypt|sensitive data|pii|at rest|in transit"
    ["Rate Limiting"]="rate limit|throttl"
    ["Logging / Monitoring"]="log|audit|monitor"
)

for label in "${!owasp_checks[@]}"; do
    pattern="${owasp_checks[$label]}"
    if echo "$SECURITY_BLOCK" | grep -qiE "$pattern"; then
        echo "  ✅ $label addressed"
    else
        echo "  ⚠️  Warning: $label not mentioned in Security section"
        ((warnings++))
    fi
done

echo ""

# ============================================
# Hardcoded secret patterns literally written into the spec (CWE-798)
# ============================================

echo "🔍 Scanning spec text for literal hardcoded secrets..."

secret_hits=0
patterns=(
    'password\s*[:=]\s*["\x27][^"\x27]{8,}["\x27]'
    'api[_-]?key\s*[:=]\s*["\x27][A-Za-z0-9]{16,}["\x27]'
    'secret\s*[:=]\s*["\x27][^"\x27]{8,}["\x27]'
    'private[_-]?key\s*[:=]\s*["\x27]'
    'AWS_SECRET|GITHUB_TOKEN|SLACK_TOKEN'
)

for pattern in "${patterns[@]}"; do
    hits=$(grep -icE "$pattern" "$SPEC_FILE")
    if [ "$hits" -gt 0 ]; then
        echo "  ❌ Possible hardcoded secret matching pattern: $pattern"
        ((secret_hits+=hits))
    fi
done

if [ "$secret_hits" -eq 0 ]; then
    echo "  ✅ No literal secrets found in spec text"
else
    ((errors+=secret_hits))
fi

echo ""

# ============================================
# Summary
# ============================================

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ "$errors" -eq 0 ]; then
    echo "✅ Security Validation PASSED"

    if [ "$warnings" -gt 0 ]; then
        echo ""
        echo "⚠️  $warnings warning(s) found (non-blocking)"
        echo "   Consider addressing before approval"
    fi

    echo ""
    echo "Next: show technical spec summary, then AskUserQuestion for approval"
    exit 0
else
    echo "❌ Security Validation FAILED"
    echo ""
    echo "   Errors: $errors (must fix)"
    echo "   Warnings: $warnings (optional)"
    echo ""
    echo "How to fix:"
    echo "• Edit: $SPEC_FILE"
    echo "• Re-validate: $0 $FEATURE_PATH --spec"
    exit 1
fi
