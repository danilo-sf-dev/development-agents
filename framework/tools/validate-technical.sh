#!/bin/bash

# SDD SDD Kit - Technical Spec Validator
# Validates technical spec completeness and quality (Step 6a, before security validation)

FEATURE_PATH=$1

if [ -z "$FEATURE_PATH" ]; then
    echo "❌ Error: Feature path required"
    echo "Usage: $0 sdd/wip/[feature-name]"
    exit 1
fi

SPEC_FILE="$FEATURE_PATH/2-technical/spec.md"

if [ ! -f "$SPEC_FILE" ]; then
    echo "❌ Error: Technical spec not found at $SPEC_FILE"
    exit 1
fi

echo "🔍 Validating technical spec for $(basename "$FEATURE_PATH")..."
echo ""

errors=0
warnings=0

# ============================================
# Required Sections Check
# ============================================

required_sections=(
    "## Executive Summary"
    "## Architecture Overview"
    "## Design Decisions"
    "## Data Model"
    "## Testing Strategy"
    "## Security"
    "## Performance"
    "## Deployment Strategy"
)

echo "📋 Checking required sections..."

for section in "${required_sections[@]}"; do
    if grep -q "^$section" "$SPEC_FILE"; then
        echo "  ✅ $section"
    else
        echo "  ❌ Missing required section: $section"
        ((errors++))
    fi
done

# Project Services / Dependencies — required unless the spec explicitly states none apply
for section in "## Project Services Used" "## Dependencies"; do
    if grep -q "^$section" "$SPEC_FILE"; then
        echo "  ✅ $section"
    else
        echo "  ⚠️  Warning: Missing section: $section (omit only if genuinely not applicable)"
        ((warnings++))
    fi
done

echo ""

# ============================================
# Design Decisions Validation
# ============================================

echo "🏗️  Validating Design Decisions..."

dd_count=$(grep -c "^### DD-" "$SPEC_FILE")

if [ "$dd_count" -eq 0 ]; then
    echo "  ⚠️  Warning: No Design Decisions found (expected format: ### DD-1: Title)"
    ((warnings++))
else
    echo "  Found $dd_count design decision(s)"

    # Every DD block must contain both "Options Considered" and "Trade-offs Accepted"
    # (mandatory per references/spec-architecture-options.md — missing either is an error, not a warning)
    dd_blocks=$(awk '/^### DD-/{n++} {print > ("/tmp/validate-technical-dd-" n ".txt")}' "$SPEC_FILE" 2>/dev/null; echo "$dd_count")

    missing_dd_sections=0
    dd_titles=$(grep "^### DD-" "$SPEC_FILE")

    while IFS= read -r title; do
        [ -z "$title" ] && continue
        dd_id=$(echo "$title" | grep -oE "DD-[0-9]+")
        # Extract the block of text for this DD up to the next ### or ## heading
        block=$(awk -v start="^### $dd_id" '
            $0 ~ start {flag=1; next}
            flag && /^(##|### DD-)/ {flag=0}
            flag {print}
        ' "$SPEC_FILE")

        block_ok=true
        if ! echo "$block" | grep -qi "Options Considered"; then
            echo "  ❌ $dd_id missing 'Options Considered'"
            block_ok=false
        fi
        if ! echo "$block" | grep -qi "Trade-offs Accepted"; then
            echo "  ❌ $dd_id missing 'Trade-offs Accepted'"
            block_ok=false
        fi
        if [ "$block_ok" = false ]; then
            ((missing_dd_sections++))
        fi
    done <<< "$dd_titles"

    if [ "$missing_dd_sections" -eq 0 ]; then
        echo "  ✅ All design decisions document Options Considered + Trade-offs Accepted"
    else
        ((errors+=missing_dd_sections))
    fi

    rm -f /tmp/validate-technical-dd-*.txt 2>/dev/null
fi

echo ""

# ============================================
# Security Section — Secrets subsection mandatory
# ============================================

echo "🔒 Checking Security section..."

security_block=$(sed -n '/^## Security$/,/^## /p' "$SPEC_FILE")

if [ -z "$security_block" ]; then
    echo "  ❌ No Security section to check (see required sections above)"
    ((errors++))
else
    if echo "$security_block" | grep -qi "secret"; then
        echo "  ✅ Secrets addressed in Security section"
    else
        echo "  ❌ Security section does not mention Secrets (mandatory)"
        ((errors++))
    fi
fi

echo ""

# ============================================
# Data Model Validation
# ============================================

echo "📊 Validating Data Model..."

if grep -A 30 "^## Data Model" "$SPEC_FILE" | grep -qE "^\||^###"; then
    echo "  ✅ Data Model has structured content (table or subsections)"
else
    echo "  ⚠️  Warning: Data Model section has no tables or subsections"
    ((warnings++))
fi

echo ""

# ============================================
# Quality Checks
# ============================================

echo "🔍 Quality checks..."

todos=$(grep -ic "TODO\|TBD\|FIXME" "$SPEC_FILE")
if [ "$todos" -gt 0 ]; then
    echo "  ⚠️  Warning: $todos TODO/TBD markers found"
    ((warnings++))
else
    echo "  ✅ No TODO markers"
fi

open_questions=$(grep -c "^- \[ \]" "$SPEC_FILE")
if [ "$open_questions" -gt 0 ]; then
    echo "  ⚠️  Warning: $open_questions open questions/checkboxes"
    ((warnings++))
else
    echo "  ✅ No open questions"
fi

echo ""

# ============================================
# Summary
# ============================================

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ "$errors" -eq 0 ]; then
    echo "✅ Technical Spec Validation PASSED"

    if [ "$warnings" -gt 0 ]; then
        echo ""
        echo "⚠️  $warnings warning(s) found (non-blocking)"
        echo "   Consider addressing before approval"
    fi

    echo ""
    echo "Next: validate-security.sh $FEATURE_PATH --spec"
    exit 0
else
    echo "❌ Technical Spec Validation FAILED"
    echo ""
    echo "   Errors: $errors (must fix)"
    echo "   Warnings: $warnings (optional)"
    echo ""
    echo "How to fix:"
    echo "• Edit: $SPEC_FILE"
    echo "• Re-validate: $0 $FEATURE_PATH"
    exit 1
fi
