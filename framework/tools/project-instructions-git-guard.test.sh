#!/bin/bash
# project-instructions-git-guard.test.sh — real execution tests for
# framework/tools/project-instructions-git-guard.sh, the CLAUDE.md/AGENTS.md local git
# protection guard used by commands/references/project-instructions-sync.md.
#
# These build REAL git repos in temp dirs and run the actual script against them — behavior
# tests, not markdown grep.
#
# ZERO-DEPENDENCY: bash + git only.
#
# Tests:
#   1.  New, untracked file created by this run -> excluded via .git/info/exclude, disappears
#       from `git status --short`
#   2.  A pre-existing, already-committed (tracked) file -> guard is a strict no-op, stays
#       tracked, never added to exclude
#   3.  A file already covered by an existing .git/info/exclude entry -> idempotent,
#       already-excluded, no duplicate line written
#   4.  Calling the guard twice on the same new file -> idempotent, exactly one exclude line
#   5.  Non-existent file path -> safe no-op, no crash
#   6.  Not inside a git repository -> safe no-op, no crash
#   7.  .gitignore is NEVER touched by this guard (local-only philosophy, unlike Graphify's
#       Scenario B) — confirms no accidental write to the shared ignore file
#   8.  bash -n syntax check
#
# Usage: bash project-instructions-git-guard.test.sh
# Exit: 0 if all pass, nonzero otherwise

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GUARD="$SCRIPT_DIR/project-instructions-git-guard.sh"

PASS=0; FAIL=0
ok()   { echo "  PASS: $1"; PASS=$((PASS+1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

WORKDIR=$(mktemp -d)
cleanup() { rm -rf "$WORKDIR"; }
trap cleanup EXIT

field() {
    # $1=guard output $2=key -> value
    printf '%s' "$1" | grep "^$2=" | head -1 | cut -d= -f2-
}

echo ""
echo "══════════════════════════════════════════════════════"
echo "  project-instructions-git-guard.sh — real execution tests"
echo "══════════════════════════════════════════════════════"

REPO="$WORKDIR/repo"
mkdir -p "$REPO"
git -C "$REPO" init -q
git -C "$REPO" config user.email test@test.com
git -C "$REPO" config user.name test
echo "seed" > "$REPO/seed.txt"
git -C "$REPO" add seed.txt
git -C "$REPO" -c commit.gpgsign=false commit -qm "initial"

# ── Test 1: new untracked file gets excluded, disappears from git status ──
echo ""
echo "Test 1: new untracked CLAUDE.md gets excluded via .git/info/exclude"
echo "## SDD Kit" > "$REPO/CLAUDE.md"
OUT=$(bash "$GUARD" --file CLAUDE.md --repo-root "$REPO")
ACTION=$(field "$OUT" GUARD_ACTION)
PROTECTED=$(field "$OUT" GUARD_PROTECTED)
STATUS_LINE=$(git -C "$REPO" status --short -- CLAUDE.md)
if [[ "$ACTION" == "excluded" && "$PROTECTED" == "true" && -z "$STATUS_LINE" ]]; then
    ok "New file excluded via .git/info/exclude, invisible to git status --short"
else
    fail "Expected excluded/true and empty status. Got action=$ACTION protected=$PROTECTED status='$STATUS_LINE'"
fi

# ── Test 2: an already-tracked file is never touched ──────────────────────
echo ""
echo "Test 2: an already-tracked (pre-existing, committed) file stays tracked, guard is a no-op"
echo "# real instructions" > "$REPO/AGENTS.md"
git -C "$REPO" add AGENTS.md
git -C "$REPO" -c commit.gpgsign=false commit -qm "add tracked AGENTS.md"
OUT=$(bash "$GUARD" --file AGENTS.md --repo-root "$REPO")
ACTION=$(field "$OUT" GUARD_ACTION)
IS_TRACKED=$(git -C "$REPO" ls-files -- AGENTS.md)
if [[ "$ACTION" == "skip-tracked" && -n "$IS_TRACKED" ]]; then
    ok "Tracked AGENTS.md left untouched — guard correctly refused to act"
else
    fail "Expected skip-tracked and file still tracked. Got action=$ACTION tracked='$IS_TRACKED'"
fi
EXCLUDE_FILE="$REPO/.git/info/exclude"
if [[ ! -f "$EXCLUDE_FILE" ]] || ! grep -qxF "AGENTS.md" "$EXCLUDE_FILE"; then
    ok "AGENTS.md never added to .git/info/exclude (tracked files are never excluded)"
else
    fail "AGENTS.md was incorrectly added to .git/info/exclude despite being tracked"
fi

# ── Test 3: file already covered by an existing exclude entry -> idempotent ──
echo ""
echo "Test 3: file already covered by an existing .git/info/exclude entry is idempotent"
REPO2="$WORKDIR/repo2"
mkdir -p "$REPO2"
git -C "$REPO2" init -q
git -C "$REPO2" config user.email test@test.com
git -C "$REPO2" config user.name test
echo "seed" > "$REPO2/seed.txt"
git -C "$REPO2" add seed.txt
git -C "$REPO2" -c commit.gpgsign=false commit -qm "initial"
mkdir -p "$REPO2/.git/info"
echo "CLAUDE.md" > "$REPO2/.git/info/exclude"
echo "## SDD Kit" > "$REPO2/CLAUDE.md"
OUT=$(bash "$GUARD" --file CLAUDE.md --repo-root "$REPO2")
ACTION=$(field "$OUT" GUARD_ACTION)
LINE_COUNT=$(grep -cxF "CLAUDE.md" "$REPO2/.git/info/exclude")
if [[ "$ACTION" == "already-excluded" && "$LINE_COUNT" -eq 1 ]]; then
    ok "Already-excluded file reported correctly, no duplicate exclude line"
else
    fail "Expected already-excluded and exactly 1 line. Got action=$ACTION count=$LINE_COUNT"
fi

# ── Test 4: calling the guard twice is idempotent (exactly one exclude line) ──
echo ""
echo "Test 4: calling the guard twice on the same new file is idempotent"
REPO3="$WORKDIR/repo3"
mkdir -p "$REPO3"
git -C "$REPO3" init -q
git -C "$REPO3" config user.email test@test.com
git -C "$REPO3" config user.name test
echo "seed" > "$REPO3/seed.txt"
git -C "$REPO3" add seed.txt
git -C "$REPO3" -c commit.gpgsign=false commit -qm "initial"
echo "## SDD Kit" > "$REPO3/CLAUDE.md"
bash "$GUARD" --file CLAUDE.md --repo-root "$REPO3" >/dev/null
bash "$GUARD" --file CLAUDE.md --repo-root "$REPO3" >/dev/null
LINE_COUNT=$(grep -cxF "CLAUDE.md" "$REPO3/.git/info/exclude" 2>/dev/null || echo 0)
if [[ "$LINE_COUNT" -eq 1 ]]; then
    ok "Exactly one CLAUDE.md line in .git/info/exclude after two guard calls"
else
    fail "Expected exactly 1 line after two calls, got $LINE_COUNT"
fi

# ── Test 5: non-existent file -> safe no-op ────────────────────────────────
echo ""
echo "Test 5: non-existent file path -> safe no-op, no crash"
OUT=$(bash "$GUARD" --file DOES_NOT_EXIST.md --repo-root "$REPO")
ACTION=$(field "$OUT" GUARD_ACTION)
RC=$?
if [[ "$ACTION" == "skip-not-found" && "$RC" -eq 0 ]]; then
    ok "Non-existent file handled safely, no crash"
else
    fail "Expected skip-not-found, exit 0. Got action=$ACTION rc=$RC"
fi

# ── Test 6: not inside a git repository -> safe no-op ─────────────────────
echo ""
echo "Test 6: --repo-root is not a git repository -> safe no-op, no crash"
NOTGIT="$WORKDIR/notgit"
mkdir -p "$NOTGIT"
echo "content" > "$NOTGIT/CLAUDE.md"
OUT=$(bash "$GUARD" --file CLAUDE.md --repo-root "$NOTGIT")
ACTION=$(field "$OUT" GUARD_ACTION)
RC=$?
if [[ "$ACTION" == "skip-no-repo" && "$RC" -eq 0 ]]; then
    ok "Non-git directory handled safely, no crash"
else
    fail "Expected skip-no-repo, exit 0. Got action=$ACTION rc=$RC"
fi

# ── Test 7: .gitignore is NEVER touched (local-only philosophy) ──────────
echo ""
echo "Test 7: .gitignore is never written by this guard"
REPO4="$WORKDIR/repo4"
mkdir -p "$REPO4"
git -C "$REPO4" init -q
git -C "$REPO4" config user.email test@test.com
git -C "$REPO4" config user.name test
echo "seed" > "$REPO4/seed.txt"
git -C "$REPO4" add seed.txt
git -C "$REPO4" -c commit.gpgsign=false commit -qm "initial"
echo "## SDD Kit" > "$REPO4/AGENTS.md"
bash "$GUARD" --file AGENTS.md --repo-root "$REPO4" >/dev/null
if [[ ! -f "$REPO4/.gitignore" ]]; then
    ok ".gitignore was never created by this guard (local-only via .git/info/exclude)"
else
    fail ".gitignore was unexpectedly created — this guard must never touch the shared ignore file"
fi

# ── Test 8: bash -n syntax check ───────────────────────────────────────────
echo ""
echo "Test 8: bash -n syntax check on the script and this test file"
if bash -n "$GUARD" 2>/tmp/pisync_guard_syntax_err && bash -n "$SCRIPT_DIR/project-instructions-git-guard.test.sh" 2>>/tmp/pisync_guard_syntax_err; then
    ok "Both the script and this test file have valid bash syntax"
else
    fail "Syntax error: $(cat /tmp/pisync_guard_syntax_err)"
fi

# ── Summary ──────────────────────────────────────────────────────────────────
echo ""
echo "══════════════════════════════════════════════════════"
echo "  Results: $PASS passed, $FAIL failed"
echo "══════════════════════════════════════════════════════"
echo ""

[[ $FAIL -eq 0 ]] || exit 1
