#!/bin/bash

# SDD SDD Kit - Spec Cross-Reference Conflict Detector
# Surfaces <!-- overrides/extends/deprecates: path#section --> annotations that are
# dangling (target missing) or that collide with another feature's annotation on the
# same target. Candidates only — the agent reviews and proposes resolutions (see
# commands/sdd.spec.md Step 7).
#
# Usage: validate-spec-conflicts.sh sdd/wip/[feature] [blocking]
#   blocking: only exit non-zero for dangling references / duplicate overrides;
#             informational-only annotations (extends/deprecates with a valid, unique
#             target) never fail exit code either way, but are still printed.

FEATURE_PATH=$1
SEVERITY=$2

if [ -z "$FEATURE_PATH" ]; then
    echo "❌ Error: Feature path required"
    echo "Usage: $0 sdd/wip/[feature-name] [blocking]"
    exit 1
fi

# Project root is three levels up from sdd/wip/[feature] (sdd -> wip -> feature)
PROJECT_ROOT=$(cd "$FEATURE_PATH/../../.." && pwd)
FEATURE_NAME=$(basename "$FEATURE_PATH")

SPEC_FILES=()
[ -f "$FEATURE_PATH/1-functional/spec.md" ] && SPEC_FILES+=("$FEATURE_PATH/1-functional/spec.md")
[ -f "$FEATURE_PATH/2-technical/spec.md" ] && SPEC_FILES+=("$FEATURE_PATH/2-technical/spec.md")

if [ ${#SPEC_FILES[@]} -eq 0 ]; then
    echo "❌ Error: No spec files found under $FEATURE_PATH"
    exit 1
fi

echo "🔍 Scanning spec cross-references for $FEATURE_NAME..."
echo ""

errors=0
warnings=0
annotation_count=0

ANNOTATION_RE='<!--[[:space:]]*(overrides|extends|deprecates):[[:space:]]*([^#[:space:]]+)#([^[:space:]]+)[[:space:]]*-->'

check_target() {
    local ref_type="$1" target_path="$2" target_section="$3" source_file="$4"
    local resolved="$PROJECT_ROOT/$target_path"

    if [ ! -f "$resolved" ]; then
        echo "  ❌ [$ref_type] $source_file → $target_path#$target_section"
        echo "     Referenced file does not exist"
        ((errors++))
        return
    fi

    # Fuzzy heading match: slugify target headings and compare to the referenced section
    local slug_match
    slug_match=$(grep -E "^#{1,6} " "$resolved" | \
        sed -E 's/^#+ //' | \
        tr '[:upper:]' '[:lower:]' | \
        sed -E 's/[^a-z0-9]+/-/g; s/^-+|-+$//g' | \
        grep -Fx "$target_section")

    if [ -z "$slug_match" ]; then
        echo "  ❌ [$ref_type] $source_file → $target_path#$target_section"
        echo "     File exists but no heading matches section '$target_section'"
        ((errors++))
    else
        echo "  ✅ [$ref_type] $source_file → $target_path#$target_section"
    fi
}

for spec_file in "${SPEC_FILES[@]}"; do
    rel_spec=${spec_file#"$PROJECT_ROOT/"}
    matches=$(grep -oE "$ANNOTATION_RE" "$spec_file")

    if [ -z "$matches" ]; then
        continue
    fi

    while IFS= read -r line; do
        [ -z "$line" ] && continue
        ((annotation_count++))
        ref_type=$(echo "$line" | sed -E 's/.*(overrides|extends|deprecates).*/\1/')
        target=$(echo "$line" | sed -E 's/.*:[[:space:]]*([^[:space:]]+)[[:space:]]*-->.*/\1/')
        target_path=${target%%#*}
        target_section=${target#*#}

        check_target "$ref_type" "$target_path" "$target_section" "$rel_spec"
    done <<< "$matches"
done

if [ "$annotation_count" -eq 0 ]; then
    echo "  ℹ️  No overrides/extends/deprecates annotations found — nothing to check"
fi

echo ""

# ============================================
# Duplicate-override detection across sibling features
# ============================================

echo "🔀 Checking for competing overrides across other features..."

this_overrides=()
for spec_file in "${SPEC_FILES[@]}"; do
    while IFS= read -r line; do
        [ -z "$line" ] && continue
        target=$(echo "$line" | sed -E 's/.*overrides:[[:space:]]*([^[:space:]]+)[[:space:]]*-->/\1/')
        this_overrides+=("$target")
    done < <(grep -oE '<!--[[:space:]]*overrides:[[:space:]]*[^[:space:]]+[[:space:]]*-->' "$spec_file")
done

duplicate_count=0
if [ ${#this_overrides[@]} -gt 0 ]; then
    for target in "${this_overrides[@]}"; do
        for sibling_dir in "$PROJECT_ROOT"/sdd/wip/*/ "$PROJECT_ROOT"/sdd/features/*/; do
            [ -d "$sibling_dir" ] || continue
            sibling_name=$(basename "$sibling_dir")
            [ "$sibling_name" = "$FEATURE_NAME" ] && continue

            for sibling_spec in "$sibling_dir"1-functional/spec.md "$sibling_dir"2-technical/spec.md; do
                [ -f "$sibling_spec" ] || continue
                if grep -qF "overrides: $target" "$sibling_spec"; then
                    echo "  ❌ Both '$FEATURE_NAME' and '$sibling_name' override $target"
                    ((duplicate_count++))
                fi
            done
        done
    done
fi

if [ "$duplicate_count" -eq 0 ]; then
    echo "  ✅ No competing overrides found"
else
    ((errors+=duplicate_count))
fi

echo ""

# ============================================
# Summary
# ============================================

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Annotations checked: $annotation_count"
echo "Conflicts: $errors"

if [ "$SEVERITY" = "blocking" ]; then
    if [ "$errors" -eq 0 ]; then
        echo "✅ No blocking conflicts"
        exit 0
    else
        echo "❌ Blocking conflicts found — resolve before proceeding"
        exit 1
    fi
else
    echo "ℹ️  Candidates surfaced for agent review (non-blocking mode)"
    exit 0
fi
