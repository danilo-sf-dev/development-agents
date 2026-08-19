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

The merge mechanics (create vs. append vs. replace-section) are 100% deterministic — no LLM
judgment needed — so they run through a real script rather than being narrated by hand. This is
what makes the merge idempotency independently testable (`framework/tools/
project-instructions-sync.test.sh`) instead of resting only on prose:

```pseudocode
FOR EACH target_file IN applicable files (per table above):
    spec_lang = resolved from Step 8 (/sdd.start) or read from sdd/PROJECT.md language.specs (/sdd.project)
    lang_names = { "en": "English", "es": "Spanish (Español)", "pt": "Portuguese (Português)" }
    lang_name = lang_names[spec_lang] or "English"

    render the SDD Kit section template (below) with lang_name/spec_lang substituted,
    write it to a temp file (section_file) — this rendering step IS LLM/template work, unlike
    the merge itself
    file_existed_before = target_file exists on disk right now, checked BEFORE the call below

    bash development-agents/framework/tools/project-instructions-sync.sh \
      --file target_file --section-file section_file
    → SYNC_ACTION=created   (target_file did not exist; now created verbatim from section_file)
    → SYNC_ACTION=appended  (target_file existed, had no "## SDD Kit" section; appended to end,
                             100% of existing content preserved)
    → SYNC_ACTION=replaced  (target_file existed, already had "## SDD Kit"; only that section's
                             body was replaced, byte-for-byte everything else preserved)

    IF NOT file_existed_before AND SYNC_ACTION == "created":
        → Run the git protection guard (§ "Git protection" below) — this is the ONLY case it
          is ever called, because it is the only case this procedure is the sole reason the
          file exists at all
    ELSE:
        → Do NOT run the git protection guard — the file predates this run (or the script
          appended/replaced into something already on disk); its tracked/untracked status is
          not this procedure's decision to make
```

**Section replacement rule (governs every target file, every adapter — this is what B-16 in `framework/standards/boundaries.md` permits)**: the SDD Kit section is the _only_ content this framework owns in `target_file`. Never touch anything else in the file. If the user ran `/init` (Claude Code) or otherwise already has project instructions, that content is preserved — the merge script only ever creates, appends, or replaces its own marked section, verified byte-for-byte in `project-instructions-sync.test.sh`.

## Git protection (new-file branch only)

A real corporate E2E run found `/sdd.install` creating `CLAUDE.md` for local harness
configuration, and that file showing up as untracked noise in `git status` — polluting the
target repo with a file nobody asked to commit. When (and only when) the `target_file does NOT
exist` branch above just created the file from nothing, run:

```bash
bash development-agents/framework/tools/project-instructions-git-guard.sh \
  --file <CLAUDE.md-or-AGENTS.md> --repo-root .
```

This mirrors the same local-only philosophy already used for `graphify-out/`
(`framework/tools/graphify-git-guard.sh`, `framework/_shared/graphify-context.md` § 2): it adds
the file to **`.git/info/exclude` only** — never the project's shared `.gitignore` — because a
per-developer harness config file is not something to impose on the whole team's ignore rules
the way an explicit, user-authorized tool like Graphify might be. If the file is somehow already
tracked at call time (e.g. a concurrent `git add`), the guard is a strict no-op — it never
removes tracking from a tracked file. It also never runs on the append/replace branches above:
a file that existed before this procedure touched it keeps whatever tracked/untracked status it
already had — that decision was never this procedure's to make.

This guard never blocks the wider `/sdd.start` or `/sdd.install` flow — a failed protection
attempt is a soft warning (the file may show up untracked), never a reason to abort.

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
- Model Routing: every command/Skill declares `model_role: STRONG|EXECUTION` — resolve and dispatch
  automatically per `development-agents/framework/_shared/model-routing.md` and this harness's
  `adapters/<harness>/README.md` § Model Routing (don't just run the command's content inline under
  whatever model this session happens to be on — follow the concrete dispatch mechanism that adapter
  documents). Never ask the operator to switch models by hand.

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
