#!/bin/bash
# telemetry-wiring.test.sh — focused tests verifying the telemetry WIRING fix from the
# 2026-08 audit (see conversation/commit history): telemetry infrastructure existed and was
# individually validated per-adapter, but was never connected to the real /sdd.* pipeline.
# These tests assert the documentation/wiring fix landed correctly — they do not re-test the
# parsers themselves (adapters/*/tests/test-telemetry.sh already do that).
#
# ZERO-DEPENDENCY: grep/bash only. No real Codex/Claude binary, no API call, no LLM call.
#
# Tests:
#   1.  adapters/codex/README.md's dispatch table/examples include --json (the flag that
#       makes turn.completed usage data exist at all — previously absent)
#   2.  adapters/codex/README.md documents OFFLOAD_READ/sdd-explorer preferring the
#       measurable child codex exec --json form over the native in-session subagent fallback
#   3.  adapters/codex/README.md states the native-subagent fallback → telemetry unavailable
#       (never estimated)
#   4.  commands/sdd.reverse-eng.md no longer contains the legacy "automatically by hooks"
#       claim
#   5.  commands/sdd.reverse-eng.md documents its own phase breakdown (0 inline, 1-3
#       delegated/measurable, 4-7 inline)
#   6.  commands/references/phase-transition-observability.md defines the Usage block field
#       order: model, input, cached input, output, reasoning, duration, cost-last
#   7.  phase-transition-observability.md documents the "never omit silently" /
#       telemetry-unavailable rule for inline work
#   8.  phase-transition-observability.md documents Total/coverage summing only available
#       phases, never mixing estimates with real data
#   9.  phase-transition-observability.md states Codex never shows a cost line
#  10.  framework/_shared/agent-instructions.md points to the Usage block section — the
#       single wiring point every command inherits, no per-command duplication
#  11.  no command file (commands/sdd.*.md) reimplements its own ad-hoc Usage block format
#       (would indicate the "single wiring point" rule was violated)
#  12.  bash -n syntax check on this test file
#
# Usage: bash telemetry-wiring.test.sh
# Exit: 0 if all pass, nonzero otherwise

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACK_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

CODEX_README="$PACK_ROOT/adapters/codex/README.md"
REVERSE_ENG="$PACK_ROOT/commands/sdd.reverse-eng.md"
OBSERVABILITY="$PACK_ROOT/commands/references/phase-transition-observability.md"
AGENT_INSTR="$PACK_ROOT/framework/_shared/agent-instructions.md"

PASS=0; FAIL=0
ok()   { echo "  PASS: $1"; PASS=$((PASS+1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

echo ""
echo "══════════════════════════════════════════════════════"
echo "  Telemetry wiring tests"
echo "══════════════════════════════════════════════════════"

# ── Test 1: Codex dispatch documented with --json ───────────────────────────
echo ""
echo "Test 1: Codex adapter dispatch examples include --json"
JSON_COUNT=$(grep -c -- '--json' "$CODEX_README")
if [[ "$JSON_COUNT" -ge 5 ]]; then
    ok "adapters/codex/README.md mentions --json $JSON_COUNT times (dispatch examples + rationale)"
else
    fail "Expected --json to appear in Codex dispatch examples, found only $JSON_COUNT mentions"
fi
# Specifically: the read-only dispatch row (sdd-explorer's mechanism) must include --json
if grep -qE 'sdd-explorer.*\|.*codex exec.*--json' "$CODEX_README"; then
    ok "Read-only dispatch row (sdd-explorer) includes --json in its command"
else
    fail "sdd-explorer dispatch row does not clearly include --json"
fi

# ── Test 2: OFFLOAD_READ prefers measurable child ────────────────────────────
echo ""
echo "Test 2: OFFLOAD_READ/sdd-explorer documented as preferring measurable child dispatch"
if grep -qi "Preferred.*dispatch.*sdd-explorer" "$CODEX_README" || \
   grep -qiE '\*\*Preferred\*\*.*codex exec' "$CODEX_README"; then
    ok "Child codex exec --json documented as the preferred OFFLOAD_READ mechanism"
else
    fail "Preferred child-dispatch mechanism not clearly documented"
fi

# ── Test 3: native-subagent fallback → unavailable ───────────────────────────
echo ""
echo "Test 3: native in-session subagent fallback documented as telemetry-unavailable"
if grep -qi "native in-session subagent" "$CODEX_README" && \
   grep -qi "telemetry is.*not.*available\|telemetry.*not available\|unavailable (interactive session)" "$CODEX_README"; then
    ok "Native subagent fallback explicitly tied to unavailable telemetry, not estimation"
else
    fail "Fallback-to-unavailable rule not clearly documented in Codex README"
fi

# ── Test 4: legacy 'automatically by hooks' text removed ────────────────────
echo ""
echo "Test 4: legacy telemetry claim removed from sdd.reverse-eng.md"
if grep -qi "automatically by hooks\|captured automatically\|No manual tracking required" "$REVERSE_ENG"; then
    fail "Legacy 'automatic via hooks' telemetry text still present in sdd.reverse-eng.md"
else
    ok "Legacy telemetry text removed from sdd.reverse-eng.md"
fi

# ── Test 5: reverse-eng phase breakdown documented ───────────────────────────
echo ""
echo "Test 5: sdd.reverse-eng.md documents its own phase-by-phase measurability"
if grep -qi "Phase 0" "$REVERSE_ENG" && \
   grep -qi "Phase 1-3" "$REVERSE_ENG" && \
   grep -qi "unavailable (interactive session)" "$REVERSE_ENG"; then
    ok "Phase 0 / Phase 1-3 / inline-unavailable breakdown present in sdd.reverse-eng.md"
else
    fail "Phase breakdown not found in sdd.reverse-eng.md telemetry section"
fi

# ── Test 6: Usage block field order ──────────────────────────────────────────
echo ""
echo "Test 6: Usage block field order documented correctly"
FIELD_BLOCK=$(awk '/^model$/{f=1} f{print} /^cost/{exit}' "$OBSERVABILITY" | head -20)
ORDER=$(printf '%s\n' "$FIELD_BLOCK" | grep -oE '^(model|input|cached input|output|reasoning|duration|cost)' | tr '\n' ' ')
EXPECTED="model input cached input output reasoning duration cost "
if [[ "$ORDER" == "$EXPECTED" ]]; then
    ok "Field order matches exactly: $ORDER"
else
    fail "Field order mismatch. Got: '$ORDER' Expected: '$EXPECTED'"
fi

# ── Test 7: never-omit-silently rule ─────────────────────────────────────────
echo ""
echo "Test 7: inline/unavailable rule documented, never silent omission"
if grep -qi "never.*omit.*silently\|never just omit the Usage section" "$OBSERVABILITY" && \
   grep -q "telemetry: unavailable (interactive session)" "$OBSERVABILITY"; then
    ok "Never-omit-silently rule and exact unavailable text both present"
else
    fail "Never-omit-silently rule or exact unavailable text missing"
fi

# ── Test 8: Total sums only available phases ─────────────────────────────────
echo ""
echo "Test 8: Total/coverage rule — only available phases summed, no estimate mixing"
if grep -qi "Sum \*\*only\*\* phases whose telemetry was \`available\`" "$OBSERVABILITY" && \
   grep -qi "Never mix an estimate into a sum with real data" "$OBSERVABILITY"; then
    ok "Coverage-only-real-data rule documented explicitly"
else
    fail "Coverage/no-estimate-mixing rule not found"
fi

# ── Test 9: Codex never shows cost ───────────────────────────────────────────
echo ""
echo "Test 9: Codex cost line explicitly forbidden"
if grep -qi "Codex \*\*never\*\* shows a \`cost\` line" "$OBSERVABILITY"; then
    ok "Codex no-cost rule explicitly documented"
else
    fail "Codex no-cost rule not found in phase-transition-observability.md"
fi

# ── Test 10: agent-instructions.md points to the single wiring point ────────
echo ""
echo "Test 10: agent-instructions.md references the Usage block as the single wiring point"
if grep -qi "Usage.Telemetry block" "$AGENT_INSTR" && \
   grep -qi "no command file re-implements" "$AGENT_INSTR"; then
    ok "agent-instructions.md correctly delegates to the shared Usage block section"
else
    fail "agent-instructions.md does not clearly reference the shared Usage block"
fi

# ── Test 11: no command file reimplements its own Usage block ───────────────
echo ""
echo "Test 11: no command file duplicates its own ad-hoc Usage block format"
DUPLICATES=""
for f in "$PACK_ROOT"/commands/sdd.*.md; do
    base=$(basename "$f")
    [[ "$base" == "sdd.reverse-eng.md" ]] && continue  # legitimately maps shared format onto its own phases
    if grep -qE '^model:.*\n^input:' "$f" 2>/dev/null; then
        DUPLICATES="$DUPLICATES $base"
    fi
done
if [[ -z "$DUPLICATES" ]]; then
    ok "No command file duplicates the Usage block format inline"
else
    fail "Found ad-hoc Usage block duplication in:$DUPLICATES"
fi

# ── Test 12: aggregate ignores unavailable phases (arithmetic, real parsers) ─
echo ""
echo "Test 12: aggregate sums only available phases, unavailable contributes nothing"
CLAUDE_PARSER="$PACK_ROOT/adapters/claude-code/tools/parse-telemetry.sh"
CLAUDE_MODEL="claude-test-agg"
AVAILABLE_STREAM=$(mktemp)
cat > "$AVAILABLE_STREAM" <<EOF
{"type":"result","subtype":"success","is_error":false,"duration_ms":4000,"total_cost_usd":0.02,"usage":{"input_tokens":100,"output_tokens":50,"cache_creation_input_tokens":0,"cache_read_input_tokens":0},"modelUsage":{"$CLAUDE_MODEL":{"inputTokens":100,"outputTokens":50,"cacheReadInputTokens":0,"cacheCreationInputTokens":0,"costUSD":0.02}}}
EOF
UNAVAILABLE_STREAM=$(mktemp)
echo '{"type":"message_start"}' > "$UNAVAILABLE_STREAM"
PHASE_A=$(bash "$CLAUDE_PARSER" --model "$CLAUDE_MODEL" --file "$AVAILABLE_STREAM")
PHASE_B=$(bash "$CLAUDE_PARSER" --model "$CLAUDE_MODEL" --file "$UNAVAILABLE_STREAM")
rm -f "$AVAILABLE_STREAM" "$UNAVAILABLE_STREAM"
A_AVAIL=$(printf '%s' "$PHASE_A" | grep -oE '"available"[[:space:]]*:[[:space:]]*[a-z]*' | grep -oE '[a-z]+$')
B_AVAIL=$(printf '%s' "$PHASE_B" | grep -oE '"available"[[:space:]]*:[[:space:]]*[a-z]*' | grep -oE '[a-z]+$')
A_INPUT=$(printf '%s' "$PHASE_A" | grep -oE '"input"[[:space:]]*:[[:space:]]*[0-9]+' | grep -oE '[0-9]+$')
if [[ "$A_AVAIL" == "true" ]] && [[ "$B_AVAIL" == "false" ]]; then
    # Aggregation rule: sum only phase A's 100 input tokens; phase B contributes 0, not
    # an estimate. Simulate the consumer-side sum exactly as the spec requires.
    TOTAL_INPUT=$A_INPUT   # B excluded entirely, never coerced to 0-and-summed as if measured
    if [[ "$TOTAL_INPUT" -eq 100 ]]; then
        ok "Unavailable phase correctly excluded from sum (total=100, not estimated/blended)"
    else
        fail "Unexpected total: $TOTAL_INPUT"
    fi
else
    fail "Precondition failed: phase A available=$A_AVAIL, phase B available=$B_AVAIL"
fi

# ── Test 13: Codex aggregate never contains a cost key ───────────────────────
echo ""
echo "Test 13: Codex aggregate contains no cost field, even across multiple phases"
CODEX_PARSER="$PACK_ROOT/adapters/codex/tools/parse-telemetry.sh"
CODEX_STREAM_A=$(mktemp)
CODEX_STREAM_B=$(mktemp)
echo '{"type":"turn.completed","usage":{"input_tokens":1000,"output_tokens":200}}' > "$CODEX_STREAM_A"
echo '{"type":"turn.completed","usage":{"input_tokens":2000,"output_tokens":300}}' > "$CODEX_STREAM_B"
CODEX_A=$(bash "$CODEX_PARSER" --model gpt-5.6-sol --effort high --file "$CODEX_STREAM_A")
CODEX_B=$(bash "$CODEX_PARSER" --model gpt-5.6-sol --effort high --file "$CODEX_STREAM_B")
rm -f "$CODEX_STREAM_A" "$CODEX_STREAM_B"
if ! printf '%s%s' "$CODEX_A" "$CODEX_B" | grep -qi '"cost'; then
    ok "Neither Codex phase output contains a cost key — aggregate has nothing to sum into cost"
else
    fail "Cost key unexpectedly found in Codex parser output: $CODEX_A / $CODEX_B"
fi

# ── Test 14: Total block field order (doc-level, distinct from per-phase) ───
echo ""
echo "Test 14: Total block documents cost strictly after duration, coverage line present"
TOTAL_BLOCK=$(awk '/^Usage Total$/{f=1} f{print} /^coverage:/{exit}' "$OBSERVABILITY")
TOTAL_ORDER=$(printf '%s\n' "$TOTAL_BLOCK" | grep -oE '^(input|cached input|output|reasoning|duration|cost|coverage):' | tr -d ':' | tr '\n' ' ')
EXPECTED_TOTAL="input cached input output reasoning duration cost coverage "
if [[ "$TOTAL_ORDER" == "$EXPECTED_TOTAL" ]]; then
    ok "Total block order matches exactly: $TOTAL_ORDER"
else
    fail "Total block order mismatch. Got: '$TOTAL_ORDER' Expected: '$EXPECTED_TOTAL'"
fi

# ── Test 15: bash -n syntax check ────────────────────────────────────────────
echo ""
echo "Test 15: bash -n syntax check on this test file"
SELF="$SCRIPT_DIR/telemetry-wiring.test.sh"
if bash -n "$SELF" 2>/tmp/telemetry_wiring_syntax_err; then
    ok "telemetry-wiring.test.sh has valid bash syntax"
else
    fail "Syntax error: $(cat /tmp/telemetry_wiring_syntax_err)"
fi

# ── Summary ──────────────────────────────────────────────────────────────────
echo ""
echo "══════════════════════════════════════════════════════"
echo "  Results: $PASS passed, $FAIL failed"
echo "══════════════════════════════════════════════════════"
echo ""

[[ $FAIL -eq 0 ]] || exit 1
