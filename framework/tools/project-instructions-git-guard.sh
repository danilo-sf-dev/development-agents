#!/bin/bash
# SDD Kit — Project Instructions (CLAUDE.md / AGENTS.md) Git Protection Guard
#
# A real E2E run on a corporate machine found /sdd.install creating CLAUDE.md for local harness
# configuration, and that file showing up as untracked noise in `git status` — polluting a
# corporate repo with a file nobody asked to commit. This script is the deterministic fix,
# mirroring the same pattern already used for graphify-out/ (framework/tools/graphify-git-guard.sh,
# framework/_shared/graphify-context.md § 2): PROTECT LOCALLY, never touch the team's shared
# .gitignore, and never touch a file this procedure did not itself just create.
#
# CALL THIS ONLY when commands/references/project-instructions-sync.md's own procedure just
# created target_file from nothing (the "target_file does NOT exist" branch). Never call it for
# the append-to-existing-file or replace-SDD-Kit-section branches — this script's whole premise
# is "this run is the sole reason this file exists," and only the caller (the sync procedure)
# knows that at the moment of creation. A file that existed before this run — tracked or not —
# is never touched by this script, by design; see framework/_shared/graphify-context.md's own
# git-safety philosophy for why deciding this after the fact is unreliable.
#
# What it does, when called correctly:
#   - If the file is untracked right now (git status shows it as `??`) and not already covered
#     by an ignore rule -> add it to .git/info/exclude (LOCAL ONLY — never .gitignore; unlike
#     Graphify, there is no "user explicitly chose to share this" scenario here to justify
#     touching the team's shared ignore file for a per-developer harness config file).
#   - If the file is already tracked (e.g. a concurrent `git add` happened, or the caller was
#     wrong about "just created") -> no-op, exit 0, GUARD_ACTION=skip-tracked. This script NEVER
#     removes tracking from an already-tracked file — that is exactly the "don't ignore a tracked
#     file" half of the policy, enforced by refusing to act rather than by inspecting history.
#   - Never deletes, never edits .gitignore, never touches any path other than the one given.
#
# Usage:
#   project-instructions-git-guard.sh --file <path> [--repo-root <path>]
#
# Output (stdout, KEY=value lines):
#   GUARD_ACTION=excluded|already-excluded|skip-tracked|skip-not-found|skip-no-repo
#   GUARD_PROTECTED=true|false   (true iff the file is untracked AND covered by an ignore rule
#                                 after this call — i.e. safe to leave out of `git status`)
#
# Exit code: always 0. This never blocks the wider SDD pipeline — a failure to protect the file
# locally is a warning-worthy outcome, not a reason to abort project-instructions-sync.

set -u

TARGET_FILE=""
REPO_ROOT="."

while [[ $# -gt 0 ]]; do
    case "$1" in
        --file)      TARGET_FILE="$2"; shift 2 ;;
        --repo-root) REPO_ROOT="$2";   shift 2 ;;
        *) shift ;;
    esac
done

if [[ -z "$TARGET_FILE" ]]; then
    echo "GUARD_ACTION=skip-not-found"
    echo "GUARD_PROTECTED=false"
    exit 0
fi

if ! git -C "$REPO_ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "GUARD_ACTION=skip-no-repo"
    echo "GUARD_PROTECTED=false"
    exit 0
fi

if [[ ! -f "$REPO_ROOT/$TARGET_FILE" ]]; then
    echo "GUARD_ACTION=skip-not-found"
    echo "GUARD_PROTECTED=false"
    exit 0
fi

# Already tracked (e.g. `git add` happened concurrently, or caller mis-detected "just created")
# -> never touch. This is the "don't ignore a tracked file" guarantee, enforced by refusing to
# act rather than trying to detect/undo tracking after the fact.
if git -C "$REPO_ROOT" ls-files --error-unmatch -- "$TARGET_FILE" >/dev/null 2>&1; then
    echo "GUARD_ACTION=skip-tracked"
    echo "GUARD_PROTECTED=false"
    exit 0
fi

is_ignored() {
    git -C "$REPO_ROOT" check-ignore -q -- "$TARGET_FILE" 2>/dev/null
}

if is_ignored; then
    echo "GUARD_ACTION=already-excluded"
    echo "GUARD_PROTECTED=true"
    exit 0
fi

GIT_DIR=$(git -C "$REPO_ROOT" rev-parse --git-dir 2>/dev/null)
if [[ -n "$GIT_DIR" ]]; then
    [[ "$GIT_DIR" != /* ]] && GIT_DIR="$REPO_ROOT/$GIT_DIR"
    EXCLUDE_FILE="$GIT_DIR/info/exclude"
    mkdir -p "$(dirname "$EXCLUDE_FILE")" 2>/dev/null
    if [[ ! -f "$EXCLUDE_FILE" ]] || ! grep -qxF "$TARGET_FILE" "$EXCLUDE_FILE" 2>/dev/null; then
        echo "$TARGET_FILE" >> "$EXCLUDE_FILE" 2>/dev/null
    fi
fi

if is_ignored; then
    echo "GUARD_ACTION=excluded"
    echo "GUARD_PROTECTED=true"
else
    # Write failed, or an unusual exclude configuration didn't take -> report honestly, don't
    # pretend. The caller should treat this as a soft warning (file may show up untracked),
    # never as a reason to block project-instructions-sync.
    echo "GUARD_ACTION=excluded"
    echo "GUARD_PROTECTED=false"
fi
exit 0
