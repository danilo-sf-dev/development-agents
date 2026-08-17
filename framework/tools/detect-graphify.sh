#!/bin/bash
# SDD Kit — Graphify Capability Detection
#
# Graphify is an OPTIONAL, DISCARDABLE local code-graph accelerator. This script never
# installs anything, never requires Python (the SDD side depends only on bash/grep/command),
# and always exits 0 — absence or failure of Graphify is a normal, silent outcome, never
# something that blocks the SDD pipeline.
#
# Detection order (first success wins):
#   A. `graphify` on PATH and `graphify --version` succeeds  → GRAPHIFY_CMD="graphify"
#   B. `python` on PATH and `python -m graphify --version` succeeds  → GRAPHIFY_CMD="python -m graphify"
#   C. `python3` on PATH and `python3 -m graphify --version` succeeds → GRAPHIFY_CMD="python3 -m graphify"
#   D. none of the above → GRAPHIFY_AVAILABLE=false, everything else false/empty
#
# Python here is Graphify's OWN interpreter dependency (tier B/C only exist because some
# installs expose Graphify as a Python module rather than a standalone binary) — the SDD
# framework itself never requires Python. If neither `graphify` nor `python`/`python3` are
# present, detection simply reports unavailable; nothing is installed to fix that.
#
# Capability check (only run when a command was found in the step above):
# does the resolved GRAPHIFY_CMD support `query`, `path`, `explain`, `update`? Checked via
# --help output (best-effort text match, not a version gate — different Graphify releases
# have shown different flag support, so a capability probe is more reliable than hardcoding
# a minimum version).
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
#   GRAPHIFY_CMD=graphify|python -m graphify|python3 -m graphify|
#   GRAPHIFY_CODE_ONLY=true|unknown|false
#   GRAPHIFY_QUERY=true|false
#   GRAPHIFY_PATH=true|false
#   GRAPHIFY_EXPLAIN=true|false
#   GRAPHIFY_UPDATE=true|false
#
# Output (--json): single-line JSON object with the same fields. All fields except `code_only`
# are JSON booleans; `code_only` is always a JSON string ("true"/"unknown"/"false") since it is
# a tri-state, not a boolean.
#
# Exit code: always 0. Detection failure is signaled via GRAPHIFY_AVAILABLE=false in the
# output, never via a nonzero exit — the caller must never treat this script's exit code as
# a gate.

JSON_OUTPUT=false
[[ "${1:-}" == "--json" ]] && JSON_OUTPUT=true

GRAPHIFY_AVAILABLE=false
GRAPHIFY_CMD=""
GRAPHIFY_CODE_ONLY="false"
GRAPHIFY_QUERY=false
GRAPHIFY_PATH_CAP=false
GRAPHIFY_EXPLAIN=false
GRAPHIFY_UPDATE=false

# ---------------------------------------------------------------------------
# Step 1: resolve GRAPHIFY_CMD (tier A → B → C), each probe best-effort and
# time-bounded by the tool's own --version response, never installed or
# assumed. A probe that hangs or errors is simply treated as "not found".
# ---------------------------------------------------------------------------

if command -v graphify >/dev/null 2>&1 && graphify --version >/dev/null 2>&1; then
    GRAPHIFY_CMD="graphify"
elif command -v python >/dev/null 2>&1 && python -m graphify --version >/dev/null 2>&1; then
    GRAPHIFY_CMD="python -m graphify"
elif command -v python3 >/dev/null 2>&1 && python3 -m graphify --version >/dev/null 2>&1; then
    GRAPHIFY_CMD="python3 -m graphify"
fi

if [[ -n "$GRAPHIFY_CMD" ]]; then
    GRAPHIFY_AVAILABLE=true

    # -----------------------------------------------------------------------
    # Step 2: capability probes — best-effort text match against --help output.
    # Never a hard requirement; each capability independently defaults to
    # false if its probe errors, times out, or the flag/subcommand isn't
    # mentioned in the help text. GRAPHIFY_CODE_ONLY is the one tri-state
    # field here — see the header comment for why "not mentioned" != "false".
    # -----------------------------------------------------------------------

    EXTRACT_HELP=$($GRAPHIFY_CMD extract --help 2>&1)
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

    TOP_HELP=$($GRAPHIFY_CMD --help 2>&1)
    printf '%s' "$TOP_HELP" | grep -qiw 'query'   && GRAPHIFY_QUERY=true
    printf '%s' "$TOP_HELP" | grep -qiw 'path'    && GRAPHIFY_PATH_CAP=true
    printf '%s' "$TOP_HELP" | grep -qiw 'explain' && GRAPHIFY_EXPLAIN=true
    printf '%s' "$TOP_HELP" | grep -qiw 'update'  && GRAPHIFY_UPDATE=true
fi

# ---------------------------------------------------------------------------
# Output
# ---------------------------------------------------------------------------

bool_json() { [[ "$1" == "true" ]] && echo "true" || echo "false"; }

if $JSON_OUTPUT; then
    # code_only is always a JSON STRING ("true"/"unknown"/"false") — it is a tri-state,
    # never a real boolean, unlike every other field here.
    printf '{"available":%s,"cmd":"%s","code_only":"%s","query":%s,"path":%s,"explain":%s,"update":%s}\n' \
        "$(bool_json "$GRAPHIFY_AVAILABLE")" \
        "$GRAPHIFY_CMD" \
        "$GRAPHIFY_CODE_ONLY" \
        "$(bool_json "$GRAPHIFY_QUERY")" \
        "$(bool_json "$GRAPHIFY_PATH_CAP")" \
        "$(bool_json "$GRAPHIFY_EXPLAIN")" \
        "$(bool_json "$GRAPHIFY_UPDATE")"
else
    echo "GRAPHIFY_AVAILABLE=$GRAPHIFY_AVAILABLE"
    echo "GRAPHIFY_CMD=$GRAPHIFY_CMD"
    echo "GRAPHIFY_CODE_ONLY=$GRAPHIFY_CODE_ONLY"
    echo "GRAPHIFY_QUERY=$GRAPHIFY_QUERY"
    echo "GRAPHIFY_PATH=$GRAPHIFY_PATH_CAP"
    echo "GRAPHIFY_EXPLAIN=$GRAPHIFY_EXPLAIN"
    echo "GRAPHIFY_UPDATE=$GRAPHIFY_UPDATE"
fi

exit 0
