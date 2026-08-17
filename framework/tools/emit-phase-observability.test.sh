#!/bin/bash
# emit-phase-observability.test.sh — real execution tests for
# framework/tools/emit-phase-observability.sh, the helper that turns
# EMIT_PHASE_OBSERVABILITY from a markdown convention into a concrete, executable action
# (see the script's own header for the real-smoke-test bug this closes).
#
# Unlike telemetry-wiring.test.sh (which greps markdown for wiring text), these tests
# actually RUN the helper against realistic fixtures and assert on its stdout / state-file
# side effects — this is the "testes reais do helper" requirement, not documentation grep.
#
# ZERO-DEPENDENCY: bash/grep/sed/awk + the two existing parsers this helper shells out to
# (adapters/claude-code/tools/parse-telemetry.sh, adapters/codex/tools/parse-telemetry.sh).
# No real Codex/Claude binary, no network call, no LLM call.
#
# Tests:
#   1.  Codex measurable child: realistic turn.completed JSONL -> real Usage block with
#       correct input/output/cached input/reasoning/duration, no cost line, ever
#   2.  Claude measurable child: realistic stream-json result -> real Usage block with
#       correct tokens/cached input/duration/cost, cost last
#   3.  Fallback: no --stream-file at all -> deterministic unavailable text
#   4.  Fallback: --stream-file pointing at a nonexistent path -> deterministic unavailable
#   5.  Fallback: --stream-file pointing at an empty file -> deterministic unavailable
#   6.  Fallback: native/interactive case (Codex, no stream) -> same deterministic text as
#       any other unavailable case, never a different/invented string
#   7.  State-file records: measurable phase appends {"available":true,...}; unavailable
#       phase appends {"available":false}
#   8.  Total/coverage: 2 measurable + 2 unavailable -> coverage 2/4, sums only the two
#       measurable phases, unavailable phases contribute nothing
#   9.  Total: harness=codex never emits a cost line, even when (hypothetically) a state
#       record carried a cost_usd field
#  10.  Total: zero measurable phases -> "telemetry: unavailable" + "coverage: 0/M", never a
#       numeric zero total presented as real consumption
#  11.  Missing --harness -> safe fallback (unavailable), never a hard failure/non-zero exit
#  12.  bash -n syntax check on the helper and on this test file
#
# Usage: bash emit-phase-observability.test.sh
# Exit: 0 if all pass, nonzero otherwise

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACK_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
HELPER="$SCRIPT_DIR/emit-phase-observability.sh"

PASS=0; FAIL=0
ok()   { echo "  PASS: $1"; PASS=$((PASS+1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

WORKDIR=$(mktemp -d)
cleanup() { rm -rf "$WORKDIR"; }
trap cleanup EXIT

echo ""
echo "══════════════════════════════════════════════════════"
echo "  emit-phase-observability.sh — real execution tests"
echo "══════════════════════════════════════════════════════"

# ── Test 1: Codex measurable child ────────────────────────────────────────
echo ""
echo "Test 1: Codex measurable child -> real Usage block, no cost, correct fields"
CODEX_STREAM="$WORKDIR/codex_real.jsonl"
cat > "$CODEX_STREAM" <<'EOF'
{"type":"session.created","session_id":"sess-1"}
{"type":"turn.completed","usage":{"input_tokens":26549,"cached_input_tokens":22272,"output_tokens":1590,"reasoning_output_tokens":413}}
EOF
OUT=$(bash "$HELPER" phase --harness codex --model gpt-5.6-sol --effort high \
    --duration-ms 18400 --stream-file "$CODEX_STREAM")
if printf '%s' "$OUT" | grep -q "^input: 26549$" && \
   printf '%s' "$OUT" | grep -q "^cached input: 22272$" && \
   printf '%s' "$OUT" | grep -q "^output: 1590$" && \
   printf '%s' "$OUT" | grep -q "^reasoning: 413$" && \
   printf '%s' "$OUT" | grep -q "^duration: 18.4s$" && \
   ! printf '%s' "$OUT" | grep -qi "cost"; then
    ok "Codex real Usage block has correct fields, no cost line"
else
    fail "Codex real Usage block incorrect. Got:
$OUT"
fi

# ── Test 2: Claude measurable child ───────────────────────────────────────
echo ""
echo "Test 2: Claude measurable child -> real Usage block, tokens/cache/duration/cost, cost last"
CLAUDE_STREAM="$WORKDIR/claude_real.jsonl"
cat > "$CLAUDE_STREAM" <<'EOF'
{"type":"result","subtype":"success","is_error":false,"duration_ms":7300,"total_cost_usd":0.0474,"usage":{"input_tokens":4,"output_tokens":214},"modelUsage":{"claude-sonnet-4-6":{"inputTokens":4,"outputTokens":214,"cacheReadInputTokens":49816,"cacheCreationInputTokens":4870,"costUSD":0.0474}}}
EOF
OUT=$(bash "$HELPER" phase --harness claude-code --model claude-sonnet-4-6 --stream-file "$CLAUDE_STREAM")
LAST_FIELD=$(printf '%s\n' "$OUT" | tail -1)
if printf '%s' "$OUT" | grep -q "^input: 4$" && \
   printf '%s' "$OUT" | grep -q "^cached input: 49816$" && \
   printf '%s' "$OUT" | grep -q "^output: 214$" && \
   printf '%s' "$OUT" | grep -q "^duration: 7.3s$" && \
   printf '%s' "$OUT" | grep -q '^cost: \$0.0474$' && \
   [[ "$LAST_FIELD" == 'cost: $0.0474' ]]; then
    ok "Claude real Usage block has correct fields, cost is the last line"
else
    fail "Claude real Usage block incorrect. Got:
$OUT"
fi

# ── Test 3: no --stream-file at all ───────────────────────────────────────
echo ""
echo "Test 3: no --stream-file -> deterministic unavailable text"
OUT=$(bash "$HELPER" phase --harness codex)
EXPECTED=$'Usage\ntelemetry: unavailable (interactive session)'
if [[ "$OUT" == "$EXPECTED" ]]; then
    ok "No-stream-file case prints exactly the canonical unavailable block"
else
    fail "Unexpected output for no-stream-file case: '$OUT'"
fi

# ── Test 4: nonexistent stream file ───────────────────────────────────────
echo ""
echo "Test 4: --stream-file pointing at a nonexistent path -> unavailable"
OUT=$(bash "$HELPER" phase --harness claude-code --model claude-sonnet-4-6 \
    --stream-file "$WORKDIR/does-not-exist.jsonl")
if [[ "$OUT" == "$EXPECTED" ]]; then
    ok "Nonexistent stream file falls back to the canonical unavailable block"
else
    fail "Unexpected output for nonexistent stream file: '$OUT'"
fi

# ── Test 5: empty stream file ─────────────────────────────────────────────
echo ""
echo "Test 5: --stream-file pointing at an empty file -> unavailable"
EMPTY_FILE="$WORKDIR/empty.jsonl"
: > "$EMPTY_FILE"
OUT=$(bash "$HELPER" phase --harness codex --model gpt-5.6-sol --stream-file "$EMPTY_FILE")
if [[ "$OUT" == "$EXPECTED" ]]; then
    ok "Empty stream file falls back to the canonical unavailable block"
else
    fail "Unexpected output for empty stream file: '$OUT'"
fi

# ── Test 6: native/interactive Codex case — same text, never invented ────
echo ""
echo "Test 6: Codex native-subagent case (no stream captured) uses the same unavailable text"
OUT=$(bash "$HELPER" phase --harness codex --phase-label "Phase 1 — Extraction")
EXPECTED_LABELED=$'Phase 1 — Extraction\n\nUsage\ntelemetry: unavailable (interactive session)'
if [[ "$OUT" == "$EXPECTED_LABELED" ]]; then
    ok "Native-subagent case (phase label, no stream) uses the exact canonical text"
else
    fail "Unexpected output for native-subagent case: '$OUT'"
fi

# ── Test 7: state-file records ────────────────────────────────────────────
echo ""
echo "Test 7: state-file gets one correct record per phase call"
STATE7="$WORKDIR/state7.jsonl"
bash "$HELPER" phase --harness codex --model gpt-5.6-sol --duration-ms 1000 \
    --stream-file "$CODEX_STREAM" --state-file "$STATE7" >/dev/null
bash "$HELPER" phase --harness codex --state-file "$STATE7" >/dev/null
LINES=$(wc -l < "$STATE7" | tr -d ' ')
if [[ "$LINES" -eq 2 ]] && \
   grep -q '"available":true' "$STATE7" && \
   grep -q '"available":false' "$STATE7"; then
    ok "State file has exactly 2 records: one available:true, one available:false"
else
    fail "State file content unexpected:
$(cat "$STATE7")"
fi

# ── Test 8: Total — 2 measurable + 2 unavailable -> coverage 2/4 ─────────
echo ""
echo "Test 8: Total sums only the 2 measurable phases, coverage reads 2/4"
# Two real `phase` calls (one Claude, one Codex-shaped-but-dispatched-standalone) produce the
# two available records; two more calls with no stream produce the two unavailable records.
# Built via direct `phase` invocations (not hand-written JSON) so this test exercises the
# same record-writing code path Test 7 already validated in isolation.
STATE8="$WORKDIR/state8.jsonl"
bash "$HELPER" phase --harness claude-code --model claude-sonnet-4-6 \
    --stream-file "$CLAUDE_STREAM" --state-file "$STATE8" >/dev/null   # available: input=4 output=214
bash "$HELPER" phase --harness claude-code --state-file "$STATE8" >/dev/null   # unavailable
CODEX_STREAM2="$WORKDIR/codex_real2.jsonl"
cat > "$CODEX_STREAM2" <<'EOF'
{"type":"turn.completed","usage":{"input_tokens":100,"output_tokens":50}}
EOF
bash "$HELPER" phase --harness codex --model gpt-5.6-luna \
    --stream-file "$CODEX_STREAM2" --state-file "$STATE8" >/dev/null   # available: input=100 output=50
bash "$HELPER" phase --harness codex --state-file "$STATE8" >/dev/null   # unavailable
OUT=$(bash "$HELPER" total --harness claude-code --state-file "$STATE8")
if printf '%s' "$OUT" | grep -q "^input: 104$" && \
   printf '%s' "$OUT" | grep -q "^output: 264$" && \
   printf '%s' "$OUT" | grep -q "^coverage: 2/4 measured phases$"; then
    ok "Total correctly sums only the 2 measurable phases (input=104, output=264), coverage 2/4"
else
    fail "Total output incorrect. Got:
$OUT"
fi

# ── Test 9: Total — Codex harness never shows a cost line ────────────────
echo ""
echo "Test 9: Total for harness=codex never emits a cost line, even if a record had cost_usd"
STATE9="$WORKDIR/state9.jsonl"
printf '%s\n' '{"available":true,"input":100,"output":50,"cost_usd":9.9999}' >> "$STATE9"
OUT=$(bash "$HELPER" total --harness codex --state-file "$STATE9")
if ! printf '%s' "$OUT" | grep -qi "cost"; then
    ok "Codex Total never shows a cost line, regardless of state-file content"
else
    fail "Codex Total unexpectedly contains a cost line:
$OUT"
fi

# ── Test 10: Total — zero measurable phases ───────────────────────────────
echo ""
echo "Test 10: zero measurable phases -> unavailable total, never a numeric zero"
STATE10="$WORKDIR/state10.jsonl"
printf '%s\n' '{"available":false}' >> "$STATE10"
printf '%s\n' '{"available":false}' >> "$STATE10"
printf '%s\n' '{"available":false}' >> "$STATE10"
OUT=$(bash "$HELPER" total --harness codex --state-file "$STATE10")
EXPECTED10=$'Usage Total\ntelemetry: unavailable\ncoverage: 0/3 measured phases'
if [[ "$OUT" == "$EXPECTED10" ]]; then
    ok "All-unavailable state produces 'telemetry: unavailable' + 'coverage: 0/3', not a zero total"
else
    fail "Unexpected zero-coverage output: '$OUT'"
fi

# ── Test 11: missing --harness never hard-fails ───────────────────────────
echo ""
echo "Test 11: missing --harness degrades to unavailable, exit code stays 0"
set +e
OUT=$(bash "$HELPER" phase 2>/dev/null)
RC=$?
set -e 2>/dev/null || true
if [[ "$RC" -eq 0 ]] && printf '%s' "$OUT" | grep -q "unavailable"; then
    ok "Missing --harness degrades safely to unavailable, exit code 0"
else
    fail "Missing --harness did not degrade safely (exit=$RC): '$OUT'"
fi

# ── Test 12: bash -n syntax check ─────────────────────────────────────────
echo ""
echo "Test 12: bash -n syntax check on the helper and this test file"
if bash -n "$HELPER" 2>/tmp/emit_helper_syntax_err && bash -n "$SCRIPT_DIR/emit-phase-observability.test.sh" 2>>/tmp/emit_helper_syntax_err; then
    ok "Both the helper and this test file have valid bash syntax"
else
    fail "Syntax error: $(cat /tmp/emit_helper_syntax_err)"
fi

# ── Summary ──────────────────────────────────────────────────────────────────
echo ""
echo "══════════════════════════════════════════════════════"
echo "  Results: $PASS passed, $FAIL failed"
echo "══════════════════════════════════════════════════════"
echo ""

[[ $FAIL -eq 0 ]] || exit 1
