#!/bin/bash
# SDD Kit — Codex CLI Telemetry Parser
#
# Extracts per-dispatch telemetry from a `codex exec --json` JSONL output stream.
# Scans for the `type:"turn.completed"` event and extracts its `usage` object.
#
# Primary source: `codex exec --json` JSONL output — the stable public API.
# Fallback (rollout-*.jsonl in ~/.codex/sessions): implementation internals that
# can change without notice. This parser does NOT use them. If --json already
# contains the usage data, fallback is unnecessary.
#
# Usage:
#   parse-telemetry.sh --model <id> [--effort <level>] [--duration-ms <N>] [--file <path>]
#   codex exec --json ... | parse-telemetry.sh --model <id> [--effort <level>]
#
# Arguments:
#   --model        Model ID exactly as passed to `codex exec --model` (from resolve-model.sh)
#   --effort       Reasoning effort level as set via `-c model_reasoning_effort=...` (optional)
#   --duration-ms  Wall-clock milliseconds measured by the caller around the codex exec call.
#                  Duration is not emitted by the Codex CLI in the JSONL stream; the caller
#                  must measure it externally (e.g., bash date +%s%3N before/after the call).
#   --file         Path to captured JSONL file; if omitted, reads from stdin
#
# Output (stdout, always exits 0 — telemetry failure never aborts the SDD pipeline):
#   success: {"available":true,"model":"...","effort":"...","input":N,...}
#   failure: {"available":false,"reason":"..."}
#
# Optional fields in success output (included only when present in the event's usage object):
#   effort         — omitted if --effort was not provided
#   cached_input   — from usage.cached_input_tokens; omitted if key absent from event
#   cache_write    — from usage.cache_write_input_tokens; omitted if key absent from event
#   reasoning      — from usage.reasoning_output_tokens; omitted if key absent from event
#   total_tokens   — input + output (reasoning is a subset of output, cached_input is a
#                    subset of input — unambiguous, no double-counting)
#   duration_ms    — omitted if --duration-ms was not provided or is not a valid integer
#
# A present-but-zero value (e.g., cached_input_tokens: 0) IS included in output.
# An absent key is NOT included. This lets the display layer distinguish "not measured"
# from "measured as zero".
#
# NO cost/dollar fields are emitted. Codex CLI runs under a ChatGPT subscription;
# there is no per-call cost to report. Never invent a cost from token counts.
#
# If multiple turn.completed events appear (e.g., multi-turn exec), the LAST one is used.
# For standard `codex exec` (one task → one response) there is exactly one.

set -euo pipefail

RESOLVED_MODEL=""
EFFORT=""
STREAM_FILE=""
DURATION_MS=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --model)       RESOLVED_MODEL="$2"; shift 2 ;;
        --effort)      EFFORT="$2";         shift 2 ;;
        --file)        STREAM_FILE="$2";    shift 2 ;;
        --duration-ms) DURATION_MS="$2";    shift 2 ;;
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

if [[ -n "$STREAM_FILE" ]]; then
    STREAM_CONTENT=$(cat "$STREAM_FILE" 2>/dev/null || true)
else
    STREAM_CONTENT=$(cat 2>/dev/null || true)
fi

if [[ -z "$STREAM_CONTENT" ]]; then
    echo '{"available":false,"reason":"empty stream input"}'
    exit 0
fi

TMP=$(mktemp)
trap "rm -f '$TMP'" EXIT
printf '%s\n' "$STREAM_CONTENT" > "$TMP"

python3 - "$RESOLVED_MODEL" "$EFFORT" "$DURATION_MS" "$TMP" 2>/dev/null <<'PYEOF' || echo '{"available":false,"reason":"python3 unavailable or crashed"}'
import json, sys

model       = sys.argv[1]
effort      = sys.argv[2]   # empty string if not provided
duration_ms = sys.argv[3]   # empty string if not provided
tmp_path    = sys.argv[4]

def emit(obj):
    print(json.dumps(obj))
    sys.exit(0)

def fail(reason):
    emit({"available": False, "reason": reason})

try:
    # Keep the last turn.completed (overwrite each time — handles multi-event streams).
    # Standard codex exec produces exactly one; resume flows may produce more.
    turn_completed = None
    with open(tmp_path) as f:
        for raw in f:
            raw = raw.strip()
            if not raw:
                continue
            try:
                obj = json.loads(raw)
                if isinstance(obj, dict) and obj.get("type") == "turn.completed":
                    turn_completed = obj
            except json.JSONDecodeError:
                pass  # skip non-JSON and partial lines silently

    if turn_completed is None:
        fail("no turn.completed event found in stream")

    usage = turn_completed.get("usage")
    if not isinstance(usage, dict):
        fail("usage field missing or not an object in turn.completed event")

    input_tokens  = usage.get("input_tokens")
    output_tokens = usage.get("output_tokens")
    if input_tokens is None or output_tokens is None:
        fail("input_tokens or output_tokens missing from usage")

    result = {"available": True, "model": model}

    if effort:
        result["effort"] = effort

    result["input"]  = int(input_tokens)
    result["output"] = int(output_tokens)

    # Optional fields: include when the key exists in usage (even if value is 0).
    # Absent key → field not emitted → display layer knows "not provided by CLI".
    if "cached_input_tokens" in usage:
        result["cached_input"] = int(usage["cached_input_tokens"])

    if "cache_write_input_tokens" in usage:
        result["cache_write"] = int(usage["cache_write_input_tokens"])

    if "reasoning_output_tokens" in usage:
        result["reasoning"] = int(usage["reasoning_output_tokens"])

    # total_tokens: input + output. Reasoning tokens are a subset of output_tokens;
    # cached_input_tokens are a subset of input_tokens. No double-counting.
    result["total_tokens"] = result["input"] + result["output"]

    if duration_ms:
        try:
            result["duration_ms"] = int(duration_ms)
        except ValueError:
            pass  # non-integer provided; omit duration_ms silently

    emit(result)

except Exception as e:
    fail(str(e))
PYEOF
