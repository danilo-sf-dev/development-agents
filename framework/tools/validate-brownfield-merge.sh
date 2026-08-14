#!/bin/bash

# SDD SDD Kit - Brownfield Merge Readiness Validator
# MANDATORY for brownfield projects, called from /sdd.finish (see
# commands/references/finish-brownfield-merge.md) before offering to merge
# feature changes back into sdd/specs/. Reads meta.md's "Brownfield Context"
# block (affected_specs + impact) — the structured source of truth the
# template already defines — rather than re-deriving it from spec prose.
#
# Usage: validate-brownfield-merge.sh sdd/wip/[feature] [--json]

FEATURE_PATH=$1
JSON_OUTPUT=false
[[ "$2" == "--json" ]] && JSON_OUTPUT=true

if [ -z "$FEATURE_PATH" ]; then
    echo "❌ Error: Feature path required"
    echo "Usage: $0 sdd/wip/[feature-name] [--json]"
    exit 1
fi

META_FILE="$FEATURE_PATH/meta.md"

if [ ! -f "$META_FILE" ]; then
    echo "❌ Error: meta.md not found at $META_FILE"
    exit 1
fi

PROJECT_ROOT=$(cd "$FEATURE_PATH/../../.." && pwd)

# Extract the affected_specs YAML block's `path:` entries
affected_specs=()
while IFS= read -r line; do
    p=$(echo "$line" | sed -E 's/^\s*-\s*path:\s*//')
    [ -n "$p" ] && affected_specs+=("$p")
done < <(sed -n '/^affected_specs:/,/^impact:/p' "$META_FILE" | grep -E "^\s*-\s*path:")

conflicts=()

for spec in "${affected_specs[@]}"; do
    if [ ! -f "$PROJECT_ROOT/$spec" ]; then
        conflicts+=("$spec: target system spec does not exist")
    fi
done

breaking_changes=$(grep -A5 "^impact:" "$META_FILE" | grep "breaking_changes:" | head -1 | sed -E 's/.*breaking_changes:\s*//' | tr -d ' "')
if [ "$breaking_changes" = "true" ]; then
    conflicts+=("impact.breaking_changes: true — requires human review before merge")
fi

conflict_count=${#conflicts[@]}
ready=true
[ "$conflict_count" -gt 0 ] && ready=false

if [ "$JSON_OUTPUT" = true ]; then
    conflicts_json=$(printf '"%s",' "${conflicts[@]}")
    conflicts_json="[${conflicts_json%,}]"
    specs_json=$(printf '"%s",' "${affected_specs[@]}")
    specs_json="[${specs_json%,}]"
    echo "{\"ready\":$ready,\"conflict_count\":$conflict_count,\"conflicts\":$conflicts_json,\"affected_specs\":$specs_json}"
else
    echo "🔍 Validating brownfield merge readiness for $(basename "$FEATURE_PATH")..."
    echo ""

    if [ ${#affected_specs[@]} -eq 0 ]; then
        echo "  ℹ️  No affected_specs recorded in meta.md — nothing to merge"
    else
        echo "📋 Affected system specs:"
        for s in "${affected_specs[@]}"; do
            echo "   - $s"
        done
    fi

    echo ""
    if [ "$conflict_count" -eq 0 ]; then
        echo "✅ Merge readiness: ready"
    else
        echo "⚠️  Merge readiness: $conflict_count issue(s)"
        for c in "${conflicts[@]}"; do
            echo "   - $c"
        done
    fi
fi

[ "$ready" = true ] && exit 0 || exit 1
