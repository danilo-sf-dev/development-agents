#!/usr/bin/env python3
"""Replace duplicated agent-instructions boilerplate in command files."""

from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
COMMANDS = ROOT / "commands"

REF_LINE = (
    "> **Shared agent instructions**: Read "
    "`development-agents/framework/_shared/agent-instructions.md` "
    "before executing this command.\n\n"
)

HOW_TO_READ = """### HOW TO READ THIS SKILL

When you see a block like this:

⛔ INVOKE TOOL (do not print this, CALL the tool):
AskUserQuestion(questions=[{...}])

This is a TOOL CALL you must execute, not content to display.

| WRONG | CORRECT |
|-------|---------|
| Bash(echo "1. Option A") | Directly call the AskUserQuestion tool |
| Print the JSON to terminal | Pass the parameters shown to the tool |

"""

CRITICAL = """
CRITICAL: USER INTERACTION RULES
When this skill shows JSON for AskUserQuestion, you MUST:
  1. CALL the AskUserQuestion TOOL with that exact JSON
  2. DO NOT print options using Bash (no echo, cat, printf)
  3. DO NOT ask "Which option?" as text
  4. Tables marked "REFERENCE ONLY" are for docs - do NOT print

"""

CRITICAL_WITH_HR = CRITICAL + "---\n\n"


def transform(content: str) -> tuple[str, bool]:
    if HOW_TO_READ not in content:
        return content, False

    updated = content.replace(HOW_TO_READ, REF_LINE, 1)
    if CRITICAL_WITH_HR in updated:
        updated = updated.replace(CRITICAL_WITH_HR, "\n", 1)
    elif CRITICAL in updated:
        updated = updated.replace(CRITICAL, "\n", 1)

    return updated, True


def main() -> None:
    updated_files: list[str] = []
    skipped_files: list[str] = []

    for path in sorted(COMMANDS.glob("sdd*.md")):
        original = path.read_text(encoding="utf-8")
        transformed, changed = transform(original)
        if not changed:
            skipped_files.append(path.name)
            continue
        path.write_text(transformed, encoding="utf-8", newline="\n")
        updated_files.append(path.name)

    print(f"Updated ({len(updated_files)}): {', '.join(updated_files)}")
    if skipped_files:
        print(f"Skipped ({len(skipped_files)}): {', '.join(skipped_files)}")


if __name__ == "__main__":
    main()
