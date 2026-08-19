#!/bin/bash
# detect-graphify.test.sh — focused tests for detect-graphify.sh (detection + capability
# probing only). Git-safety mechanics live in graphify-git-guard.sh and are tested in
# graphify-git-guard.test.sh — not duplicated here.
#
# ZERO-DEPENDENCY: no python/jq required to run these tests. No real Graphify binary,
# no API call, no LLM call — every scenario uses a small fake executable placed on PATH
# via a scratch directory.
#
# Tests:
#   1.  graphify CLI detected (tier A: real `graphify --version` succeeds), full capabilities
#   2.  graphify absent, python -m graphify fallback detected (tier C)
#   3.  graphify + python absent, python3 -m graphify fallback detected (tier D)
#   4.  nothing available anywhere on PATH → GRAPHIFY_AVAILABLE=false, exit 0
#   5.  REGRESSION (real Windows false-negative): --code-only absent from --help text but
#       extract subcommand genuinely exists → GRAPHIFY_CODE_ONLY=unknown, never false;
#       also proves the real `extract --code-only` call succeeds independent of --help text
#   5b. genuine false: extract subcommand itself doesn't respond to --help
#   6.  capability flags (query/path/explain/update) individually false when absent from --help
#   7.  script always exits 0 regardless of scenario (never a hard failure)
#   8.  --json output is well-formed; code_only is a JSON STRING ("true"/"unknown"/"false"),
#       never a bare boolean, since it is a tri-state
#   9.  zero-dependency proof: python and python3 both absent from PATH entirely →
#       script still runs cleanly and reports unavailable (no crash, no hang)
#  10.  bash -n syntax check on detect-graphify.sh
#  11.  REAL SCENARIO — Caso A (personal Windows PC): `graphify` on PATH is a broken uv
#       trampoline (command -v succeeds, --version fails); tier B recovers by asking a real
#       `cmd.exe` where the actual executable lives and running that instead — proves
#       "command -v alone is not enough" and "real execution is the only proof that counts"
#  12.  REAL SCENARIO — Caso B (corporate PC): no standalone binary reachable at all
#       (`graphify` absent, tier B's `cmd.exe` absent too) but `python -m graphify --version`
#       genuinely works → accepted normally via tier C, no Windows-specific assumption forced
#  13.  tier B present but finds nothing (cmd.exe reachable, `where` finds no match) → falls
#       through cleanly to tier C, exactly like tier A's own failure does — no special-casing
#
# Usage: bash detect-graphify.test.sh
# Exit: 0 if all pass, nonzero otherwise

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DETECT="$SCRIPT_DIR/detect-graphify.sh"
SCRATCH="$(mktemp -d)"
trap 'rm -rf "$SCRATCH"' EXIT

# Absolute path to bash itself — needed because tests 4/9 deliberately set PATH to a
# directory with nothing in it (to simulate a fully empty environment); a bare `bash`
# invocation would then fail to resolve "bash" via the very PATH being tested.
BASH_BIN="$(command -v bash)"

PASS=0; FAIL=0
ok()   { echo "  PASS: $1"; PASS=$((PASS+1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

field() {
    # $1=KEY=value-style output  $2=KEY
    printf '%s\n' "$1" | grep "^$2=" | cut -d= -f2-
}

echo ""
echo "══════════════════════════════════════════════════════"
echo "  detect-graphify.sh tests"
echo "══════════════════════════════════════════════════════"

# ── Test 1: tier A — graphify CLI detected, full capabilities ─────────────
echo ""
echo "Test 1: graphify CLI detected (tier A), full capabilities"
MOCK1="$SCRATCH/mock1"
mkdir -p "$MOCK1"
cat > "$MOCK1/graphify" <<'EOF'
#!/bin/bash
[[ "$1" == "--version" ]] && { echo "graphify 2.1.0"; exit 0; }
[[ "$1" == "extract" && "$2" == "--help" ]] && { echo "Usage: extract [--code-only] [--cluster-only]"; exit 0; }
[[ "$1" == "--help" ]] && { echo "Commands: query, path, explain, update, extract"; exit 0; }
exit 1
EOF
chmod +x "$MOCK1/graphify"
OUT1=$(PATH="$MOCK1:/usr/bin:/bin" bash "$DETECT")
if [[ "$(field "$OUT1" GRAPHIFY_AVAILABLE)" == "true" ]] && \
   [[ "$(field "$OUT1" GRAPHIFY_CMD)" == "graphify" ]] && \
   [[ "$(field "$OUT1" GRAPHIFY_CODE_ONLY)" == "true" ]] && \
   [[ "$(field "$OUT1" GRAPHIFY_QUERY)" == "true" ]] && \
   [[ "$(field "$OUT1" GRAPHIFY_UPDATE)" == "true" ]]; then
    ok "Tier A detected: cmd=graphify, code_only=true, query=true, update=true"
else
    fail "Tier A detection wrong: $OUT1"
fi

# ── Test 2: tier C — python -m graphify fallback ────────────────────────────
echo ""
echo "Test 2: python -m graphify fallback (tier C), graphify absent"
MOCK2="$SCRATCH/mock2"
mkdir -p "$MOCK2"
cat > "$MOCK2/python" <<'EOF'
#!/bin/bash
if [[ "$1" == "-m" && "$2" == "graphify" ]]; then
    shift 2
    [[ "$1" == "--version" ]] && { echo "graphify 1.0.0 (module)"; exit 0; }
    [[ "$1" == "extract" && "$2" == "--help" ]] && { echo "Usage: extract [--code-only]"; exit 0; }
    [[ "$1" == "--help" ]] && { echo "Commands: query, update"; exit 0; }
fi
exit 1
EOF
chmod +x "$MOCK2/python"
OUT2=$(PATH="$MOCK2:/usr/bin:/bin" bash "$DETECT")
if [[ "$(field "$OUT2" GRAPHIFY_AVAILABLE)" == "true" ]] && \
   [[ "$(field "$OUT2" GRAPHIFY_CMD)" == "python -m graphify" ]]; then
    ok "Tier C detected: cmd='python -m graphify'"
else
    fail "Tier C detection wrong: $OUT2"
fi

# ── Test 3: tier D — python3 -m graphify fallback ───────────────────────────
echo ""
echo "Test 3: python3 -m graphify fallback (tier D), graphify+python absent"
MOCK3="$SCRATCH/mock3"
mkdir -p "$MOCK3"
cat > "$MOCK3/python3" <<'EOF'
#!/bin/bash
if [[ "$1" == "-m" && "$2" == "graphify" ]]; then
    shift 2
    [[ "$1" == "--version" ]] && { echo "graphify 1.0.0 (module)"; exit 0; }
fi
exit 1
EOF
chmod +x "$MOCK3/python3"
OUT3=$(PATH="$MOCK3:/usr/bin:/bin" bash "$DETECT")
if [[ "$(field "$OUT3" GRAPHIFY_AVAILABLE)" == "true" ]] && \
   [[ "$(field "$OUT3" GRAPHIFY_CMD)" == "python3 -m graphify" ]]; then
    ok "Tier D detected: cmd='python3 -m graphify'"
else
    fail "Tier D detection wrong: $OUT3"
fi

# ── Test 4: nothing available → unavailable, exit 0 ─────────────────────────
echo ""
echo "Test 4: nothing available on PATH"
MOCK4="$SCRATCH/mock4_empty"
mkdir -p "$MOCK4"
OUT4=$(PATH="$MOCK4" "$BASH_BIN" "$DETECT")
RC4=$?
if [[ "$(field "$OUT4" GRAPHIFY_AVAILABLE)" == "false" ]] && [[ $RC4 -eq 0 ]]; then
    ok "Unavailable + exit 0 when PATH has no graphify/python/python3"
else
    fail "Expected unavailable+exit0, got rc=$RC4 out=$OUT4"
fi

# ── Test 5: --code-only not mentioned in --help → UNKNOWN, never a false negative ──
# Regression test for the exact real-world case found on Windows: `extract --help`
# responds cleanly (exit 0, extract subcommand genuinely exists) but its text never
# mentions `--code-only`, even though `extract . --code-only` itself works fine on that
# install. Help text is not a reliable oracle for this flag — a missing mention must
# report `unknown`, never `false`, so the preflight (graphify-context.md § 4) is never
# blocked in advance by a false negative. The real capability test is the actual
# `extract . --code-only` call made later, only when the user authorizes it — this
# script must never attempt that call itself just to answer this probe (it would
# create/alter graphify-out/ in the target project as a side effect of detection).
echo ""
echo "Test 5: --code-only absent from --help text → GRAPHIFY_CODE_ONLY=unknown (not false)"
MOCK5="$SCRATCH/mock5"
mkdir -p "$MOCK5"
cat > "$MOCK5/graphify" <<'EOF'
#!/bin/bash
[[ "$1" == "--version" ]] && { echo "graphify 2.3.0"; exit 0; }
[[ "$1" == "extract" && "$2" == "--help" ]] && { echo "Usage: graphify extract [PATH]"; echo "Extract a code graph from the given path."; exit 0; }
[[ "$1" == "--help" ]] && { echo "Commands: query, path, explain, update, extract"; exit 0; }
exit 1
EOF
chmod +x "$MOCK5/graphify"
OUT5=$(PATH="$MOCK5:/usr/bin:/bin" bash "$DETECT")
if [[ "$(field "$OUT5" GRAPHIFY_AVAILABLE)" == "true" ]] && \
   [[ "$(field "$OUT5" GRAPHIFY_CODE_ONLY)" == "unknown" ]]; then
    ok "code_only=unknown (not false) when --help doesn't mention --code-only but extract exists"
else
    fail "Expected available=true code_only=unknown (Windows false-negative regression): $OUT5"
fi

# Prove, independently, that the detector's static probe and the real capability are
# decoupled: the SAME mock's `extract --code-only` invocation (simulating the real,
# user-authorized call the preflight would make in Step 4.2) succeeds despite --help
# never mentioning the flag — confirming a caller that trusted "unknown" and proceeded
# to attempt the real extract would NOT have been wrongly blocked.
SCRATCH_TARGET="$SCRATCH/mock5_target"
mkdir -p "$SCRATCH_TARGET"
cat > "$MOCK5/graphify" <<'EOF'
#!/bin/bash
[[ "$1" == "--version" ]] && { echo "graphify 2.3.0"; exit 0; }
if [[ "$1" == "extract" && "$2" == "--help" ]]; then
    echo "Usage: graphify extract [PATH]"; echo "Extract a code graph from the given path."; exit 0
fi
[[ "$1" == "--help" ]] && { echo "Commands: query, path, explain, update, extract"; exit 0; }
if [[ "$1" == "extract" ]]; then
    # Real invocation: accepts --code-only even though --help never advertised it.
    for arg in "$@"; do [[ "$arg" == "--code-only" ]] && { echo '{"nodes":[]}' > "$2/graph.json" 2>/dev/null; exit 0; }; done
    exit 1
fi
exit 1
EOF
chmod +x "$MOCK5/graphify"
if PATH="$MOCK5:/usr/bin:/bin" graphify extract "$SCRATCH_TARGET" --code-only >/dev/null 2>&1; then
    ok "Real 'extract --code-only' call succeeds despite --help not mentioning it — unknown correctly did not block this flow"
else
    fail "Real extract --code-only call unexpectedly failed in the mock — test setup broken"
fi

# ── Test 5b: genuine false — extract subcommand itself doesn't respond ─────
echo ""
echo "Test 5b: extract subcommand itself absent → GRAPHIFY_CODE_ONLY=false"
MOCK5B="$SCRATCH/mock5b"
mkdir -p "$MOCK5B"
cat > "$MOCK5B/graphify" <<'EOF'
#!/bin/bash
[[ "$1" == "--version" ]] && { echo "graphify 0.1.0"; exit 0; }
[[ "$1" == "extract" && "$2" == "--help" ]] && { echo "Error: no such command 'extract'" >&2; exit 2; }
[[ "$1" == "--help" ]] && { echo "Commands: query"; exit 0; }
exit 1
EOF
chmod +x "$MOCK5B/graphify"
OUT5B=$(PATH="$MOCK5B:/usr/bin:/bin" bash "$DETECT")
if [[ "$(field "$OUT5B" GRAPHIFY_AVAILABLE)" == "true" ]] && \
   [[ "$(field "$OUT5B" GRAPHIFY_CODE_ONLY)" == "false" ]]; then
    ok "code_only=false correctly reported when extract --help itself fails (no extract command)"
else
    fail "Expected available=true code_only=false when extract subcommand is genuinely absent: $OUT5B"
fi

# ── Test 6: capability flags individually false when absent from --help ────
echo ""
echo "Test 6: query/path/explain/update individually absent"
MOCK6="$SCRATCH/mock6"
mkdir -p "$MOCK6"
cat > "$MOCK6/graphify" <<'EOF'
#!/bin/bash
[[ "$1" == "--version" ]] && { echo "graphify 2.0.0"; exit 0; }
[[ "$1" == "extract" && "$2" == "--help" ]] && { echo "Usage: extract [--code-only]"; exit 0; }
[[ "$1" == "--help" ]] && { echo "Commands: query"; exit 0; }
exit 1
EOF
chmod +x "$MOCK6/graphify"
OUT6=$(PATH="$MOCK6:/usr/bin:/bin" bash "$DETECT")
if [[ "$(field "$OUT6" GRAPHIFY_QUERY)" == "true" ]] && \
   [[ "$(field "$OUT6" GRAPHIFY_PATH)" == "false" ]] && \
   [[ "$(field "$OUT6" GRAPHIFY_EXPLAIN)" == "false" ]] && \
   [[ "$(field "$OUT6" GRAPHIFY_UPDATE)" == "false" ]]; then
    ok "Only 'query' true; path/explain/update correctly false"
else
    fail "Capability flags wrong: $OUT6"
fi

# ── Test 7: always exits 0 ───────────────────────────────────────────────────
echo ""
echo "Test 7: exit code always 0 across all scenarios above"
ALL_RC_OK=true
for MOCKDIR in "$MOCK1" "$MOCK2" "$MOCK3" "$MOCK4" "$MOCK5" "$MOCK5B" "$MOCK6"; do
    PATH="$MOCKDIR:/usr/bin:/bin" bash "$DETECT" >/dev/null 2>&1
    [[ $? -ne 0 ]] && ALL_RC_OK=false
done
if $ALL_RC_OK; then
    ok "exit 0 in every scenario tested"
else
    fail "Non-zero exit code found in at least one scenario"
fi

# ── Test 8: --json output well-formed ────────────────────────────────────────
echo ""
echo "Test 8: --json output well-formed"
OUT8=$(PATH="$MOCK1:/usr/bin:/bin" bash "$DETECT" --json)
if printf '%s' "$OUT8" | grep -qE '^\{"available":true,"cmd":"graphify","exec":"graphify","args":"","code_only":"true","query":true,"path":true,"explain":true,"update":true\}$'; then
    ok "JSON output matches expected shape: $OUT8"
else
    fail "JSON output malformed: $OUT8"
fi

# ── Test 9: zero-dependency proof — python/python3 both absent, no crash ───
echo ""
echo "Test 9: zero-dependency — python and python3 both absent from PATH"
MOCK9="$SCRATCH/mock9_no_python"
mkdir -p "$MOCK9"
# deliberately empty — no graphify, no python, no python3. No `timeout` dependency:
# every probe here is a `command -v` miss, which returns instantly, so a hang is not
# a realistic risk and adding `timeout` would itself be an extra, non-portable dependency.
OUT9=$(PATH="$MOCK9" "$BASH_BIN" "$DETECT")
RC9=$?
if [[ $RC9 -eq 0 ]] && [[ "$(field "$OUT9" GRAPHIFY_AVAILABLE)" == "false" ]]; then
    ok "No hang, no crash, clean unavailable report with zero interpreters on PATH"
else
    fail "Zero-dependency scenario failed: rc=$RC9 out=$OUT9"
fi

# ── Test 10: bash -n syntax check ────────────────────────────────────────────
echo ""
echo "Test 10: bash -n syntax check"
if bash -n "$DETECT" 2>"$SCRATCH/syntax_err"; then
    ok "detect-graphify.sh has valid bash syntax"
else
    fail "Syntax error in detect-graphify.sh: $(cat "$SCRATCH/syntax_err")"
fi

# Git-safety scenarios (Scenario A/B, staged-file correction, real `git check-ignore`) are
# covered by graphify-git-guard.test.sh against the real graphify-git-guard.sh script — not
# duplicated here as inline simulation.

# ── Test 11: Caso A — broken uv trampoline recovered via cmd.exe //c where ──────
# The exact real-world case reported from a personal Windows machine: `graphify` is on
# PATH (command -v succeeds) but `graphify --version` fails (a broken uv-installed
# trampoline/launcher). Tier B asks a real `cmd.exe` where the actual executable lives and
# runs THAT instead. This proves two things at once: (1) command -v alone is never
# sufficient — only a real successful --version execution counts; (2) the recovery path
# doesn't assume "Windows" from any OS check, it simply uses cmd.exe because it's reachable.
echo ""
echo "Test 11: Caso A — broken graphify trampoline recovered via cmd.exe where"
MOCK11="$SCRATCH/mock11"
mkdir -p "$MOCK11"

# Broken trampoline: found by command -v, but --version genuinely fails.
cat > "$MOCK11/graphify" <<'EOF'
#!/bin/bash
exit 1
EOF
chmod +x "$MOCK11/graphify"

# The real, working executable that `where` will "find".
cat > "$MOCK11/real_graphify.exe" <<'EOF'
#!/bin/bash
[[ "$1" == "--version" ]] && { echo "graphify 2.3.0 (real exe)"; exit 0; }
[[ "$1" == "extract" && "$2" == "--help" ]] && { echo "Usage: extract [PATH]"; exit 0; }
[[ "$1" == "--help" ]] && { echo "Commands: query, path, explain, update, extract"; exit 0; }
exit 1
EOF
chmod +x "$MOCK11/real_graphify.exe"

# cmd.exe mock: `//c where graphify` returns a native Windows path with CRLF, exactly
# like the real `where.exe` would.
cat > "$MOCK11/cmd.exe" <<EOF
#!/bin/bash
if [[ "\$1" == "//c" && "\$2" == "where" && "\$3" == "graphify" ]]; then
    printf 'C:\\\\FAKE\\\\graphify.exe\r\n'
    exit 0
fi
exit 1
EOF
chmod +x "$MOCK11/cmd.exe"

# cygpath mock: resolves the fake Windows path to our real mock executable.
cat > "$MOCK11/cygpath" <<EOF
#!/bin/bash
[[ "\$1" == "-u" ]] && { echo "$MOCK11/real_graphify.exe"; exit 0; }
exit 1
EOF
chmod +x "$MOCK11/cygpath"

OUT11=$(PATH="$MOCK11:/usr/bin:/bin" bash "$DETECT")
if [[ "$(field "$OUT11" GRAPHIFY_AVAILABLE)" == "true" ]] && \
   [[ "$(field "$OUT11" GRAPHIFY_CMD)" == "$MOCK11/real_graphify.exe" ]] && \
   [[ "$(field "$OUT11" GRAPHIFY_EXEC)" == "$MOCK11/real_graphify.exe" ]] && \
   [[ "$(field "$OUT11" GRAPHIFY_ARGS)" == "" ]] && \
   [[ "$(field "$OUT11" GRAPHIFY_QUERY)" == "true" ]]; then
    ok "Caso A: broken trampoline recovered — tier B resolved GRAPHIFY_EXEC to the real executable, GRAPHIFY_ARGS empty"
else
    fail "Caso A recovery failed: $OUT11"
fi

# ── Test 12: Caso B — corporate PC, no standalone binary, python -m graphify works ──
# The second real-world case: no `graphify` executable reachable at all (no trampoline,
# no cmd.exe/Windows executable to fall back to either), but `python -m graphify --version`
# genuinely works. Must be accepted normally via tier C — no forced Windows-only path.
echo ""
echo "Test 12: Caso B — no standalone binary, python -m graphify accepted normally"
MOCK12="$SCRATCH/mock12"
mkdir -p "$MOCK12"
cat > "$MOCK12/python" <<'EOF'
#!/bin/bash
if [[ "$1" == "-m" && "$2" == "graphify" ]]; then
    shift 2
    [[ "$1" == "--version" ]] && { echo "graphify 1.0.0 (module)"; exit 0; }
    [[ "$1" == "extract" && "$2" == "--help" ]] && { echo "Usage: extract [PATH]"; exit 0; }
    [[ "$1" == "--help" ]] && { echo "Commands: query, update"; exit 0; }
fi
exit 1
EOF
chmod +x "$MOCK12/python"
# No cmd.exe anywhere on this PATH — tier B is naturally unreachable, exactly like a
# real Linux/macOS corporate machine, or a Windows machine where `cmd.exe` itself isn't
# on PATH for some reason. No special-case needed either way.
OUT12=$(PATH="$MOCK12:/usr/bin:/bin" bash "$DETECT")
if [[ "$(field "$OUT12" GRAPHIFY_AVAILABLE)" == "true" ]] && \
   [[ "$(field "$OUT12" GRAPHIFY_CMD)" == "python -m graphify" ]]; then
    ok "Caso B: python -m graphify accepted normally via tier C, no cmd.exe involved"
else
    fail "Caso B failed: $OUT12"
fi

# ── Test 13: tier B reachable but finds nothing → clean fall-through to tier C ──
# cmd.exe is present and runs, but `where graphify` finds no match (empty output / nonzero
# exit) — must fall through to tier C exactly like tier A's own failure does, not treated
# as a hard stop just because the Windows-specific tier was attempted.
echo ""
echo "Test 13: cmd.exe present but finds nothing → falls through to tier C cleanly"
MOCK13="$SCRATCH/mock13"
mkdir -p "$MOCK13"
cat > "$MOCK13/cmd.exe" <<'EOF'
#!/bin/bash
exit 1
EOF
chmod +x "$MOCK13/cmd.exe"
cat > "$MOCK13/python" <<'EOF'
#!/bin/bash
if [[ "$1" == "-m" && "$2" == "graphify" ]]; then
    shift 2
    [[ "$1" == "--version" ]] && { echo "graphify 1.0.0 (module)"; exit 0; }
fi
exit 1
EOF
chmod +x "$MOCK13/python"
OUT13=$(PATH="$MOCK13:/usr/bin:/bin" bash "$DETECT")
if [[ "$(field "$OUT13" GRAPHIFY_AVAILABLE)" == "true" ]] && \
   [[ "$(field "$OUT13" GRAPHIFY_CMD)" == "python -m graphify" ]]; then
    ok "Empty tier B result falls through cleanly to tier C"
else
    fail "Fall-through from empty tier B failed: $OUT13"
fi

# ── Summary ──────────────────────────────────────────────────────────────────
echo ""
echo "══════════════════════════════════════════════════════"
echo "  Results: $PASS passed, $FAIL failed"
echo "══════════════════════════════════════════════════════"
echo ""

[[ $FAIL -eq 0 ]] || exit 1
