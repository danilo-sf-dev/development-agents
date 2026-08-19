#!/bin/bash
# SDD Kit — Reverse-Eng UPDATE MODE Delta Detector
#
# Deterministic, real (not LLM-narrated) answer to "what changed since the last
# /sdd.reverse-eng extraction?" — the missing piece that let UPDATE MODE silently behave
# like FULL EXTRACTION (re-run the whole exploration protocol, then diff after the fact).
# This script computes the delta BEFORE any exploration happens, so UPDATE MODE can skip
# exploration entirely on a zero-delta run, or hand a small, real target set to whatever
# comes next (local reads or a scoped subagent dispatch) on a non-zero delta.
#
# ZERO-DEPENDENCY BY DESIGN: bash + git + POSIX stat/date only. No jq, no Python. git is
# already a hard requirement for /sdd.reverse-eng (git-guard, branch detection, etc.), so
# this adds nothing new.
#
# Baseline resolution (first success wins, each tier progressively less precise):
#   Tier 1 "sha"   — DETECTION_REPORT.md's Extraction History table has a real, reachable
#                    Git SHA in its last row (the pipeline's own recorded baseline).
#   Tier 2 "mtime" — no usable SHA recorded (e.g. an extraction predating this feature), but
#                    the nearest commit at-or-before DETECTION_REPORT.md's own mtime can be
#                    found — an approximation, not exact, but still real git history, not a
#                    guess.
#   Tier 3 "none"  — neither worked. Delta cannot be determined. This is reported honestly
#                    (`baseline_source:"none"`, `delta_empty:false`, `fallback:"full"`) —
#                    never silently assumed empty, never silently assumed the whole repo.
#
# Usage:
#   reverse-eng-delta.sh --detection-report <path/to/DETECTION_REPORT.md> [--repo-root <path>]
#
# Output (stdout, always valid JSON, always exits 0 — a detection failure degrades to the
# safe "don't know, don't pretend" fallback above, it never aborts the calling command):
#   {"baseline_source":"sha|mtime|none","baseline_sha":"<sha-or-empty>",
#    "current_sha":"<sha-or-empty>","changed_files":[...],"relevant_changed_files":[...],
#    "delta_empty":true|false,"fallback":"full|none"}
#
# `changed_files` includes committed diffs since the baseline AND uncommitted/untracked
# working-tree changes (a real UPDATE run may be re-invoked before committing prior work).
# `relevant_changed_files` excludes this pipeline's own output (`sdd/`) and `.git/` — a
# change only under `sdd/` (e.g. from a previous run) must never be read back as "the repo
# changed," which would create a self-triggering non-empty delta forever.
#
# It also excludes a small, deterministic, path-prefix set of known SDD/harness tooling
# directories that real E2E runs showed appearing as noisy "delta" even though they are never
# part of the target application: `development-agents/` (the pack itself, when vendored inside
# the target repo), `.claude/`, `.cursor/` (harness config dirs), `graphify-out/` (Graphify's own
# disposable cache, already root-level per framework/_shared/graphify-context.md). These are
# EXACT path prefixes, not extension/content-based guesses — `.devcontainer/`, `src/test/`, and
# any `*Test.java`/real application file are never touched by this list, on purpose: a filter
# broad enough to catch those would silently hide real application changes, which is worse than
# not filtering at all.
#
# Root-level `CLAUDE.md`/`AGENTS.md` get one narrow, STATEFUL exception on top of the static
# list: excluded only when they are currently untracked (`git status` `??`) — i.e. created by
# this SDD flow's own installer/bootstrap and never committed. A tracked/committed `CLAUDE.md`
# or `AGENTS.md` (pre-existing project documentation, or one the team already committed) is never
# excluded — a real edit to it must still surface as delta.

set -u

DETECTION_REPORT=""
REPO_ROOT="."

while [[ $# -gt 0 ]]; do
    case "$1" in
        --detection-report) DETECTION_REPORT="$2"; shift 2 ;;
        --repo-root)        REPO_ROOT="$2";        shift 2 ;;
        *) echo "reverse-eng-delta.sh: unknown argument: $1" >&2; shift ;;
    esac
done

json_escape() {
    local s="$1"
    s="${s//\\/\\\\}"
    s="${s//\"/\\\"}"
    printf '%s' "$s"
}

json_array() {
    # $@ = list of strings -> ["a","b",...]; empty list -> []
    local out="[" first=1 item
    for item in "$@"; do
        [[ -z "$item" ]] && continue
        if [[ "$first" -eq 1 ]]; then first=0; else out+=","; fi
        out+="\"$(json_escape "$item")\""
    done
    out+="]"
    printf '%s' "$out"
}

emit_none() {
    # $1 = reason (unused in output today, kept for future debugging via stderr only)
    echo "reverse-eng-delta.sh: $1" >&2
    printf '{"baseline_source":"none","baseline_sha":"","current_sha":"%s","changed_files":[],"relevant_changed_files":[],"delta_empty":false,"fallback":"full"}\n' \
        "$(json_escape "$CURRENT_SHA")"
    exit 0
}

# ---------------------------------------------------------------------------
# Preconditions
# ---------------------------------------------------------------------------

if ! git -C "$REPO_ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    CURRENT_SHA=""
    emit_none "not a git repository at --repo-root ($REPO_ROOT)"
fi

CURRENT_SHA=$(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null || echo "")

if [[ -z "$DETECTION_REPORT" ]] || [[ ! -f "$DETECTION_REPORT" ]]; then
    emit_none "no DETECTION_REPORT.md found at --detection-report ($DETECTION_REPORT)"
fi

# ---------------------------------------------------------------------------
# Tier 1: real Git SHA from the Extraction History table's last row.
# Table shape (see sdd.reverse-eng.md's DETECTION_REPORT.md template):
#   | Date | Mode | Focus | Summary | Git SHA |
# Take the last non-header, non-separator row and read its last `|`-delimited cell.
# ---------------------------------------------------------------------------

LAST_ROW=$(grep -E '^\|' "$DETECTION_REPORT" 2>/dev/null | grep -viE '^\| *date *\||^\|[- ]*\|[- ]*\|' | tail -1)

BASELINE_SHA=""
if [[ -n "$LAST_ROW" ]]; then
    RAW_SHA=$(printf '%s' "$LAST_ROW" | awk -F'|' '{cell=$(NF-1); gsub(/^[ \t]+|[ \t]+$/, "", cell); print cell}')
    # A real SHA is hex, 7-40 chars. Anything else (empty, "-", a leftover "[Git SHA]"
    # placeholder) means this row predates the field or was never filled in.
    if [[ "$RAW_SHA" =~ ^[0-9a-fA-F]{7,40}$ ]]; then
        if git -C "$REPO_ROOT" cat-file -e "${RAW_SHA}^{commit}" 2>/dev/null; then
            BASELINE_SHA="$RAW_SHA"
        fi
    fi
fi

BASELINE_SOURCE=""
if [[ -n "$BASELINE_SHA" ]]; then
    BASELINE_SOURCE="sha"
else
    # -----------------------------------------------------------------------
    # Tier 2: nearest commit at-or-before DETECTION_REPORT.md's own mtime.
    # GNU stat (Linux, Git Bash/MSYS on Windows) vs BSD stat (macOS) differ — try both.
    # -----------------------------------------------------------------------
    MTIME=$(stat -c %Y "$DETECTION_REPORT" 2>/dev/null || stat -f %m "$DETECTION_REPORT" 2>/dev/null || echo "")
    if [[ -n "$MTIME" ]]; then
        CANDIDATE=$(git -C "$REPO_ROOT" log -1 --before="@${MTIME}" --format=%H 2>/dev/null || echo "")
        if [[ -n "$CANDIDATE" ]]; then
            BASELINE_SHA="$CANDIDATE"
            BASELINE_SOURCE="mtime"
        fi
    fi
fi

if [[ -z "$BASELINE_SOURCE" ]]; then
    emit_none "no reachable Git SHA in DETECTION_REPORT.md and no mtime-derived commit found"
fi

# ---------------------------------------------------------------------------
# Changed files since the baseline: committed diff + uncommitted/untracked working-tree
# state (a real re-run may happen before prior work is committed).
# ---------------------------------------------------------------------------

COMMITTED_CHANGED=$(git -C "$REPO_ROOT" diff --name-only "$BASELINE_SHA" -- . 2>/dev/null || echo "")

# Full porcelain (status codes kept) so untracked entries (`??`) can be told apart from
# tracked-but-modified ones below — needed for the CLAUDE.md/AGENTS.md stateful exception.
STATUS_PORCELAIN=$(git -C "$REPO_ROOT" status --porcelain --untracked-files=all -- . 2>/dev/null || echo "")
WORKING_TREE_CHANGED=$(printf '%s\n' "$STATUS_PORCELAIN" | sed -E 's/^.. //' || echo "")
UNTRACKED_ONLY=$(printf '%s\n' "$STATUS_PORCELAIN" | grep -E '^\?\? ' | sed -E 's/^\?\? //' || echo "")

ALL_CHANGED=$(printf '%s\n%s\n' "$COMMITTED_CHANGED" "$WORKING_TREE_CHANGED" | sed '/^$/d' | sort -u)

# Static, exact path-prefix exclusion — deliberately narrow (see header comment). Never
# extension-based, never content-based, never a wildcard broad enough to catch .devcontainer/,
# src/test/, or a real *Test.java change.
TOOLING_PREFIX_REGEX='^(sdd/|\.git/|development-agents/|\.claude/|\.cursor/|graphify-out/)'

RELEVANT_CHANGED=$(printf '%s\n' "$ALL_CHANGED" | grep -vE "$TOOLING_PREFIX_REGEX" || true)
RELEVANT_CHANGED=$(printf '%s\n' "$RELEVANT_CHANGED" | sed '/^$/d')

# Stateful exception: root-level CLAUDE.md/AGENTS.md excluded ONLY when currently untracked
# (created by this SDD flow's own bootstrap, never committed). Exact filename match, root only
# — a nested docs/CLAUDE.md or similar is real project content, never touched by this rule.
if [[ -n "$RELEVANT_CHANGED" ]]; then
    FILTERED=""
    while IFS= read -r f; do
        [[ -z "$f" ]] && continue
        if { [[ "$f" == "CLAUDE.md" ]] || [[ "$f" == "AGENTS.md" ]]; } \
            && printf '%s\n' "$UNTRACKED_ONLY" | grep -qxF "$f"; then
            continue
        fi
        FILTERED+="$f"$'\n'
    done <<< "$RELEVANT_CHANGED"
    RELEVANT_CHANGED=$(printf '%s' "$FILTERED" | sed '/^$/d')
fi

DELTA_EMPTY="false"
[[ -z "$RELEVANT_CHANGED" ]] && DELTA_EMPTY="true"

# Convert newline-separated lists to bash arrays for json_array
mapfile -t ALL_CHANGED_ARR <<< "$ALL_CHANGED"
mapfile -t RELEVANT_CHANGED_ARR <<< "$RELEVANT_CHANGED"

CHANGED_JSON=$(json_array "${ALL_CHANGED_ARR[@]}")
RELEVANT_JSON=$(json_array "${RELEVANT_CHANGED_ARR[@]}")

printf '{"baseline_source":"%s","baseline_sha":"%s","current_sha":"%s","changed_files":%s,"relevant_changed_files":%s,"delta_empty":%s,"fallback":"none"}\n' \
    "$BASELINE_SOURCE" "$(json_escape "$BASELINE_SHA")" "$(json_escape "$CURRENT_SHA")" \
    "$CHANGED_JSON" "$RELEVANT_JSON" "$DELTA_EMPTY"

exit 0
