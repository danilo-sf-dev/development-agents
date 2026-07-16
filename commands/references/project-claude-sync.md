# Reference: PROJECT.md ↔ CLAUDE.md Language Sync

**Used by**: `/sdd.project` after language change.

## CLAUDE.md Sync on Language Change

> **MANDATORY**: After writing/updating PROJECT.md, sync the spec language to CLAUDE.md if it exists.

**When to execute**: After ANY write to PROJECT.md that includes `language.specs` (wizard, prompt inference, or `--edit`).

```pseudocode
IF .claude/ directory exists AND CLAUDE.md exists:
    # Resolve language from just-written PROJECT.md
    spec_lang = read language.specs from sdd/PROJECT.md (fallback: "en")
    lang_names = { "en": "English", "es": "Spanish (Español)", "pt": "Portuguese (Português)" }
    lang_name = lang_names[spec_lang] or "English"

    IF CLAUDE.md contains "## SDD Kit":
        → Replace existing "## SDD Kit" section with updated language
           (from that header to the next ## header or end of file)
    ELSE:
        → Append SDD Kit section to end of CLAUDE.md
```

**SDD Kit section** (same template as `/sdd.start` Step 9.5):
```markdown
## SDD Kit

This project uses **SDD Kit** for spec-driven development.

### Spec Language
All specifications MUST be written in **[lang_name]** (`[spec_lang]`).
Do not mix languages in specs. Technical terms (API, REST, CRUD) stay in English.

### Quick Reference
- Framework expert: `Skill("sdd-kit-expert")`
- Workflow: `/sdd.start` → `/sdd.spec` → `/sdd.plan` → `/sdd.test` → `/sdd.build` → `/sdd.finish` (canonical: `framework/PIPELINE.md`)
- Project conventions: `sdd/PROJECT.md`
- Discovered patterns: `sdd/PATTERNS.md`

### Rules
- Never create files under `sdd/specs/`, `sdd/wip/`, or `sdd/features/` manually
- Always go through the `/sdd.start` workflow
- Respect the phased workflow — don't skip phases
```

**Important**: Only replace the `## SDD Kit` section — never touch any other content in CLAUDE.md.

---
