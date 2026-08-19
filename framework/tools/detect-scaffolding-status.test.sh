#!/bin/bash
# detect-scaffolding-status.test.sh — real execution tests for
# framework/tools/detect-scaffolding-status.sh, including the `has_baseline` field that backs
# /sdd.project's Next-Command Navigation rule (commands/sdd.project.md).
#
# A real E2E run found /sdd.project recommending /sdd.start for a brownfield project with no
# reverse-eng/spec baseline at all — a footnote inside a Model Routing line, not a real decision.
# These tests build real directory/git fixtures and run the actual script — behavior tests, not
# markdown grep.
#
# Tests:
#   1.  Greenfield: empty dir, 0 commits, no specs -> project_mode=greenfield, has_baseline=false
#       -> navigation rule recommends /sdd.start
#   2.  Brownfield without baseline: real app code (pom.xml, src/), commits exist, no sdd/specs
#       or sdd/extracted -> project_mode=brownfield, has_baseline=false
#       -> navigation rule recommends /sdd.reverse-eng
#   3.  Brownfield with baseline via sdd/specs/ -> project_mode=brownfield, has_baseline=true
#       -> navigation rule recommends /sdd.start
#   4.  Brownfield with baseline via sdd/extracted/ only (reverse-eng ran, never promoted) ->
#       has_baseline=true even without sdd/specs/
#   5.  Empty sdd/specs/ and sdd/extracted/ directories (present but empty) do NOT count as a
#       baseline -> has_baseline=false
#   6.  sdd/features/ alone (archived completed work, no active specs) does NOT set
#       has_baseline=true — distinct signal from HAS_SPECS_OR_FEATURES
#   7.  bash -n syntax check
#
# Usage: bash detect-scaffolding-status.test.sh
# Exit: 0 if all pass, nonzero otherwise

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DETECT="$SCRIPT_DIR/detect-scaffolding-status.sh"

PASS=0; FAIL=0
ok()   { echo "  PASS: $1"; PASS=$((PASS+1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

WORKDIR=$(mktemp -d)
cleanup() { rm -rf "$WORKDIR"; }
trap cleanup EXIT

field() {
    printf '%s' "$1" | grep -oE "\"$2\":(true|false|\"[^\"]*\")" | head -1 | cut -d: -f2-
}

# Navigation rule under test (mirrors commands/sdd.project.md § Next-Command Navigation)
recommend_next() {
    local mode="$1" baseline="$2"
    if [[ "$mode" == '"greenfield"' ]]; then
        echo "/sdd.start"
    elif [[ "$mode" == '"brownfield"' && "$baseline" == "false" ]]; then
        echo "/sdd.reverse-eng"
    elif [[ "$mode" == '"brownfield"' && "$baseline" == "true" ]]; then
        echo "/sdd.start"
    else
        echo "UNKNOWN"
    fi
}

echo ""
echo "══════════════════════════════════════════════════════"
echo "  detect-scaffolding-status.sh — real execution tests"
echo "══════════════════════════════════════════════════════"

# ── Test 1: greenfield -> recommend /sdd.start ─────────────────────────────
echo ""
echo "Test 1: greenfield (empty dir) -> project_mode=greenfield, has_baseline=false, recommend /sdd.start"
G="$WORKDIR/greenfield"
mkdir -p "$G"
OUT=$(bash "$DETECT" "$G" --json)
MODE=$(field "$OUT" project_mode)
BASELINE=$(field "$OUT" has_baseline)
REC=$(recommend_next "$MODE" "$BASELINE")
if [[ "$MODE" == '"greenfield"' && "$BASELINE" == "false" && "$REC" == "/sdd.start" ]]; then
    ok "Greenfield correctly recommends /sdd.start"
else
    fail "Expected greenfield/false/sdd.start. Got mode=$MODE baseline=$BASELINE rec=$REC"
fi

# ── Test 2: brownfield, no baseline -> recommend /sdd.reverse-eng ─────────
echo ""
echo "Test 2: brownfield without baseline (real app code, no specs/extracted) -> recommend /sdd.reverse-eng"
B1="$WORKDIR/brownfield-nobaseline"
mkdir -p "$B1/src"
echo "<project/>" > "$B1/pom.xml"
git -C "$B1" init -q
git -C "$B1" config user.email test@test.com
git -C "$B1" config user.name test
echo "code" > "$B1/src/App.java"
git -C "$B1" add pom.xml src/App.java
git -C "$B1" -c commit.gpgsign=false commit -qm "initial"
echo "more code" >> "$B1/src/App.java"
git -C "$B1" add src/App.java
git -C "$B1" -c commit.gpgsign=false commit -qm "second commit"
OUT=$(bash "$DETECT" "$B1" --json)
MODE=$(field "$OUT" project_mode)
BASELINE=$(field "$OUT" has_baseline)
REC=$(recommend_next "$MODE" "$BASELINE")
if [[ "$MODE" == '"brownfield"' && "$BASELINE" == "false" && "$REC" == "/sdd.reverse-eng" ]]; then
    ok "Brownfield without baseline correctly recommends /sdd.reverse-eng"
else
    fail "Expected brownfield/false/sdd.reverse-eng. Got mode=$MODE baseline=$BASELINE rec=$REC"
fi

# ── Test 3: brownfield with sdd/specs/ baseline -> recommend /sdd.start ──
echo ""
echo "Test 3: brownfield with sdd/specs/ baseline -> recommend /sdd.start"
B2="$WORKDIR/brownfield-specs"
mkdir -p "$B2/sdd/specs"
echo "# Functional Spec" > "$B2/sdd/specs/functional-spec.md"
OUT=$(bash "$DETECT" "$B2" --json)
MODE=$(field "$OUT" project_mode)
BASELINE=$(field "$OUT" has_baseline)
REC=$(recommend_next "$MODE" "$BASELINE")
if [[ "$MODE" == '"brownfield"' && "$BASELINE" == "true" && "$REC" == "/sdd.start" ]]; then
    ok "Brownfield with sdd/specs/ baseline correctly recommends /sdd.start"
else
    fail "Expected brownfield/true/sdd.start. Got mode=$MODE baseline=$BASELINE rec=$REC"
fi

# ── Test 4: baseline via sdd/extracted/ only (never promoted) ────────────
echo ""
echo "Test 4: sdd/extracted/ alone (reverse-eng ran, never promoted) counts as baseline=true"
B3="$WORKDIR/brownfield-extracted-only"
mkdir -p "$B3/sdd/extracted"
echo "# Detection Report" > "$B3/sdd/extracted/DETECTION_REPORT.md"
OUT=$(bash "$DETECT" "$B3" --json)
BASELINE=$(field "$OUT" has_baseline)
if [[ "$BASELINE" == "true" ]]; then
    ok "sdd/extracted/ alone correctly counts as has_baseline=true"
else
    fail "Expected has_baseline=true from sdd/extracted/ alone. Got: $OUT"
fi

# ── Test 5: empty sdd/specs/ and sdd/extracted/ do NOT count as baseline ──
echo ""
echo "Test 5: empty sdd/specs/ and sdd/extracted/ directories do not count as a baseline"
B4="$WORKDIR/brownfield-empty-dirs"
mkdir -p "$B4/sdd/specs" "$B4/sdd/extracted" "$B4/src"
touch "$B4/pom.xml"
OUT=$(bash "$DETECT" "$B4" --json)
BASELINE=$(field "$OUT" has_baseline)
if [[ "$BASELINE" == "false" ]]; then
    ok "Empty sdd/specs/ and sdd/extracted/ correctly do NOT count as a baseline"
else
    fail "Expected has_baseline=false for empty dirs. Got: $OUT"
fi

# ── Test 6: sdd/features/ alone does not set has_baseline ────────────────
echo ""
echo "Test 6: sdd/features/ alone (archived work, no active specs) does not set has_baseline=true"
B5="$WORKDIR/brownfield-features-only"
mkdir -p "$B5/sdd/features/20260101-old-feature"
echo "# Old feature" > "$B5/sdd/features/20260101-old-feature/README.md"
OUT=$(bash "$DETECT" "$B5" --json)
MODE=$(field "$OUT" project_mode)
BASELINE=$(field "$OUT" has_baseline)
if [[ "$MODE" == '"brownfield"' && "$BASELINE" == "false" ]]; then
    ok "sdd/features/ alone: project_mode=brownfield (correct) but has_baseline=false (distinct signal)"
else
    fail "Expected brownfield/false. Got mode=$MODE baseline=$BASELINE"
fi

# ── Test 7: bash -n syntax check ──────────────────────────────────────────
echo ""
echo "Test 7: bash -n syntax check on the script and this test file"
if bash -n "$DETECT" 2>/tmp/scaffold_syntax_err && bash -n "$SCRIPT_DIR/detect-scaffolding-status.test.sh" 2>>/tmp/scaffold_syntax_err; then
    ok "Both the script and this test file have valid bash syntax"
else
    fail "Syntax error: $(cat /tmp/scaffold_syntax_err)"
fi

# ── Summary ──────────────────────────────────────────────────────────────────
echo ""
echo "══════════════════════════════════════════════════════"
echo "  Results: $PASS passed, $FAIL failed"
echo "══════════════════════════════════════════════════════"
echo ""

[[ $FAIL -eq 0 ]] || exit 1
