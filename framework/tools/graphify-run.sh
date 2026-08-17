#!/bin/bash
# SDD Kit — Graphify: the ONE canonical, safe way to invoke Graphify
#
# No caller — no command file, no skill, no ad-hoc script — should ever build a raw
# `$GRAPHIFY_CMD <args>` string and expand it unquoted. A resolved executable path can
# contain a space (e.g. a Windows username with a space in it, such as
# "C:\Users\Jane Doe\.local\bin\graphify.exe"), and no amount of quoting discipline at
# the call site fixes that once the executable and its args have been flattened into one
# unquoted string — there is nothing left at that point to tell bash "this middle part was
# one argument." The fix is to never flatten it in the first place.
#
# This wrapper re-resolves EXEC/ARGS via detect-graphify.sh IN THIS SAME PROCESS (no
# array is ever serialized to text and re-parsed across a process boundary — the only
# thing that crosses that boundary is GRAPHIFY_ARGS, a plain space-joined string that is
# safe to `read -ra` back into an array specifically because detect-graphify.sh only ever
# sets it to "" or the literal "-m graphify", both fully controlled, neither token ever
# containing whitespace itself), then execs with real bash array semantics:
#
#   "$EXEC" "${PREFIX_ARGS[@]}" "$@"
#
# No `eval`, anywhere.
#
# Usage:
#   graphify-run.sh <graphify-subcommand-or-flag> [args...]
#
# Examples:
#   graphify-run.sh --version
#   graphify-run.sh extract . --code-only
#   graphify-run.sh query "payment calculation flow" --budget 1500
#   graphify-run.sh path Foo Bar
#   graphify-run.sh update .
#
# Every argument after the script name is passed through to the real Graphify invocation
# exactly as received — this script never re-parses, re-quotes, or otherwise touches "$@".
#
# Exit code: passes through the real Graphify invocation's own exit code. If Graphify
# could not be resolved at all, exits 127 with a short diagnostic on stderr — callers
# should already have checked GRAPHIFY_AVAILABLE via detect-graphify.sh before ever
# reaching this wrapper (see framework/_shared/graphify-context.md § "Invocation"); this
# is a safety backstop, not the primary availability check, and it never blocks the wider
# SDD pipeline — only this one Graphify call.

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DETECT="$SCRIPT_DIR/detect-graphify.sh"

DETECTION=$(bash "$DETECT")
EXEC=$(printf '%s\n' "$DETECTION" | grep '^GRAPHIFY_EXEC=' | cut -d= -f2-)
ARGS_STR=$(printf '%s\n' "$DETECTION" | grep '^GRAPHIFY_ARGS=' | cut -d= -f2-)

if [[ -z "$EXEC" ]]; then
    echo "graphify-run.sh: Graphify is not available (detect-graphify.sh found nothing runnable)." >&2
    exit 127
fi

PREFIX_ARGS=()
if [[ -n "$ARGS_STR" ]]; then
    read -ra PREFIX_ARGS <<< "$ARGS_STR"
fi

exec "$EXEC" "${PREFIX_ARGS[@]}" "$@"
