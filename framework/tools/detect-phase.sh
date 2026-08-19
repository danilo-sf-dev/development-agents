#!/bin/bash
# detect-phase.sh - Detect current phase from meta.md
# Usage: detect-phase.sh <FEATURE_PATH> [--json]

set -e

FEATURE_PATH="${1:-.}"
JSON_OUTPUT=false
[[ "$2" == "--json" ]] && JSON_OUTPUT=true

META_FILE="$FEATURE_PATH/meta.md"
[ ! -f "$META_FILE" ] && { echo "❌ meta.md not found at $META_FILE"; exit 1; }

# Method 1 (primary source): read the "Current Stage" field. Canonical format
# (framework/templates/meta.md) is bold markdown: "**Current Stage**: functional".
# Tolerate 0-2 asterisks on either side so a plain "Current Stage: x" also matches,
# and ignore any trailing text (e.g. "implementation (Phase 4/4)").
current_stage=$(grep -m1 -iE '^\*{0,2}Current Stage\*{0,2}:' "$META_FILE" 2>/dev/null \
    | sed -E 's/^\*{0,2}Current Stage\*{0,2}: *//I' \
    | awk '{print $1}' \
    | tr -d '*' \
    | tr '[:upper:]' '[:lower:]')

# Method 2: infer from the `stages:` YAML block (## Stage History) if the field
# above is missing/unreadable. Sequence: functional -> technical -> tasks ->
# tests -> implementation. Each stage's status starts "pending" (not started
# yet -- this is the template default for every stage that hasn't been reached),
# then moves to "in-progress", then "approved" (or "completed" for
# implementation) -- see commands/sdd.test.md Step 1 and
# commands/references/plan-approval.md for the real write points. A "pending"
# status is never itself a "this is the current stage" signal.
if [ -z "$current_stage" ]; then
    # Scope the parse to the stages: block only, so same-named keys elsewhere
    # in meta.md (e.g. Backlog Workflow's auto_generated.functional/technical,
    # or Validation Overrides' functional/technical/tasks) can't be matched.
    stages_block=$(sed -n '/^stages:/,/^```/p' "$META_FILE" 2>/dev/null)

    get_status() {
        echo "$stages_block" | grep -A5 "^  $1:" | grep "status:" | head -1 | sed 's/.*status: *//' | awk '{print $1}'
    }

    stages=(functional technical tasks tests implementation)
    statuses=()
    for s in "${stages[@]}"; do
        statuses+=("$(get_status "$s")")
    done

    # Find the last (highest-index) stage that has actually started
    # (status present and not "pending").
    last_started_idx=-1
    for i in "${!stages[@]}"; do
        st="${statuses[$i]}"
        if [ -n "$st" ] && [ "$st" != "pending" ]; then
            last_started_idx=$i
        fi
    done

    if [ "$last_started_idx" -eq -1 ]; then
        # Nothing started yet -> brand new feature, still at the first stage.
        current_stage="functional"
    else
        st="${statuses[$last_started_idx]}"
        if [ "$st" = "in-progress" ]; then
            current_stage="${stages[$last_started_idx]}"
        else
            # approved / completed -> move on to the next stage in sequence
            next_idx=$((last_started_idx + 1))
            if [ "$next_idx" -lt "${#stages[@]}" ]; then
                current_stage="${stages[$next_idx]}"
            else
                # implementation approved/completed is terminal -- stay there
                current_stage="${stages[$last_started_idx]}"
            fi
        fi
    fi
fi

# Map stage to phase number
case "$current_stage" in
    functional) phase=1 ;;
    technical) phase=2 ;;
    tasks) phase=3 ;;
    tests) phase=4 ;;
    implementation) phase=5 ;;
    *) echo "❌ Unknown stage: $current_stage"; exit 1 ;;
esac

# Determine available layers
case $phase in
    1) layers="functional" ;;
    2) layers="functional technical" ;;
    3) layers="functional technical tasks" ;;
    4) layers="functional technical tasks tests" ;;
    5) layers="functional technical tasks tests code" ;;
esac

if [ "$JSON_OUTPUT" = true ]; then
    echo "{\"phase\":$phase,\"stage\":\"$current_stage\",\"layers\":\"$layers\"}"
else
    echo "📊 Phase: $phase ($current_stage)"
    echo "   Available layers: $layers"
fi
exit 0
