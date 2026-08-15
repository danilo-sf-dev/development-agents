#!/bin/bash
# SDD Kit — Claude Code Telemetry Parser
#
# Extracts per-dispatch telemetry from a `claude -p --output-format stream-json --verbose`
# result. The resolved model ID (--model arg) is used as the direct lookup key in
# modelUsage — no heuristics, no date-suffix stripping needed. The adapter resolves the
# model via resolve-model.sh before dispatch and passes that same ID to --model in the
# claude -p call; modelUsage uses that exact ID as its key.
#
# Usage:
#   parse-telemetry.sh --model <resolved-model-id> [--file <stream-json-file>]
#   echo "<stream-json>" | parse-telemetry.sh --model <resolved-model-id>
#
# Output (stdout, always exit 0 — telemetry failure never propagates):
#   success: {"available":true,"model":"...","input":N,"output":N,"cache_read":N,"cache_write":N,"cost_usd":N.NN,"duration_ms":N}
#   failure: {"available":false,"reason":"<why>"}
#
# All fields are always emitted (cache_read/cache_write included). The display layer
# decides which fields to show based on verbose mode — the parser never filters.

set -euo pipefail

RESOLVED_MODEL=""
STREAM_FILE=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --model) RESOLVED_MODEL="$2"; shift 2 ;;
        --file)  STREAM_FILE="$2";   shift 2 ;;
        *)
            echo "{\"available\":false,\"reason\":\"unknown argument: $1\"}"
            exit 0
            ;;
    esac
done

if [[ -z "$RESOLVED_MODEL" ]]; then
    echo '{"available":false,"reason":"--model argument required"}'
    exit 0
fi

# Read stream content
if [[ -n "$STREAM_FILE" ]]; then
    STREAM_CONTENT=$(cat "$STREAM_FILE" 2>/dev/null || true)
else
    STREAM_CONTENT=$(cat 2>/dev/null || true)
fi

if [[ -z "$STREAM_CONTENT" ]]; then
    echo '{"available":false,"reason":"empty stream input"}'
    exit 0
fi

# Write to temp file — avoids shell quoting issues with large/multi-line JSON
TMP=$(mktemp)
trap "rm -f '$TMP'" EXIT
printf '%s\n' "$STREAM_CONTENT" > "$TMP"

# Python3 parses the result envelope. Reads code from stdin (here-doc); stream content
# from the temp file passed as argv[2]. Always exits 0 regardless of parse errors.
python3 - "$RESOLVED_MODEL" "$TMP" 2>/dev/null <<'PYEOF' || echo '{"available":false,"reason":"python3 unavailable or crashed"}'
import json, sys

model     = sys.argv[1]
tmp_path  = sys.argv[2]

def emit(obj):
    print(json.dumps(obj))
    sys.exit(0)

def fail(reason):
    emit({"available": False, "reason": reason})

try:
    result_line = None
    with open(tmp_path) as f:
        for raw in f:
            raw = raw.strip()
            if not raw:
                continue
            try:
                obj = json.loads(raw)
                if isinstance(obj, dict) and obj.get("type") == "result":
                    result_line = obj
            except json.JSONDecodeError:
                pass  # skip non-JSON and partial lines

    if result_line is None:
        fail("no result line found in stream")

    model_usage = result_line.get("modelUsage")
    if not isinstance(model_usage, dict):
        fail("modelUsage missing or not an object")

    if model not in model_usage:
        fail("model '{}' not in modelUsage; found: {}".format(model, list(model_usage.keys())))

    mu       = model_usage[model]
    duration = result_line.get("duration_ms", 0)

    emit({
        "available":   True,
        "model":       model,
        "input":       mu.get("inputTokens",             0),
        "output":      mu.get("outputTokens",            0),
        "cache_read":  mu.get("cacheReadInputTokens",    0),
        "cache_write": mu.get("cacheCreationInputTokens",0),
        "cost_usd":    mu.get("costUSD",                 0.0),
        "duration_ms": duration,
    })

except Exception as e:
    fail(str(e))
PYEOF
