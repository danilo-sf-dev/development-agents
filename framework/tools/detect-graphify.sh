#!/bin/bash
# SDD Kit — Graphify Capability Detection
#
# Graphify is an OPTIONAL, DISCARDABLE local code-graph accelerator. This script never
# installs anything, never requires Python (the SDD side depends only on bash/grep/command),
# and always exits 0 — absence or failure of Graphify is a normal, silent outcome, never
# something that blocks the SDD pipeline.
#
# Detection is a REAL-EXECUTION cascade, not a presence check: the winner is whichever
# candidate is the FIRST to actually run `--version` successfully. `command -v` finding a
# name on PATH is never sufficient by itself — real-machine testing found `command -v
# graphify` succeeding (a `uv`-installed launcher/trampoline script exists) while `graphify
# --version` itself failed (the trampoline's underlying venv was broken), which the plain
# presence check alone would have missed.
#
# Detection order (first REAL SUCCESSFUL EXECUTION wins, no minimum required by any tier —
# every tier is attempted only if the previous one didn't already produce a working command):
#   A. `graphify` on PATH AND `graphify --version` actually succeeds → EXEC=graphify
#   B. Tier A failed AND `cmd.exe` is reachable (Git Bash/MSYS/Cygwin/WSL-interop — detected
#      by `command -v cmd.exe`, never by an OS-name check): ask the real Windows shell where
#      a `graphify` executable actually lives (`cmd.exe //c where graphify`), resolve each
#      candidate path to something bash can exec, and try `--version` on each until one
#      really succeeds → EXEC=<resolved absolute path>. This is what recovers from tier A's
#      uv-trampoline failure: `where` finds the real `graphify.exe` installed
#      alongside/instead of the broken launcher, and running that real executable directly
#      works even though the PATH-resolved `graphify` command did not.
#   C. Tiers A/B failed AND `python` on PATH AND `python -m graphify --version` actually
#      succeeds → EXEC=python, ARGS="-m graphify"
#   D. Tiers A/B/C failed AND `python3` on PATH AND `python3 -m graphify --version` actually
#      succeeds → EXEC=python3, ARGS="-m graphify"
#   E. none of the above → GRAPHIFY_AVAILABLE=false, everything else false/empty
#
# None of B/C/D is "the Windows path" or "the Python path" by assumption — each is simply
# attempted, in order, until something really runs. A machine with no `cmd.exe` skips tier B
# entirely and falls straight to C; a machine with `cmd.exe` but no matching Windows
# executable falls through to C/D exactly the same way tier A's failure does.
#
# Python here (tiers C/D) is Graphify's OWN interpreter dependency (these tiers only exist
# because some installs expose Graphify as a Python module rather than a standalone binary)
# — the SDD framework itself never requires Python, PowerShell, `uv`, or any other tool from
# any tier; they are optional fallbacks the cascade may or may not need on a given machine.
# If nothing in A-D produces a real successful execution, detection simply reports
# unavailable; nothing is installed to fix that.
#
# ---------------------------------------------------------------------------------------
# SAFE INVOCATION CONTRACT — read this before building any real Graphify command
# ---------------------------------------------------------------------------------------
# GRAPHIFY_CMD is DISPLAY-ONLY. Never invoke it as `$GRAPHIFY_CMD <args>` — a tier B
# resolved path can contain a space (e.g. a Windows username with a space in it, such as
# "C:\Users\Jane Doe\.local\bin\graphify.exe"), and an unquoted expansion of a
# space-containing single string will word-split into bogus tokens no matter how careful
# the surrounding code is. This is not a quoting-discipline problem to work around at each
# call site — a single string cannot represent "one argument that contains a space"
# without something to interpret its quoting, and plain KEY=value text has nothing to do
# that safely.
#
# Instead, this script emits the executable and its required prefix arguments as TWO
# separate fields:
#   GRAPHIFY_EXEC=<the executable — ALWAYS used as a single quoted token, e.g. "$EXEC">
#   GRAPHIFY_ARGS=<prefix args required before the real subcommand, space-joined>
#
# GRAPHIFY_ARGS is safe to reconstruct with `read -ra` into a bash array because this
# script only ever sets it to "" or the literal "-m graphify" — both fully controlled,
# neither token ever contains whitespace itself. It is never derived from external or
# untrusted input, so this narrow assumption holds by construction, not by luck.
#
# THE CANONICAL WAY TO ACTUALLY RUN GRAPHIFY IS `framework/tools/graphify-run.sh` — it
# resolves EXEC/ARGS itself (same-process, no array ever crosses a process boundary) and
# execs safely: `"$EXEC" "${PREFIX_ARGS[@]}" "$@"`. No caller — no command file, no skill,
# no ad-hoc script — should reconstruct EXEC/ARGS invocation itself; they should shell out
# to graphify-run.sh instead. See framework/_shared/graphify-context.md § "Invocation".
#
# Capability check (only run when EXEC was resolved in the step above):
# does the resolved command support `query`, `path`, `explain`, `update`? Checked via
# --help output (best-effort text match, not a version gate — different Graphify releases
# have shown different flag support, so a capability probe is more reliable than hardcoding
# a minimum version). These internal probes use the same safe EXEC/ARGS array invocation —
# never unquoted string expansion — so a space-containing tier B path never breaks
# detection's own capability probing either.
#
# `GRAPHIFY_CODE_ONLY` is the one exception to "a --help match settles it" — real-machine
# testing found `graphify extract . --code-only` succeeding on installs whose `extract --help`
# text never mentions `--code-only` at all (help text is not a reliable capability oracle for
# this flag on every release). So this field is a TRI-STATE, not a boolean:
#   true    — `extract --help` responded AND explicitly documents `--code-only`
#   unknown — `extract --help` responded (extract subcommand exists) but did NOT mention
#             `--code-only` — the flag may still work; this script does not know either way
#   false   — `extract --help` itself did not respond cleanly (nonzero exit) — no confirmed
#             path to `extract` at all, so no path to a code-only graph either
#
# This script never actually runs `extract . --code-only` itself — doing so here would
# create/alter `graphify-out/` in the target project just to answer a detection probe, which
# is not this script's job and not safe to do outside an explicit user decision. `unknown` is
# not a block: the caller (framework/_shared/graphify-context.md § 4 preflight) treats `true`
# and `unknown` the same way — proceed to offer bootstrap — and only `false` withholds it.
# The real, definitive capability test is the actual `extract . --code-only` call the user
# authorizes during preflight: its own exit code is the ground truth, confirmed or refuted
# in real time, never assumed in advance from static text.
#
# Usage:
#   detect-graphify.sh [--json]
#
# Output (default — simple KEY=value lines, safe to `source` or grep):
#   GRAPHIFY_AVAILABLE=true|false
#   GRAPHIFY_CMD=<human-readable resolved command — DISPLAY ONLY, never invoke this>
#   GRAPHIFY_EXEC=<the executable — safe to invoke ONLY as a quoted single token>
#   GRAPHIFY_ARGS=<prefix args, space-joined, safe to `read -ra` — "" or "-m graphify">
#   GRAPHIFY_CODE_ONLY=true|unknown|false
#   GRAPHIFY_QUERY=true|false
#   GRAPHIFY_PATH=true|false
#   GRAPHIFY_EXPLAIN=true|false
#   GRAPHIFY_UPDATE=true|false
#
# Output (--json): single-line JSON object with the same fields (as JSON strings for
# cmd/exec/args/code_only; real JSON booleans for the rest).
#
# Exit code: always 0. Detection failure is signaled via GRAPHIFY_AVAILABLE=false in the
# output, never via a nonzero exit — the caller must never treat this script's exit code as
# a gate.

JSON_OUTPUT=false
[[ "${1:-}" == "--json" ]] && JSON_OUTPUT=true

GRAPHIFY_AVAILABLE=false
GRAPHIFY_CMD=""
GRAPHIFY_EXEC=""
GRAPHIFY_ARGS=""
GRAPHIFY_CODE_ONLY="false"
GRAPHIFY_QUERY=false
GRAPHIFY_PATH_CAP=false
GRAPHIFY_EXPLAIN=false
GRAPHIFY_UPDATE=false

# ---------------------------------------------------------------------------
# Step 1: resolve GRAPHIFY_EXEC/GRAPHIFY_ARGS (tier A → B → C → D), each probe
# best-effort and gated on a REAL successful --version execution, never on
# command -v alone, never installed or assumed. A probe that hangs or errors
# is simply treated as "not found" and the cascade moves to the next tier.
# GRAPHIFY_CMD is derived afterward, purely for human-readable display.
# ---------------------------------------------------------------------------

# Tier A: graphify directly on PATH, real execution required.
if command -v graphify >/dev/null 2>&1 && graphify --version >/dev/null 2>&1; then
    GRAPHIFY_EXEC="graphify"
    GRAPHIFY_ARGS=""
fi

# Tier B: tier A failed but a real Windows shell is reachable (Git Bash/MSYS/Cygwin,
# or WSL with Windows interop) — ask it directly where a graphify executable actually
# lives, rather than trusting whatever `graphify` on bash's own PATH resolved to (which
# may be a broken uv/pip trampoline). `command -v cmd.exe` is the only gate — no OS-name
# check, no assumption that this tier is "the Windows path"; it is simply attempted
# whenever the tool needed to attempt it is present.
if [[ -z "$GRAPHIFY_EXEC" ]] && command -v cmd.exe >/dev/null 2>&1; then
    # `//c` (doubled leading slash) is the Git-Bash/MSYS idiom that stops the shell's own
    # path-mangling heuristic from rewriting `/c` into a Windows path before cmd.exe ever
    # sees it; cmd.exe itself accepts it the same as `/c`.
    WIN_MATCHES=$(cmd.exe //c where graphify 2>/dev/null | tr -d '\r')
    if [[ -n "$WIN_MATCHES" ]]; then
        while IFS= read -r WIN_PATH; do
            [[ -z "$WIN_PATH" ]] && continue

            # Resolve the native Windows path to something bash can exec directly.
            # cygpath (Git Bash/MSYS/Cygwin) and wslpath (WSL) are the two real
            # converters this might need; if neither is present, try the raw path as
            # a last resort — Git Bash can often exec a native Windows path as-is.
            if command -v cygpath >/dev/null 2>&1; then
                RESOLVED_PATH=$(cygpath -u "$WIN_PATH" 2>/dev/null)
            elif command -v wslpath >/dev/null 2>&1; then
                RESOLVED_PATH=$(wslpath -u "$WIN_PATH" 2>/dev/null)
            else
                RESOLVED_PATH="$WIN_PATH"
            fi
            [[ -z "$RESOLVED_PATH" ]] && continue

            # The only real proof: does this resolved path actually run? Quoted, so a
            # path containing spaces is passed to the OS as one argument here — this is
            # exactly why GRAPHIFY_EXEC/GRAPHIFY_ARGS exist as separate fields: EXEC is
            # always used as a single quoted token downstream too (never word-split),
            # so a space in this resolved path is safe all the way through, not just here.
            if "$RESOLVED_PATH" --version >/dev/null 2>&1; then
                GRAPHIFY_EXEC="$RESOLVED_PATH"
                GRAPHIFY_ARGS=""
                break
            fi
        done <<< "$WIN_MATCHES"
    fi
fi

# Tier C: python -m graphify, real execution required.
if [[ -z "$GRAPHIFY_EXEC" ]] && command -v python >/dev/null 2>&1 && python -m graphify --version >/dev/null 2>&1; then
    GRAPHIFY_EXEC="python"
    GRAPHIFY_ARGS="-m graphify"
fi

# Tier D: python3 -m graphify, real execution required.
if [[ -z "$GRAPHIFY_EXEC" ]] && command -v python3 >/dev/null 2>&1 && python3 -m graphify --version >/dev/null 2>&1; then
    GRAPHIFY_EXEC="python3"
    GRAPHIFY_ARGS="-m graphify"
fi

if [[ -n "$GRAPHIFY_EXEC" ]]; then
    GRAPHIFY_AVAILABLE=true

    # Human-readable display form only — never invoked. Matches what earlier versions of
    # this script emitted as the single GRAPHIFY_CMD field, kept for logging/observability.
    if [[ -n "$GRAPHIFY_ARGS" ]]; then
        GRAPHIFY_CMD="$GRAPHIFY_EXEC $GRAPHIFY_ARGS"
    else
        GRAPHIFY_CMD="$GRAPHIFY_EXEC"
    fi

    # Build the real, safe invocation array ONCE, in this process, from the two
    # controlled fields above — never from a serialized/re-parsed external source.
    GRAPHIFY_INVOKE=("$GRAPHIFY_EXEC")
    if [[ -n "$GRAPHIFY_ARGS" ]]; then
        ARGS_ARR=()
        read -ra ARGS_ARR <<< "$GRAPHIFY_ARGS"
        GRAPHIFY_INVOKE+=("${ARGS_ARR[@]}")
    fi

    # -----------------------------------------------------------------------
    # Step 2: capability probes — best-effort text match against --help output.
    # Never a hard requirement; each capability independently defaults to
    # false if its probe errors, times out, or the flag/subcommand isn't
    # mentioned in the help text. GRAPHIFY_CODE_ONLY is the one tri-state
    # field here — see the header comment for why "not mentioned" != "false".
    # Invoked via the array built above — safe even if GRAPHIFY_EXEC has spaces.
    # -----------------------------------------------------------------------

    EXTRACT_HELP=$("${GRAPHIFY_INVOKE[@]}" extract --help 2>&1)
    EXTRACT_HELP_RC=$?
    if [[ $EXTRACT_HELP_RC -eq 0 ]]; then
        if printf '%s' "$EXTRACT_HELP" | grep -qi -- '--code-only'; then
            GRAPHIFY_CODE_ONLY="true"
        else
            GRAPHIFY_CODE_ONLY="unknown"
        fi
    else
        # extract --help itself didn't respond cleanly — no confirmed path to `extract`
        # at all, so no confirmed path to a code-only graph either.
        GRAPHIFY_CODE_ONLY="false"
    fi

    TOP_HELP=$("${GRAPHIFY_INVOKE[@]}" --help 2>&1)
    printf '%s' "$TOP_HELP" | grep -qiw 'query'   && GRAPHIFY_QUERY=true
    printf '%s' "$TOP_HELP" | grep -qiw 'path'    && GRAPHIFY_PATH_CAP=true
    printf '%s' "$TOP_HELP" | grep -qiw 'explain' && GRAPHIFY_EXPLAIN=true
    printf '%s' "$TOP_HELP" | grep -qiw 'update'  && GRAPHIFY_UPDATE=true
fi

# ---------------------------------------------------------------------------
# Output
# ---------------------------------------------------------------------------

bool_json() { [[ "$1" == "true" ]] && echo "true" || echo "false"; }

# Minimal JSON string escaping — backslash and double-quote, the two characters a raw
# (unconverted) Windows path or an unusual executable name could realistically contain
# and that would otherwise produce invalid JSON.
json_escape() { printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'; }

if $JSON_OUTPUT; then
    # code_only is always a JSON STRING ("true"/"unknown"/"false") — it is a tri-state,
    # never a real boolean, unlike every other non-string field here.
    printf '{"available":%s,"cmd":"%s","exec":"%s","args":"%s","code_only":"%s","query":%s,"path":%s,"explain":%s,"update":%s}\n' \
        "$(bool_json "$GRAPHIFY_AVAILABLE")" \
        "$(json_escape "$GRAPHIFY_CMD")" \
        "$(json_escape "$GRAPHIFY_EXEC")" \
        "$(json_escape "$GRAPHIFY_ARGS")" \
        "$GRAPHIFY_CODE_ONLY" \
        "$(bool_json "$GRAPHIFY_QUERY")" \
        "$(bool_json "$GRAPHIFY_PATH_CAP")" \
        "$(bool_json "$GRAPHIFY_EXPLAIN")" \
        "$(bool_json "$GRAPHIFY_UPDATE")"
else
    echo "GRAPHIFY_AVAILABLE=$GRAPHIFY_AVAILABLE"
    echo "GRAPHIFY_CMD=$GRAPHIFY_CMD"
    echo "GRAPHIFY_EXEC=$GRAPHIFY_EXEC"
    echo "GRAPHIFY_ARGS=$GRAPHIFY_ARGS"
    echo "GRAPHIFY_CODE_ONLY=$GRAPHIFY_CODE_ONLY"
    echo "GRAPHIFY_QUERY=$GRAPHIFY_QUERY"
    echo "GRAPHIFY_PATH=$GRAPHIFY_PATH_CAP"
    echo "GRAPHIFY_EXPLAIN=$GRAPHIFY_EXPLAIN"
    echo "GRAPHIFY_UPDATE=$GRAPHIFY_UPDATE"
fi

exit 0
