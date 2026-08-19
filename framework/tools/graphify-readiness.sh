#!/bin/bash
# SDD Kit — Graphify Graph Readiness Check
#
# The deterministic half of framework/_shared/graphify-context.md § 4.2's "validate
# graphify-out/graph.json exists and is non-empty" step — extracted into a real, testable
# script instead of living only as prose an agent is trusted to follow. This script never
# calls Graphify itself and never decides GRAPHIFY_MODE/GRAPHIFY_GRAPH state (that remains the
# preflight's ASK_USER-driven decision, persisted via graphify-state.sh) — it only answers one
# narrow, mechanical question: "does a usable graph.json exist right now?"
#
# A "usable" graph.json is a real, non-trivial requirement, not just file-exists: an empty file,
# a zero-byte file, or a file that isn't even syntactically plausible JSON (doesn't start with
# `{`) must never be reported ready — a failed/interrupted `extract` can leave exactly this kind
# of debris behind, and treating it as ready would make the calling command trust a graph that
# was never actually built.
#
# Usage:
#   graphify-readiness.sh [--repo-root <path>]
#
# Output (stdout, KEY=value lines):
#   GRAPH_READY=true|false
#   GRAPH_PATH=<the path checked, always graphify-out/graph.json under repo-root>
#   GRAPH_REASON=<short reason, only present when GRAPH_READY=false>
#
# Exit code: always 0 — absence or invalidity of the graph is a normal, non-blocking outcome,
# exactly like every other Graphify primitive in this framework (see detect-graphify.sh,
# graphify-git-guard.sh). The caller decides what to do with GRAPH_READY; this script never
# aborts anything.

set -u

REPO_ROOT="."

while [[ $# -gt 0 ]]; do
    case "$1" in
        --repo-root) REPO_ROOT="$2"; shift 2 ;;
        *) shift ;;
    esac
done

GRAPH_FILE="$REPO_ROOT/graphify-out/graph.json"

if [[ ! -f "$GRAPH_FILE" ]]; then
    echo "GRAPH_READY=false"
    echo "GRAPH_PATH=graphify-out/graph.json"
    echo "GRAPH_REASON=file does not exist"
    exit 0
fi

if [[ ! -s "$GRAPH_FILE" ]]; then
    echo "GRAPH_READY=false"
    echo "GRAPH_PATH=graphify-out/graph.json"
    echo "GRAPH_REASON=file is empty"
    exit 0
fi

# Syntactic plausibility only (no jq dependency, matching this framework's zero-dependency
# rule) — the first non-whitespace character of a JSON object/array must be `{` or `[`.
FIRST_CHAR=$(tr -d '[:space:]' < "$GRAPH_FILE" | head -c 1)
if [[ "$FIRST_CHAR" != "{" && "$FIRST_CHAR" != "[" ]]; then
    echo "GRAPH_READY=false"
    echo "GRAPH_PATH=graphify-out/graph.json"
    echo "GRAPH_REASON=file does not look like JSON (first non-whitespace char: '$FIRST_CHAR')"
    exit 0
fi

echo "GRAPH_READY=true"
echo "GRAPH_PATH=graphify-out/graph.json"
exit 0
