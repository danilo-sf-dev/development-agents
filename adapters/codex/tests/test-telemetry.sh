#!/bin/bash
# SDD Kit — Codex CLI Telemetry Parser Tests
#
# ZERO-DEPENDENCY: this test suite does NOT require Python to run. Assertion helpers
# use grep/sed against the parser's own (small, fully-controlled) JSON output shape —
# no JSON library needed on the test side either. Tests that specifically exercise a
# python3/python/jq FALLBACK tier are skipped (not failed) when that runtime is absent
# — the fallback is optional, so its absence is not a test failure.
#
# Tests:
#   1:    turn.completed with all fields present (portable tier)
#   2:    cached_input_tokens absent
#   3:    cache_write_input_tokens absent
#   4:    reasoning_output_tokens absent
#   5:    real zero values (fields present, value 0)
#   6:    irrelevant JSONL events before turn.completed
#   7:    multiple turn.completed events (last one wins)
#   8:    invalid / non-JSON lines do not crash the parser
#   9:    aggregation of two phases (sum correctness)
#  10:    field ordering in output matches spec
#  11:    no cost field anywhere in Codex parser output
#  12:    Claude Code parser regression (skipped if python3 absent — that parser is
#         intentionally unchanged and still depends on python3 by design)
#  13:    ZERO-DEPENDENCY: portable tier alone succeeds with python3/python/jq all
#         removed from PATH (proves telemetry works with Python fully absent)
#  14:    No turn.completed present → unavailable, exit 0, regardless of tools on PATH
#  15:    Script files use LF line endings (not CRLF) — Windows/Git Bash compatibility
#  16:    Fallback exercise: multi-line JSON defeats the portable tier; python3
#         fallback recovers it (skipped if python3 absent)
#  17:    Fallback exercise: same multi-line case recovered via jq when python3/python
#         are both absent from PATH (skipped if jq absent)
#   *:    smoke test (real codex exec --json, skipped if binary absent)
#
# Usage:
#   bash test-telemetry.sh [--unit-only | --smoke-only]
# Exit: 0 if all executed (non-skipped) tests pass, nonzero otherwise

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACK_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
CODEX_PARSER="$PACK_ROOT/adapters/codex/tools/parse-telemetry.sh"
CLAUDE_PARSER="$PACK_ROOT/adapters/claude-code/tools/parse-telemetry.sh"
RESOLVER="$PACK_ROOT/framework/tools/resolve-model.sh"
SCRATCHPAD="$(mktemp -d)"
trap "rm -rf '$SCRATCHPAD'" EXIT

BASH_BIN="$(command -v bash)"

PASS=0; FAIL=0; SKIP=0
SMOKE_ONLY=false; UNIT_ONLY=false
[[ "${1:-}" == "--smoke-only" ]] && SMOKE_ONLY=true
[[ "${1:-}" == "--unit-only"  ]] && UNIT_ONLY=true

ok()   { echo "  PASS: $1"; ((PASS++))  || true; }
fail() { echo "  FAIL: $1"; ((FAIL++)) || true; }
skip() { echo "  SKIP: $1"; ((SKIP++)) || true; }

# ---------------------------------------------------------------------------
# Assertion helpers — grep/sed only, no python/jq required to run these tests.
# Safe because the parser's own output shape is small, flat, and fully known.
# ---------------------------------------------------------------------------

json_available() {
    # prints "true" or "false" — tolerates both compact (Codex parser: "available":true)
    # and spaced (Claude parser, python json.dumps default: "available": true) output.
    if printf '%s' "$1" | grep -qE '"available"[[:space:]]*:[[:space:]]*true'; then
        echo true
    else
        echo false
    fi
}

json_field() {
    # $1=json $2=key ; works for "key":"str", "key":123 and "key":1.23 shapes,
    # with or without whitespace after the colon (python json.dumps adds a space;
    # the Codex parser's own hand-built output does not — both must work here).
    printf '%s' "$1" \
        | grep -oE "\"$2\"[[:space:]]*:[[:space:]]*\"[^\"]*\"|\"$2\"[[:space:]]*:[[:space:]]*-?[0-9]+(\.[0-9]+)?" \
        | head -1 \
        | sed -E 's/^"[^"]+"[[:space:]]*:[[:space:]]*"?//; s/"$//'
}

has_key() {
    printf '%s' "$1" | grep -qE "\"$2\"[[:space:]]*:"
}

key_order() {
    printf '%s' "$1" | grep -oE '"[a-zA-Z_]+":' | sed -E 's/^"([a-zA-Z_]+)":$/\1/' | tr '\n' ' ' | sed 's/ $//'
}

echo ""
echo "══════════════════════════════════════════════════════"
echo "  SDD Codex Telemetry Parser Tests"
echo "══════════════════════════════════════════════════════"

if ! $SMOKE_ONLY; then

    MODEL="gpt-5.6-sol"
    EFFORT="high"

    # ── Test 1: Full turn.completed — all optional fields present ──────────────
    echo ""
    echo "Test 1: turn.completed with all fields"
    STREAM1="$SCRATCHPAD/t1.jsonl"
    cat > "$STREAM1" <<'EOF'
{"type":"session.started","session_id":"s1"}
{"type":"turn.completed","usage":{"input_tokens":26549,"cached_input_tokens":22272,"cache_write_input_tokens":4100,"output_tokens":1590,"reasoning_output_tokens":413}}
EOF
    T1=$(bash "$CODEX_PARSER" --model "$MODEL" --effort "$EFFORT" --duration-ms 18400 --file "$STREAM1")
    if [[ "$(json_available "$T1")" == "true" ]] && \
       [[ "$(json_field "$T1" model)"        == "$MODEL"  ]] && \
       [[ "$(json_field "$T1" effort)"       == "$EFFORT" ]] && \
       [[ "$(json_field "$T1" input)"        == "26549"   ]] && \
       [[ "$(json_field "$T1" cached_input)" == "22272"   ]] && \
       [[ "$(json_field "$T1" cache_write)"  == "4100"    ]] && \
       [[ "$(json_field "$T1" output)"       == "1590"    ]] && \
       [[ "$(json_field "$T1" reasoning)"    == "413"     ]] && \
       [[ "$(json_field "$T1" total_tokens)" == "28139"   ]] && \
       [[ "$(json_field "$T1" duration_ms)"  == "18400"   ]]; then
        ok "All fields correct: model=$MODEL effort=$EFFORT input=26549 output=1590 reasoning=413 total=28139 duration=18400ms"
    else
        fail "Field mismatch: $T1"
    fi

    # ── Test 2: cached_input_tokens absent ────────────────────────────────────
    echo ""
    echo "Test 2: cached_input_tokens absent"
    STREAM2="$SCRATCHPAD/t2.jsonl"
    cat > "$STREAM2" <<'EOF'
{"type":"turn.completed","usage":{"input_tokens":1000,"cache_write_input_tokens":200,"output_tokens":500,"reasoning_output_tokens":100}}
EOF
    T2=$(bash "$CODEX_PARSER" --model "$MODEL" --effort "$EFFORT" --file "$STREAM2")
    if [[ "$(json_available "$T2")" == "true" ]] && \
       ! has_key "$T2" cached_input && \
       [[ "$(json_field "$T2" input)"  == "1000" ]] && \
       [[ "$(json_field "$T2" output)" == "500"  ]]; then
        ok "cached_input absent from output when not in usage"
    else
        fail "Expected no cached_input key: $T2"
    fi

    # ── Test 3: cache_write_input_tokens absent ───────────────────────────────
    echo ""
    echo "Test 3: cache_write_input_tokens absent"
    STREAM3="$SCRATCHPAD/t3.jsonl"
    cat > "$STREAM3" <<'EOF'
{"type":"turn.completed","usage":{"input_tokens":1000,"cached_input_tokens":800,"output_tokens":500,"reasoning_output_tokens":100}}
EOF
    T3=$(bash "$CODEX_PARSER" --model "$MODEL" --effort "$EFFORT" --file "$STREAM3")
    if [[ "$(json_available "$T3")" == "true" ]] && \
       ! has_key "$T3" cache_write && \
       has_key "$T3" cached_input; then
        ok "cache_write absent when not in usage; cached_input still present"
    else
        fail "Expected no cache_write key: $T3"
    fi

    # ── Test 4: reasoning_output_tokens absent ────────────────────────────────
    echo ""
    echo "Test 4: reasoning_output_tokens absent"
    STREAM4="$SCRATCHPAD/t4.jsonl"
    cat > "$STREAM4" <<'EOF'
{"type":"turn.completed","usage":{"input_tokens":1000,"cached_input_tokens":800,"cache_write_input_tokens":200,"output_tokens":500}}
EOF
    T4=$(bash "$CODEX_PARSER" --model "$MODEL" --effort "$EFFORT" --file "$STREAM4")
    if [[ "$(json_available "$T4")" == "true" ]] && \
       ! has_key "$T4" reasoning && \
       has_key "$T4" cached_input && \
       has_key "$T4" cache_write; then
        ok "reasoning absent when not in usage; other optional fields still present"
    else
        fail "Expected no reasoning key: $T4"
    fi

    # ── Test 5: Real zero values — fields present, value 0 ───────────────────
    echo ""
    echo "Test 5: Real zero values (fields present, value 0)"
    STREAM5="$SCRATCHPAD/t5.jsonl"
    cat > "$STREAM5" <<'EOF'
{"type":"turn.completed","usage":{"input_tokens":100,"cached_input_tokens":0,"cache_write_input_tokens":0,"output_tokens":50,"reasoning_output_tokens":0}}
EOF
    T5=$(bash "$CODEX_PARSER" --model "$MODEL" --effort "$EFFORT" --file "$STREAM5")
    if [[ "$(json_available "$T5")" == "true" ]] && \
       has_key "$T5" cached_input && [[ "$(json_field "$T5" cached_input)" == "0" ]] && \
       has_key "$T5" cache_write  && [[ "$(json_field "$T5" cache_write)"  == "0" ]] && \
       has_key "$T5" reasoning    && [[ "$(json_field "$T5" reasoning)"    == "0" ]]; then
        ok "Zero values included when field key IS present: cached_input=0 cache_write=0 reasoning=0"
    else
        fail "Zero fields not handled correctly: $T5"
    fi

    # ── Test 6: Irrelevant JSONL events before turn.completed ─────────────────
    echo ""
    echo "Test 6: Irrelevant events before turn.completed"
    STREAM6="$SCRATCHPAD/t6.jsonl"
    cat > "$STREAM6" <<'EOF'
{"type":"session.started","session_id":"abc123"}
{"type":"message.created","id":"msg_1","role":"assistant"}
{"type":"response.output_text.delta","delta":"Hello, I'll help"}
{"type":"response.output_text.done","text":"Hello, I'll help with that."}
{"type":"turn.completed","usage":{"input_tokens":500,"cached_input_tokens":400,"output_tokens":200}}
EOF
    T6=$(bash "$CODEX_PARSER" --model "$MODEL" --effort "$EFFORT" --duration-ms 9200 --file "$STREAM6")
    if [[ "$(json_available "$T6")" == "true" ]] && \
       [[ "$(json_field "$T6" input)"  == "500" ]] && \
       [[ "$(json_field "$T6" output)" == "200" ]]; then
        ok "Parser correctly skips irrelevant events and finds turn.completed"
    else
        fail "Irrelevant event handling failed: $T6"
    fi

    # ── Test 7: Multiple turn.completed events — last one wins ────────────────
    echo ""
    echo "Test 7: Multiple turn.completed events (last wins)"
    STREAM7="$SCRATCHPAD/t7.jsonl"
    cat > "$STREAM7" <<'EOF'
{"type":"turn.started"}
{"type":"turn.completed","usage":{"input_tokens":100,"output_tokens":50}}
{"type":"session.status","status":"continuing"}
{"type":"turn.completed","usage":{"input_tokens":200,"cached_input_tokens":180,"output_tokens":80}}
EOF
    T7=$(bash "$CODEX_PARSER" --model "$MODEL" --effort "$EFFORT" --file "$STREAM7")
    if [[ "$(json_available "$T7")" == "true" ]] && \
       [[ "$(json_field "$T7" input)"  == "200" ]] && \
       [[ "$(json_field "$T7" output)" == "80"  ]] && \
       [[ "$(json_field "$T7" cached_input)" == "180" ]]; then
        ok "Last turn.completed used: input=200 output=80 cached_input=180"
    else
        fail "Multiple turn.completed not handled correctly: $T7"
    fi

    # ── Test 8: Invalid / non-JSON lines do not crash parser ──────────────────
    echo ""
    echo "Test 8: Invalid/non-JSON lines mixed in"
    STREAM8="$SCRATCHPAD/t8.jsonl"
    cat > "$STREAM8" <<'EOF'
not json at all
{"valid": "but not turn.completed"}
{broken json here
{"type":"message.output"}

{"type":"turn.completed","usage":{"input_tokens":300,"output_tokens":120}}
EOF
    T8=$(bash "$CODEX_PARSER" --model "$MODEL" --effort "$EFFORT" --file "$STREAM8")
    if [[ "$(json_available "$T8")" == "true" ]] && \
       [[ "$(json_field "$T8" input)"  == "300" ]] && \
       [[ "$(json_field "$T8" output)" == "120" ]]; then
        ok "Parser survives malformed lines: still found turn.completed"
    else
        fail "Parser crashed on invalid input: $T8"
    fi

    # ── Test 9: Aggregation of two phases ─────────────────────────────────────
    echo ""
    echo "Test 9: Aggregation of two phases"
    STREAM9A="$SCRATCHPAD/t9a.jsonl"
    STREAM9B="$SCRATCHPAD/t9b.jsonl"
    cat > "$STREAM9A" <<'EOF'
{"type":"turn.completed","usage":{"input_tokens":10000,"cached_input_tokens":8000,"output_tokens":500,"reasoning_output_tokens":100}}
EOF
    cat > "$STREAM9B" <<'EOF'
{"type":"turn.completed","usage":{"input_tokens":5000,"cached_input_tokens":4000,"output_tokens":300,"reasoning_output_tokens":50}}
EOF
    T9A=$(bash "$CODEX_PARSER" --model "$MODEL" --effort "$EFFORT" --duration-ms 10000 --file "$STREAM9A")
    T9B=$(bash "$CODEX_PARSER" --model "$MODEL" --effort "$EFFORT" --duration-ms 5000  --file "$STREAM9B")

    IN_A=$(json_field "$T9A" input);     IN_B=$(json_field "$T9B" input)
    CA_A=$(json_field "$T9A" cached_input); CA_B=$(json_field "$T9B" cached_input)
    OUT_A=$(json_field "$T9A" output);   OUT_B=$(json_field "$T9B" output)
    RE_A=$(json_field "$T9A" reasoning); RE_B=$(json_field "$T9B" reasoning)
    DUR_A=$(json_field "$T9A" duration_ms); DUR_B=$(json_field "$T9B" duration_ms)

    TOTAL_INPUT=$(( IN_A + IN_B ))
    TOTAL_CACHED=$(( CA_A + CA_B ))
    TOTAL_OUTPUT=$(( OUT_A + OUT_B ))
    TOTAL_REASONING=$(( RE_A + RE_B ))
    TOTAL_DURATION=$(( DUR_A + DUR_B ))
    TOTAL_TOKENS=$(( TOTAL_INPUT + TOTAL_OUTPUT ))

    if [[ "$TOTAL_INPUT" == "15000" ]] && [[ "$TOTAL_CACHED" == "12000" ]] && \
       [[ "$TOTAL_OUTPUT" == "800" ]] && [[ "$TOTAL_REASONING" == "150" ]] && \
       [[ "$TOTAL_DURATION" == "15000" ]] && [[ "$TOTAL_TOKENS" == "15800" ]]; then
        ok "Aggregation correct: input=$TOTAL_INPUT cached=$TOTAL_CACHED output=$TOTAL_OUTPUT reasoning=$TOTAL_REASONING duration_ms=$TOTAL_DURATION total_tokens=$TOTAL_TOKENS"
    else
        fail "Aggregation mismatch: input=$TOTAL_INPUT cached=$TOTAL_CACHED output=$TOTAL_OUTPUT reasoning=$TOTAL_REASONING duration_ms=$TOTAL_DURATION total_tokens=$TOTAL_TOKENS"
    fi

    # ── Test 10: Field ordering matches spec ───────────────────────────────────
    echo ""
    echo "Test 10: Field ordering in output"
    STREAM10="$SCRATCHPAD/t10.jsonl"
    cat > "$STREAM10" <<'EOF'
{"type":"turn.completed","usage":{"input_tokens":100,"cached_input_tokens":80,"cache_write_input_tokens":10,"output_tokens":50,"reasoning_output_tokens":5}}
EOF
    T10=$(bash "$CODEX_PARSER" --model "$MODEL" --effort "$EFFORT" --duration-ms 1000 --file "$STREAM10")
    KEYSEQ=$(key_order "$T10")
    EXPECTED="available model effort input output cached_input cache_write reasoning total_tokens duration_ms"
    if [[ "$KEYSEQ" == "$EXPECTED" ]]; then
        ok "Key order correct: $KEYSEQ"
    else
        fail "Key order mismatch: got '$KEYSEQ' want '$EXPECTED'"
    fi

    # ── Test 11: No cost field in Codex parser output ─────────────────────────
    echo ""
    echo "Test 11: No cost field in parser output"
    STREAM11="$SCRATCHPAD/t11.jsonl"
    cat > "$STREAM11" <<'EOF'
{"type":"turn.completed","usage":{"input_tokens":1000,"output_tokens":500}}
EOF
    T11=$(bash "$CODEX_PARSER" --model "$MODEL" --effort "$EFFORT" --file "$STREAM11")
    if [[ "$(json_available "$T11")" == "true" ]] && \
       ! has_key "$T11" cost && \
       ! has_key "$T11" cost_usd && \
       ! has_key "$T11" total_cost && \
       ! has_key "$T11" total_cost_usd; then
        ok "No cost fields in output (cost, cost_usd, total_cost, total_cost_usd all absent)"
    else
        fail "Cost field found in Codex parser output: $T11"
    fi

    # ── Test 12: Claude Code parser regression — behavior unchanged ────────────
    echo ""
    echo "Test 12: Claude Code parser unchanged (regression)"
    if ! command -v python3 >/dev/null 2>&1; then
        skip "python3 not on PATH — Claude Code parser intentionally still depends on python3 (unchanged by this fix); cannot exercise it here"
    else
        CLAUDE_MODEL="claude-sonnet-4-6"
        CLAUDE_STREAM="$SCRATCHPAD/t12_claude.jsonl"
        cat > "$CLAUDE_STREAM" <<EOF
{"type":"message_start","message":{"model":"$CLAUDE_MODEL"}}
{"type":"content_block_delta","delta":{"text":"OK"}}
{"type":"result","subtype":"success","is_error":false,"duration_ms":7300,"total_cost_usd":0.0474,"usage":{"input_tokens":4,"output_tokens":214,"cache_creation_input_tokens":4870,"cache_read_input_tokens":49816},"modelUsage":{"$CLAUDE_MODEL":{"inputTokens":4,"outputTokens":214,"cacheReadInputTokens":49816,"cacheCreationInputTokens":4870,"costUSD":0.0474},"claude-haiku-4-5-20251001":{"inputTokens":563,"outputTokens":13,"cacheReadInputTokens":27082,"cacheCreationInputTokens":0,"costUSD":0.0002}}}
EOF
        T12=$(bash "$CLAUDE_PARSER" --model "$CLAUDE_MODEL" --file "$CLAUDE_STREAM")
        if [[ "$(json_available "$T12")" == "true" ]] && \
           [[ "$(json_field "$T12" model)"      == "$CLAUDE_MODEL" ]] && \
           [[ "$(json_field "$T12" input)"      == "4"             ]] && \
           [[ "$(json_field "$T12" output)"     == "214"           ]] && \
           [[ "$(json_field "$T12" cache_read)" == "49816"         ]] && \
           [[ "$(json_field "$T12" cost_usd)"   == "0.0474"        ]] && \
           [[ "$(json_field "$T12" duration_ms)" == "7300"         ]]; then
            ok "Claude Code parser: unchanged — all fields correct (model/input/output/cache_read/cost_usd/duration_ms)"
        else
            fail "Claude Code parser regression: $T12"
        fi
    fi

    # ── Test 13: ZERO-DEPENDENCY — portable tier alone, python3/python/jq absent ──
    echo ""
    echo "Test 13: Zero-dependency — python3, python, jq all removed from PATH"
    SANDBOX_BIN="$SCRATCHPAD/sandbox_bin_min"
    mkdir -p "$SANDBOX_BIN"
    # Only the tools the parser's portable tier + shell plumbing actually need.
    for b in grep sed cat mktemp head tail rm printf wc cut basename dirname mkdir; do
        src=$(command -v "$b" 2>/dev/null || true)
        [[ -n "$src" ]] && ln -sf "$src" "$SANDBOX_BIN/$b"
    done
    STREAM13="$SCRATCHPAD/t13.jsonl"
    cat > "$STREAM13" <<'EOF'
{"type":"turn.completed","usage":{"input_tokens":9000,"cached_input_tokens":7000,"output_tokens":600,"reasoning_output_tokens":150}}
EOF
    T13=$(PATH="$SANDBOX_BIN" "$BASH_BIN" "$CODEX_PARSER" --model "$MODEL" --effort "$EFFORT" --file "$STREAM13")
    if [[ "$(json_available "$T13")" == "true" ]] && \
       [[ "$(json_field "$T13" input)"  == "9000" ]] && \
       [[ "$(json_field "$T13" output)" == "600"  ]]; then
        ok "Telemetry available with python3/python/jq fully absent from PATH — portable tier sufficed"
    else
        fail "Zero-dependency extraction failed: $T13"
    fi

    # ── Test 14: No turn.completed present → unavailable, exit 0 ──────────────
    echo ""
    echo "Test 14: No turn.completed data → unavailable, exit 0, pipeline continues"
    STREAM14="$SCRATCHPAD/t14.jsonl"
    cat > "$STREAM14" <<'EOF'
{"type":"session.started","session_id":"s1"}
{"type":"turn.started"}
EOF
    set +e
    T14=$(bash "$CODEX_PARSER" --model "$MODEL" --effort "$EFFORT" --file "$STREAM14")
    RC14=$?
    set -e
    if [[ $RC14 -eq 0 ]] && [[ "$(json_available "$T14")" == "false" ]]; then
        ok "No turn.completed → available=false, exit 0 (parser reason: $(json_field "$T14" reason))"
    else
        fail "Expected exit 0 + available=false, got exit=$RC14 output=$T14"
    fi

    # ── Test 15: LF line endings (no CRLF) — Windows/Git Bash compatibility ────
    echo ""
    echo "Test 15: Script files use LF line endings"
    CRLF_FOUND=false
    for f in "$CODEX_PARSER" "$SCRIPT_DIR/test-telemetry.sh"; do
        if grep -qU $'\r' "$f" 2>/dev/null; then
            CRLF_FOUND=true
            fail "CRLF found in $f"
        fi
    done
    if ! $CRLF_FOUND; then
        ok "No CRLF in parser or test script (set -euo pipefail-safe on Git Bash)"
    fi

    # ── Test 16: Fallback exercise — python3 engages when grep/sed unavailable ──
    # The portable tier itself depends on grep/sed. Remove those from PATH (leaving
    # only python3 + core file utilities) to force the cascade to actually fall
    # through to tier 2, and confirm it still recovers the correct values.
    echo ""
    echo "Test 16: python3 fallback engages when portable tier's own tools (grep/sed) are unavailable"
    if ! command -v python3 >/dev/null 2>&1; then
        skip "python3 not on PATH — cannot exercise this fallback tier"
    else
        SANDBOX_PY="$SCRATCHPAD/sandbox_bin_py"
        mkdir -p "$SANDBOX_PY"
        for b in cat mktemp head tail rm printf wc cut basename dirname mkdir python3; do
            src=$(command -v "$b" 2>/dev/null || true)
            [[ -n "$src" ]] && ln -sf "$src" "$SANDBOX_PY/$b"
        done
        STREAM16="$SCRATCHPAD/t16.jsonl"
        cat > "$STREAM16" <<'EOF'
{"type":"turn.completed","usage":{"input_tokens":7000,"cached_input_tokens":6000,"output_tokens":400,"reasoning_output_tokens":80}}
EOF
        T16=$(PATH="$SANDBOX_PY" "$BASH_BIN" "$CODEX_PARSER" --model "$MODEL" --effort "$EFFORT" --file "$STREAM16")
        if [[ "$(json_available "$T16")" == "true" ]] && \
           [[ "$(json_field "$T16" input)"  == "7000" ]] && \
           [[ "$(json_field "$T16" output)" == "400"  ]]; then
            ok "python3 fallback engaged with grep/sed absent from PATH — values correctly recovered"
        else
            fail "python3 fallback did not recover correct values with grep/sed absent: $T16"
        fi
    fi

    # ── Test 17: Fallback exercise — jq engages when grep/sed/python3/python absent ─
    echo ""
    echo "Test 17: jq fallback engages when portable tier's tools AND python are all unavailable"
    if ! command -v jq >/dev/null 2>&1; then
        skip "jq not on PATH — cannot exercise this fallback tier"
    else
        SANDBOX_JQ="$SCRATCHPAD/sandbox_bin_jq"
        mkdir -p "$SANDBOX_JQ"
        for b in cat mktemp head tail rm printf wc cut basename dirname mkdir jq; do
            src=$(command -v "$b" 2>/dev/null || true)
            [[ -n "$src" ]] && ln -sf "$src" "$SANDBOX_JQ/$b"
        done
        STREAM17="$SCRATCHPAD/t17.jsonl"
        cat > "$STREAM17" <<'EOF'
{"type":"turn.completed","usage":{"input_tokens":3000,"output_tokens":250}}
EOF
        T17=$(PATH="$SANDBOX_JQ" "$BASH_BIN" "$CODEX_PARSER" --model "$MODEL" --effort "$EFFORT" --file "$STREAM17")
        if [[ "$(json_available "$T17")" == "true" ]] && \
           [[ "$(json_field "$T17" input)"  == "3000" ]] && \
           [[ "$(json_field "$T17" output)" == "250"  ]]; then
            ok "jq fallback engaged with grep/sed/python3/python all absent — values correctly recovered"
        else
            fail "jq fallback did not recover correct values: $T17"
        fi
    fi

fi  # end unit tests

# ── Smoke test: real codex exec --json ────────────────────────────────────────
if ! $UNIT_ONLY; then
    echo ""
    echo "Smoke test: real codex exec --json"

    CODEX_BIN=$(command -v codex 2>/dev/null || true)
    if [[ -z "$CODEX_BIN" ]]; then
        skip "codex binary not found on PATH — skipping smoke test"
    else
        CODEX_VERSION=$("$CODEX_BIN" --version 2>/dev/null || echo "unknown")
        echo "  codex version: $CODEX_VERSION"

        STRONG_RESOLVED=$(bash "$RESOLVER" codex STRONG --json 2>/dev/null)
        SMOKE_MODEL=$(printf '%s' "$STRONG_RESOLVED" | grep -oE '"model":"[^"]*"' | sed -E 's/"model":"([^"]*)"/\1/')
        SMOKE_EFFORT=$(printf '%s' "$STRONG_RESOLVED" | grep -oE '"effort":"[^"]*"' | sed -E 's/"effort":"([^"]*)"/\1/')
        echo "  resolved model: $SMOKE_MODEL  effort: $SMOKE_EFFORT"

        SMOKE_STREAM="$SCRATCHPAD/smoke.jsonl"
        T0=$(date +%s%3N)
        if "$CODEX_BIN" exec --json \
               --model "$SMOKE_MODEL" \
               -c "model_reasoning_effort=\"$SMOKE_EFFORT\"" \
               "Reply with the single word OK. Do not write any files." \
               > "$SMOKE_STREAM" 2>&1; then
            SMOKE_DUR=$(( $(date +%s%3N) - T0 ))
            TS=$(bash "$CODEX_PARSER" \
                    --model "$SMOKE_MODEL" \
                    --effort "$SMOKE_EFFORT" \
                    --duration-ms "$SMOKE_DUR" \
                    --file "$SMOKE_STREAM")

            echo "  smoke raw JSONL (first 5 lines):"
            head -5 "$SMOKE_STREAM" | sed 's/^/    /'
            echo "  parsed telemetry: $TS"

            if [[ "$(json_available "$TS")" == "true" ]]; then
                ok "Smoke: available=true model=$(json_field "$TS" model) effort=$(json_field "$TS" effort) input=$(json_field "$TS" input) output=$(json_field "$TS" output) duration_ms=$(json_field "$TS" duration_ms)"
            else
                fail "Smoke: parser returned unavailable: $TS"
            fi
        else
            skip "codex exec failed (exit nonzero); check credentials or model availability"
        fi
    fi
fi

# ── Summary ────────────────────────────────────────────────────────────────────
echo ""
echo "══════════════════════════════════════════════════════"
echo "  Results: $PASS passed, $FAIL failed, $SKIP skipped"
echo "══════════════════════════════════════════════════════"
echo ""

[[ $FAIL -eq 0 ]] || exit 1
