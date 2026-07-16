from pathlib import Path

path = Path("commands/sdd.check.md")
text = path.read_bytes().decode("utf-8-sig")
start = "## `/sdd.check --sync` - Consistency Validation"
end = "---\n\n## AI Agent Instructions"
si = text.index(start)
ei = text.index(end, si)
block = text[si:ei].strip()
header = """# Reference: /sdd.check Rare Workflows

**Used by**: `/sdd.check --sync`, `--compliance`, `--project`, `--version`, `task TASK-XXX`, `--resume`.

For rules and output examples, also read `references/check-flag-rules.md` and `references/check-output-examples.md`.

---

"""
Path("commands/references/check-rare-workflows.md").write_text(
    header + block + "\n", encoding="utf-8", newline="\n"
)
replacement = """## Rare workflows (lazy-loaded)

When a flag-specific variant is invoked, read `references/check-rare-workflows.md` (matching section) plus the rules/examples in **Optional flags** below.

"""
path.write_text(text[:si] + replacement + text[ei:], encoding="utf-8", newline="\n")
print(f"extracted {len(block.splitlines())} lines from sdd.check.md")
