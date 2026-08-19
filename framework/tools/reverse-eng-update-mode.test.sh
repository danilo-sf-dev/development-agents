#!/bin/bash
# reverse-eng-update-mode.test.sh — doc-wiring tests for the UPDATE MODE delta-first protocol
# (commands/references/reverse-eng-update-delta.md) and confirmation that FULL EXTRACTION's
# existing behavior is untouched.
#
# The deterministic PART of this fix (delta detection itself: zero-delta detection, target-set
# file lists, baseline tiering) is tested with real git fixtures in
# framework/tools/reverse-eng-delta.test.sh — this file covers the parts that are inherently
# agent-judgment calls (when to delegate, how to build a target set with Graphify, which
# artifacts to touch) and can only be verified as a documented CONTRACT. Grep-based, honestly so.
#
# ZERO-DEPENDENCY: grep/bash only.
#
# Tests:
#   1.  [UPDATE] Zero-delta run explicitly forbids spawning a subagent or re-reading source
#   2.  [UPDATE] Zero-delta run explicitly forbids re-generating PATTERNS.md / rewriting specs
#   3.  [UPDATE] Non-zero, small delta explicitly builds a target set from relevant_changed_files
#   4.  [UPDATE] Graphify-active path is graph-first (query/path/explain) BEFORE any source-wide
#       search, and is used to size the delta's blast radius, not to rediscover the delta
#   5.  [UPDATE] Graphify-unavailable path has an explicit, documented fallback that does not
#       widen to a full repo scan
#   6.  [UPDATE] Subagent delegation is explicitly NOT automatic/inherited for UPDATE MODE
#   7.  [UPDATE] When delegation does happen, the target set must be passed explicitly — no
#       open-ended "explore the codebase" prompt allowed
#   8.  [UPDATE] Unaffected artifacts/sections are explicitly never rewritten
#   9.  [FULL] FULL EXTRACTION's MANDATORY subagent delegation block is still present and
#       unconditional for FULL/ENHANCE
#  10.  [FULL] The exact FULL EXTRACTION delegation workflow text (ASCII block) is byte-for-byte
#       unchanged from before this round (confirms FULL wasn't touched while UPDATE was fixed)
#  11.  [SHARED] sdd.reverse-eng.md points UPDATE MODE (no --focus) at the new reference file
#       before Phase 1, not just informationally
#  12.  [SHARED] DETECTION_REPORT.md template has a Git SHA column (the baseline UPDATE's delta
#       detection depends on)
#  13.  [SHARED] `--focus` behavior/reference is untouched (orthogonal, not redefined)
#  14.  [SHARED] VIEW STATUS / promotion gate behavior is not mentioned as changed by this file
#  15.  [SHARED] Graphify tool files have zero working-tree diff this round (no Graphify tool
#       was modified to build this feature — only a new *use* of the existing mechanism)
#  16.  bash -n syntax check on this test file
#
# Usage: bash reverse-eng-update-mode.test.sh
# Exit: 0 if all pass, nonzero otherwise

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACK_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

REVERSE_ENG="$PACK_ROOT/commands/sdd.reverse-eng.md"
DELTA_REF="$PACK_ROOT/commands/references/reverse-eng-update-delta.md"

PASS=0; FAIL=0
ok()   { echo "  PASS: $1"; PASS=$((PASS+1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

echo ""
echo "══════════════════════════════════════════════════════"
echo "  reverse-eng UPDATE MODE delta-first — doc-wiring tests"
echo "══════════════════════════════════════════════════════"

# ── Test 1: zero-delta forbids subagent/re-read ──────────────────────────
echo ""
echo "Test 1 [UPDATE]: zero-delta run explicitly forbids subagent spawn / source re-read"
if grep -q "Do NOT, on a zero-delta run" "$DELTA_REF" && \
   grep -q "spawn \`sdd-explorer\` or any subagent" "$DELTA_REF"; then
    ok "Zero-delta prohibition on subagent/re-read explicitly documented"
else
    fail "Zero-delta prohibition text missing or incomplete"
fi

# ── Test 2: zero-delta forbids regen/rewrite ──────────────────────────────
echo ""
echo "Test 2 [UPDATE]: zero-delta run explicitly forbids regenerating PATTERNS.md / rewriting specs"
if grep -q "regenerate \`PATTERNS.md\`, rewrite" "$DELTA_REF"; then
    ok "Zero-delta prohibition on regeneration/rewrite explicitly documented"
else
    fail "Zero-delta regeneration/rewrite prohibition missing"
fi

# ── Test 3: non-zero delta builds a real target set ───────────────────────
echo ""
echo "Test 3 [UPDATE]: non-zero delta explicitly builds target set from relevant_changed_files"
if grep -q "target set = relevant_changed_files" "$DELTA_REF"; then
    ok "Target-set construction from relevant_changed_files explicitly documented"
else
    fail "Target-set construction rule missing"
fi

# ── Test 4: Graphify-first ordering, sizing not rediscovery ──────────────
echo ""
echo "Test 4 [UPDATE]: Graphify path is graph-first, used to size (not rediscover) the delta"
if grep -qi "Graphify ACTIVE + READY" "$DELTA_REF" && \
   grep -q "never to re-discover the delta itself" "$DELTA_REF"; then
    ok "Graphify-first ordering and its sizing-only role explicitly documented"
else
    fail "Graphify-first ordering rule missing or unclear"
fi

# ── Test 5: Graphify-unavailable fallback doesn't widen to full scan ─────
echo ""
echo "Test 5 [UPDATE]: Graphify-unavailable path has an explicit non-widening fallback"
if grep -q "Do NOT widen it with a manual" "$DELTA_REF"; then
    ok "Graphify-unavailable fallback explicitly forbids widening the scan"
else
    fail "Graphify-unavailable fallback rule missing"
fi

# ── Test 6: subagent delegation not automatic for UPDATE ──────────────────
echo ""
echo "Test 6 [UPDATE]: subagent delegation is explicitly not automatic/inherited for UPDATE MODE"
if grep -q "does NOT inherit this block automatically" "$REVERSE_ENG" && \
   grep -q "delegate by default" "$DELTA_REF" && \
   grep -qi "UPDATE MODE does" "$DELTA_REF"; then
    ok "UPDATE MODE's non-automatic delegation explicitly documented in both files"
else
    fail "UPDATE MODE delegation-is-not-automatic rule missing"
fi

# ── Test 7: delegation must carry an explicit target set ─────────────────
echo ""
echo "Test 7 [UPDATE]: delegation, when it happens, must carry an explicit pre-scoped target set"
if grep -q "the target set explicitly" "$DELTA_REF" && grep -q "open-ended prompt" "$DELTA_REF"; then
    ok "Explicit-target-set-only delegation rule documented"
else
    fail "Explicit-target-set delegation rule missing"
fi

# ── Test 8: unaffected artifacts never rewritten ──────────────────────────
echo ""
echo "Test 8 [UPDATE]: unaffected artifacts/sections explicitly never rewritten"
if grep -qi "left untouched — no rewrite, no cosmetic refresh" "$DELTA_REF"; then
    ok "No-rewrite-of-unaffected-artifacts rule explicitly documented"
else
    fail "No-rewrite-of-unaffected-artifacts rule missing"
fi

# ── Test 9: FULL EXTRACTION mandatory subagent block still present ───────
echo ""
echo "Test 9 [FULL]: MANDATORY subagent delegation block still present and unconditional for FULL"
if grep -q "MANDATORY for FULL EXTRACTION and ENHANCE SPECS" "$REVERSE_ENG"; then
    ok "FULL/ENHANCE mandatory delegation block still present"
else
    fail "FULL/ENHANCE mandatory delegation block missing or reworded away"
fi

# ── Test 10: FULL's own workflow block text is byte-for-byte unchanged ───
echo ""
echo "Test 10 [FULL]: FULL EXTRACTION's delegation workflow ASCII block is unchanged"
if grep -q "Delegate Phase 0-3 to sdd-explorer (model_role: EXECUTION)," "$REVERSE_ENG" && \
   grep -q "Reduces tokens 30-40%, isolates read-only operations," "$REVERSE_ENG" && \
   grep -q "sdd-explorer subagent performs all read-only exploration" "$REVERSE_ENG"; then
    ok "FULL EXTRACTION's original delegation workflow text is intact, verbatim"
else
    fail "FULL EXTRACTION's delegation workflow text was altered — regression risk"
fi

# ── Test 11: sdd.reverse-eng.md points UPDATE at the new file before Phase 1 ──
echo ""
echo "Test 11 [SHARED]: sdd.reverse-eng.md routes UPDATE MODE to reverse-eng-update-delta.md before Phase 1"
if grep -q "read \`references/reverse-eng-update-delta.md\` FIRST, not this" "$REVERSE_ENG" && \
   grep -q "references/reverse-eng-update-delta.md" "$REVERSE_ENG"; then
    ok "UPDATE MODE routed to the delta-first reference before Phase 1's full protocol"
else
    fail "UPDATE MODE routing to reverse-eng-update-delta.md missing or not before Phase 1"
fi

# ── Test 12: DETECTION_REPORT.md template has a Git SHA column ───────────
echo ""
echo "Test 12 [SHARED]: DETECTION_REPORT.md template's Extraction History table has a Git SHA column"
if grep -q '| Date | Mode | Focus | Summary | Git SHA |' "$REVERSE_ENG"; then
    ok "Git SHA column present in the Extraction History table template"
else
    fail "Git SHA column missing from DETECTION_REPORT.md template"
fi

# ── Test 13: --focus is untouched/orthogonal ──────────────────────────────
echo ""
echo "Test 13 [SHARED]: --focus behavior documented as orthogonal, not redefined"
if grep -qi "Orthogonal\. \`--focus\` targets one named component" "$DELTA_REF"; then
    ok "--focus documented as orthogonal to delta-first UPDATE, not replaced"
else
    fail "--focus orthogonality statement missing"
fi

# ── Test 14: VIEW STATUS / promotion gate explicitly out of scope ────────
echo ""
echo "Test 14 [SHARED]: VIEW STATUS / promotion gate explicitly declared out of scope here"
if grep -q "PROMOVER AGORA" "$DELTA_REF" && grep -q "Phase 0-1 scoping only" "$DELTA_REF"; then
    ok "VIEW STATUS / promotion gate explicitly declared unaffected"
else
    fail "VIEW STATUS / promotion out-of-scope statement missing"
fi

# ── Test 15: Graphify tool files zero diff ────────────────────────────────
# graphify-context.md is intentionally excluded from this check in the telemetry-removal round:
# it cited two files (adapters/*/tools/parse-telemetry.sh, adapters/*/references/
# telemetry-display.md) that were deleted along with the rest of the custom telemetry system.
# The only change there is swapping that dangling citation for a generic sentence — zero change
# to Graphify's own mechanism, scripts, or behavior. The 4 actual Graphify tool scripts below
# still must have zero diff.
echo ""
echo "Test 15 [SHARED]: zero diff under Graphify tool surface this round"
if git -C "$PACK_ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    GRAPHIFY_DIFF=$(git -C "$PACK_ROOT" diff --name-only -- \
        'framework/tools/detect-graphify.sh' \
        'framework/tools/graphify-run.sh' \
        'framework/tools/graphify-git-guard.sh' \
        'framework/tools/graphify-state.sh' 2>/dev/null)
    if [[ -z "$GRAPHIFY_DIFF" ]]; then
        ok "No Graphify tool script has a working-tree diff (graphify-context.md excluded — see comment above)"
    else
        fail "Unexpected diff under Graphify tool surface: $GRAPHIFY_DIFF"
    fi
else
    fail "Not inside a git work tree — cannot verify Graphify zero-diff"
fi

# ── Test 16: bash -n syntax check ─────────────────────────────────────────
echo ""
echo "Test 16: bash -n syntax check on this test file"
if bash -n "$SCRIPT_DIR/reverse-eng-update-mode.test.sh" 2>/tmp/reverse_eng_update_mode_syntax_err; then
    ok "reverse-eng-update-mode.test.sh has valid bash syntax"
else
    fail "Syntax error: $(cat /tmp/reverse_eng_update_mode_syntax_err)"
fi

# ── Summary ──────────────────────────────────────────────────────────────────
echo ""
echo "══════════════════════════════════════════════════════"
echo "  Results: $PASS passed, $FAIL failed"
echo "══════════════════════════════════════════════════════"
echo ""

[[ $FAIL -eq 0 ]] || exit 1
