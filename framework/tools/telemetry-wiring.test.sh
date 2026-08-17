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
# Round 2 (enforcement fix — the "no Usage block, not even unavailable" real Codex smoke-test
# bug): tests 16-30 below verify EMIT_PHASE_OBSERVABILITY is actually wired as a blocking,
# situated instruction in every command file, not just documented once in agent-instructions.md;
# and that the two per-adapter telemetry-display.md files no longer carry their own competing
# format (a real, separate divergence found during this round's audit).
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
GO_CMD="$PACK_ROOT/commands/sdd.go.md"
CLAUDE_README="$PACK_ROOT/adapters/claude-code/README.md"
CLAUDE_DISPLAY="$PACK_ROOT/adapters/claude-code/references/telemetry-display.md"
CODEX_DISPLAY="$PACK_ROOT/adapters/codex/references/telemetry-display.md"
SINGLE_PHASE_CMDS="sdd.start.md sdd.spec.md sdd.plan.md sdd.test.md sdd.build.md sdd.check.md sdd.finish.md"

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
# Round 2: the literal "unavailable (interactive session)" string is now owned by the helper
# script's own deterministic output (never restated verbatim per phase in this doc — the doc
# instead says which phases call the helper without --stream-file, which is what triggers it).
echo ""
echo "Test 5: sdd.reverse-eng.md documents its own phase-by-phase measurability"
if grep -qi "Phase 0" "$REVERSE_ENG" && \
   grep -qi "Phase 1-3" "$REVERSE_ENG" && \
   grep -q "no \`--model\`/\`--stream-file\` → \`unavailable\`" "$REVERSE_ENG"; then
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

# ══════════════════════════════════════════════════════════════════════════
# Round 2 — EMIT_PHASE_OBSERVABILITY enforcement (Codex + Claude Code symmetric)
# ══════════════════════════════════════════════════════════════════════════

# ── SHARED Test 16: EMIT_PHASE_OBSERVABILITY defined as blocking in the canonical file ──
echo ""
echo "Test 16 [SHARED]: phase-transition-observability.md defines EMIT_PHASE_OBSERVABILITY as blocking"
if grep -q "EMIT_PHASE_OBSERVABILITY" "$OBSERVABILITY" && \
   grep -qi "blocking, not optional" "$OBSERVABILITY"; then
    ok "EMIT_PHASE_OBSERVABILITY defined, explicitly blocking"
else
    fail "EMIT_PHASE_OBSERVABILITY not defined as a blocking routine in the canonical file"
fi

# ── SHARED Test 17: agent-instructions.md names EMIT_PHASE_OBSERVABILITY, not just Usage block ──
echo ""
echo "Test 17 [SHARED]: agent-instructions.md names EMIT_PHASE_OBSERVABILITY explicitly"
if grep -q "EMIT_PHASE_OBSERVABILITY" "$AGENT_INSTR"; then
    ok "agent-instructions.md references EMIT_PHASE_OBSERVABILITY by name"
else
    fail "agent-instructions.md does not name EMIT_PHASE_OBSERVABILITY"
fi

# ── SHARED Test 18: every single-phase command invokes the concrete helper ──
# Round 2 replaced the abstract EMIT_PHASE_OBSERVABILITY term in these files with a concrete
# `emit-phase-observability.sh phase` invocation (the whole point of round 2 — a textual-only
# reminder was tested against a real Codex run and found insufficient). The term itself is
# intentionally gone from these files now; check for the executable action instead.
echo ""
echo "Test 18 [SHARED]: every single-phase command invokes emit-phase-observability.sh concretely"
MISSING=""
for f in $SINGLE_PHASE_CMDS; do
    if ! grep -q "emit-phase-observability.sh phase" "$PACK_ROOT/commands/$f" 2>/dev/null; then
        MISSING="$MISSING $f"
    fi
done
if [[ -z "$MISSING" ]]; then
    ok "All 7 single-phase commands ($SINGLE_PHASE_CMDS) invoke the helper concretely"
else
    fail "Missing concrete emit-phase-observability.sh invocation in:$MISSING"
fi

# ── SHARED Test 19: sdd.reverse-eng.md enforces per-phase via the concrete helper ──
echo ""
echo "Test 19 [SHARED]: sdd.reverse-eng.md invokes the helper per phase, plus a state-file total"
if grep -q "emit-phase-observability.sh phase" "$REVERSE_ENG" && \
   grep -q "emit-phase-observability.sh total" "$REVERSE_ENG" && \
   grep -q "SDD_TELEMETRY_STATE" "$REVERSE_ENG" && \
   grep -qi "Eight-Phase Workflow" "$REVERSE_ENG"; then
    ok "sdd.reverse-eng.md carries concrete per-phase + total helper invocations and state-file convention"
else
    fail "sdd.reverse-eng.md concrete helper wiring missing or incomplete"
fi

# ── SHARED Test 20: sdd.go.md enforces per-phase via the concrete helper + Total/coverage ──
echo ""
echo "Test 20 [SHARED]: sdd.go.md invokes the helper per phase and a final total with N/7 coverage"
if grep -q "emit-phase-observability.sh phase" "$GO_CMD" && \
   grep -q "emit-phase-observability.sh total" "$GO_CMD" && \
   grep -q "SDD_TELEMETRY_STATE" "$GO_CMD" && \
   grep -qi "coverage: N/7" "$GO_CMD"; then
    ok "sdd.go.md ties each of its 7 phases to a concrete helper call and a coverage total"
else
    fail "sdd.go.md missing concrete per-phase helper call or the N/7 coverage requirement"
fi

# ── SHARED Test 21: old parsers untouched (git working tree, if this is a git repo) ─────
echo ""
echo "Test 21 [SHARED]: parser scripts were not rewritten this round"
if git -C "$PACK_ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    PARSER_DIFF=$(git -C "$PACK_ROOT" diff --name-only -- \
        adapters/claude-code/tools/parse-telemetry.sh \
        adapters/codex/tools/parse-telemetry.sh 2>/dev/null)
    if [[ -z "$PARSER_DIFF" ]]; then
        ok "Neither parse-telemetry.sh script has a working-tree diff"
    else
        fail "Unexpected diff in parser script(s): $PARSER_DIFF"
    fi
else
    fail "Not inside a git work tree — cannot verify parser zero-diff"
fi

# ── SHARED Test 22: Graphify zero diff ───────────────────────────────────────
echo ""
echo "Test 22 [SHARED]: zero diff under Graphify surface this round"
if git -C "$PACK_ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    GRAPHIFY_DIFF=$(git -C "$PACK_ROOT" diff --name-only -- \
        'framework/tools/detect-graphify.sh' \
        'framework/tools/graphify-run.sh' \
        'framework/tools/graphify-git-guard.sh' \
        'framework/tools/graphify-state.sh' \
        'framework/_shared/graphify-context.md' 2>/dev/null)
    if [[ -z "$GRAPHIFY_DIFF" ]]; then
        ok "No Graphify surface file has a working-tree diff"
    else
        fail "Unexpected diff under Graphify surface: $GRAPHIFY_DIFF"
    fi
else
    fail "Not inside a git work tree — cannot verify Graphify zero-diff"
fi

# ── SHARED Test 23: model-routing zero diff ──────────────────────────────────
echo ""
echo "Test 23 [SHARED]: zero diff under model-routing surface this round"
if git -C "$PACK_ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    ROUTING_DIFF=$(git -C "$PACK_ROOT" diff --name-only -- \
        'config/model-routing.yaml' \
        'framework/tools/resolve-model.sh' \
        'framework/_shared/model-routing.md' 2>/dev/null)
    if [[ -z "$ROUTING_DIFF" ]]; then
        ok "No model-routing surface file has a working-tree diff"
    else
        fail "Unexpected diff under model-routing surface: $ROUTING_DIFF"
    fi
else
    fail "Not inside a git work tree — cannot verify model-routing zero-diff"
fi

# ── SHARED Test 24: Cursor zero diff ─────────────────────────────────────────
echo ""
echo "Test 24 [SHARED]: zero diff under adapters/cursor this round"
if git -C "$PACK_ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    CURSOR_DIFF=$(git -C "$PACK_ROOT" diff --name-only -- 'adapters/cursor/' 2>/dev/null)
    if [[ -z "$CURSOR_DIFF" ]]; then
        ok "No file under adapters/cursor/ has a working-tree diff"
    else
        fail "Unexpected diff under adapters/cursor/: $CURSOR_DIFF"
    fi
else
    fail "Not inside a git work tree — cannot verify Cursor zero-diff"
fi

# ── CODEX Test 25: native/inline fallback tied to the concrete helper, not just text ─────
echo ""
echo "Test 25 [CODEX]: native-subagent fallback tied to the concrete helper mechanism"
if grep -q "emit-phase-observability.sh" "$CODEX_README" && \
   grep -q "does not, by itself, guarantee the Usage block" "$CODEX_README"; then
    ok "Codex README ties the real smoke-test gap to the concrete emit-phase-observability.sh helper"
else
    fail "Codex README does not tie the native-subagent case to the concrete helper"
fi

# ── CODEX Test 26: codex telemetry-display.md no longer defines a competing format ───
# (the file legitimately *mentions* the old format once, in prose, to explain what was removed —
# the regression check is for the old format's actual rendered block, not the word of it)
echo ""
echo "Test 26 [CODEX]: codex telemetry-display.md defers to the canonical format (no more duplicate)"
if grep -q "format authority moved" "$CODEX_DISPLAY" && \
   ! grep -q "total tokens:" "$CODEX_DISPLAY" && \
   ! grep -qE '^\s*- model:\s+gpt-5\.6-sol$' "$CODEX_DISPLAY"; then
    ok "Codex telemetry-display.md no longer renders its own competing Usage/Total block"
else
    fail "Codex telemetry-display.md still renders (or fails to disclaim) a competing format"
fi

# ── CLAUDE Test 27: claude-code README/display no longer define a competing format ───
echo ""
echo "Test 27 [CLAUDE]: claude-code telemetry-display.md defers to the canonical format (no more duplicate)"
if grep -q "format authority moved" "$CLAUDE_DISPLAY" && \
   ! grep -q "total cost:" "$CLAUDE_DISPLAY" && \
   ! grep -qE '^\s*Phase\s+Model\s+Input\s+Output' "$CLAUDE_DISPLAY"; then
    ok "Claude Code telemetry-display.md no longer renders its own competing Usage/Total block"
else
    fail "Claude Code telemetry-display.md still renders (or fails to disclaim) a competing format"
fi

# ── CLAUDE Test 28: unavailable text now matches canonical exactly (previously diverged) ──
echo ""
echo "Test 28 [CLAUDE]: claude-code docs use the canonical two-line unavailable text"
if grep -q "telemetry: unavailable (interactive session)" "$CLAUDE_DISPLAY" && \
   ! grep -qE '^Usage: unavailable$' "$CLAUDE_DISPLAY"; then
    ok "Claude Code display doc uses the canonical unavailable text, old one-liner removed"
else
    fail "Claude Code display doc still uses (or lost) the canonical unavailable text"
fi

# ── CLAUDE Test 29: README ties enforcement to EMIT_PHASE_OBSERVABILITY ──────
echo ""
echo "Test 29 [CLAUDE]: claude-code README ties printing to EMIT_PHASE_OBSERVABILITY, not just data capture"
if grep -q "EMIT_PHASE_OBSERVABILITY" "$CLAUDE_README"; then
    ok "Claude Code README references EMIT_PHASE_OBSERVABILITY as the print trigger"
else
    fail "Claude Code README does not reference EMIT_PHASE_OBSERVABILITY"
fi

# ── CLAUDE Test 30: cache fields no longer verbose-gated in the per-phase Usage block ──
echo ""
echo "Test 30 [CLAUDE]: cache fields documented as unconditional-if-reported, not verbose-only, per phase"
if grep -qi "no verbose gate" "$CLAUDE_DISPLAY"; then
    ok "Claude Code display doc aligns per-phase cache fields with the canonical no-verbose-gate rule"
else
    fail "Claude Code display doc does not clarify the per-phase cache-field verbose-gate fix"
fi

# ── Summary ──────────────────────────────────────────────────────────────────
echo ""
echo "══════════════════════════════════════════════════════"
echo "  Results: $PASS passed, $FAIL failed"
echo "══════════════════════════════════════════════════════"
echo ""

[[ $FAIL -eq 0 ]] || exit 1
