#!/bin/bash
# SDD Kit — Project Instructions Section Merge (mechanical half of WRITE_PROJECT_INSTRUCTIONS)
#
# The section-merge logic in commands/references/project-instructions-sync.md is 100%
# mechanical (find "## SDD Kit", replace to the next "## " header or EOF; otherwise append or
# create) — it needs no LLM judgment, unlike most of this framework's prose-driven procedures.
# This script implements that mechanical half so it can be tested deterministically, real file
# in, real file out — no markdown grep, no narration.
#
# What stays in commands/references/project-instructions-sync.md (prose, LLM-driven, NOT this
# script's job): resolving spec_lang, choosing which target files apply per adapter, rendering
# the section template's placeholders, and calling framework/tools/project-instructions-
# git-guard.sh on the create branch. This script only does the merge mechanics once the final
# section text is already rendered.
#
# Usage:
#   project-instructions-sync.sh --file <target_file> --section-file <rendered_section.md>
#
# `<rendered_section.md>` must start with a `## ` header line (the section header itself, e.g.
# "## SDD Kit") — its own first line's header text is what this script matches against when
# looking for an existing section to replace.
#
# Behavior:
#   - target_file does not exist -> create it, content = section-file's content verbatim
#   - target_file exists, does NOT contain the section header -> append section-file's content
#     to the end (preserving 100% of existing content, exactly one blank line separator)
#   - target_file exists, DOES contain the section header -> replace only that section (from
#     the header line to the next line starting with "## " or EOF) with section-file's content;
#     everything else in the file is byte-for-byte preserved
#
# Output (stdout, KEY=value lines):
#   SYNC_ACTION=created|appended|replaced|error
#
# Exit code: 0 on success, 1 if arguments are missing/invalid. Never destructive — never
# touches any file other than target_file, never deletes target_file.

set -u

TARGET_FILE=""
SECTION_FILE=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --file)         TARGET_FILE="$2";  shift 2 ;;
        --section-file) SECTION_FILE="$2"; shift 2 ;;
        *) shift ;;
    esac
done

if [[ -z "$TARGET_FILE" || -z "$SECTION_FILE" || ! -f "$SECTION_FILE" ]]; then
    echo "SYNC_ACTION=error"
    echo "project-instructions-sync.sh: --file and --section-file (must exist) are required" >&2
    exit 1
fi

SECTION_HEADER=$(head -1 "$SECTION_FILE")
if [[ "$SECTION_HEADER" != "## "* ]]; then
    echo "SYNC_ACTION=error"
    echo "project-instructions-sync.sh: section-file must start with a '## ' header line" >&2
    exit 1
fi

if [[ ! -f "$TARGET_FILE" ]]; then
    cp "$SECTION_FILE" "$TARGET_FILE"
    echo "SYNC_ACTION=created"
    exit 0
fi

if ! grep -qxF "$SECTION_HEADER" "$TARGET_FILE"; then
    printf '\n' >> "$TARGET_FILE"
    cat "$SECTION_FILE" >> "$TARGET_FILE"
    echo "SYNC_ACTION=appended"
    exit 0
fi

# Replace only the existing section: everything before the header line, then the new section
# content, then everything from the next "## " header (or EOF) onward. Preserves byte-for-byte
# everything outside the matched section.
TMP_FILE=$(mktemp)
awk -v header="$SECTION_HEADER" -v secfile="$SECTION_FILE" '
    BEGIN { in_section = 0; inserted = 0 }
    $0 == header {
        in_section = 1
        while ((getline line < secfile) > 0) print line
        close(secfile)
        inserted = 1
        next
    }
    in_section && /^## / {
        in_section = 0
    }
    in_section { next }
    { print }
' "$TARGET_FILE" > "$TMP_FILE"

mv "$TMP_FILE" "$TARGET_FILE"
echo "SYNC_ACTION=replaced"
exit 0
