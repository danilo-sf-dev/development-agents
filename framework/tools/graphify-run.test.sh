#!/bin/bash
# graphify-run.test.sh — focused tests for graphify-run.sh, the ONE canonical, safe way
# to invoke Graphify (framework/_shared/graphify-context.md § "Invocation").
#
# ZERO-DEPENDENCY: no python/jq needed to run these tests themselves. No real Graphify
# binary, no API call, no LLM call — every scenario uses a small fake executable placed
# on PATH via a scratch directory.
#
# Covers the 6 required scenarios plus argument-passthrough correctness:
#   A. plain `graphify` on PATH
#   B. `python -m graphify`
#   C. `python3 -m graphify`
#   D. resolved Windows executable WITHOUT a space in its path
#   E. resolved Windows executable WITH a space in its path — the actual bug being fixed
#   F. argument shapes: query "<multi-word question>", path Foo Bar, extract . --code-only,
#      update . — confirmed to arrive at the real Graphify invocation EXACTLY as given,
#      with correct argument COUNT and boundaries (no merging, no splitting)
#
# Usage: bash graphify-run.test.sh
# Exit: 0 if all pass, nonzero otherwise

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RUN="$SCRIPT_DIR/graphify-run.sh"
SCRATCH="$(mktemp -d)"
trap 'rm -rf "$SCRATCH"' EXIT

PASS=0; FAIL=0
ok()   { echo "  PASS: $1"; PASS=$((PASS+1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

# A mock Graphify executable that echoes back exactly what it received — argc and each
# argument on its own bracketed line — so tests can assert on both count and boundaries.
make_echo_mock() {
    local path="$1"
    mkdir -p "$(dirname "$path")"
    cat > "$path" <<'EOF'
#!/bin/bash
[[ "$1" == "--version" ]] && { echo "graphify mock"; exit 0; }
echo "ARGC=$#"
for a in "$@"; do echo "ARG=[$a]"; done
exit 0
EOF
    chmod +x "$path"
}

echo ""
echo "══════════════════════════════════════════════════════"
echo "  graphify-run.sh tests"
echo "══════════════════════════════════════════════════════"

# ── Scenario A: plain graphify on PATH ──────────────────────────────────────
echo ""
echo "Scenario A: plain 'graphify' on PATH"
MOCKA="$SCRATCH/a"
make_echo_mock "$MOCKA/graphify"
OUTA=$(PATH="$MOCKA:/usr/bin:/bin" bash "$RUN" --version)
if [[ "$OUTA" == "graphify mock" ]]; then
    ok "Scenario A: plain graphify invoked correctly"
else
    fail "Scenario A failed: $OUTA"
fi

# ── Scenario B: python -m graphify ──────────────────────────────────────────
echo ""
echo "Scenario B: python -m graphify"
MOCKB="$SCRATCH/b"
mkdir -p "$MOCKB"
cat > "$MOCKB/python" <<'EOF'
#!/bin/bash
if [[ "$1" == "-m" && "$2" == "graphify" ]]; then
    shift 2
    [[ "$1" == "--version" ]] && { echo "graphify mock (python -m)"; exit 0; }
    echo "ARGC=$#"
    for a in "$@"; do echo "ARG=[$a]"; done
    exit 0
fi
exit 1
EOF
chmod +x "$MOCKB/python"
OUTB=$(PATH="$MOCKB:/usr/bin:/bin" bash "$RUN" --version)
if [[ "$OUTB" == "graphify mock (python -m)" ]]; then
    ok "Scenario B: python -m graphify invoked correctly"
else
    fail "Scenario B failed: $OUTB"
fi

# ── Scenario C: python3 -m graphify ─────────────────────────────────────────
echo ""
echo "Scenario C: python3 -m graphify"
MOCKC="$SCRATCH/c"
mkdir -p "$MOCKC"
cat > "$MOCKC/python3" <<'EOF'
#!/bin/bash
if [[ "$1" == "-m" && "$2" == "graphify" ]]; then
    shift 2
    [[ "$1" == "--version" ]] && { echo "graphify mock (python3 -m)"; exit 0; }
    echo "ARGC=$#"
    for a in "$@"; do echo "ARG=[$a]"; done
    exit 0
fi
exit 1
EOF
chmod +x "$MOCKC/python3"
OUTC=$(PATH="$MOCKC:/usr/bin:/bin" bash "$RUN" --version)
if [[ "$OUTC" == "graphify mock (python3 -m)" ]]; then
    ok "Scenario C: python3 -m graphify invoked correctly"
else
    fail "Scenario C failed: $OUTC"
fi

# ── Scenario D: resolved Windows executable, NO space in path ──────────────
echo ""
echo "Scenario D: resolved Windows executable path without a space"
MOCKD="$SCRATCH/d"
mkdir -p "$MOCKD"
cat > "$MOCKD/graphify" <<'EOF'
#!/bin/bash
exit 1
EOF
chmod +x "$MOCKD/graphify"
make_echo_mock "$MOCKD/nospacepath/graphify.exe"
cat > "$MOCKD/cmd.exe" <<EOF
#!/bin/bash
if [[ "\$1" == "//c" && "\$2" == "where" && "\$3" == "graphify" ]]; then
    printf 'C:\\\\FAKE\\\\nospacepath\\\\graphify.exe\r\n'
    exit 0
fi
exit 1
EOF
chmod +x "$MOCKD/cmd.exe"
cat > "$MOCKD/cygpath" <<EOF
#!/bin/bash
[[ "\$1" == "-u" ]] && { echo "$MOCKD/nospacepath/graphify.exe"; exit 0; }
exit 1
EOF
chmod +x "$MOCKD/cygpath"
OUTD=$(PATH="$MOCKD:/usr/bin:/bin" bash "$RUN" --version)
if [[ "$OUTD" == "graphify mock" ]]; then
    ok "Scenario D: resolved Windows executable (no space) invoked correctly"
else
    fail "Scenario D failed: $OUTD"
fi

# ── Scenario E: resolved Windows executable WITH a space in its path ───────
# The actual bug being fixed: "C:\Users\Jane Doe\.local\bin\graphify.exe"-style path.
echo ""
echo "Scenario E: resolved Windows executable WITH a space in its path"
MOCKE="$SCRATCH/e"
mkdir -p "$MOCKE"
cat > "$MOCKE/graphify" <<'EOF'
#!/bin/bash
exit 1
EOF
chmod +x "$MOCKE/graphify"
make_echo_mock "$MOCKE/Jane Doe/.local/bin/graphify.exe"
cat > "$MOCKE/cmd.exe" <<EOF
#!/bin/bash
if [[ "\$1" == "//c" && "\$2" == "where" && "\$3" == "graphify" ]]; then
    printf 'C:\\\\FAKE\\\\Jane Doe\\\\.local\\\\bin\\\\graphify.exe\r\n'
    exit 0
fi
exit 1
EOF
chmod +x "$MOCKE/cmd.exe"
cat > "$MOCKE/cygpath" <<EOF
#!/bin/bash
[[ "\$1" == "-u" ]] && { echo "$MOCKE/Jane Doe/.local/bin/graphify.exe"; exit 0; }
exit 1
EOF
chmod +x "$MOCKE/cygpath"
OUTE=$(PATH="$MOCKE:/usr/bin:/bin" bash "$RUN" --version)
if [[ "$OUTE" == "graphify mock" ]]; then
    ok "Scenario E: resolved Windows executable WITH a space invoked correctly (the fix)"
else
    fail "Scenario E failed (space-in-path bug): $OUTE"
fi

# ── Scenario F: argument shapes arrive exactly as expected ─────────────────
# Reuse Scenario E's spaced-path executable — the harder case — for all sub-cases, since
# a passthrough bug would be most likely to surface there.
echo ""
echo "Scenario F: argument shapes (spaced-path executable)"

echo ""
echo "  F1: query \"payment calculation flow\" (one multi-word argument)"
OUTF1=$(PATH="$MOCKE:/usr/bin:/bin" bash "$RUN" query "payment calculation flow")
EXPECTED_F1=$'ARGC=2\nARG=[query]\nARG=[payment calculation flow]'
if [[ "$OUTF1" == "$EXPECTED_F1" ]]; then
    ok "F1: multi-word query argument arrives as ONE argument, not split"
else
    fail "F1 failed. Got:
$OUTF1
Expected:
$EXPECTED_F1"
fi

echo ""
echo "  F2: path Foo Bar (two separate arguments)"
OUTF2=$(PATH="$MOCKE:/usr/bin:/bin" bash "$RUN" path Foo Bar)
EXPECTED_F2=$'ARGC=3\nARG=[path]\nARG=[Foo]\nARG=[Bar]'
if [[ "$OUTF2" == "$EXPECTED_F2" ]]; then
    ok "F2: 'path Foo Bar' arrives as three separate arguments, not merged"
else
    fail "F2 failed. Got:
$OUTF2
Expected:
$EXPECTED_F2"
fi

echo ""
echo "  F3: extract . --code-only"
OUTF3=$(PATH="$MOCKE:/usr/bin:/bin" bash "$RUN" extract . --code-only)
EXPECTED_F3=$'ARGC=3\nARG=[extract]\nARG=[.]\nARG=[--code-only]'
if [[ "$OUTF3" == "$EXPECTED_F3" ]]; then
    ok "F3: 'extract . --code-only' arrives with exact argument boundaries"
else
    fail "F3 failed. Got:
$OUTF3
Expected:
$EXPECTED_F3"
fi

echo ""
echo "  F4: update ."
OUTF4=$(PATH="$MOCKE:/usr/bin:/bin" bash "$RUN" update .)
EXPECTED_F4=$'ARGC=2\nARG=[update]\nARG=[.]'
if [[ "$OUTF4" == "$EXPECTED_F4" ]]; then
    ok "F4: 'update .' arrives with exact argument boundaries"
else
    fail "F4 failed. Got:
$OUTF4
Expected:
$EXPECTED_F4"
fi

# Also confirm F1-F4 work identically through the python -m tier (Scenario B's mock),
# proving the two-word prefix ("-m graphify") composes correctly with real args too.
echo ""
echo "  F5: query \"multi word\" through python -m graphify (prefix + real args compose)"
OUTF5=$(PATH="$MOCKB:/usr/bin:/bin" bash "$RUN" query "multi word question")
EXPECTED_F5=$'ARGC=2\nARG=[query]\nARG=[multi word question]'
if [[ "$OUTF5" == "$EXPECTED_F5" ]]; then
    ok "F5: prefix args (-m graphify) + real args compose correctly, no cross-contamination"
else
    fail "F5 failed. Got:
$OUTF5
Expected:
$EXPECTED_F5"
fi

# ── Exit code passthrough ────────────────────────────────────────────────────
echo ""
echo "Exit code: passes through the real Graphify invocation's own exit code"
MOCKRC="$SCRATCH/rc"
mkdir -p "$MOCKRC"
cat > "$MOCKRC/graphify" <<'EOF'
#!/bin/bash
[[ "$1" == "--version" ]] && { echo "ok"; exit 0; }
[[ "$1" == "fail-me" ]] && exit 42
exit 1
EOF
chmod +x "$MOCKRC/graphify"
PATH="$MOCKRC:/usr/bin:/bin" bash "$RUN" fail-me >/dev/null 2>&1
RC=$?
if [[ $RC -eq 42 ]]; then
    ok "Exit code 42 from the real invocation passed through unchanged"
else
    fail "Expected exit 42, got $RC"
fi

# ── Unavailable case: exit 127, no crash ─────────────────────────────────────
echo ""
echo "Unavailable: no graphify/python/python3/cmd.exe anywhere → exit 127, no crash"
MOCKNONE="$SCRATCH/none"
mkdir -p "$MOCKNONE"
PATH="$MOCKNONE:/usr/bin:/bin" bash "$RUN" --version >/dev/null 2>/dev/null
RC_NONE=$?
if [[ $RC_NONE -eq 127 ]]; then
    ok "Unavailable case: exit 127, no crash"
else
    fail "Expected exit 127 when unavailable, got $RC_NONE"
fi

# ── bash -n syntax check ─────────────────────────────────────────────────────
echo ""
echo "bash -n syntax check"
if bash -n "$RUN" 2>"$SCRATCH/syntax_err"; then
    ok "graphify-run.sh has valid bash syntax"
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
