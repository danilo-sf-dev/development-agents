#!/bin/bash

# SDD SDD Kit - PROJECT.md Validator
# Advisory (non-blocking) structural check of PROJECT.md against the framework template.
# Used by /sdd.start (references/start-project-md.md) and /sdd.check --project.
#
# Usage: validate-project.sh sdd/PROJECT.md [--json]

PROJECT_FILE=$1
JSON_OUTPUT=false
[[ "$2" == "--json" ]] && JSON_OUTPUT=true

if [ -z "$PROJECT_FILE" ]; then
    echo "❌ Error: PROJECT.md path required"
    echo "Usage: $0 sdd/PROJECT.md [--json]"
    exit 1
fi

if [ ! -f "$PROJECT_FILE" ]; then
    if [ "$JSON_OUTPUT" = true ]; then
        echo "{\"valid\":false,\"warnings\":[\"PROJECT.md not found at $PROJECT_FILE\"]}"
    else
        echo "❌ Error: PROJECT.md not found at $PROJECT_FILE"
    fi
    exit 1
fi

warnings=()

expected_sections=(
    "## Project Vision"
    "## Platform Configuration"
    "## Technology Preferences"
    "## Quality Gates"
    "## Default Feature Settings"
)

for section in "${expected_sections[@]}"; do
    if ! grep -q "^$section" "$PROJECT_FILE"; then
        warnings+=("Missing expected section: $section")
    fi
done

if grep -qi "TODO\|TBD\|\[fill" "$PROJECT_FILE"; then
    warnings+=("Unfilled placeholders (TODO/TBD/[fill...]) found — review before relying on PROJECT.md defaults")
fi

warning_count=${#warnings[@]}
valid=true
[ "$warning_count" -gt 0 ] && valid=false

if [ "$JSON_OUTPUT" = true ]; then
    warnings_json=$(printf '"%s",' "${warnings[@]}")
    warnings_json="[${warnings_json%,}]"
    echo "{\"valid\":$valid,\"warnings\":$warnings_json}"
else
    echo "🔍 Validating PROJECT.md..."
    echo ""
    if [ "$warning_count" -eq 0 ]; then
        echo "✅ PROJECT.md looks complete"
    else
        echo "⚠️  $warning_count warning(s):"
        for w in "${warnings[@]}"; do
            echo "   - $w"
        done
    fi
fi

exit 0
