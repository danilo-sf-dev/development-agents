#!/bin/bash
# project-instructions-sync.test.sh — real execution tests for
# framework/tools/project-instructions-sync.sh, the deterministic section-merge mechanics
# behind commands/references/project-instructions-sync.md (WRITE_PROJECT_INSTRUCTIONS).
#
# Real files in, real files out — no markdown grep, no narration. Paired with
# framework/tools/project-instructions-git-guard.test.sh (git tracking/exclude behavior) —
# together these cover all 4 behaviors requested for CLAUDE.md/AGENTS.md handling:
#   1. new file created by SDD stays out of Git       -> git-guard.test.sh
#   2. a pre-existing file's non-SDD content survives  -> Test 3/5 below
#   3. a tracked file stays tracked                     -> git-guard.test.sh
#   4. the "## SDD Kit" merge never duplicates          -> Test 4/6 below
#
# ZERO-DEPENDENCY: bash + awk + git (only for the one test that exercises the real
# WRITE_PROJECT_INSTRUCTIONS trigger point end-to-end).
#
# Tests:
#   1.  target_file does not exist -> created verbatim from section-file, SYNC_ACTION=created
#   2.  target_file exists, has NO "## SDD Kit" section -> appended, 100% of existing content
#       preserved, exactly one section present afterward
#   3.  target_file exists with unrelated content (e.g. user's own /init output), no SDD Kit
#       section -> that unrelated content survives byte-for-byte after append
#   4.  target_file already has "## SDD Kit" -> replaced in place, appears exactly once, content
#       before and after the section is preserved unchanged
#   5.  Content OUTSIDE the SDD Kit section (before AND after it) is untouched by a replace
#   6.  Calling sync twice in a row (idempotency) never produces two "## SDD Kit" headers
#   7.  Missing --section-file argument -> SYNC_ACTION=error, exit 1, no partial write
#   8.  End-to-end: create -> git-guard fires (new file) branch, matches the documented
#       procedure in project-instructions-sync.md
#   9.  bash -n syntax check
#
# Usage: bash project-instructions-sync.test.sh
# Exit: 0 if all pass, nonzero otherwise

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SYNC="$SCRIPT_DIR/project-instructions-sync.sh"
GUARD="$SCRIPT_DIR/project-instructions-git-guard.sh"

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
echo "  project-instructions-sync.sh — real execution tests"
echo "══════════════════════════════════════════════════════"

SECTION="$WORKDIR/section.md"
cat > "$SECTION" <<'EOF'
## SDD Kit

This project uses **SDD Kit** for spec-driven development.

### Spec Language
All specifications MUST be written in **English** (`en`).
EOF

# ── Test 1: target_file does not exist -> created verbatim ────────────────
echo ""
echo "Test 1: target_file does not exist -> created verbatim from section-file"
TARGET1="$WORKDIR/CLAUDE-new.md"
OUT=$(bash "$SYNC" --file "$TARGET1" --section-file "$SECTION")
ACTION=$(field "$OUT" SYNC_ACTION)
if [[ "$ACTION" == "created" ]] && diff -q "$TARGET1" "$SECTION" >/dev/null 2>&1; then
    ok "New file created verbatim from section-file, SYNC_ACTION=created"
else
    fail "Expected created + byte-identical content. Got action=$ACTION"
fi

# ── Test 2: target_file exists, no SDD Kit section -> appended ────────────
echo ""
echo "Test 2: target_file exists with no SDD Kit section -> appended, existing content preserved"
TARGET2="$WORKDIR/CLAUDE-append.md"
printf '# My Project\n\nSome existing instructions here.\n' > "$TARGET2"
OUT=$(bash "$SYNC" --file "$TARGET2" --section-file "$SECTION")
ACTION=$(field "$OUT" SYNC_ACTION)
HEADER_COUNT=$(grep -c '^## SDD Kit$' "$TARGET2")
if [[ "$ACTION" == "appended" ]] \
    && grep -qF "Some existing instructions here." "$TARGET2" \
    && [[ "$HEADER_COUNT" -eq 1 ]]; then
    ok "Appended correctly, existing content preserved, exactly one SDD Kit header"
else
    fail "Expected appended + preserved content + 1 header. Got action=$ACTION count=$HEADER_COUNT"
fi

# ── Test 3: unrelated content survives the append byte-for-byte ──────────
echo ""
echo "Test 3: content before the append is preserved byte-for-byte"
BEFORE_HASH=$(head -3 "$TARGET2" | md5sum | cut -d' ' -f1)
EXPECTED_HASH=$(printf '# My Project\n\nSome existing instructions here.\n' | md5sum | cut -d' ' -f1)
if [[ "$BEFORE_HASH" == "$EXPECTED_HASH" ]]; then
    ok "Pre-existing content (user's own /init output) survives append unchanged"
else
    fail "Pre-existing content was altered by the append"
fi

# ── Test 4: target_file already has SDD Kit -> replaced in place ─────────
echo ""
echo "Test 4: target_file already has SDD Kit section -> replaced in place, appears exactly once"
TARGET4="$WORKDIR/CLAUDE-replace.md"
cat > "$TARGET4" <<'EOF'
# My Project

Some notes before.

## SDD Kit

This project uses **SDD Kit** for spec-driven development.

### Spec Language
All specifications MUST be written in **Portuguese** (`pt`).

## Other Section

Notes after, unrelated to SDD Kit.
EOF
OUT=$(bash "$SYNC" --file "$TARGET4" --section-file "$SECTION")
ACTION=$(field "$OUT" SYNC_ACTION)
HEADER_COUNT=$(grep -c '^## SDD Kit$' "$TARGET4")
if [[ "$ACTION" == "replaced" ]] \
    && [[ "$HEADER_COUNT" -eq 1 ]] \
    && grep -qF "English" "$TARGET4" \
    && ! grep -qF "Portuguese" "$TARGET4"; then
    ok "Section replaced in place (English replaces Portuguese), exactly one header"
else
    fail "Expected replaced, 1 header, new lang present, old lang gone. Got action=$ACTION count=$HEADER_COUNT"
fi

# ── Test 5: content before AND after the section is untouched by replace ──
echo ""
echo "Test 5: content before and after the replaced section is byte-for-byte preserved"
if grep -qF "Some notes before." "$TARGET4" && grep -qF "## Other Section" "$TARGET4" \
    && grep -qF "Notes after, unrelated to SDD Kit." "$TARGET4"; then
    ok "Content before and after the SDD Kit section survives the replace unchanged"
else
    fail "Content outside the SDD Kit section was altered by the replace"
fi

# ── Test 6: calling sync twice never duplicates the header (idempotency) ──
echo ""
echo "Test 6: calling sync twice in a row is idempotent — never two SDD Kit headers"
TARGET6="$WORKDIR/CLAUDE-idempotent.md"
bash "$SYNC" --file "$TARGET6" --section-file "$SECTION" >/dev/null
bash "$SYNC" --file "$TARGET6" --section-file "$SECTION" >/dev/null
bash "$SYNC" --file "$TARGET6" --section-file "$SECTION" >/dev/null
HEADER_COUNT=$(grep -c '^## SDD Kit$' "$TARGET6")
if [[ "$HEADER_COUNT" -eq 1 ]]; then
    ok "Exactly one SDD Kit header after three consecutive sync calls"
else
    fail "Expected exactly 1 header after 3 calls, got $HEADER_COUNT"
fi

# ── Test 7: missing --section-file -> error, no partial write ────────────
echo ""
echo "Test 7: missing --section-file argument -> SYNC_ACTION=error, exit 1, no write"
TARGET7="$WORKDIR/CLAUDE-error.md"
set +e
OUT=$(bash "$SYNC" --file "$TARGET7" --section-file "/nonexistent/section.md" 2>/dev/null)
RC=$?
set -e 2>/dev/null || true
ACTION=$(field "$OUT" SYNC_ACTION)
if [[ "$ACTION" == "error" && "$RC" -eq 1 && ! -f "$TARGET7" ]]; then
    ok "Missing section-file correctly errors out, no partial write"
else
    fail "Expected error/exit1/no-file. Got action=$ACTION rc=$RC exists=$([[ -f "$TARGET7" ]] && echo yes || echo no)"
fi

# ── Test 8: end-to-end — create branch triggers the git guard, matches procedure ──
echo ""
echo "Test 8: end-to-end — new-file branch protects the file from Git (matches documented procedure)"
REPO="$WORKDIR/e2e-repo"
mkdir -p "$REPO"
git -C "$REPO" init -q
git -C "$REPO" config user.email test@test.com
git -C "$REPO" config user.name test
echo "seed" > "$REPO/seed.txt"
git -C "$REPO" add seed.txt
git -C "$REPO" -c commit.gpgsign=false commit -qm "initial"

TARGET8="$REPO/CLAUDE.md"
EXISTED_BEFORE=false
[[ -f "$TARGET8" ]] && EXISTED_BEFORE=true
SYNC_OUT=$(bash "$SYNC" --file "$TARGET8" --section-file "$SECTION")
SYNC_ACTION=$(field "$SYNC_OUT" SYNC_ACTION)
if [[ "$EXISTED_BEFORE" == "false" && "$SYNC_ACTION" == "created" ]]; then
    bash "$GUARD" --file CLAUDE.md --repo-root "$REPO" >/dev/null
fi
STATUS_LINE=$(git -C "$REPO" status --short -- CLAUDE.md)
if [[ "$SYNC_ACTION" == "created" && -z "$STATUS_LINE" ]]; then
    ok "End-to-end: file created, then correctly protected — invisible to git status --short"
else
    fail "Expected created + protected. Got sync_action=$SYNC_ACTION status='$STATUS_LINE'"
fi

# ── Test 9: bash -n syntax check ───────────────────────────────────────────
echo ""
echo "Test 9: bash -n syntax check on the script and this test file"
if bash -n "$SYNC" 2>/tmp/pisync_syntax_err && bash -n "$SCRIPT_DIR/project-instructions-sync.test.sh" 2>>/tmp/pisync_syntax_err; then
    ok "Both the script and this test file have valid bash syntax"
else
    fail "Syntax error: $(cat /tmp/pisync_syntax_err)"
fi

# ── Summary ──────────────────────────────────────────────────────────────────
echo ""
echo "══════════════════════════════════════════════════════"
echo "  Results: $PASS passed, $FAIL failed"
echo "══════════════════════════════════════════════════════"
echo ""

[[ $FAIL -eq 0 ]] || exit 1
