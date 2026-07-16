#!/usr/bin/env python3
"""Apply remaining rare-branch extractions (project, check, fix, finish, reverse-eng)."""

from __future__ import annotations

from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
COMMANDS = ROOT / "commands"


def read_text(path: Path) -> str:
    raw = path.read_bytes()
    if raw.startswith(b"\xef\xbb\xbf"):
        return raw.decode("utf-8-sig")
    return raw.decode("utf-8")


def write_text(path: Path, content: str) -> None:
    path.write_text(content.rstrip() + "\n", encoding="utf-8", newline="\n")


def replace_block(text: str, start: str, end: str, replacement: str) -> str:
    start_idx = text.index(start)
    end_idx = text.index(end, start_idx)
    return text[:start_idx] + replacement.rstrip() + "\n\n" + text[end_idx:]


def extract_project() -> None:
    path = COMMANDS / "sdd.project.md"
    text = read_text(path)

    mode7_start = "## Mode 7: Framework Viewer (`--view`)"
    mode7_end = "---\n\n## AI Agent Instructions"
    text = replace_block(
        text,
        mode7_start,
        mode7_end,
        "> **Lazy-loaded**: When `--view` is present, Read `references/project-view.md` and follow it.\n",
    )

    hub_start = "### --hub Flag Detection"
    view_start = "### --view Flag Detection"
    hub_block = text[text.index(hub_start) : text.index(view_start, text.index(hub_start))]

    optional = """## Optional flags (lazy-loaded)

**Before the standard wizard**, if any flag below is present, read its reference first:

| Flag | Reference | Behavior |
|------|-----------|----------|
| `--hub` | `references/project-hub.md` | Replace standard wizard |
| `--view` | `references/project-view.md` | Replace all other logic |
| `--audio` | `references/audio-capture-flow.md` | Feeds wizard interview answers |

"""
    text = text.replace(hub_block, optional)
    text = text.replace(
        "### --view Flag Detection\n\n**WHEN** user runs `/sdd.project --view`:\n\n1. **Run the viewer script**:\n   ```bash\n   bash development-agents/framework/tools/state/view-framework.sh \"$(pwd)\"\n   ```\n2. **Report result** to user (generated files, browser opened)\n3. Do NOT execute any other project logic\n",
        "",
    )
    # Remove duplicate audio header block if optional table covers it
    text = text.replace(
        "### --audio Flag Detection\n\n> **Lazy-loaded**: When `--audio` is present, Read `references/audio-capture-flow.md` and follow the `/sdd.project --audio` mapping (transcription feeds the `sdd-project-wizard` interview answers).\n\n",
        "",
    )
    write_text(path, text)


def extract_check() -> None:
    path = COMMANDS / "sdd.check.md"
    text = read_text(path)

    rules_start = "### --sync Specific Rules"
    rules_end = "---\n\n## Related Commands"
    replacement = """## Optional flags (lazy-loaded)

Read the matching reference **only** when the flag is present:

| Flag | Rules | Output examples |
|------|-------|-----------------|
| `--sync` | `references/check-flag-rules.md` § `--sync` | `references/check-output-examples.md` § `--sync` |
| `--compliance` | `references/check-flag-rules.md` § `--compliance` | `references/check-output-examples.md` § `--compliance` |
| `--project` | `references/check-flag-rules.md` § `--project` | `references/check-output-examples.md` § `--project` |
| `--version` | `references/check-flag-rules.md` § `--version` | `references/check-output-examples.md` § `--version` |
"""
    text = replace_block(text, rules_start, rules_end, replacement)
    write_text(path, text)


def extract_fix() -> None:
    path = COMMANDS / "sdd.fix.md"
    text = read_text(path)

    dangerous_start = "### ⚠️ Dangerous Flags Warning"
    dangerous_end = "---\n\n## Output Format"
    dangerous_block = text[
        text.index(dangerous_start) : text.index(dangerous_end, text.index(dangerous_start))
    ]
    text = text.replace(
        dangerous_block,
        "> **Lazy-loaded**: When `--code-only` or `--layer` is present, Read `references/fix-dangerous-flags.md` before proceeding.\n\n",
    )

    batch_start = "### --batch Flag Detection ⭐ v1.7.0"
    batch_end = "### Key Rules"
    batch_block = text[text.index(batch_start) : text.index(batch_end, text.index(batch_start))]
    text = text.replace(
        batch_block,
        "> **Lazy-loaded**: When `--batch` is present (or Step -1 detects N > 1), Read `references/fix-batch.md`.\n\n",
    )

    # Update internal anchor references
    text = text.replace(
        "See [--batch Flag Detection](#--batch-flag-detection-v170) for the subagent implementation.",
        "See `references/fix-batch.md` for the subagent implementation.",
    )
    text = text.replace(
        "→ Full template: see [--batch Flag Detection](#--batch-flag-detection-v170)",
        "→ Full template: see `references/fix-batch.md`",
    )

    optional = """
## Optional flags (lazy-loaded)

| Flag | Reference |
|------|-----------|
| `--batch` | `references/fix-batch.md` |
| `--audio` | `references/audio-capture-flow.md` |
| `--code-only`, `--layer` | `references/fix-dangerous-flags.md` |
| Classification / Plan Mode | `references/classification-guide.md`, `references/fix-templates.md` (see lazy-load pointers in workflow) |
"""
    if "## Optional flags (lazy-loaded)" not in text:
        text = text.rstrip() + "\n" + optional + "\n"

    write_text(path, text)


def extract_finish() -> None:
    path = COMMANDS / "sdd.finish.md"
    text = read_text(path)

    ci_mobile = "**If `IS_MOBILE = true`** — run mobile tests instead of the CI pipeline:"
    ci_end = "**If `IS_MOBILE = false`** — use the project's configured CI command"
    if ci_mobile in text:
        start_idx = text.index(ci_mobile)
        end_idx = text.index(ci_end, start_idx)
        text = (
            text[:start_idx]
            + "> **Lazy-loaded**: When `IS_MOBILE = true`, Read `references/finish-mobile-validation.md` § CI validation.\n\n"
            + text[end_idx:]
        )

    comp_mobile = "**If `IS_MOBILE = true`** — run mobile compliance via `sdd-validator` skill:"
    comp_end = "**If `IS_MOBILE = false`** — run  platform compliance:"
    if comp_mobile in text:
        start_idx = text.index(comp_mobile)
        end_idx = text.index(comp_end, start_idx)
        # Find end of mobile block (next **If or ####)
        mobile_block_end = text.find("\n\n**If `IS_MOBILE = false`**", start_idx)
        if mobile_block_end == -1:
            mobile_block_end = end_idx
        text = (
            text[:start_idx]
            + "> **Lazy-loaded**: When `IS_MOBILE = true`, Read `references/finish-mobile-validation.md` § Platform compliance.\n\n"
            + text[mobile_block_end + 2 :]  # skip the blank line before **If false
        )

    optional = """
## Optional conditions (lazy-loaded)

| Condition | Reference |
|-----------|-----------|
| `PROFILE == TECHNICAL_ONLY` or `NON_TECHNICAL_ONLY` | `references/output-examples-by-profile.md` |
| `IS_MOBILE = true` | `references/finish-mobile-validation.md` |
"""
    if "## Optional conditions (lazy-loaded)" not in text:
        # Insert before AI Agent Instructions if present
        marker = "## AI Agent Instructions"
        if marker in text:
            idx = text.index(marker)
            text = text[:idx] + optional.strip() + "\n\n---\n\n" + text[idx:]
        else:
            text = text.rstrip() + "\n" + optional + "\n"

    write_text(path, text)


def extract_reverse_eng() -> None:
    path = COMMANDS / "sdd.reverse-eng.md"
    text = read_text(path)

    focus_start = "### `--focus` Behavior (CRITICAL)"
    focus_end = "### ⚠️ ANTI-PATTERN: No `-UPDATED` Suffixes"
    focus_block = text[text.index(focus_start) : text.index(focus_end, text.index(focus_start))]
    text = text.replace(
        focus_block,
        "> **Lazy-loaded**: When `--focus` is present, Read `references/reverse-eng-focus.md`.\n\n",
    )

    mobile_start = "> **CONDITIONAL — Mobile Implementation Rule**"
    mobile_end = "---\n\n### Phase 0: Repository State Detection"
    if mobile_start in text:
        text = replace_block(
            text,
            mobile_start,
            mobile_end,
            "> **Lazy-loaded**: When `platform = android` or `platform = ios`, Read "
            "`references/start-mobile-claude.md` before appending the Mobile Implementation Rule to `CLAUDE.md`.\n",
        )

    optional = """
## Optional flags (lazy-loaded)

| Flag / condition | Reference |
|------------------|-----------|
| `--focus` | `references/reverse-eng-focus.md` |
| `--focus --audio` | `references/audio-capture-flow.md` + `references/reverse-eng-focus.md` |
| mode FULL or ENHANCE (code ownership) | `references/code-ownership.md` |
| `platform = android \| ios` (CLAUDE.md) | `references/start-mobile-claude.md` |
"""
    audio_header = "### --audio Flag Detection (with --focus)\n\n> **Lazy-loaded**: When `--audio` is present alongside `--focus`, Read `references/audio-capture-flow.md` and follow the `/sdd.reverse-eng --audio` mapping (transcription becomes the `--focus` scope description).\n\n"
    if audio_header in text:
        text = text.replace(audio_header, "")

    if "## Optional flags (lazy-loaded)" not in text:
        marker = "### Phase 0: Repository State Detection Rules"
        if marker in text:
            idx = text.index(marker)
            text = text[:idx] + optional.strip() + "\n\n" + text[idx:]

    write_text(path, text)


def patch_start_mobile_header() -> None:
    path = REFERENCES / "start-mobile-claude.md"
    if not path.exists():
        return
    text = read_text(path)
    if "reverse-eng" not in text:
        text = text.replace(
            "**Used by**: `/sdd.start` Step 9.5",
            "**Used by**: `/sdd.start` Step 9.5 and `/sdd.reverse-eng` CLAUDE.md integration",
        )
        write_text(path, text)


def add_optional_flags_small_commands() -> None:
    patches = {
        "sdd.go.md": """
## Optional flags (lazy-loaded)

| Flag | Reference |
|------|-----------|
| `--audio` | `references/audio-capture-flow.md` |
""",
        "sdd.cancel.md": """
## Optional flags (lazy-loaded)

| Flag | Reference |
|------|-----------|
| `--audio` | `references/audio-capture-flow.md` |
""",
        "sdd.backlog.md": """
## Optional flags (lazy-loaded)

| Flag / condition | Reference |
|------------------|-----------|
| `--audio` (with `add`) | `references/audio-capture-flow.md` |
| DEBT/TODO workflow modes | `references/workflow-modes.md` |
| modes 2/3 auto-generation | `references/auto-spec-template.md` |
""",
    }
    for name, block in patches.items():
        path = COMMANDS / name
        text = read_text(path)
        # Remove standalone audio lazy-load headers (now in table)
        for old in [
            "### --audio Flag Detection\n\n> **Lazy-loaded**: When `--audio` is present, Read `references/audio-capture-flow.md` and follow the `/sdd.go --audio` mapping (transcription becomes the feature description), then continue to Step 0 below.\n\n",
            "### --audio Flag Detection\n\n> **Lazy-loaded**: When `--audio` is present, Read `references/audio-capture-flow.md` and follow the `/sdd.cancel --audio` mapping (feature name + cancellation reason, in that order).\n\n",
            "### --audio Flag Detection (with add)\n\n> **Lazy-loaded**: When `--audio` is present alongside `add`, Read `references/audio-capture-flow.md` and follow the `/sdd.backlog --audio` mapping (transcription becomes the item's title/description).\n\n",
        ]:
            text = text.replace(old, "")
        if "## Optional flags (lazy-loaded)" not in text:
            text = text.rstrip() + "\n" + block + "\n"
        write_text(path, text)


REFERENCES = COMMANDS / "references"


def main() -> None:
    extract_project()
    extract_check()
    extract_fix()
    extract_finish()
    extract_reverse_eng()
    patch_start_mobile_header()
    add_optional_flags_small_commands()
    print("Applied remaining rare-branch extractions")


if __name__ == "__main__":
    main()
