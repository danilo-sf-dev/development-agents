#!/bin/bash
# SDD Kit — Phase Observability Emitter
#
# Turns EMIT_PHASE_OBSERVABILITY (commands/references/phase-transition-observability.md
# § "Enforcement") from a textual convention into a concrete, executable action. Markdown
# instructions alone ("print the Usage block", "blocking, not optional") were tested against
# a real Codex run of /sdd.reverse-eng and did not survive: no Usage block printed, not even
# the `unavailable` fallback, because nothing forced the fallback text to be written when the
# LLM had nothing captured to report and no situated reminder fired at that exact moment
# (especially inside a delegated native subagent that may never load the parent command's
# markdown at all). This script is the fix: the calling command runs it as a real Bash step
# after every phase closure; if there is nothing measurable to report, the fallback text is
# printed by this script's own deterministic logic, not by the LLM "remembering" the string.
#
# ZERO-DEPENDENCY BY DESIGN (this script itself): pure bash + grep/sed, matching
# adapters/*/tools/parse-telemetry.sh's own zero-dependency contract. This script does NOT
# reimplement telemetry extraction — it shells out to the existing, already-tested
# adapters/claude-code/tools/parse-telemetry.sh / adapters/codex/tools/parse-telemetry.sh and
# only reads their small, fixed-shape JSON output. Whatever optional interpreter tier those
# parsers use internally (python3/python/jq) is unchanged by this script and irrelevant to it.
#
# Subcommands:
#
#   phase   — emit one phase's Usage block (or the deterministic unavailable fallback) and,
#             if --state-file is given, append a JSONL record for a later `total` call.
#
#     emit-phase-observability.sh phase --harness <claude-code|codex>
#         [--model <resolved-model-id>] [--effort <level>] [--duration-ms <N>]
#         [--stream-file <path>] [--phase-label "Phase N — Name"] [--state-file <path>]
#
#     No --stream-file (or a missing/empty file) is the honest default for inline work or a
#     native in-session subagent — the caller does not need to know or declare *why* there is
#     no stream, only to omit the flag when there truly isn't one. This is what makes the
#     unavailable fallback deterministic rather than a text the LLM has to compose correctly.
#
#   total   — read an accumulated --state-file and print the Usage Total + coverage block.
#
#     emit-phase-observability.sh total --harness <claude-code|codex>
#         --state-file <path> [--expected-total <M>]
#
#     Sums only records marked available; never coerces an unavailable phase into a zero that
#     gets summed. `--expected-total` lets the caller declare M explicitly when it knows more
#     phases were attempted than were ever passed to `phase` (should not normally happen if
#     every phase closure calls `phase`, but is available so coverage is never silently wrong).
#
# State file format: JSONL, one compact JSON object per `phase` call, written with canonical
# field names regardless of harness (available, input, output, cached_input, reasoning,
# duration_ms, cost_usd) — this is what lets `total` sum across a mixed-harness state file
# (not a real scenario in this pipeline today, but it costs nothing to keep the format
# harness-agnostic). Always a local, disposable path chosen by the caller (e.g. `mktemp`) —
# this script never writes anywhere on its own, never versions runtime data, never requires
# the state file to exist ahead of time.
#
# This script never blocks the pipeline: every code path exits 0. A telemetry problem is
# never a dispatch-result problem.

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACK_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

CLAUDE_PARSER="$PACK_ROOT/adapters/claude-code/tools/parse-telemetry.sh"
CODEX_PARSER="$PACK_ROOT/adapters/codex/tools/parse-telemetry.sh"

UNAVAILABLE_TEXT="telemetry: unavailable (interactive session)"

# ---------------------------------------------------------------------------
# Tiny, fixed-shape JSON field readers — these only ever read the small, flat
# JSON objects this file's own tools produce (the parsers' output, or this
# script's own state-file records). Not a general JSON parser.
# ---------------------------------------------------------------------------

json_get_bool() {
    # $1=json $2=key
    printf '%s' "$1" | grep -oE "\"$2\"[[:space:]]*:[[:space:]]*(true|false)" | head -1 \
        | grep -oE 'true|false'
}

json_get_num() {
    # $1=json $2=key — integer or decimal
    printf '%s' "$1" | grep -oE "\"$2\"[[:space:]]*:[[:space:]]*-?[0-9]+(\.[0-9]+)?" | head -1 \
        | sed -E 's/.*:[[:space:]]*(-?[0-9]+(\.[0-9]+)?)/\1/'
}

json_get_str() {
    # $1=json $2=key
    printf '%s' "$1" | grep -oE "\"$2\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" | head -1 \
        | sed -E 's/.*:[[:space:]]*"([^"]*)"/\1/'
}

# ---------------------------------------------------------------------------
# Formatting helpers — plain integers (no thousands separator, matching the
# canonical file's placeholder examples literally), duration to one decimal
# second, cost to four decimals.
# ---------------------------------------------------------------------------

format_duration() {
    # $1 = duration_ms (integer, may be empty)
    local ms="$1"
    [[ -z "$ms" ]] && return 1
    awk -v ms="$ms" 'BEGIN { printf "%.1fs", ms/1000 }'
}

format_cost() {
    # $1 = cost_usd (decimal, may be empty)
    local cost="$1"
    [[ -z "$cost" ]] && return 1
    awk -v c="$cost" 'BEGIN { printf "$%.4f", c }'
}

print_unavailable_block() {
    echo "Usage"
    echo "$UNAVAILABLE_TEXT"
}

# ---------------------------------------------------------------------------
# phase subcommand
# ---------------------------------------------------------------------------

cmd_phase() {
    local harness="" model="" effort="" duration_ms="" stream_file="" phase_label="" state_file=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --harness)      harness="$2";      shift 2 ;;
            --model)        model="$2";        shift 2 ;;
            --effort)       effort="$2";        shift 2 ;;
            --duration-ms)  duration_ms="$2";   shift 2 ;;
            --stream-file)  stream_file="$2";   shift 2 ;;
            --phase-label)  phase_label="$2";   shift 2 ;;
            --state-file)   state_file="$2";    shift 2 ;;
            *) echo "emit-phase-observability.sh phase: unknown argument: $1" >&2; shift ;;
        esac
    done

    if [[ "$harness" != "claude-code" && "$harness" != "codex" ]]; then
        echo "emit-phase-observability.sh phase: --harness must be claude-code or codex" >&2
        if [[ -n "$phase_label" ]]; then echo "$phase_label"; echo; fi
        print_unavailable_block
        [[ -n "$state_file" ]] && printf '%s\n' '{"available":false}' >> "$state_file"
        exit 0
    fi

    # Canonical "Per-phase block" example (§ phase-transition-observability.md) shows a blank
    # line between the "Phase <N> — <name>" header and "Usage" — preserved here.
    if [[ -n "$phase_label" ]]; then echo "$phase_label"; echo; fi

    # No stream captured (inline work, or a native/in-session subagent with nothing to
    # intercept) — the caller's only job was to omit --stream-file; everything from here is
    # deterministic, no text for the LLM to compose.
    if [[ -z "$stream_file" ]] || [[ ! -s "$stream_file" ]] || [[ -z "$model" ]]; then
        print_unavailable_block
        [[ -n "$state_file" ]] && printf '%s\n' '{"available":false}' >> "$state_file"
        exit 0
    fi

    local parsed=""
    if [[ "$harness" == "codex" ]]; then
        local -a args=(--model "$model" --file "$stream_file")
        [[ -n "$effort" ]] && args+=(--effort "$effort")
        [[ -n "$duration_ms" ]] && args+=(--duration-ms "$duration_ms")
        parsed=$(bash "$CODEX_PARSER" "${args[@]}" 2>/dev/null)
    else
        parsed=$(bash "$CLAUDE_PARSER" --model "$model" --file "$stream_file" 2>/dev/null)
    fi

    local available
    available=$(json_get_bool "$parsed" "available")

    if [[ "$available" != "true" ]]; then
        print_unavailable_block
        [[ -n "$state_file" ]] && printf '%s\n' '{"available":false}' >> "$state_file"
        exit 0
    fi

    # Real, measurable dispatch — build the canonical Usage block. Field order is fixed by
    # commands/references/phase-transition-observability.md § "Field order": model, input,
    # cached input (if reported), output, reasoning (if reported), duration, cost (Claude
    # Code only, if reported, always last).
    local p_input p_output p_cached p_reasoning p_duration_ms p_cost
    p_input=$(json_get_num "$parsed" "input")
    p_output=$(json_get_num "$parsed" "output")
    p_duration_ms=$(json_get_num "$parsed" "duration_ms")

    if [[ "$harness" == "codex" ]]; then
        p_cached=$(json_get_num "$parsed" "cached_input")
        p_reasoning=$(json_get_num "$parsed" "reasoning")
        p_cost=""
    else
        p_cached=$(json_get_num "$parsed" "cache_read")
        p_reasoning=""
        p_cost=$(json_get_num "$parsed" "cost_usd")
    fi

    echo "Usage"
    if [[ "$harness" == "codex" && -n "$effort" ]]; then
        echo "model: $model (effort: $effort)"
    else
        echo "model: $model"
    fi
    echo "input: $p_input"
    [[ -n "$p_cached" ]] && echo "cached input: $p_cached"
    echo "output: $p_output"
    [[ -n "$p_reasoning" ]] && echo "reasoning: $p_reasoning"
    local fmt_duration
    if fmt_duration=$(format_duration "$p_duration_ms"); then
        echo "duration: $fmt_duration"
    fi
    if [[ "$harness" == "claude-code" && -n "$p_cost" ]]; then
        local fmt_cost
        fmt_cost=$(format_cost "$p_cost")
        echo "cost: $fmt_cost"
    fi

    if [[ -n "$state_file" ]]; then
        local rec="{\"available\":true,\"input\":$p_input,\"output\":$p_output"
        [[ -n "$p_cached" ]]    && rec+=",\"cached_input\":$p_cached"
        [[ -n "$p_reasoning" ]] && rec+=",\"reasoning\":$p_reasoning"
        [[ -n "$p_duration_ms" ]] && rec+=",\"duration_ms\":$p_duration_ms"
        [[ "$harness" == "claude-code" && -n "$p_cost" ]] && rec+=",\"cost_usd\":$p_cost"
        rec+="}"
        printf '%s\n' "$rec" >> "$state_file"
    fi

    exit 0
}

# ---------------------------------------------------------------------------
# total subcommand
# ---------------------------------------------------------------------------

cmd_total() {
    local harness="" state_file="" expected_total=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --harness)        harness="$2";        shift 2 ;;
            --state-file)     state_file="$2";      shift 2 ;;
            --expected-total) expected_total="$2";  shift 2 ;;
            *) echo "emit-phase-observability.sh total: unknown argument: $1" >&2; shift ;;
        esac
    done

    local sum_input=0 sum_output=0 sum_cached=0 sum_reasoning=0 sum_duration_ms=0
    local sum_cost="0"
    local have_cached=0 have_reasoning=0 have_cost=0
    local n_available=0 n_total=0

    if [[ -n "$state_file" && -s "$state_file" ]]; then
        while IFS= read -r line || [[ -n "$line" ]]; do
            [[ -z "$line" ]] && continue
            n_total=$((n_total + 1))
            local avail
            avail=$(json_get_bool "$line" "available")
            [[ "$avail" != "true" ]] && continue
            n_available=$((n_available + 1))

            local v
            v=$(json_get_num "$line" "input");        [[ -n "$v" ]] && sum_input=$((sum_input + v))
            v=$(json_get_num "$line" "output");       [[ -n "$v" ]] && sum_output=$((sum_output + v))
            v=$(json_get_num "$line" "cached_input"); if [[ -n "$v" ]]; then sum_cached=$((sum_cached + v)); have_cached=1; fi
            v=$(json_get_num "$line" "reasoning");    if [[ -n "$v" ]]; then sum_reasoning=$((sum_reasoning + v)); have_reasoning=1; fi
            v=$(json_get_num "$line" "duration_ms");  [[ -n "$v" ]] && sum_duration_ms=$((sum_duration_ms + v))
            v=$(json_get_num "$line" "cost_usd")
            if [[ -n "$v" ]]; then
                sum_cost=$(awk -v a="$sum_cost" -v b="$v" 'BEGIN { printf "%.10f", a+b }')
                have_cost=1
            fi
        done < "$state_file"
    fi

    local m_total="$n_total"
    [[ -n "$expected_total" ]] && m_total="$expected_total"

    echo "Usage Total"
    if [[ "$n_available" -eq 0 ]]; then
        echo "telemetry: unavailable"
        echo "coverage: 0/$m_total measured phases"
        exit 0
    fi

    echo "input: $sum_input"
    [[ "$have_cached" -eq 1 ]] && echo "cached input: $sum_cached"
    echo "output: $sum_output"
    [[ "$have_reasoning" -eq 1 ]] && echo "reasoning: $sum_reasoning"
    local fmt_duration
    if fmt_duration=$(format_duration "$sum_duration_ms"); then
        echo "duration: $fmt_duration"
    fi
    if [[ "$harness" == "claude-code" && "$have_cost" -eq 1 ]]; then
        local fmt_cost
        fmt_cost=$(format_cost "$sum_cost")
        echo "cost: $fmt_cost"
    fi
    echo "coverage: $n_available/$m_total measured phases"
    exit 0
}

# ---------------------------------------------------------------------------
# dispatch
# ---------------------------------------------------------------------------

SUBCOMMAND="${1:-}"
shift || true

case "$SUBCOMMAND" in
    phase) cmd_phase "$@" ;;
    total) cmd_total "$@" ;;
    *)
        echo "Usage: emit-phase-observability.sh <phase|total> [options]" >&2
        exit 0
        ;;
esac
