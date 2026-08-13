# Reference: Project Instructions Sync (`WRITE_PROJECT_INSTRUCTIONS`)

**Used by**: `/sdd.start` Step 9.5, `/sdd.project` after a language change, and the installer agent (`skills/sdd-installer/SKILL.md`) Passos 3/4b. Implements the `WRITE_PROJECT_INSTRUCTIONS` capability from `framework/_shared/harness-capabilities.md` — read that file first if you haven't already.

Replaces the old harness-specific `start-claude-md.md` (Claude Code only) and `project-claude-sync.md` (Claude Code only) references, which duplicated ~90% of this logic and had no Codex/Cursor equivalent. One procedure now, parameterized by which file each adapter owns.

---

## Which file each adapter writes

| Adapter     | Target file                                                                                                            | Precondition to write                                                                     |
| ----------- | ---------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------- |
| Claude Code | `CLAUDE.md` (project root)                                                                                             | `.claude/` directory exists                                                               |
| Codex CLI   | `AGENTS.md` (project root)                                                                                             | `.agents/` directory exists, or the Codex adapter was explicitly selected at install time |
| Cursor      | _(none — uses `.cursor/rules/sdd-workflow.mdc` instead, which is a full file the installer owns, not a section merge)_ | n/a                                                                                       |
| Generic     | _(none — no file written; the installer prints the section content for the operator to paste manually)_                | n/a                                                                                       |

If more than one of `.claude/`/`.agents/` exists (multi-adapter project), sync **both** `CLAUDE.md` and `AGENTS.md` — run the procedure once per target file.

---

## Procedure (idempotent, section-scoped merge — same for every target file)

```pseudocode
FOR EACH target_file IN applicable files (per table above):
    spec_lang = resolved from Step 8 (/sdd.start) or read from sdd/PROJECT.md language.specs (/sdd.project)
    lang_names = { "en": "English", "es": "Spanish (Español)", "pt": "Portuguese (Português)" }
    lang_name = lang_names[spec_lang] or "English"

    IF target_file does NOT exist:
        → Create target_file with the SDD Kit section (template below) as its entire content
    ELSE IF target_file exists but does NOT contain "## SDD Kit":
        → Append the SDD Kit section to the end of the file — preserve 100% of existing content
    ELSE:
        → Replace only the existing "## SDD Kit" section (from that header to the next `##` header
          or end of file) with the updated version — e.g. when the spec language changed
```

**Section replacement rule (governs every target file, every adapter — this is what B-16 in `framework/standards/boundaries.md` permits)**: the SDD Kit section is the _only_ content this framework owns in `target_file`. Never touch anything else in the file. If the user ran `/init` (Claude Code) or otherwise already has project instructions, that content is preserved — this procedure only ever creates, appends, or replaces its own marked section.

## SDD Kit section template (same for `CLAUDE.md` and `AGENTS.md`)

```markdown
## SDD Kit

This project uses **SDD Kit** for spec-driven development.

### Spec Language
All specifications MUST be written in **[lang_name]** (`[spec_lang]`).
Do not mix languages in specs. Technical terms (API, REST, CRUD) stay in English.

### Quick Reference
- Framework expert: `Skill("sdd-kit-expert")` (or read `development-agents/skills/sdd-kit-expert/SKILL.md` directly if `Skill()` isn't available — see `framework/_shared/harness-capabilities.md`, `INVOKE_PROCEDURE`)
- Workflow: `/sdd.start` → `/sdd.spec` → `/sdd.plan` → `/sdd.test` → `/sdd.build` → `/sdd.check` → `/sdd.finish` (canonical: `framework/PIPELINE.md`)
- Project conventions: `sdd/PROJECT.md`
- Discovered patterns: `sdd/PATTERNS.md`

### Rules
- Never create files under `sdd/specs/`, `sdd/wip/`, or `sdd/features/` manually
- Always go through the `/sdd.start` workflow
- Respect the phased workflow — don't skip phases
```

> **Lazy-loaded**: When `platform = android` or `platform = ios`, read `references/start-mobile-claude.md` before appending the Mobile Implementation Rule to the target file.

---

## Trigger points

- `/sdd.start` Step 9.5, first time a project is bootstrapped.
- `/sdd.project` after any write to `PROJECT.md` that includes `language.specs` (wizard, prompt inference, or `--edit`).
- `skills/sdd-installer/SKILL.md` Passo 3 (Claude Code adapter) / Passo 4b (Codex adapter), on install or reinstall.
