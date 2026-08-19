#!/bin/bash
# SDD SDD Kit - Scaffolding Status Detection Script
# Detects whether a project is freshly scaffolded (external template/starter,
# not yet developed) vs an established greenfield/brownfield project.
#
# Contract implemented here matches the plain-text rules already documented in
# commands/sdd.start.md:
#   - Step 2.5: freshly_scaffolded = 0-1 commits AND no sdd/specs or sdd/features
#   - Step 4:   project_mode = greenfield  if freshly_scaffolded, or no specs/features
#                                            and no application code markers
#                             = brownfield otherwise (existing specs/features,
#                                            or existing application code)
#
# Usage: detect-scaffolding-status.sh [PROJECT_PATH] [--json]
#
# Options:
#   --json  Output as JSON: {"project_mode":"...","freshly_scaffolded":true|false,
#                             "technology":"...","reason":"...","has_baseline":true|false}
#
# `has_baseline` (used by /sdd.project's navigation rule, commands/sdd.project.md): true if
# sdd/specs/ (promoted specs) OR sdd/extracted/ (a reverse-eng run's own working output, even if
# never promoted) has any content. This is the "does a reverse-eng/spec baseline already exist"
# signal — distinct from `project_mode`, which only asks greenfield-vs-brownfield. A brownfield
# project with `has_baseline:false` (real application code, but never reverse-engineered or
# spec'd) is the one case /sdd.project routes to `/sdd.reverse-eng` instead of `/sdd.start`.

set -e

PROJECT_PATH="."
JSON_OUTPUT=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --json) JSON_OUTPUT=true; shift ;;
        -*)
            # Skip unknown flags
            shift ;;
        *)
            # First non-flag argument is PROJECT_PATH
            PROJECT_PATH="$1"
            shift ;;
    esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ============================================
# Commit count (0 if not a git repo yet)
# ============================================

COMMIT_COUNT=0
if git -C "$PROJECT_PATH" rev-parse --git-dir >/dev/null 2>&1; then
    COMMIT_COUNT=$(git -C "$PROJECT_PATH" rev-list --count HEAD 2>/dev/null || echo 0)
fi

# ============================================
# Specs/features presence (non-empty dirs only)
# ============================================

HAS_SPECS_OR_FEATURES=false
if [ -d "$PROJECT_PATH/sdd/specs" ] && [ -n "$(ls -A "$PROJECT_PATH/sdd/specs" 2>/dev/null)" ]; then
    HAS_SPECS_OR_FEATURES=true
elif [ -d "$PROJECT_PATH/sdd/features" ] && [ -n "$(ls -A "$PROJECT_PATH/sdd/features" 2>/dev/null)" ]; then
    HAS_SPECS_OR_FEATURES=true
fi

# ============================================
# Baseline presence (sdd/specs/ OR sdd/extracted/ non-empty) — see header comment.
# Deliberately a separate signal from HAS_SPECS_OR_FEATURES above: sdd/features/ (archived,
# completed work) does NOT imply a reverse-eng/spec baseline exists, only sdd/specs/ does;
# sdd/extracted/ (a reverse-eng run's own raw output) counts even if never promoted to specs/.
# ============================================

HAS_BASELINE=false
if [ -d "$PROJECT_PATH/sdd/specs" ] && [ -n "$(ls -A "$PROJECT_PATH/sdd/specs" 2>/dev/null)" ]; then
    HAS_BASELINE=true
elif [ -d "$PROJECT_PATH/sdd/extracted" ] && [ -n "$(ls -A "$PROJECT_PATH/sdd/extracted" 2>/dev/null)" ]; then
    HAS_BASELINE=true
fi

# ============================================
# Application code markers (same signal set as detect-stack.sh's detect_level
# "app" case, reused here rather than re-invented)
# ============================================

HAS_CODE_MARKERS=false
if [ -f "$PROJECT_PATH/.platform-config" ] || \
   [ -d "$PROJECT_PATH/src" ] || \
   [ -f "$PROJECT_PATH/pom.xml" ] || \
   [ -f "$PROJECT_PATH/go.mod" ] || \
   [ -f "$PROJECT_PATH/package.json" ] || \
   [ -f "$PROJECT_PATH/requirements.txt" ] || \
   [ -f "$PROJECT_PATH/pyproject.toml" ] || \
   [ -f "$PROJECT_PATH/Cargo.toml" ] || \
   [ -f "$PROJECT_PATH/build.gradle" ] || \
   [ -f "$PROJECT_PATH/build.gradle.kts" ] || \
   [ -f "$PROJECT_PATH/Podfile" ] || \
   ls -d "$PROJECT_PATH"/*.xcodeproj 2>/dev/null | head -1 | grep -q ".xcodeproj" 2>/dev/null; then
    HAS_CODE_MARKERS=true
fi

# ============================================
# freshly_scaffolded (Step 2.5 rule)
# ============================================

FRESHLY_SCAFFOLDED=false
if [ "$COMMIT_COUNT" -le 1 ] && [ "$HAS_SPECS_OR_FEATURES" = false ]; then
    FRESHLY_SCAFFOLDED=true
fi

# ============================================
# project_mode (Step 4 rule)
# ============================================

if [ "$FRESHLY_SCAFFOLDED" = true ]; then
    PROJECT_MODE="greenfield"
    REASON="freshly scaffolded ($COMMIT_COUNT commit(s), no sdd/specs or sdd/features)"
elif [ "$HAS_SPECS_OR_FEATURES" = true ]; then
    PROJECT_MODE="brownfield"
    REASON="existing sdd/specs or sdd/features found"
elif [ "$HAS_CODE_MARKERS" = true ]; then
    PROJECT_MODE="brownfield"
    REASON="existing application code markers found"
else
    PROJECT_MODE="greenfield"
    REASON="no specs/features and no application code detected"
fi

# ============================================
# technology (delegate to detect-stack.sh, single source of truth)
# ============================================

TECHNOLOGY="unknown"
if [ -f "$SCRIPT_DIR/detect-stack.sh" ]; then
    stack_json=$(bash "$SCRIPT_DIR/detect-stack.sh" "$PROJECT_PATH" --json 2>/dev/null || true)
    detected=$(echo "$stack_json" | grep -o '"language": *"[^"]*"' | cut -d'"' -f4)
    [ -n "$detected" ] && TECHNOLOGY="$detected"
fi

# ============================================
# Output
# ============================================

if [ "$JSON_OUTPUT" = true ]; then
    echo "{\"project_mode\":\"$PROJECT_MODE\",\"freshly_scaffolded\":$FRESHLY_SCAFFOLDED,\"technology\":\"$TECHNOLOGY\",\"reason\":\"$REASON\",\"has_baseline\":$HAS_BASELINE}"
else
    echo "🔍 Scaffolding Status: $PROJECT_MODE (freshly_scaffolded=$FRESHLY_SCAFFOLDED)"
    echo "   Technology: $TECHNOLOGY"
    echo "   Reason: $REASON"
    echo "   Baseline (sdd/specs or sdd/extracted): $HAS_BASELINE"
fi
