#!/bin/bash

# SDD SDD Kit - Spec Alignment Validator
# Detects drift between functional and technical specs (functional -> technical direction):
# every functional User Story should be traceable to something in the technical spec.
# Used by /sdd.check --sync Step 0a (see commands/references/check-rare-workflows.md).
#
# Usage: validate-spec-alignment.sh sdd/wip/[feature] [--json]

FEATURE_PATH=$1
JSON_OUTPUT=false
[[ "$2" == "--json" ]] && JSON_OUTPUT=true

if [ -z "$FEATURE_PATH" ]; then
    echo "❌ Error: Feature path required"
    echo "Usage: $0 sdd/wip/[feature-name] [--json]"
    exit 1
fi

FUNCTIONAL_FILE="$FEATURE_PATH/1-functional/spec.md"
TECHNICAL_FILE="$FEATURE_PATH/2-technical/spec.md"

if [ ! -f "$FUNCTIONAL_FILE" ]; then
    echo "❌ Error: Functional spec not found at $FUNCTIONAL_FILE"
    exit 1
fi

if [ ! -f "$TECHNICAL_FILE" ]; then
    echo "❌ Error: Technical spec not found at $TECHNICAL_FILE"
    echo "   Spec alignment requires both specs to exist"
    exit 1
fi

us_ids=$(grep -oE "^### US-[0-9]+" "$FUNCTIONAL_FILE" | grep -oE "US-[0-9]+")

drifts=()
for us_id in $us_ids; do
    if ! grep -q "$us_id" "$TECHNICAL_FILE"; then
        drifts+=("$us_id")
    fi
done

drift_count=${#drifts[@]}
aligned=true
[ "$drift_count" -gt 0 ] && aligned=false

if [ "$JSON_OUTPUT" = true ]; then
    drifts_json=$(printf '"%s",' "${drifts[@]}")
    drifts_json="[${drifts_json%,}]"
    echo "{\"aligned\":$aligned,\"drift_count\":$drift_count,\"drifts\":$drifts_json}"
else
    echo "🔍 Validating spec alignment for $(basename "$FEATURE_PATH")..."
    echo ""
    echo "📋 Checking functional → technical traceability..."
    total_us=$(grep -oE "^### US-[0-9]+" "$FUNCTIONAL_FILE" | wc -l | tr -d ' ')
    echo "  Found $total_us user stories in functional spec"

    if [ "$drift_count" -eq 0 ]; then
        echo "  ✅ Every user story is referenced in the technical spec"
    else
        echo "  ❌ $drift_count user stor$([ "$drift_count" -eq 1 ] && echo "y" || echo "ies") not referenced in technical spec:"
        for d in "${drifts[@]}"; do
            echo "     - $d"
        done
    fi

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    if [ "$aligned" = true ]; then
        echo "✅ Spec Alignment PASSED"
    else
        echo "⚠️  Spec Alignment: $drift_count drift(s) found"
        echo "   Non-blocking — review before /sdd.check --sync proposes fixes"
    fi
fi

[ "$aligned" = true ] && exit 0 || exit 1
