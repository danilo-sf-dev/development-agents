#!/usr/bin/env python3
"""Extract rare-branch sections from command files into references/."""

from __future__ import annotations

from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
COMMANDS = ROOT / "commands"
REFERENCES = COMMANDS / "references"


def read_text(path: Path) -> str:
    raw = path.read_bytes()
    if raw.startswith(b"\xef\xbb\xbf"):
        return raw.decode("utf-8-sig")
    return raw.decode("utf-8")


def write_text(path: Path, content: str) -> None:
    path.write_text(content.rstrip() + "\n", encoding="utf-8", newline="\n")


def replace_block(text: str, start: str, end: str | None, replacement: str) -> str:
    start_idx = text.index(start)
    if end is None:
        return text[:start_idx] + replacement + "\n"
    end_idx = text.index(end, start_idx)
    return text[:start_idx] + replacement.rstrip() + "\n\n" + text[end_idx:]


def extract_start() -> None:
    path = COMMANDS / "sdd.start.md"
    text = read_text(path)

    mobile_start = "> **CONDITIONAL — Mobile Implementation Rule**"
    mobile_end = "**Section replacement rules**:"
    mobile_block = text[text.index(mobile_start) : text.index(mobile_end, text.index(mobile_start))]
    write_text(
        REFERENCES / "start-mobile-claude.md",
        f"""# Reference: Mobile CLAUDE.md Section (`/sdd.start`)

**Used by**: `/sdd.start` Step 9.5, when `platform = android` or `platform = ios`.

Append this platform-specific section **after** the base `## SDD Kit` block in `CLAUDE.md`.
Read `$platform` from the `$IS_MOBILE` flag or `detect-stack.sh` output (already resolved in Step 2).
Do NOT append for backend, web, or empty platform.

{mobile_block.strip()}
""",
    )

    rename_start = "## --rename Flag"
    rename_block = text[text.index(rename_start) :].strip()
    write_text(
        REFERENCES / "start-rename.md",
        f"""# Reference: `/sdd.start --rename`

**Used by**: `/sdd.start --rename [new-name]`.

{rename_block.replace("## --rename Flag\n\n", "").strip()}
""",
    )

    backlog_start = "## From Backlog Option"
    backlog_end = "## --reopen Flag"
    backlog_block = text[
        text.index(backlog_start) : text.index(backlog_end, text.index(backlog_start))
    ].strip()
    write_text(
        REFERENCES / "start-from-backlog.md",
        f"""# Reference: `/sdd.start --from-backlog`

**Used by**: `/sdd.start --from-backlog <ID>`.

{backlog_block.replace("## From Backlog Option\n\n", "").strip()}
""",
    )

    examples_start = "### --audio Flag Detection"
    examples_end = "## From Backlog Option"
    examples_block = text[
        text.index(examples_start) : text.index(examples_end, text.index(examples_start))
    ].strip()
    write_text(
        REFERENCES / "start-examples.md",
        f"""# Reference: `/sdd.start` Output Examples

**Used by**: `/sdd.start` (optional UX reference — not required for the standard path).

{examples_block.replace("### --audio Flag Detection\n\n", "").strip()}
""",
    )

    write_text(
        REFERENCES / "start-audio.md",
        """# Reference: `/sdd.start --audio`

**Used by**: `/sdd.start --audio`.

## Flow

1. Run the standard `/sdd.start` initialization through Step 11 (feature folder + `meta.md`).
2. Explain that the recording becomes the saved description for `/sdd.spec`.
3. Start the configured audio capture tool:

```bash
python3 development-agents/framework/tools/audio-capture/server.py
```

4. Transcribe the recording.
5. Store the transcription in `meta.md` as the saved description / initial context.
6. Invoke `Skill("sdd.spec", args="--audio")` **or** continue with `/sdd.spec` using the saved transcription as initial context.
7. If capture or transcription fails, ask the user to provide the description as text instead.

Audio input enriches the start/spec interview; it does not skip required gates.
""",
    )

    optional_flags = """## Optional flags (lazy-loaded)

Read the matching reference **only** when the flag is present:

| Flag / condition | Reference |
|------------------|-----------|
| `--reopen` | `references/reopen-workflow.md` |
| `--rename` | `references/start-rename.md` |
| `--from-backlog <ID>` | `references/start-from-backlog.md` |
| `--audio` | `references/start-audio.md` |

> **Output examples** (optional UX reference): `references/start-examples.md`
"""

    text = replace_block(
        text,
        mobile_start,
        mobile_end,
        "> **Lazy-loaded**: When `platform = android` or `platform = ios`, Read "
        "`references/start-mobile-claude.md` before appending the Mobile Implementation Rule to `CLAUDE.md`.\n",
    )

    text = replace_block(text, examples_start, None, optional_flags)
    write_text(path, text)


def extract_spec() -> None:
    path = COMMANDS / "sdd.spec.md"
    text = read_text(path)

    mobile_start = "#### Mobile Technical Spec (platform = android | ios)"
    mobile_end = "#### Backend/Web Technical Spec (platform = backend | web | \"\")"
    mobile_block = text[
        text.index(mobile_start) : text.index(mobile_end, text.index(mobile_start))
    ].strip()
    write_text(
        REFERENCES / "spec-mobile-technical.md",
        f"""# Reference: Mobile Technical Spec (`/sdd.spec`)

**Used by**: `/sdd.spec technical`, when `platform = android` or `platform = ios`.

{mobile_block}
""",
    )

    approve_start = "### --approve Flag Detection"
    approve_end = "---\n\n## `--summary` Flag Behavior"
    approve_block = text[
        text.index(approve_start) : text.index(approve_end, text.index(approve_start))
    ].strip()
    write_text(
        REFERENCES / "spec-approve.md",
        f"""# Reference: `/sdd.spec --approve`

**Used by**: `/sdd.spec functional --approve` or `/sdd.spec technical --approve`.

{approve_block.replace("### --approve Flag Detection\n\n", "").strip()}
""",
    )

    text = replace_block(
        text,
        mobile_start,
        mobile_end,
        "> **Lazy-loaded**: When `platform = android` or `platform = ios`, Read "
        "`references/spec-mobile-technical.md` for the complete mobile technical spec workflow.\n",
    )

    text = text.replace(
        approve_block,
        "**WHEN** the user runs `/sdd.spec functional --approve` or `/sdd.spec technical --approve`, "
        "Read `references/spec-approve.md` and follow it.\n",
    )

    summary_section_start = "## `--summary` Flag Behavior"
    summary_section_end = "## `--audio` Flag Behavior"
    text = replace_block(
        text,
        summary_section_start,
        summary_section_end,
        "> **Lazy-loaded**: When `--summary` is present, Read `references/spec-summary.md`.\n",
    )

    audio_section_start = "## `--audio` Flag Behavior"
    if audio_section_start in text:
        text = text[: text.index(audio_section_start)].rstrip() + (
            "\n\n> **Lazy-loaded**: When `--audio` is present, Read `references/spec-audio.md`.\n"
        )

    write_text(path, text)


def main() -> None:
    extract_start()
    extract_spec()
    print("Extracted rare branches for sdd.start and sdd.spec")


if __name__ == "__main__":
    main()
