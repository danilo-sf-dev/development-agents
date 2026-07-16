# Reference: Reverse-Eng Project Configuration

**Used by**: `/sdd.reverse-eng` Phase 0 pre-step 2.

### Phase 0 Pre-step 2: Project Configuration Check (MANDATORY)

> **PURPOSE**: Ensure PROJECT.md and CLAUDE.md exist before extraction, so specs are written in the correct language.

**ALWAYS execute AFTER directory structure creation, BEFORE Phase 0 detection**:

```pseudocode
# 1. Ensure PROJECT.md exists (needed for language resolution)
IF NOT EXISTS sdd/PROJECT.md:
    → Invoke Skill("sdd.project") — runs wizard, creates PROJECT.md with language
    → Wait for wizard completion before continuing

# 2. Ensure CLAUDE.md exists (Claude Code session bootstrap)
IF .claude/ directory exists:
    # Resolve language from PROJECT.md
    spec_lang = read language.specs from sdd/PROJECT.md (fallback: "en")
    lang_names = { "en": "English", "es": "Spanish (Español)", "pt": "Portuguese (Português)" }
    lang_name = lang_names[spec_lang] or "English"

    IF NOT EXISTS CLAUDE.md:
        → Generate CLAUDE.md with SDD Kit section
           (language, workflow, links to PROJECT.md and PATTERNS.md)
        → Note: /init is a built-in CLI command and CANNOT be invoked programmatically
        → User can run /init later to enrich CLAUDE.md; framework re-injects project section on next run
    ELSE IF CLAUDE.md exists but missing "## SDD Kit" section:
        → Append SDD Kit section (preserve existing content)
    ELSE:
        → Update existing "## SDD Kit" section (e.g., language changed)

# 3. Continue Phase 0 with language resolved from PROJECT.md
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

> **Lazy-loaded**: When `platform = android` or `platform = ios`, Read `references/start-mobile-claude.md` before appending the Mobile Implementation Rule to `CLAUDE.md`.

---
