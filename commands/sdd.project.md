---
name: sdd.project
description: Initialize or manage PROJECT.md configuration file. Use when user needs to set up project conventions or edit project settings.
model: sonnet
---

> **Shared agent instructions**: Read `development-agents/framework/_shared/agent-instructions.md` before executing this command.

# Command: /sdd.project

**Version**: 1.4.0-beta
**Last Updated**: 2026-01-29
**Description**: Initialize or edit PROJECT.md with team conventions via interactive wizard or prompt inference.

> **Note**: PROJECT.md defines team conventions that apply to ALL features. It's optional - without it, framework defaults apply.

**Usage**:
- `/sdd.project` → Interactive wizard (step-by-step)
- `/sdd.project "<description>"` → Deduce conventions from prompt
- `/sdd.project --audio` → Record project conventions via microphone
- `/sdd.project --edit` → Edit existing PROJECT.md
- `/sdd.project profile` → View current user profile settings
- `/sdd.project profile --edit` → Update user profile interactively
- `/sdd.project patterns` → View/manage PATTERNS.md
- `/sdd.project patterns --add` → Add new pattern interactively
- `/sdd.project patterns "<desc>"` → Infer patterns from description
- `/sdd.project patterns --edit` → Edit PATTERNS.md directly
- `/sdd.project vision` → Interactive wizard to define product vision
- `/sdd.project vision --edit` → Edit existing vision
- `/sdd.project --view` → Open framework viewer in browser

---

## Quick Help

> `/sdd.project help` → Shows this summary

**Syntax**: `/sdd.project [description] [flags]`

| Flag | Description |
|------|-------------|
| (none) | Interactive wizard (step-by-step) |
| `"<description>"` | Deduce conventions from prompt |
| `--audio` | Record project conventions via microphone |
| `--edit` | Edit existing PROJECT.md |
| `--init` | Initialize PROJECT.md (alias) |
| `--update` | Update existing conventions |
| `profile` | View current user profile and Plan Mode settings |
| `profile --edit` | Update user profile interactively |
| `patterns` | View/manage PATTERNS.md |
| `patterns --add` | Add new pattern interactively |
| `patterns "<desc>"` | Infer patterns from description |
| `patterns --edit` | Edit PATTERNS.md directly |
| `vision` | Interactive wizard to define product vision |
| `vision --edit` | Edit existing vision |
| `--view` | Open framework viewer in browser |
| `--hub` | Initialize as hub workspace (adds `## Hub members` table) |

**See also**: `/sdd.help project` · subcommands/flags lazy-loaded at bottom.

Route first: `profile*` | `patterns*` | `vision*` | `--hub` | `--view` | `--edit` | description → Mode 2 | else Mode 1 wizard.

---



## Purpose (short)

Create/update `sdd/PROJECT.md` (team conventions). Without it, framework defaults apply.
Stack from detection — do not invent a corporate default language.
Belongs: architecture prefs, testing gates, gitflow, frontend/design-system, vision, hub members.
Does not belong: feature-specific specs (those go in `sdd/wip/`).
> **ONLY IF** full belongs/doesn't ASCII:
> Read `references/project-purpose.md`.

## Mode 1: Interactive Wizard (default `/sdd.project`)

Steps: detect stack → architecture (backend) → testing standards → team conventions → frontend config (if web) → summary & write `sdd/PROJECT.md`.
> **ONLY IF** running interactive wizard (no subcommand/flags for other modes):
> Read `references/project-wizard.md`.

## Mode 2: Prompt Inference (lazy-loaded)

> **ONLY IF** user passed a natural-language description (and not a subcommand):
> Read `references/project-prompt-inference.md`.

## Mode 3: Edit Existing (lazy-loaded)

> **ONLY IF** `--edit` or `--update`:
> Read `references/project-edit.md`.

## Mode 4: Patterns (lazy-loaded)

> **ONLY IF** `patterns` / `patterns --add` / `patterns --edit` / `patterns "…"`:
> Read `references/project-patterns.md`.

## Mode 5: Profile (lazy-loaded)

> **ONLY IF** `profile` or `profile --edit`:
> Read `references/project-profile.md`.

## Mode 6: Vision (lazy-loaded)

> **ONLY IF** `vision` or `vision --edit`:
> Read `references/project-vision.md`.

## Output: PROJECT.md (lazy-loaded)

> Write overrides-only PROJECT.md. **ONLY IF** needing full template / hub section:
> Read `references/project-output-template.md`. Hub: `references/project-hub.md` ONLY IF `--hub`.

## CLAUDE.md Sync (lazy-loaded)

> **ONLY IF** spec language changed and Claude Code CLAUDE.md exists:
> Read `references/project-claude-sync.md`.

## Integration with /sdd.start (short)

`/sdd.start` loads PROJECT.md when present. Missing file → recommend `/sdd.project` (then continue with defaults if user opts in).

## Validation (short)

After write: file exists under `sdd/PROJECT.md`; required sections present for chosen stack; YAML/MD well-formed.

## Examples (lazy-loaded)

> Read `references/project-examples.md` ONLY IF user asks for walkthroughs.

## Error Handling (short)

Missing permissions / invalid YAML → show error, do not overwrite silently. Backup existing PROJECT.md before destructive edit.

## Related Commands

`/sdd.start`, `/sdd.doctor`, `/sdd.help project`.

## AI Agent Instructions

1. Flag/subcommand-first — load matching ref; do not run full wizard when `patterns`/`profile`/`vision`/`--hub`/`--view`.
2. Never invent stack defaults; use detection + user answers.
3. PROJECT.md = team conventions only; write overrides, not a novel.
4. After create/update, confirm path `sdd/PROJECT.md` and next step (`/sdd.start` if starting a feature).
5. **Model advisory**: Read `references/model-suggestion-advisory.md` — full box for brownfield → `project→reverse-eng`; greenfield/next feature → `project→start` (ask which path if unclear).

## Optional flags (lazy-loaded)

| Flag / condition | Reference |
|------------------|-----------|
| `--audio` | `references/audio-capture-flow.md` |
| `--hub` | `references/project-hub.md` |
| `--view` | `references/project-view.md` |
| Interactive wizard | `references/project-wizard.md` |
| Prompt inference | `references/project-prompt-inference.md` |
| `--edit` / `--update` | `references/project-edit.md` |
| `patterns*` | `references/project-patterns.md` |
| `profile*` | `references/project-profile.md` |
| `vision*` | `references/project-vision.md` |
| Output template | `references/project-output-template.md` |
| CLAUDE.md language sync | `references/project-claude-sync.md` |
