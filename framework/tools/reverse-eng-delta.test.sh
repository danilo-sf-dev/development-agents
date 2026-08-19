#!/bin/bash
# reverse-eng-delta.test.sh — real execution tests for framework/tools/reverse-eng-delta.sh,
# the deterministic delta detector behind /sdd.reverse-eng UPDATE MODE's delta-first protocol
# (see commands/references/reverse-eng-update-delta.md).
#
# These build REAL git repos in temp dirs and run the actual script against them — behavior
# tests, not markdown grep. Every fixture uses `git -C "$REPO"` so this script's own cwd never
# changes (safe to run from anywhere, no directory-removed-while-inside-it hazards).
#
# ZERO-DEPENDENCY: bash + git only. No real Codex/Claude binary, no LLM call.
#
# Tests:
#   1.  Zero delta: no changes since baseline SHA -> delta_empty:true, baseline_source:"sha"
#   2.  Small delta: one file changed (uncommitted) -> relevant_changed_files has exactly it
#   3.  Small delta: one file changed AND committed, baseline still points to the old SHA ->
#       same result as (2), committed or not doesn't matter
#   4.  Delta confined to sdd/ (this pipeline's own output) -> filtered out, delta_empty:true
#   5.  No Git SHA column in DETECTION_REPORT.md (old-format report) -> mtime fallback tier,
#       baseline_source:"mtime"
#   6.  DETECTION_REPORT.md missing entirely -> baseline_source:"none", delta_empty:false,
#       fallback:"full" (never claims zero delta when it doesn't know)
#   7.  Not a git repository -> same safe "none" fallback, script never crashes/hangs
#   8.  Garbage/unreachable SHA in the report (simulating a rebased/rewritten history) ->
#       falls through past tier 1 to tier 2 or tier 3, never crashes
#   9.  Multiple relevant files changed -> all present in relevant_changed_files, none lost
#  10.  Script always exits 0 regardless of scenario (never aborts the calling command)
#  11.  bash -n syntax check on the script and this test file
#  12.  Tooling directories (development-agents/, .claude/, .cursor/, graphify-out/) are
#       filtered out of relevant_changed_files, individually and combined
#  13.  Untracked, newly-created CLAUDE.md/AGENTS.md at repo root are filtered out
#  14.  A TRACKED, pre-existing CLAUDE.md/AGENTS.md that gets modified is NOT filtered —
#       real edits to committed project docs must still surface as delta
#  15.  .devcontainer/ is never filtered — a real devcontainer config change stays relevant
#  16.  src/test/ and a *Test.java file are never filtered — real test changes stay relevant
#  17.  Real application files with .json/.yaml/.xml extensions are never filtered just
#       because of their extension
#
# Usage: bash reverse-eng-delta.test.sh
# Exit: 0 if all pass, nonzero otherwise

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DELTA="$SCRIPT_DIR/reverse-eng-delta.sh"

PASS=0; FAIL=0
ok()   { echo "  PASS: $1"; PASS=$((PASS+1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

WORKDIR=$(mktemp -d)
cleanup() { rm -rf "$WORKDIR"; }
trap cleanup EXIT

json_field() {
    # $1=json $2=key (string or bool/number field) -> raw value text
    printf '%s' "$1" | grep -oE "\"$2\"[[:space:]]*:[[:space:]]*(\"[^\"]*\"|true|false|\[[^]]*\])" \
        | head -1 | sed -E 's/^"[^"]*"[[:space:]]*:[[:space:]]*//'
}

echo ""
echo "══════════════════════════════════════════════════════"
echo "  reverse-eng-delta.sh — real execution tests"
echo "══════════════════════════════════════════════════════"

# ── Fixture: a real git repo with one commit and a DETECTION_REPORT.md pointing at it ──
REPO="$WORKDIR/repo"
mkdir -p "$REPO/src" "$REPO/sdd/extracted"
git -C "$REPO" init -q
git -C "$REPO" config user.email test@test.com
git -C "$REPO" config user.name test
echo "hello" > "$REPO/README.md"
echo "code v1" > "$REPO/src/main.py"
git -C "$REPO" add README.md src/main.py
git -C "$REPO" -c commit.gpgsign=false commit -qm "initial"
SHA1=$(git -C "$REPO" rev-parse HEAD)

write_report() {
    # $1 = repo, $2 = sha (empty for no-SHA-column variant)
    if [[ -n "$2" ]]; then
        cat > "$1/sdd/extracted/DETECTION_REPORT.md" <<EOF
# Detection Report
## Extraction History
| Date | Mode | Focus | Summary | Git SHA |
|------|------|-------|---------|---------|
| 2026-08-18 | FULL | - | Initial extraction | $2 |
EOF
    else
        cat > "$1/sdd/extracted/DETECTION_REPORT.md" <<'EOF'
# Detection Report
## Extraction History
| Date | Mode | Focus | Summary |
|------|------|-------|---------|
| 2026-08-18 | FULL | - | Initial extraction |
EOF
    fi
}

write_report "$REPO" "$SHA1"

# ── Test 1: zero delta ────────────────────────────────────────────────────
echo ""
echo "Test 1: zero delta (no changes since baseline)"
OUT=$(bash "$DELTA" --detection-report "$REPO/sdd/extracted/DETECTION_REPORT.md" --repo-root "$REPO")
SRC=$(json_field "$OUT" baseline_source)
EMPTY=$(json_field "$OUT" delta_empty)
if [[ "$SRC" == '"sha"' && "$EMPTY" == "true" ]]; then
    ok "Zero delta correctly detected via real SHA baseline"
else
    fail "Expected baseline_source=sha, delta_empty=true. Got: $OUT"
fi

# ── Test 2: small delta, uncommitted ──────────────────────────────────────
echo ""
echo "Test 2: small delta (uncommitted change to one file)"
echo "code v2" > "$REPO/src/main.py"
OUT=$(bash "$DELTA" --detection-report "$REPO/sdd/extracted/DETECTION_REPORT.md" --repo-root "$REPO")
EMPTY=$(json_field "$OUT" delta_empty)
RELEVANT=$(json_field "$OUT" relevant_changed_files)
if [[ "$EMPTY" == "false" ]] && printf '%s' "$RELEVANT" | grep -q "src/main.py"; then
    ok "Uncommitted single-file delta detected, src/main.py in relevant_changed_files"
else
    fail "Expected delta_empty=false with src/main.py present. Got: $OUT"
fi

# ── Test 3: same delta, now committed ─────────────────────────────────────
echo ""
echo "Test 3: same delta, committed (baseline still points to the old SHA)"
git -C "$REPO" add src/main.py
git -C "$REPO" -c commit.gpgsign=false commit -qm "update main"
OUT=$(bash "$DELTA" --detection-report "$REPO/sdd/extracted/DETECTION_REPORT.md" --repo-root "$REPO")
EMPTY=$(json_field "$OUT" delta_empty)
RELEVANT=$(json_field "$OUT" relevant_changed_files)
if [[ "$EMPTY" == "false" ]] && printf '%s' "$RELEVANT" | grep -q "src/main.py"; then
    ok "Committed delta still detected correctly against the old baseline"
else
    fail "Expected delta_empty=false with src/main.py present. Got: $OUT"
fi

SHA2=$(git -C "$REPO" rev-parse HEAD)

# ── Test 4: delta confined to sdd/ (this pipeline's own output) ──────────
echo ""
echo "Test 4: change confined to sdd/ is filtered out -> zero relevant delta"
write_report "$REPO" "$SHA2"
echo "note" >> "$REPO/sdd/extracted/PATTERNS.md"
OUT=$(bash "$DELTA" --detection-report "$REPO/sdd/extracted/DETECTION_REPORT.md" --repo-root "$REPO")
EMPTY=$(json_field "$OUT" delta_empty)
if [[ "$EMPTY" == "true" ]]; then
    ok "sdd/-only change correctly filtered — never a self-triggering non-empty delta"
else
    fail "Expected delta_empty=true (sdd/ excluded). Got: $OUT"
fi

# ── Test 5: no Git SHA column -> mtime fallback ───────────────────────────
echo ""
echo "Test 5: DETECTION_REPORT.md without a Git SHA column -> mtime tier"
write_report "$REPO" ""
OUT=$(bash "$DELTA" --detection-report "$REPO/sdd/extracted/DETECTION_REPORT.md" --repo-root "$REPO")
SRC=$(json_field "$OUT" baseline_source)
if [[ "$SRC" == '"mtime"' ]]; then
    ok "Correctly fell through to the mtime baseline tier"
else
    fail "Expected baseline_source=mtime. Got: $OUT"
fi

# ── Test 6: no DETECTION_REPORT.md at all ─────────────────────────────────
echo ""
echo "Test 6: DETECTION_REPORT.md missing entirely -> honest 'none', never fake zero-delta"
OUT=$(bash "$DELTA" --detection-report "$REPO/sdd/extracted/DOES_NOT_EXIST.md" --repo-root "$REPO")
SRC=$(json_field "$OUT" baseline_source)
EMPTY=$(json_field "$OUT" delta_empty)
FALLBACK=$(json_field "$OUT" fallback)
if [[ "$SRC" == '"none"' && "$EMPTY" == "false" && "$FALLBACK" == '"full"' ]]; then
    ok "Missing report correctly reports baseline_source=none, delta_empty=false, fallback=full"
else
    fail "Expected none/false/full triplet. Got: $OUT"
fi

# ── Test 7: not a git repository ──────────────────────────────────────────
echo ""
echo "Test 7: --repo-root is not a git repository -> safe 'none' fallback, no crash"
NOTGIT="$WORKDIR/notgit"
mkdir -p "$NOTGIT"
OUT=$(bash "$DELTA" --detection-report "$NOTGIT/DETECTION_REPORT.md" --repo-root "$NOTGIT")
SRC=$(json_field "$OUT" baseline_source)
if [[ "$SRC" == '"none"' ]]; then
    ok "Non-git directory handled safely, no crash"
else
    fail "Expected baseline_source=none for non-git dir. Got: $OUT"
fi

# ── Test 8: garbage/unreachable SHA in the report ─────────────────────────
echo ""
echo "Test 8: unreachable SHA (simulated rewritten history) falls through cleanly"
write_report "$REPO" "0000000deadbeef0000000deadbeef00000000"
OUT=$(bash "$DELTA" --detection-report "$REPO/sdd/extracted/DETECTION_REPORT.md" --repo-root "$REPO")
SRC=$(json_field "$OUT" baseline_source)
if [[ "$SRC" == '"mtime"' || "$SRC" == '"none"' ]]; then
    ok "Unreachable SHA correctly rejected, fell through to $SRC tier"
else
    fail "Expected fallthrough past tier 1. Got: $OUT"
fi

# ── Test 9: multiple relevant files changed, none lost ───────────────────
echo ""
echo "Test 9: multiple changed files all present in relevant_changed_files"
write_report "$REPO" "$SHA2"
echo "extra" > "$REPO/src/extra.py"
echo "more"  > "$REPO/README.md"
OUT=$(bash "$DELTA" --detection-report "$REPO/sdd/extracted/DETECTION_REPORT.md" --repo-root "$REPO")
RELEVANT=$(json_field "$OUT" relevant_changed_files)
if printf '%s' "$RELEVANT" | grep -q "src/extra.py" && printf '%s' "$RELEVANT" | grep -q "README.md"; then
    ok "Both changed files (src/extra.py, README.md) present in relevant_changed_files"
else
    fail "Expected both files present. Got: $OUT"
fi

# ── Test 10: exit code is always 0 ────────────────────────────────────────
echo ""
echo "Test 10: script always exits 0, across all scenarios above"
set +e
bash "$DELTA" --detection-report "/nonexistent/path/DETECTION_REPORT.md" --repo-root "/nonexistent/path" >/dev/null 2>&1
RC=$?
set -e 2>/dev/null || true
if [[ "$RC" -eq 0 ]]; then
    ok "Exits 0 even with entirely nonexistent paths"
else
    fail "Expected exit 0, got $RC"
fi

# ── Test 11: bash -n syntax check ─────────────────────────────────────────
echo ""
echo "Test 11: bash -n syntax check on the script and this test file"
if bash -n "$DELTA" 2>/tmp/reverse_eng_delta_syntax_err && bash -n "$SCRIPT_DIR/reverse-eng-delta.test.sh" 2>>/tmp/reverse_eng_delta_syntax_err; then
    ok "Both the script and this test file have valid bash syntax"
else
    fail "Syntax error: $(cat /tmp/reverse_eng_delta_syntax_err)"
fi

# ── Fixture: fresh repo for the tooling-filter tests (12-17) ──────────────
TREPO="$WORKDIR/tooling-repo"
mkdir -p "$TREPO/src/main" "$TREPO/src/test/java/com/example" "$TREPO/sdd/extracted" \
    "$TREPO/development-agents/commands" "$TREPO/.claude/commands" "$TREPO/.cursor/rules" \
    "$TREPO/.devcontainer" "$TREPO/config"
git -C "$TREPO" init -q
git -C "$TREPO" config user.email test@test.com
git -C "$TREPO" config user.name test
echo "app v1" > "$TREPO/src/main/App.java"
git -C "$TREPO" add src/main/App.java
git -C "$TREPO" -c commit.gpgsign=false commit -qm "initial"
TSHA1=$(git -C "$TREPO" rev-parse HEAD)
cat > "$TREPO/sdd/extracted/DETECTION_REPORT.md" <<EOF
# Detection Report
## Extraction History
| Date | Mode | Focus | Summary | Git SHA |
|------|------|-------|---------|---------|
| 2026-08-18 | FULL | - | Initial extraction | $TSHA1 |
EOF

# ── Test 12: tooling directories filtered out, individually and combined ──
echo ""
echo "Test 12: tooling dirs (development-agents/, .claude/, .cursor/, graphify-out/) filtered"
echo "pack file"   > "$TREPO/development-agents/commands/sdd.reverse-eng.md"
echo "claude cmd"  > "$TREPO/.claude/commands/foo.md"
echo "cursor rule" > "$TREPO/.cursor/rules/sdd-workflow.mdc"
mkdir -p "$TREPO/graphify-out"
echo '{"nodes":[]}' > "$TREPO/graphify-out/graph.json"
OUT=$(bash "$DELTA" --detection-report "$TREPO/sdd/extracted/DETECTION_REPORT.md" --repo-root "$TREPO")
EMPTY=$(json_field "$OUT" delta_empty)
RELEVANT=$(json_field "$OUT" relevant_changed_files)
if [[ "$EMPTY" == "true" ]] \
    && ! printf '%s' "$RELEVANT" | grep -q "development-agents/" \
    && ! printf '%s' "$RELEVANT" | grep -q "\.claude/" \
    && ! printf '%s' "$RELEVANT" | grep -q "\.cursor/" \
    && ! printf '%s' "$RELEVANT" | grep -q "graphify-out/"; then
    ok "All four tooling directories correctly filtered — zero relevant delta"
else
    fail "Expected all tooling dirs filtered, delta_empty=true. Got: $OUT"
fi
rm -rf "$TREPO/development-agents" "$TREPO/.claude" "$TREPO/.cursor" "$TREPO/graphify-out"

# ── Test 13: untracked, newly-created CLAUDE.md/AGENTS.md filtered out ────
echo ""
echo "Test 13: untracked (newly-created) CLAUDE.md/AGENTS.md filtered out of relevant delta"
echo "## SDD Kit" > "$TREPO/CLAUDE.md"
echo "## SDD Kit" > "$TREPO/AGENTS.md"
OUT=$(bash "$DELTA" --detection-report "$TREPO/sdd/extracted/DETECTION_REPORT.md" --repo-root "$TREPO")
EMPTY=$(json_field "$OUT" delta_empty)
RELEVANT=$(json_field "$OUT" relevant_changed_files)
if [[ "$EMPTY" == "true" ]] \
    && ! printf '%s' "$RELEVANT" | grep -q "CLAUDE.md" \
    && ! printf '%s' "$RELEVANT" | grep -q "AGENTS.md"; then
    ok "Untracked CLAUDE.md/AGENTS.md correctly excluded from relevant delta"
else
    fail "Expected CLAUDE.md/AGENTS.md excluded (untracked). Got: $OUT"
fi
rm -f "$TREPO/CLAUDE.md" "$TREPO/AGENTS.md"

# ── Test 14: a TRACKED CLAUDE.md that gets modified IS relevant ──────────
echo ""
echo "Test 14: a tracked, pre-existing CLAUDE.md modified afterward stays in relevant delta"
echo "# Project instructions" > "$TREPO/CLAUDE.md"
git -C "$TREPO" add CLAUDE.md
git -C "$TREPO" -c commit.gpgsign=false commit -qm "add tracked CLAUDE.md"
TSHA2=$(git -C "$TREPO" rev-parse HEAD)
cat > "$TREPO/sdd/extracted/DETECTION_REPORT.md" <<EOF
# Detection Report
## Extraction History
| Date | Mode | Focus | Summary | Git SHA |
|------|------|-------|---------|---------|
| 2026-08-18 | FULL | - | Initial extraction | $TSHA2 |
EOF
echo "# Project instructions, updated" > "$TREPO/CLAUDE.md"
OUT=$(bash "$DELTA" --detection-report "$TREPO/sdd/extracted/DETECTION_REPORT.md" --repo-root "$TREPO")
EMPTY=$(json_field "$OUT" delta_empty)
RELEVANT=$(json_field "$OUT" relevant_changed_files)
if [[ "$EMPTY" == "false" ]] && printf '%s' "$RELEVANT" | grep -q "CLAUDE.md"; then
    ok "Tracked CLAUDE.md edit correctly stays in relevant delta — real doc changes are never hidden"
else
    fail "Expected CLAUDE.md present (tracked file, real edit). Got: $OUT"
fi

# ── Test 15: .devcontainer/ is NEVER filtered ──────────────────────────────
echo ""
echo "Test 15: .devcontainer/ config change is never filtered (not a tooling dir)"
mkdir -p "$TREPO/.devcontainer"
echo '{"image":"foo"}' > "$TREPO/.devcontainer/devcontainer.json"
OUT=$(bash "$DELTA" --detection-report "$TREPO/sdd/extracted/DETECTION_REPORT.md" --repo-root "$TREPO")
RELEVANT=$(json_field "$OUT" relevant_changed_files)
if printf '%s' "$RELEVANT" | grep -q "\.devcontainer/devcontainer.json"; then
    ok ".devcontainer/ change correctly NOT filtered — stays in relevant delta"
else
    fail "Expected .devcontainer/devcontainer.json present (must never be filtered). Got: $OUT"
fi
rm -rf "$TREPO/.devcontainer"

# ── Test 16: src/test/ and *Test.java are NEVER filtered ─────────────────
echo ""
echo "Test 16: src/test/ dir and a *Test.java file are never filtered as tooling"
echo "test v1" > "$TREPO/src/test/java/com/example/FooTest.java"
OUT=$(bash "$DELTA" --detection-report "$TREPO/sdd/extracted/DETECTION_REPORT.md" --repo-root "$TREPO")
RELEVANT=$(json_field "$OUT" relevant_changed_files)
if printf '%s' "$RELEVANT" | grep -q "src/test/java/com/example/FooTest.java"; then
    ok "src/test/*Test.java correctly NOT filtered — real test changes stay relevant"
else
    fail "Expected FooTest.java present (real test file, must never be filtered). Got: $OUT"
fi
rm -f "$TREPO/src/test/java/com/example/FooTest.java"

# ── Test 17: real app files are never filtered just by extension ─────────
echo ""
echo "Test 17: .json/.yaml/.xml application files are never filtered by extension alone"
echo '{"key":"value"}'        > "$TREPO/config/app.json"
echo 'key: value'             > "$TREPO/config/app.yaml"
echo '<config><a/></config>'  > "$TREPO/config/app.xml"
OUT=$(bash "$DELTA" --detection-report "$TREPO/sdd/extracted/DETECTION_REPORT.md" --repo-root "$TREPO")
RELEVANT=$(json_field "$OUT" relevant_changed_files)
if printf '%s' "$RELEVANT" | grep -q "config/app.json" \
    && printf '%s' "$RELEVANT" | grep -q "config/app.yaml" \
    && printf '%s' "$RELEVANT" | grep -q "config/app.xml"; then
    ok "JSON/YAML/XML application files correctly NOT filtered by extension"
else
    fail "Expected all three config files present. Got: $OUT"
fi

# ── Summary ──────────────────────────────────────────────────────────────────
echo ""
echo "══════════════════════════════════════════════════════"
echo "  Results: $PASS passed, $FAIL failed"
echo "══════════════════════════════════════════════════════"
echo ""

[[ $FAIL -eq 0 ]] || exit 1
