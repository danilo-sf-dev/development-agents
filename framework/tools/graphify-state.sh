#!/bin/bash
# SDD Kit — Graphify Flow State
#
# Two independent, deliberately simple pieces of state — no state machine, no framework:
#
#   1. Per-flow state (GRAPHIFY_MODE, GRAPHIFY_GRAPH), persisted in the feature's own
#      meta.md so downstream dispatched phases (spec/plan/build/check — each potentially a
#      fresh subprocess per Model Routing) read the same decision instead of re-asking.
#      Written once by the preflight (see framework/_shared/graphify-context.md § 4), then
#      only mutated by `mark-stale` (build, on structural code change) and by whichever
#      phase resolves that staleness (check, after the user's answer).
#
#        GRAPHIFY_MODE:  active | disabled
#        GRAPHIFY_GRAPH: missing | ready | stale
#
#   2. A project-wide, LOCAL-ONLY preference: "don't ask about Graphify being absent again
#      in this project." Stored inside .git/ (never tracked, never pushed, exactly like
#      .git/info/exclude) — never written to any file that could be committed.
#
# This script never calls Graphify itself, never runs extract/update, and never decides
# anything on its own — it only stores/retrieves decisions that the command's own ASK_USER
# flow already made. All subcommands are best-effort: a missing/unreadable file yields safe
# defaults (disabled/missing), never an error that could block the pipeline.
#
# Usage:
#   graphify-state.sh get <meta-file>
#   graphify-state.sh set <meta-file> --mode <active|disabled> --graph <missing|ready|stale>
#   graphify-state.sh mark-stale <meta-file>
#   graphify-state.sh pref-get <pref-file>
#   graphify-state.sh pref-set-dont-ask <pref-file>
#
# `get` output (KEY=value lines, always):
#   GRAPHIFY_MODE=active|disabled
#   GRAPHIFY_GRAPH=missing|ready|stale
#
# `pref-get` output:
#   DONT_ASK_ABSENT=true|false
#
# State block markers used inside meta-file (HTML comments — invisible in rendered
# Markdown, and don't collide with meta.md's own YAML content):
#   <!-- graphify-state:start -->
#   GRAPHIFY_MODE=active
#   GRAPHIFY_GRAPH=ready
#   <!-- graphify-state:end -->

set -u

SUBCOMMAND="${1:-}"
shift || true

BLOCK_START="<!-- graphify-state:start -->"
BLOCK_END="<!-- graphify-state:end -->"

read_block() {
    local file="$1"
    [[ -f "$file" ]] || return 1
    awk -v s="$BLOCK_START" -v e="$BLOCK_END" '
        $0 == s { inblock=1; next }
        $0 == e { inblock=0; next }
        inblock { print }
    ' "$file"
}

strip_block() {
    local file="$1"
    [[ -f "$file" ]] || return 0
    awk -v s="$BLOCK_START" -v e="$BLOCK_END" '
        $0 == s { inblock=1; next }
        $0 == e { inblock=0; next }
        !inblock { print }
    ' "$file"
}

case "$SUBCOMMAND" in

    get)
        META_FILE="${1:-}"
        MODE="disabled"
        GRAPH="missing"
        if [[ -n "$META_FILE" ]]; then
            BLOCK=$(read_block "$META_FILE")
            V_MODE=$(printf '%s\n' "$BLOCK" | grep '^GRAPHIFY_MODE='  | tail -1 | cut -d= -f2-)
            V_GRAPH=$(printf '%s\n' "$BLOCK" | grep '^GRAPHIFY_GRAPH=' | tail -1 | cut -d= -f2-)
            [[ -n "$V_MODE"  ]] && MODE="$V_MODE"
            [[ -n "$V_GRAPH" ]] && GRAPH="$V_GRAPH"
        fi
        echo "GRAPHIFY_MODE=$MODE"
        echo "GRAPHIFY_GRAPH=$GRAPH"
        exit 0
        ;;

    set)
        META_FILE="${1:-}"; shift || true
        MODE=""
        GRAPH=""
        while [[ $# -gt 0 ]]; do
            case "$1" in
                --mode)  MODE="$2";  shift 2 ;;
                --graph) GRAPH="$2"; shift 2 ;;
                *) shift ;;
            esac
        done
        if [[ -z "$META_FILE" || -z "$MODE" || -z "$GRAPH" ]]; then
            echo "Usage: graphify-state.sh set <meta-file> --mode <active|disabled> --graph <missing|ready|stale>" >&2
            exit 1
        fi
        case "$MODE"  in active|disabled) ;; *) echo "invalid --mode: $MODE" >&2; exit 1 ;; esac
        case "$GRAPH" in missing|ready|stale) ;; *) echo "invalid --graph: $GRAPH" >&2; exit 1 ;; esac

        TMP=$(mktemp)
        if [[ -f "$META_FILE" ]]; then
            strip_block "$META_FILE" > "$TMP"
        fi
        {
            echo "$BLOCK_START"
            echo "GRAPHIFY_MODE=$MODE"
            echo "GRAPHIFY_GRAPH=$GRAPH"
            echo "$BLOCK_END"
        } >> "$TMP"
        mkdir -p "$(dirname "$META_FILE")" 2>/dev/null
        mv "$TMP" "$META_FILE"
        echo "GRAPHIFY_MODE=$MODE"
        echo "GRAPHIFY_GRAPH=$GRAPH"
        exit 0
        ;;

    mark-stale)
        META_FILE="${1:-}"
        if [[ -z "$META_FILE" ]]; then
            echo "Usage: graphify-state.sh mark-stale <meta-file>" >&2
            exit 1
        fi
        BLOCK=$(read_block "$META_FILE")
        CURRENT_MODE=$(printf '%s\n' "$BLOCK" | grep '^GRAPHIFY_MODE=' | tail -1 | cut -d= -f2-)
        if [[ "$CURRENT_MODE" != "active" ]]; then
            # No-op: nothing to mark stale if Graphify isn't active for this flow.
            echo "GRAPHIFY_MODE=${CURRENT_MODE:-disabled}"
            echo "GRAPHIFY_GRAPH=unchanged"
            exit 0
        fi
        "$0" set "$META_FILE" --mode active --graph stale
        exit 0
        ;;

    pref-get)
        PREF_FILE="${1:-}"
        DONT_ASK="false"
        if [[ -n "$PREF_FILE" && -f "$PREF_FILE" ]]; then
            grep -qx "dont_ask_absent=true" "$PREF_FILE" 2>/dev/null && DONT_ASK="true"
        fi
        echo "DONT_ASK_ABSENT=$DONT_ASK"
        exit 0
        ;;

    pref-set-dont-ask)
        PREF_FILE="${1:-}"
        if [[ -z "$PREF_FILE" ]]; then
            echo "Usage: graphify-state.sh pref-set-dont-ask <pref-file>" >&2
            exit 1
        fi
        mkdir -p "$(dirname "$PREF_FILE")" 2>/dev/null
        if [[ ! -f "$PREF_FILE" ]] || ! grep -qx "dont_ask_absent=true" "$PREF_FILE" 2>/dev/null; then
            echo "dont_ask_absent=true" >> "$PREF_FILE"
        fi
        echo "DONT_ASK_ABSENT=true"
        exit 0
        ;;

    *)
        echo "Usage: graphify-state.sh <get|set|mark-stale|pref-get|pref-set-dont-ask> ..." >&2
        exit 1
        ;;
esac
