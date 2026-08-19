#!/bin/bash
# graphify-readiness.test.sh — real execution tests for framework/tools/graphify-readiness.sh,
# the deterministic graph.json validity check backing framework/_shared/graphify-context.md
# § 4.2's preflight readiness decision.
#
# Paired with framework/tools/graphify-run.test.sh (F3: proves `extract . --code-only` arrives
# at the real Graphify invocation with exact argument boundaries — the "--code-only is the path
# the runner uses" behavior lives there, not duplicated here) and
# framework/tools/reverse-eng-delta.test.sh (proves the delta detector never touches Graphify on
# a zero-delta UPDATE — see Test 6 below, which asserts this statically against the real script
# rather than re-testing reverse-eng-delta.sh's own behavior).
#
# Tests:
#   1.  graphify-out/graph.json does not exist -> GRAPH_READY=false, reason mentions "does not exist"
#   2.  graphify-out/graph.json exists, non-empty, valid-looking JSON -> GRAPH_READY=true
#   3.  graphify-out/graph.json exists but is a zero-byte file (failed/interrupted extract) ->
#       GRAPH_READY=false, never silently treated as ready
#   4.  graphify-out/graph.json exists but is not JSON-shaped (garbage/partial write) ->
#       GRAPH_READY=false
#   5.  graphify-out/ directory itself does not exist at all -> GRAPH_READY=false, no crash
#   6.  reverse-eng-delta.sh (the delta detector UPDATE MODE runs first) never invokes Graphify
#       in any way — grep-verified against the real script, not narration: a zero-delta UPDATE
#       literally cannot call graphify-run.sh because the delta detector never mentions it
#   7.  A Graphify failure (readiness false) never causes a nonzero exit — the wider pipeline is
#       never blocked by this check
#   8.  bash -n syntax check
#
# Usage: bash graphify-readiness.test.sh
# Exit: 0 if all pass, nonzero otherwise

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
READY="$SCRIPT_DIR/graphify-readiness.sh"
DELTA="$SCRIPT_DIR/reverse-eng-delta.sh"

PASS=0; FAIL=0
ok()   { echo "  PASS: $1"; PASS=$((PASS+1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

WORKDIR=$(mktemp -d)
cleanup() { rm -rf "$WORKDIR"; }
trap cleanup EXIT

field() {
    printf '%s' "$1" | grep "^$2=" | head -1 | cut -d= -f2-
}

echo ""
echo "══════════════════════════════════════════════════════"
echo "  graphify-readiness.sh — real execution tests"
echo "══════════════════════════════════════════════════════"

# ── Test 1: graph.json does not exist ──────────────────────────────────────
echo ""
echo "Test 1: graphify-out/graph.json does not exist -> GRAPH_READY=false"
R1="$WORKDIR/no-graph"
mkdir -p "$R1"
OUT=$(bash "$READY" --repo-root "$R1")
READY_VAL=$(field "$OUT" GRAPH_READY)
REASON=$(field "$OUT" GRAPH_REASON)
if [[ "$READY_VAL" == "false" ]] && printf '%s' "$REASON" | grep -qi "does not exist"; then
    ok "Missing graph.json correctly reports GRAPH_READY=false"
else
    fail "Expected false + 'does not exist' reason. Got: $OUT"
fi

# ── Test 2: valid, non-empty graph.json -> ready ───────────────────────────
echo ""
echo "Test 2: valid non-empty graph.json -> GRAPH_READY=true"
R2="$WORKDIR/valid-graph"
mkdir -p "$R2/graphify-out"
echo '{"nodes":[{"id":"Foo"}],"edges":[]}' > "$R2/graphify-out/graph.json"
OUT=$(bash "$READY" --repo-root "$R2")
READY_VAL=$(field "$OUT" GRAPH_READY)
if [[ "$READY_VAL" == "true" ]]; then
    ok "Valid graph.json correctly reports GRAPH_READY=true"
else
    fail "Expected GRAPH_READY=true. Got: $OUT"
fi

# ── Test 3: zero-byte graph.json (failed/interrupted extract) -> not ready ──
echo ""
echo "Test 3: zero-byte graph.json (failed extraction) -> GRAPH_READY=false, never silently ready"
R3="$WORKDIR/empty-graph"
mkdir -p "$R3/graphify-out"
: > "$R3/graphify-out/graph.json"
OUT=$(bash "$READY" --repo-root "$R3")
READY_VAL=$(field "$OUT" GRAPH_READY)
REASON=$(field "$OUT" GRAPH_REASON)
if [[ "$READY_VAL" == "false" ]] && printf '%s' "$REASON" | grep -qi "empty"; then
    ok "Zero-byte graph.json correctly reports GRAPH_READY=false — extraction failure not masked"
else
    fail "Expected false + 'empty' reason. Got: $OUT"
fi

# ── Test 4: garbage/non-JSON content -> not ready ─────────────────────────
echo ""
echo "Test 4: graph.json exists but is not JSON-shaped -> GRAPH_READY=false"
R4="$WORKDIR/garbage-graph"
mkdir -p "$R4/graphify-out"
echo "Traceback (most recent call last): extraction crashed" > "$R4/graphify-out/graph.json"
OUT=$(bash "$READY" --repo-root "$R4")
READY_VAL=$(field "$OUT" GRAPH_READY)
if [[ "$READY_VAL" == "false" ]]; then
    ok "Non-JSON content correctly reports GRAPH_READY=false"
else
    fail "Expected GRAPH_READY=false for garbage content. Got: $OUT"
fi

# ── Test 5: graphify-out/ directory doesn't exist at all -> no crash ──────
echo ""
echo "Test 5: graphify-out/ directory does not exist at all -> GRAPH_READY=false, no crash"
R5="$WORKDIR/no-dir-at-all"
mkdir -p "$R5"
set +e
OUT=$(bash "$READY" --repo-root "$R5")
RC=$?
set -e 2>/dev/null || true
READY_VAL=$(field "$OUT" GRAPH_READY)
if [[ "$READY_VAL" == "false" && "$RC" -eq 0 ]]; then
    ok "Missing graphify-out/ directory handled safely, GRAPH_READY=false, exit 0"
else
    fail "Expected false + exit 0. Got ready=$READY_VAL rc=$RC"
fi

# ── Test 6: UPDATE zero-delta path never touches Graphify (static, real-script check) ──
echo ""
echo "Test 6: reverse-eng-delta.sh (runs first on every UPDATE) never invokes Graphify"
# The script legitimately mentions the string "graphify-out/" once, as a path it excludes from
# the delta (it must know that name to filter it) — that is data, not a call. What must never
# appear is any actual invocation: a call to graphify-run.sh, or a direct `graphify` command.
if ! grep -qE "graphify-run\.sh|(^|[^-])\bgraphify\b[^-]" "$DELTA"; then
    ok "reverse-eng-delta.sh never invokes Graphify — a zero-delta UPDATE cannot call it, only excludes its output path"
else
    fail "reverse-eng-delta.sh unexpectedly appears to invoke Graphify — delta detection must stay git-only"
fi

# ── Test 7: a failure never produces a nonzero exit (never blocks the pipeline) ──
echo ""
echo "Test 7: GRAPH_READY=false never causes a nonzero exit — never blocks the wider pipeline"
R7="$WORKDIR/failure-nonblocking"
mkdir -p "$R7"
set +e
bash "$READY" --repo-root "$R7" >/dev/null 2>&1
RC=$?
set -e 2>/dev/null || true
if [[ "$RC" -eq 0 ]]; then
    ok "Readiness failure exits 0 — caller is never blocked, only informed"
else
    fail "Expected exit 0 even on GRAPH_READY=false, got $RC"
fi

# ── Test 8: bash -n syntax check ───────────────────────────────────────────
echo ""
echo "Test 8: bash -n syntax check on the script and this test file"
if bash -n "$READY" 2>/tmp/graphify_readiness_syntax_err && bash -n "$SCRIPT_DIR/graphify-readiness.test.sh" 2>>/tmp/graphify_readiness_syntax_err; then
    ok "Both the script and this test file have valid bash syntax"
else
    fail "Syntax error: $(cat /tmp/graphify_readiness_syntax_err)"
fi

# ── Summary ──────────────────────────────────────────────────────────────────
echo ""
echo "══════════════════════════════════════════════════════"
echo "  Results: $PASS passed, $FAIL failed"
echo "══════════════════════════════════════════════════════"
echo ""

[[ $FAIL -eq 0 ]] || exit 1
