#!/bin/bash
# SDD Kit — Graphify Git Safety Guard
#
# MANDATORY before every single `<GRAPHIFY_CMD> extract|update|query|path|explain` call —
# not just before the first extract. Whether graphify-out/ already existed before this SDD
# session touched it or not, protection is (re-)validated every time, using a REAL git check
# (`git check-ignore`), never a text search inside .gitignore.
#
# Order is mandatory: PROTECT GIT → VALIDATE IGNORE → (caller) USE GRAPHIFY.
# This script only does the first two; the caller decides whether to proceed with the actual
# Graphify CLI call based on this script's exit code.
#
# Two scenarios (see framework/_shared/graphify-context.md § 3):
#   Scenario A (default, no flag) — Graphify/graphify-out/ pre-existed this SDD flow.
#     Only .git/info/exclude is touched. The project's own .gitignore is NEVER edited
#     automatically just because Graphify was detected.
#   Scenario B (--gitignore) — the user explicitly chose, via the SDD preflight ASK_USER,
#     to install/configure Graphify through this flow. In this case the project .gitignore
#     is also updated (if not already covering graphify-out/), because the user's own choice
#     to bring Graphify into the project makes the ignore rule worth sharing with the team.
#
# Usage:
#   graphify-git-guard.sh [--gitignore] [--repo-root <path>]
#
# Output (stdout, KEY=value lines):
#   GUARD_PROTECTED=true|false
#   GUARD_STAGED_CORRECTED=true|false   (true only if a staged graphify-out/ path was found and unstaged)
#   GUARD_REASON=<text, only present when GUARD_PROTECTED=false>
#
# Exit code:
#   0 = protected and safe — caller MAY proceed with the Graphify CLI call.
#   1 = NOT protected — caller MUST treat Graphify as unavailable for this call and fall
#       back to normal Read/Grep/Glob. This never blocks the wider SDD pipeline; it only
#       withholds this one Graphify invocation until protection can be (re-)established.
#
# This script never deletes files, never runs `git clean`/`git reset --hard`, and never
# touches any path other than the `graphify-out/` entry itself.

set -u

USE_GITIGNORE=false
REPO_ROOT="."

while [[ $# -gt 0 ]]; do
    case "$1" in
        --gitignore)  USE_GITIGNORE=true; shift ;;
        --repo-root)  REPO_ROOT="$2"; shift 2 ;;
        *) shift ;;
    esac
done

GUARD_PROTECTED=false
GUARD_STAGED_CORRECTED=false
GUARD_REASON=""

cd "$REPO_ROOT" 2>/dev/null || {
    echo "GUARD_PROTECTED=false"
    echo "GUARD_STAGED_CORRECTED=false"
    echo "GUARD_REASON=repo root not accessible: $REPO_ROOT"
    exit 1
}

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "GUARD_PROTECTED=false"
    echo "GUARD_STAGED_CORRECTED=false"
    echo "GUARD_REASON=not inside a git work tree"
    exit 1
fi

# ---------------------------------------------------------------------------
# Step 1: staging safety FIRST. This must run before the ignore check below —
# git check-ignore reports an already-tracked/staged path as "not ignored"
# regardless of exclude rules (ignore rules only govern untracked files), so
# checking ignore status while graphify-out/ is still staged would give a
# false negative and cause this guard to (wrongly) add duplicate protection
# or report failure. Unstage first, then the ignore check reflects reality.
# ---------------------------------------------------------------------------

STAGED_GRAPHIFY=$(git diff --cached --name-only 2>/dev/null | grep -E '^graphify-out/' || true)
if [[ -n "$STAGED_GRAPHIFY" ]]; then
    git restore --staged -- graphify-out/ 2>/dev/null || git reset -q -- graphify-out/ 2>/dev/null
    GUARD_STAGED_CORRECTED=true
fi

# ---------------------------------------------------------------------------
# Step 2: real ignore check (git check-ignore, not text search)
# ---------------------------------------------------------------------------

is_ignored() {
    git check-ignore -q graphify-out/ 2>/dev/null
}

if ! is_ignored; then
    # ---------------------------------------------------------------------------
    # Step 2: add protection. Scenario A → .git/info/exclude only.
    #         Scenario B (--gitignore) → also project .gitignore.
    # ---------------------------------------------------------------------------

    GIT_DIR=$(git rev-parse --git-dir 2>/dev/null)
    if [[ -n "$GIT_DIR" ]]; then
        EXCLUDE_FILE="$GIT_DIR/info/exclude"
        mkdir -p "$(dirname "$EXCLUDE_FILE")" 2>/dev/null
        if [[ ! -f "$EXCLUDE_FILE" ]] || ! grep -qx "graphify-out/" "$EXCLUDE_FILE" 2>/dev/null; then
            echo "graphify-out/" >> "$EXCLUDE_FILE" 2>/dev/null
        fi
    fi

    if $USE_GITIGNORE; then
        TOPLEVEL=$(git rev-parse --show-toplevel 2>/dev/null || echo ".")
        GITIGNORE_FILE="$TOPLEVEL/.gitignore"
        if [[ ! -f "$GITIGNORE_FILE" ]] || ! grep -qx "graphify-out/" "$GITIGNORE_FILE" 2>/dev/null; then
            echo "graphify-out/" >> "$GITIGNORE_FILE" 2>/dev/null
        fi
    fi

    # Re-validate with the real check — never assume the write worked.
    if ! is_ignored; then
        echo "GUARD_PROTECTED=false"
        echo "GUARD_STAGED_CORRECTED=false"
        echo "GUARD_REASON=graphify-out/ still not recognized as ignored after protection attempt (git check-ignore failed post-write)"
        exit 1
    fi
fi

GUARD_PROTECTED=true

# ---------------------------------------------------------------------------
# Step 3: final staging re-check. A concurrent process could in theory stage
# graphify-out/ again between Step 1 and here; cheap enough to re-verify.
# Never touches any file other than graphify-out/ paths; never destructive.
# ---------------------------------------------------------------------------

STILL_STAGED=$(git diff --cached --name-only 2>/dev/null | grep -E '^graphify-out/' || true)
if [[ -n "$STILL_STAGED" ]]; then
    git restore --staged -- graphify-out/ 2>/dev/null || git reset -q -- graphify-out/ 2>/dev/null
    GUARD_STAGED_CORRECTED=true
fi

echo "GUARD_PROTECTED=true"
echo "GUARD_STAGED_CORRECTED=$GUARD_STAGED_CORRECTED"
exit 0
