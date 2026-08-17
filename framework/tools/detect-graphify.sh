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
# does the resolved GRAPHIFY_CMD support `extract --code-only`, `query`, `path`, `explain`,
# `update`? Checked via --help output (best-effort text match, not a version gate — different
# Graphify releases have shown different flag support, so a capability probe is more reliable
# than hardcoding a minimum version). If `--code-only` is not supported, GRAPHIFY_CODE_ONLY=false
# and the caller must treat Graphify as unavailable for SDD purposes (no bootstrap) even though
# the binary itself works — see framework/_shared/graphify-context.md.
#
# Usage:
#   detect-graphify.sh [--json]
#
# Output (default — simple KEY=value lines, safe to `source` or grep):
#   GRAPHIFY_AVAILABLE=true|false
#   GRAPHIFY_CMD=graphify|python -m graphify|python3 -m graphify|
#   GRAPHIFY_CODE_ONLY=true|false
#   GRAPHIFY_QUERY=true|false
#   GRAPHIFY_PATH=true|false
#   GRAPHIFY_EXPLAIN=true|false
#   GRAPHIFY_UPDATE=true|false
#
# Output (--json): single-line JSON object with the same fields (booleans, not strings).
#
# Exit code: always 0. Detection failure is signaled via GRAPHIFY_AVAILABLE=false in the
# output, never via a nonzero exit — the caller must never treat this script's exit code as
# a gate.

JSON_OUTPUT=false
[[ "${1:-}" == "--json" ]] && JSON_OUTPUT=true

GRAPHIFY_AVAILABLE=false
GRAPHIFY_CMD=""
GRAPHIFY_CODE_ONLY=false
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
    # mentioned in the help text.
    # -----------------------------------------------------------------------

    EXTRACT_HELP=$($GRAPHIFY_CMD extract --help 2>&1)
    if printf '%s' "$EXTRACT_HELP" | grep -qi -- '--code-only'; then
        GRAPHIFY_CODE_ONLY=true
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
    printf '{"available":%s,"cmd":"%s","code_only":%s,"query":%s,"path":%s,"explain":%s,"update":%s}\n' \
        "$(bool_json "$GRAPHIFY_AVAILABLE")" \
        "$GRAPHIFY_CMD" \
        "$(bool_json "$GRAPHIFY_CODE_ONLY")" \
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
