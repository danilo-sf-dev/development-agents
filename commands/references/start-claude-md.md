# Reference: Start CLAUDE.md Integration

**Used by**: `/sdd.start` Step 9.5.

### Step 9.5: CLAUDE.md Integration (Claude Code Only)

> **PURPOSE**: Inject SDD Kit section into CLAUDE.md for session-bootstrap language enforcement.

**Precondition**: Only execute if `.claude/` directory exists (indicates Claude Code project).

```pseudocode
IF .claude/ directory exists:
    # Resolve language name for display
    spec_lang = resolved from Step 8
    lang_names = { "en": "English", "es": "Spanish (Español)", "pt": "Portuguese (Português)" }
    lang_name = lang_names[spec_lang] or "English"

    IF CLAUDE.md does NOT exist:
        → Generate CLAUDE.md with SDD Kit section (see template below)
    ELSE IF CLAUDE.md exists but does NOT contain "## SDD Kit":
        → Append SDD Kit section to end of file (preserve existing content)
    ELSE:
        → Replace existing "## SDD Kit" section with updated version
           (e.g., language may have changed)
```

**SDD Kit section template**:

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

> **Lazy-loaded**: When `platform = android` or `platform = ios`, Read `references/start-mobile-claude.md` before appending the Mobile Implementation Rule to `CLAUDE.md`.

**Section replacement rules**:
- Framework ONLY owns the `## SDD Kit` section — never touch the rest of CLAUDE.md
- If user ran `/init` before, their content is preserved; we just append our section
- The section is idempotent: if `## SDD Kit` exists, replace from that header to the next `##` header (or end of file)
- If user runs `/init` after, they can re-run `/sdd.start` to re-inject the section
