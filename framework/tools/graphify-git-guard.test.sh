#!/bin/bash
# graphify-git-guard.test.sh — focused tests for graphify-git-guard.sh, the mandatory
# pre-use git-safety guard (framework/_shared/graphify-context.md § 2).
#
# ZERO-DEPENDENCY: no python/jq needed. Uses real scratch git repos (git itself is already
# a hard requirement of the SDD pipeline, not a new dependency introduced here) — no real
# Graphify binary, no API call, no LLM call.
#
# Tests:
#   1.  Scenario A (default): unprotected graphify-out/ → protected via .git/info/exclude
#       only; project .gitignore is NOT touched (and not created if absent)
#   2.  Scenario B (--gitignore): unprotected graphify-out/ → protected via BOTH
#       .git/info/exclude AND project .gitignore
#   3.  Already ignored via existing .gitignore → no unnecessary write to .git/info/exclude
#   4.  Already ignored via existing .git/info/exclude → idempotent, no duplicate line
#   5.  Staged graphify-out/ path is unstaged; sibling staged file untouched (ordering fix:
#       staging is corrected BEFORE the ignore check, since git check-ignore reports a
#       tracked/staged path as "not ignored" regardless of exclude rules)
#   6.  Not inside a git repository → GUARD_PROTECTED=false, exit 1, no crash
#   7.  GUARD_STAGED_CORRECTED=false when nothing was staged (no false positive)
#   8.  bash -n syntax check on graphify-git-guard.sh
#
# Usage: bash graphify-git-guard.test.sh
# Exit: 0 if all pass, nonzero otherwise

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GUARD="$SCRIPT_DIR/graphify-git-guard.sh"
SCRATCH="$(mktemp -d)"
trap 'rm -rf "$SCRATCH"' EXIT

PASS=0; FAIL=0
ok()   { echo "  PASS: $1"; PASS=$((PASS+1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

field() { printf '%s\n' "$1" | grep "^$2=" | cut -d= -f2-; }

git config --global user.email "test@test.com" >/dev/null 2>&1
git config --global user.name "test" >/dev/null 2>&1

echo ""
echo "══════════════════════════════════════════════════════"
echo "  graphify-git-guard.sh tests"
echo "══════════════════════════════════════════════════════"

# ── Test 1: Scenario A — .git/info/exclude only, .gitignore untouched ──────
echo ""
echo "Test 1: Scenario A (pre-existing) — local exclude only"
REPO1="$SCRATCH/repo1"
mkdir -p "$REPO1/graphify-out"
(cd "$REPO1" && git init -q && git commit -q --allow-empty -m init)
echo '{"nodes":[]}' > "$REPO1/graphify-out/graph.json"
OUT1=$(bash "$GUARD" --repo-root "$REPO1")
if [[ "$(field "$OUT1" GUARD_PROTECTED)" == "true" ]] && \
   grep -qx "graphify-out/" "$REPO1/.git/info/exclude" 2>/dev/null && \
   [[ ! -f "$REPO1/.gitignore" ]]; then
    ok "Scenario A: protected via .git/info/exclude, .gitignore not created"
else
    fail "Scenario A failed: $OUT1 / exclude=$(cat "$REPO1/.git/info/exclude" 2>/dev/null) / gitignore_exists=$([[ -f "$REPO1/.gitignore" ]] && echo yes || echo no)"
fi

# ── Test 2: Scenario B — both .git/info/exclude AND .gitignore ─────────────
echo ""
echo "Test 2: Scenario B (--gitignore) — both layers protected"
REPO2="$SCRATCH/repo2"
mkdir -p "$REPO2/graphify-out"
(cd "$REPO2" && git init -q && git commit -q --allow-empty -m init)
echo '{"nodes":[]}' > "$REPO2/graphify-out/graph.json"
OUT2=$(bash "$GUARD" --repo-root "$REPO2" --gitignore)
if [[ "$(field "$OUT2" GUARD_PROTECTED)" == "true" ]] && \
   grep -qx "graphify-out/" "$REPO2/.git/info/exclude" 2>/dev/null && \
   grep -qx "graphify-out/" "$REPO2/.gitignore" 2>/dev/null; then
    ok "Scenario B: protected via both .git/info/exclude and .gitignore"
else
    fail "Scenario B failed: $OUT2"
fi

# ── Test 3: already ignored via .gitignore → no unnecessary local write ────
echo ""
echo "Test 3: already ignored via .gitignore → no unnecessary .git/info/exclude write"
REPO3="$SCRATCH/repo3"
mkdir -p "$REPO3/graphify-out"
(cd "$REPO3" && git init -q && echo "graphify-out/" > .gitignore && git add .gitignore && git commit -q -m init)
echo '{"nodes":[]}' > "$REPO3/graphify-out/graph.json"
BEFORE3=$(wc -l < "$REPO3/.git/info/exclude" 2>/dev/null || echo 0)
OUT3=$(bash "$GUARD" --repo-root "$REPO3")
AFTER3=$(wc -l < "$REPO3/.git/info/exclude" 2>/dev/null || echo 0)
if [[ "$(field "$OUT3" GUARD_PROTECTED)" == "true" ]] && [[ "$BEFORE3" == "$AFTER3" ]]; then
    ok "No-op on .git/info/exclude when .gitignore already covers it (lines: $BEFORE3 unchanged)"
else
    fail "Unexpected write: before=$BEFORE3 after=$AFTER3, out=$OUT3"
fi

# ── Test 4: already ignored via .git/info/exclude → idempotent, no dup line ─
echo ""
echo "Test 4: already ignored via .git/info/exclude → idempotent (no duplicate line)"
REPO4="$SCRATCH/repo4"
mkdir -p "$REPO4/graphify-out"
(cd "$REPO4" && git init -q && git commit -q --allow-empty -m init && echo "graphify-out/" >> .git/info/exclude)
echo '{"nodes":[]}' > "$REPO4/graphify-out/graph.json"
bash "$GUARD" --repo-root "$REPO4" >/dev/null
bash "$GUARD" --repo-root "$REPO4" >/dev/null
COUNT4=$(grep -cx "graphify-out/" "$REPO4/.git/info/exclude")
if [[ "$COUNT4" -eq 1 ]]; then
    ok "Idempotent: exactly one 'graphify-out/' line after two guard runs"
else
    fail "Duplicate lines found: count=$COUNT4"
fi

# ── Test 5: staged graphify-out/ unstaged; sibling file untouched ──────────
echo ""
echo "Test 5: staged graphify-out/ corrected without touching other staged files"
REPO5="$SCRATCH/repo5"
mkdir -p "$REPO5/graphify-out" "$REPO5/src"
(
    cd "$REPO5" || exit 1
    git init -q
    echo "print(1)" > src/app.py
    echo '{"nodes":[]}' > graphify-out/graph.json
    git add src/app.py graphify-out/graph.json
)
OUT5=$(bash "$GUARD" --repo-root "$REPO5")
STAGED5=$(cd "$REPO5" && git diff --cached --name-only)
if [[ "$(field "$OUT5" GUARD_PROTECTED)" == "true" ]] && \
   [[ "$(field "$OUT5" GUARD_STAGED_CORRECTED)" == "true" ]] && \
   printf '%s\n' "$STAGED5" | grep -qx 'src/app.py' && \
   ! printf '%s\n' "$STAGED5" | grep -q 'graphify-out/'; then
    ok "graphify-out/ unstaged, src/app.py remains staged and untouched"
else
    fail "Staged-file correction failed: $OUT5 / staged=$STAGED5"
fi

# ── Test 6: not inside a git repo → protected=false, exit 1, no crash ──────
echo ""
echo "Test 6: not inside a git repository"
REPO6="$SCRATCH/not_a_repo"
mkdir -p "$REPO6/graphify-out"
OUT6=$(bash "$GUARD" --repo-root "$REPO6")
RC6=$?
if [[ "$(field "$OUT6" GUARD_PROTECTED)" == "false" ]] && [[ $RC6 -eq 1 ]]; then
    ok "Non-repo: GUARD_PROTECTED=false, exit 1, no crash"
else
    fail "Expected protected=false exit=1, got rc=$RC6 out=$OUT6"
fi

# ── Test 7: nothing staged → GUARD_STAGED_CORRECTED=false (no false positive) ─
echo ""
echo "Test 7: nothing staged → no false-positive correction reported"
REPO7="$SCRATCH/repo7"
mkdir -p "$REPO7/graphify-out"
(cd "$REPO7" && git init -q && git commit -q --allow-empty -m init)
echo '{"nodes":[]}' > "$REPO7/graphify-out/graph.json"
OUT7=$(bash "$GUARD" --repo-root "$REPO7")
if [[ "$(field "$OUT7" GUARD_STAGED_CORRECTED)" == "false" ]]; then
    ok "GUARD_STAGED_CORRECTED=false when nothing was staged"
else
    fail "False-positive staged correction: $OUT7"
fi

# ── Test 8: bash -n syntax check ────────────────────────────────────────────
echo ""
echo "Test 8: bash -n syntax check"
if bash -n "$GUARD" 2>"$SCRATCH/syntax_err"; then
    ok "graphify-git-guard.sh has valid bash syntax"
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
