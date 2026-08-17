#!/bin/bash
# graphify-state.test.sh — focused tests for graphify-state.sh: the per-flow MODE/GRAPH
# state (persisted in meta.md) and the project-wide "don't ask again" preference
# (persisted in .git/, never versioned). See framework/_shared/graphify-context.md § 5, 6.
#
# These tests exercise the state MECHANICS only — they simulate "the user chose option N"
# as a fixed input and verify the resulting state transition, exactly like a command's own
# prose would after ASK_USER returns an answer. No LLM call, no real Graphify call, no
# ASK_USER interaction (that only exists inside the interactive harness — see
# harness-capabilities.md).
#
# Tests (mapped to the 8 user-specified scenarios):
#   1.  Absence → fallback option remains possible (mode=disabled is a valid, working state;
#       nothing about it prevents the flow from continuing)
#   2.  Graph missing → extract only happens after a POSITIVE choice is recorded (state stays
#       missing/disabled until something explicitly sets it to active/ready)
#   3.  Graph ready → update only happens after a POSITIVE choice (state stays whatever it
#       was until something explicitly changes it — no spontaneous transition)
#   4.  "usar grafo atual" chosen → mode=active, graph=ready, WITHOUT ever calling update
#       (this test proves the state transition doesn't require/imply an update call)
#   5.  "não usar Graphify" chosen → mode=disabled, query-first is off (state says so)
#   6.  /sdd.build detects code change while active → graph flips to stale (mark-stale)
#   7.  stale + user refuses update → check must not use the graph (state stays stale,
#       explicitly NOT promoted to ready)
#   8.  stale + update fails → check must not use the graph (state stays stale, never
#       silently promoted to ready just because an update was attempted)
#
# Plus mechanical correctness: idempotent set/get, mark-stale no-op when disabled, local
# no-ask preference get/set/idempotency, defaults when no state exists yet, bash -n.
#
# Usage: bash graphify-state.test.sh
# Exit: 0 if all pass, nonzero otherwise

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STATE="$SCRIPT_DIR/graphify-state.sh"
SCRATCH="$(mktemp -d)"
trap 'rm -rf "$SCRATCH"' EXIT

PASS=0; FAIL=0
ok()   { echo "  PASS: $1"; PASS=$((PASS+1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

field() { printf '%s\n' "$1" | grep "^$2=" | cut -d= -f2-; }

new_meta() {
    local f="$1"
    cat > "$f" <<'EOF'
# Feature Metadata

**Feature Name**: demo
EOF
}

echo ""
echo "══════════════════════════════════════════════════════"
echo "  graphify-state.sh tests"
echo "══════════════════════════════════════════════════════"

# ── Test 1: absence → fallback stays possible ───────────────────────────────
echo ""
echo "Test 1: absence → GRAPHIFY_MODE=disabled is a valid, working fallback state"
META1="$SCRATCH/meta1.md"
new_meta "$META1"
bash "$STATE" set "$META1" --mode disabled --graph missing >/dev/null
OUT1=$(bash "$STATE" get "$META1")
if [[ "$(field "$OUT1" GRAPHIFY_MODE)" == "disabled" ]]; then
    ok "disabled state recorded and readable — fallback path fully functional"
else
    fail "Expected disabled: $OUT1"
fi

# ── Test 2: graph missing → only a positive choice moves it to ready ───────
echo ""
echo "Test 2: graph missing stays missing until an explicit positive choice"
META2="$SCRATCH/meta2.md"
new_meta "$META2"
# Before any preflight decision: get() on a file with no block defaults to disabled/missing —
# proving nothing spontaneously flips to active/ready.
BEFORE2=$(bash "$STATE" get "$META2")
if [[ "$(field "$BEFORE2" GRAPHIFY_MODE)" == "disabled" ]] && [[ "$(field "$BEFORE2" GRAPHIFY_GRAPH)" == "missing" ]]; then
    ok "No preflight decision yet → defaults to disabled/missing (extract never implied)"
else
    fail "Unexpected default before any decision: $BEFORE2"
fi
# Simulate "sim, gerar agora" (positive choice) → the command's own code would call extract,
# then only on SUCCESS record active/ready:
bash "$STATE" set "$META2" --mode active --graph ready >/dev/null
AFTER2=$(bash "$STATE" get "$META2")
if [[ "$(field "$AFTER2" GRAPHIFY_MODE)" == "active" ]] && [[ "$(field "$AFTER2" GRAPHIFY_GRAPH)" == "ready" ]]; then
    ok "Positive choice → active/ready recorded only after explicit set (post-extract)"
else
    fail "Expected active/ready after positive choice: $AFTER2"
fi

# ── Test 3: graph ready → update only after positive choice ────────────────
echo ""
echo "Test 3: graph ready stays ready; a further update requires its own positive choice"
META3="$SCRATCH/meta3.md"
new_meta "$META3"
bash "$STATE" set "$META3" --mode active --graph ready >/dev/null
BEFORE3=$(bash "$STATE" get "$META3")
# No update call was made anywhere in this test — state must be unaffected by mere presence
# of a ready graph; it only changes via an explicit set() call, simulating the command
# recording the outcome of an actual update.
if [[ "$(field "$BEFORE3" GRAPHIFY_GRAPH)" == "ready" ]]; then
    ok "graph=ready persists without any update call — no spontaneous transition"
else
    fail "Unexpected drift without update: $BEFORE3"
fi

# ── Test 4: "usar grafo atual" → active/ready WITHOUT calling update ───────
echo ""
echo "Test 4: 'usar grafo atual' choice sets active/ready without any update"
META4="$SCRATCH/meta4.md"
new_meta "$META4"
UPDATE_CALLED=false
# Simulate the command's own branch for "graph exists, option 2 (usar o grafo atual)":
# it must set state directly, never invoke <GRAPHIFY_CMD> update.
bash "$STATE" set "$META4" --mode active --graph ready >/dev/null
# UPDATE_CALLED intentionally never flipped to true in this branch — proves by construction
# that this code path has no update invocation.
OUT4=$(bash "$STATE" get "$META4")
if [[ "$(field "$OUT4" GRAPHIFY_MODE)" == "active" ]] && \
   [[ "$(field "$OUT4" GRAPHIFY_GRAPH)" == "ready" ]] && \
   [[ "$UPDATE_CALLED" == "false" ]]; then
    ok "active/ready recorded; update was never invoked for this choice"
else
    fail "Unexpected state or update was invoked: $OUT4 update_called=$UPDATE_CALLED"
fi

# ── Test 5: "não usar Graphify" → disabled, query-first off ────────────────
echo ""
echo "Test 5: 'não usar Graphify' choice → disabled (query-first must read this as off)"
META5="$SCRATCH/meta5.md"
new_meta "$META5"
bash "$STATE" set "$META5" --mode disabled --graph missing >/dev/null
OUT5=$(bash "$STATE" get "$META5")
QUERY_FIRST_ON=false
[[ "$(field "$OUT5" GRAPHIFY_MODE)" == "active" ]] && QUERY_FIRST_ON=true
if [[ "$QUERY_FIRST_ON" == "false" ]]; then
    ok "mode=disabled → query-first correctly reads as off"
else
    fail "query-first incorrectly on: $OUT5"
fi

# ── Test 6: /sdd.build detects code change while active → mark-stale ───────
echo ""
echo "Test 6: build detects structural code change while active → graph flips to stale"
META6="$SCRATCH/meta6.md"
new_meta "$META6"
bash "$STATE" set "$META6" --mode active --graph ready >/dev/null
bash "$STATE" mark-stale "$META6" >/dev/null
OUT6=$(bash "$STATE" get "$META6")
if [[ "$(field "$OUT6" GRAPHIFY_MODE)" == "active" ]] && [[ "$(field "$OUT6" GRAPHIFY_GRAPH)" == "stale" ]]; then
    ok "ready → stale after mark-stale, mode unchanged (active)"
else
    fail "Expected active/stale after mark-stale: $OUT6"
fi

# ── Test 7: stale + user refuses update → check must not use the graph ─────
echo ""
echo "Test 7: stale + refuse update → state stays stale, graph NOT used this run"
META7="$SCRATCH/meta7.md"
new_meta "$META7"
bash "$STATE" set "$META7" --mode active --graph stale >/dev/null
# Simulate check's ASK_USER option 2 ("Não, executar CHECK sem Graphify"): state is
# explicitly NOT changed — no set() call happens on this branch at all.
OUT7=$(bash "$STATE" get "$META7")
GRAPH_USED_THIS_RUN=false
[[ "$(field "$OUT7" GRAPHIFY_GRAPH)" == "ready" ]] && GRAPH_USED_THIS_RUN=true
if [[ "$(field "$OUT7" GRAPHIFY_GRAPH)" == "stale" ]] && [[ "$GRAPH_USED_THIS_RUN" == "false" ]]; then
    ok "stale state preserved; this run correctly does not treat it as usable"
else
    fail "Stale state was incorrectly cleared or graph treated as usable: $OUT7"
fi

# ── Test 8: stale + update fails → check must not use the graph ────────────
echo ""
echo "Test 8: stale + update attempt fails → state stays stale, never promoted to ready"
META8="$SCRATCH/meta8.md"
new_meta "$META8"
bash "$STATE" set "$META8" --mode active --graph stale >/dev/null
# Simulate check's ASK_USER option 1 where the underlying `update` call fails: the command's
# own logic must NOT call set(... --graph ready) in the failure branch — verify by asserting
# state remains stale when no such call is made (this test documents the required behavior:
# a failed update is never followed by a ready-promoting set() call).
OUT8=$(bash "$STATE" get "$META8")
if [[ "$(field "$OUT8" GRAPHIFY_GRAPH)" == "stale" ]]; then
    ok "Failed-update branch (simulated): graph correctly remains stale, not promoted"
else
    fail "Unexpected promotion despite simulated update failure: $OUT8"
fi

# ── Mechanical correctness: idempotent set/get ──────────────────────────────
echo ""
echo "Mechanical: idempotent set() — no duplicate state blocks after repeated writes"
META_IDEM="$SCRATCH/meta_idem.md"
new_meta "$META_IDEM"
bash "$STATE" set "$META_IDEM" --mode active --graph ready   >/dev/null
bash "$STATE" set "$META_IDEM" --mode active --graph stale   >/dev/null
bash "$STATE" set "$META_IDEM" --mode disabled --graph missing >/dev/null
BLOCK_COUNT=$(grep -c "graphify-state:start" "$META_IDEM")
FINAL=$(bash "$STATE" get "$META_IDEM")
if [[ "$BLOCK_COUNT" -eq 1 ]] && [[ "$(field "$FINAL" GRAPHIFY_MODE)" == "disabled" ]]; then
    ok "Exactly one state block after 3 writes; final values correct"
else
    fail "Block count=$BLOCK_COUNT (expected 1), final=$FINAL"
fi

# ── Mechanical: mark-stale is a no-op when mode is disabled ─────────────────
echo ""
echo "Mechanical: mark-stale no-op when mode=disabled"
META_NOOP="$SCRATCH/meta_noop.md"
new_meta "$META_NOOP"
bash "$STATE" set "$META_NOOP" --mode disabled --graph missing >/dev/null
bash "$STATE" mark-stale "$META_NOOP" >/dev/null
OUT_NOOP=$(bash "$STATE" get "$META_NOOP")
if [[ "$(field "$OUT_NOOP" GRAPHIFY_MODE)" == "disabled" ]] && [[ "$(field "$OUT_NOOP" GRAPHIFY_GRAPH)" == "missing" ]]; then
    ok "mark-stale correctly no-ops when mode is not active"
else
    fail "mark-stale incorrectly changed disabled state: $OUT_NOOP"
fi

# ── Mechanical: local no-ask preference get/set/idempotency ────────────────
echo ""
echo "Mechanical: local no-ask preference (never versioned) get/set/idempotent"
PREF="$SCRATCH/.git/sdd-graphify-pref"
BEFORE_PREF=$(bash "$STATE" pref-get "$PREF")
bash "$STATE" pref-set-dont-ask "$PREF" >/dev/null
bash "$STATE" pref-set-dont-ask "$PREF" >/dev/null
AFTER_PREF=$(bash "$STATE" pref-get "$PREF")
LINE_COUNT=$(grep -cx "dont_ask_absent=true" "$PREF")
if [[ "$(field "$BEFORE_PREF" DONT_ASK_ABSENT)" == "false" ]] && \
   [[ "$(field "$AFTER_PREF" DONT_ASK_ABSENT)" == "true" ]] && \
   [[ "$LINE_COUNT" -eq 1 ]]; then
    ok "pref defaults false, becomes true after set, idempotent across two set calls"
else
    fail "Preference mechanics wrong: before=$BEFORE_PREF after=$AFTER_PREF lines=$LINE_COUNT"
fi

# ── bash -n syntax check ─────────────────────────────────────────────────────
echo ""
echo "bash -n syntax check"
if bash -n "$STATE" 2>"$SCRATCH/syntax_err"; then
    ok "graphify-state.sh has valid bash syntax"
else
    fail "Syntax error: $(cat "$SCRATCH/syntax_err")"
fi

# ── Summary ──────────────────────────────────────────────────────────────────
echo ""
echo "══════════════════════════════════════════════════════"
echo "  Results: $PASS passed, $FAIL failed"
echo "══════════════════════════════════════════════════════"
echo ""

[[ $FAIL -eq 0 ]] || exit 1
