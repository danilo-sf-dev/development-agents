#!/bin/bash
# SDD Kit — Codex CLI Telemetry Parser
#
# Extracts per-dispatch telemetry from a `codex exec --json` JSONL output stream.
# Scans for the `type:"turn.completed"` event and extracts its `usage` object.
#
# ZERO-DEPENDENCY BY DESIGN: this parser does NOT require Python, jq, or any other
# external interpreter. The primary extraction mechanism uses only grep/sed — tools
# already assumed present by this pack (framework/tools/resolve-model.sh already
# depends on awk/grep unconditionally). python3/python/jq are tried ONLY as optional
# fallbacks, and only if the portable mechanism fails to find usable data — never as
# a requirement. This matters because:
#   - the framework must stay zero-install;
#   - a corporate machine may have no Python, no jq, or have them blocked;
#   - telemetry is observability, never a functional requirement — its absence must
#     never affect /sdd.* commands, Codex CLI, or the SDD pipeline in any way.
#
# Capability-detection order (first success wins, nothing here is a hard requirement):
#   1. portable   — grep/sed text extraction (always attempted first, no external tool)
#   2. python3    — only if `command -v python3` succeeds AND tier 1 failed
#   3. python     — only if `command -v python` succeeds AND tiers 1-2 failed
#   4. jq         — only if `command -v jq` succeeds AND tiers 1-3 failed
#   5. unavailable — none of the above produced usable input/output token counts
#
# Primary source: `codex exec --json` JSONL output — the stable public API.
# Fallback (rollout-*.jsonl in ~/.codex/sessions): NOT used by this parser.
# Those files are implementation internals that can change without notice.
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
# from "measured as zero". This convention holds across all four extraction tiers.
#
# NO cost/dollar fields are emitted, ever. Codex CLI runs under a ChatGPT subscription;
# there is no per-call cost to report. Never invent a cost from token counts.
#
# If multiple turn.completed events appear (e.g., multi-turn exec), the LAST one is used,
# across every tier — consistent "last wins" semantics regardless of extraction method.

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

# ---------------------------------------------------------------------------
# Tier 1: portable extraction — grep/sed only, no external interpreter.
# Relies on codex exec --json emitting one JSON object per line (JSONL). Each
# usage field is a flat integer, so a targeted regex per field is reliable
# without needing a real JSON parser.
# ---------------------------------------------------------------------------

# Sets EX_INPUT/EX_OUTPUT/EX_CACHED_INPUT/EX_CACHE_WRITE/EX_REASONING on success.
# Returns 1 (no side effects on the EX_* vars) if no usable turn.completed line found.
extract_num_field() {
    local line="$1" key="$2"
    printf '%s\n' "$line" \
        | grep -oE "\"$key\"[[:space:]]*:[[:space:]]*-?[0-9]+" \
        | head -1 \
        | sed -E 's/.*:[[:space:]]*(-?[0-9]+)/\1/'
}

portable_extract() {
    local file="$1"
    local line
    line=$(grep -E '"type"[[:space:]]*:[[:space:]]*"turn\.completed"' "$file" 2>/dev/null | tail -1)
    [[ -z "$line" ]] && return 1

    local input output
    input=$(extract_num_field "$line" "input_tokens")
    output=$(extract_num_field "$line" "output_tokens")
    [[ -z "$input" || -z "$output" ]] && return 1

    EX_INPUT="$input"
    EX_OUTPUT="$output"
    EX_CACHED_INPUT=$(extract_num_field "$line" "cached_input_tokens")
    EX_CACHE_WRITE=$(extract_num_field "$line" "cache_write_input_tokens")
    EX_REASONING=$(extract_num_field "$line" "reasoning_output_tokens")
    return 0
}

# ---------------------------------------------------------------------------
# Tier 2/3: python3/python fallback — OPTIONAL, only tried if tier 1 fails
# AND the interpreter happens to be present. Never a requirement.
# Handles cases tier 1's line-oriented regex can't (e.g. pretty-printed /
# multi-line JSON, unusual whitespace).
# ---------------------------------------------------------------------------

python_extract() {
    local pybin="$1" file="$2"
    local out
    out=$("$pybin" - "$file" <<'PYEOF' 2>/dev/null
import json, sys
path = sys.argv[1]
turn = None
with open(path) as f:
    for raw in f:
        raw = raw.strip()
        if not raw:
            continue
        try:
            obj = json.loads(raw)
        except ValueError:
            continue
        if isinstance(obj, dict) and obj.get("type") == "turn.completed":
            turn = obj
if turn is None:
    sys.exit(1)
usage = turn.get("usage")
if not isinstance(usage, dict):
    sys.exit(1)
inp = usage.get("input_tokens")
out = usage.get("output_tokens")
if inp is None or out is None:
    sys.exit(1)
def line(key, val):
    print("{}={}".format(key, "" if val is None else val))
line("input", inp)
line("output", out)
line("cached_input", usage.get("cached_input_tokens"))
line("cache_write", usage.get("cache_write_input_tokens"))
line("reasoning", usage.get("reasoning_output_tokens"))
PYEOF
    ) || return 1

    [[ -z "$out" ]] && return 1

    # Parse the "key=value" lines with pure bash (no sed) — this tier must stay
    # usable even in a PATH stripped down to just python3/python + core utils.
    EX_INPUT="" EX_OUTPUT="" EX_CACHED_INPUT="" EX_CACHE_WRITE="" EX_REASONING=""
    local ln
    while IFS= read -r ln || [[ -n "$ln" ]]; do
        case "$ln" in
            input=*)        EX_INPUT="${ln#input=}" ;;
            output=*)       EX_OUTPUT="${ln#output=}" ;;
            cached_input=*) EX_CACHED_INPUT="${ln#cached_input=}" ;;
            cache_write=*)  EX_CACHE_WRITE="${ln#cache_write=}" ;;
            reasoning=*)    EX_REASONING="${ln#reasoning=}" ;;
        esac
    done <<< "$out"

    [[ -z "$EX_INPUT" || -z "$EX_OUTPUT" ]] && return 1
    return 0
}

# ---------------------------------------------------------------------------
# Tier 4: jq fallback — OPTIONAL, tried only if tiers 1-3 all failed AND jq
# happens to be present. Never a requirement. Processes line-by-line so a
# malformed/non-JSON line elsewhere in the stream cannot abort extraction.
# ---------------------------------------------------------------------------

jq_extract() {
    local file="$1"
    local last=""
    while IFS= read -r ln || [[ -n "$ln" ]]; do
        [[ -z "$ln" ]] && continue
        if printf '%s' "$ln" | jq -e 'select(.type=="turn.completed")' >/dev/null 2>&1; then
            last="$ln"
        fi
    done < "$file"
    [[ -z "$last" ]] && return 1

    local input output
    input=$(printf '%s' "$last"  | jq -r '.usage.input_tokens  // empty' 2>/dev/null)
    output=$(printf '%s' "$last" | jq -r '.usage.output_tokens // empty' 2>/dev/null)
    [[ -z "$input" || -z "$output" ]] && return 1

    EX_INPUT="$input"
    EX_OUTPUT="$output"
    EX_CACHED_INPUT=$(printf '%s' "$last" | jq -r '.usage.cached_input_tokens      // empty' 2>/dev/null)
    EX_CACHE_WRITE=$(printf '%s' "$last"  | jq -r '.usage.cache_write_input_tokens // empty' 2>/dev/null)
    EX_REASONING=$(printf '%s' "$last"    | jq -r '.usage.reasoning_output_tokens  // empty' 2>/dev/null)
    return 0
}

# ---------------------------------------------------------------------------
# Run the capability-detection cascade
# ---------------------------------------------------------------------------

EX_INPUT="" EX_OUTPUT="" EX_CACHED_INPUT="" EX_CACHE_WRITE="" EX_REASONING=""
METHOD=""

if portable_extract "$TMP"; then
    METHOD="portable"
elif command -v python3 >/dev/null 2>&1 && python_extract python3 "$TMP"; then
    METHOD="python3"
elif command -v python >/dev/null 2>&1 && python_extract python "$TMP"; then
    METHOD="python"
elif command -v jq >/dev/null 2>&1 && jq_extract "$TMP"; then
    METHOD="jq"
else
    echo '{"available":false,"reason":"no turn.completed usage data found (tried: portable text extraction, python3, python, jq)"}'
    exit 0
fi

# Defensive validation — never let unexpected data crash the arithmetic below,
# regardless of which tier produced it.
if ! [[ "$EX_INPUT" =~ ^-?[0-9]+$ ]] || ! [[ "$EX_OUTPUT" =~ ^-?[0-9]+$ ]]; then
    echo "{\"available\":false,\"reason\":\"non-numeric token value from $METHOD extraction\"}"
    exit 0
fi

# ---------------------------------------------------------------------------
# Build output JSON manually (no json-encoding library needed for this small,
# fully-controlled shape). Fixed field order: available, model, effort, input,
# output, cached_input?, cache_write?, reasoning?, total_tokens, duration_ms?
# ---------------------------------------------------------------------------

json_escape() {
    # Pure bash parameter expansion — no sed. Keeps this final output-building
    # step working even in a PATH with no sed at all (sed is only needed by
    # the portable *extraction* tier above, not by output construction).
    local s="$1"
    s="${s//\\/\\\\}"
    s="${s//\"/\\\"}"
    printf '%s' "$s"
}

TOTAL_TOKENS=$(( EX_INPUT + EX_OUTPUT ))

OUT="{\"available\":true,\"model\":\"$(json_escape "$RESOLVED_MODEL")\""
[[ -n "$EFFORT" ]] && OUT+=",\"effort\":\"$(json_escape "$EFFORT")\""
OUT+=",\"input\":$EX_INPUT,\"output\":$EX_OUTPUT"
[[ -n "$EX_CACHED_INPUT" ]] && OUT+=",\"cached_input\":$EX_CACHED_INPUT"
[[ -n "$EX_CACHE_WRITE"  ]] && OUT+=",\"cache_write\":$EX_CACHE_WRITE"
[[ -n "$EX_REASONING"    ]] && OUT+=",\"reasoning\":$EX_REASONING"
OUT+=",\"total_tokens\":$TOTAL_TOKENS"
if [[ -n "$DURATION_MS" ]] && [[ "$DURATION_MS" =~ ^[0-9]+$ ]]; then
    OUT+=",\"duration_ms\":$DURATION_MS"
fi
OUT+="}"

echo "$OUT"
exit 0
