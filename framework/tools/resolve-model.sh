#!/bin/bash
# SDD Kit - Model Role Resolver
# The one authoritative resolve_model(harness, model_role) implementation.
# Reads config/model-routing.yaml — nothing else in the pack may hardcode this mapping.
#
# Usage: resolve-model.sh <harness> <STRONG|EXECUTION> [--json]
#   harness: claude-code | cursor | codex
# Output (default): "model=<value> effort=<value-or-empty>" on stdout, one line.
# Output (--json):  {"model":"...","effort":"..."} (effort omitted if not set for that harness/role)
# Exit codes: 0 = resolved, 1 = bad usage, 2 = role/harness not found in config

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACK_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
CONFIG_FILE="$PACK_ROOT/config/model-routing.yaml"

HARNESS="$1"
ROLE="$2"
OUTPUT_JSON=false
[[ "$3" == "--json" ]] && OUTPUT_JSON=true

if [[ -z "$HARNESS" || -z "$ROLE" ]]; then
    echo "Usage: resolve-model.sh <claude-code|cursor|codex> <STRONG|EXECUTION> [--json]" >&2
    exit 1
fi

if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "ERROR: config file not found at $CONFIG_FILE" >&2
    exit 2
fi

# Minimal, dependency-free parse of the fixed 2-level structure:
#   roles:
#     <ROLE>:
#       <harness>:
#         model: <value>
#         effort: <value>   # optional
# No YAML library required — the schema is intentionally flat and stable so this stays
# parseable with awk alone on any target project (no guaranteed yq/python present).
BLOCK=$(awk -v role="  $ROLE:" -v harness="    $HARNESS:" '
    $0 == role { in_role=1; next }
    in_role && /^  [A-Za-z]/ && $0 != role { in_role=0 }
    in_role && $0 == harness { in_harness=1; next }
    in_harness && /^    [a-z]/ && $0 != harness { in_harness=0 }
    in_harness && /^      model:/ { sub(/^      model:[ \t]*/, ""); print "model=" $0 }
    in_harness && /^      effort:/ { sub(/^      effort:[ \t]*/, ""); print "effort=" $0 }
' "$CONFIG_FILE")

MODEL=$(echo "$BLOCK" | grep '^model=' | cut -d= -f2-)
EFFORT=$(echo "$BLOCK" | grep '^effort=' | cut -d= -f2-)

if [[ -z "$MODEL" ]]; then
    echo "ERROR: no model resolved for harness='$HARNESS' role='$ROLE' in $CONFIG_FILE" >&2
    echo "This harness may not have an entry (e.g. 'generic') — see adapters/<harness>/README.md for its fallback rule." >&2
    exit 2
fi

if $OUTPUT_JSON; then
    if [[ -n "$EFFORT" ]]; then
        echo "{\"model\":\"$MODEL\",\"effort\":\"$EFFORT\"}"
    else
        echo "{\"model\":\"$MODEL\"}"
    fi
else
    echo "model=$MODEL effort=$EFFORT"
fi
