---
name: sdd.start
description: Initialize new feature in SDD Kit framework. Use when user wants to begin a new feature, set up the sdd/wip/ directory structure, and configure project metadata. Supports --reopen for archived features.
model: sonnet
argument-hint: "[feature-description] [--express|--lite|--audio|--from-backlog|--reopen]"
---

> **Shared agent instructions**: Read `development-agents/framework/_shared/agent-instructions.md` before executing this command.

# Command: /sdd.start

**Description**: Initialize new feature in SDD Kit framework

**Usage**:
- `/sdd.start "feature-description"` → Standard mode (default)
- `/sdd.start "feature-description" --express` → Express mode (minimal interaction)

- `/sdd.start "feature-description" --lite` → Lite template (~80 lines, combined spec)
- `/sdd.start --audio` → Record feature description via microphone
- `/sdd.start --from-backlog <ID>` → Create from backlog item
- `/sdd.start --rename [new-name]` → Rename current feature
- `/sdd.start --reopen [feature-name]` → Reopen completed feature for iteration
- `/sdd.start --reopen [feature-name] --phase N` → Reopen to specific phase

---

## Quick Help

`/sdd.start [description] [--express|--lite]` · rare flags: `--audio|--from-backlog|--rename|--reopen` (lazy table at bottom).
Infer kebab name → detect stack → create `sdd/wip/YYYYMMDD-name/` + meta.md → next `/sdd.spec`.
Modes: Standard (confirm) | Express (minimal). Templates: standard | `--lite` (combined short spec).
App name ≠ feature name. See `/sdd.help start`.

**Model advisory (entry)**: Read `references/model-suggestion-advisory.md` — compact line for `phase_key`: `entry:start`.

## Workflow (Steps in Order)

### Step 0: User Profile Check (BLOCKING)

> Never skip. If global profile missing → AskUserQuestion (technical/non-technical) before Step 1.
> **ONLY IF** needing full AskUserQuestion payloads / yaml paths:
> Read `references/start-user-profile.md` (also used in Step 5.5).

### Step 1: Validate Input (BLOCKING)

**Must pass before ANY file creation:**

1. **Detect input type**:
   - Valid name? (3-100 chars, kebab-case) → Continue
   - Looks like prompt? (>5 words, sentences) → Convert to name automatically, proceed
     - Show: "✓ Feature name inferred: `{suggested-name}` (from your description)"
     - Store original description for use as initial context in /sdd.spec
     - Do NOT ask for confirmation, continue to Step 2
   - Invalid format? → Reject, ask for correction

2. **Check uniqueness**: Feature must not exist in `sdd/wip/`

### Step 2: Platform + Frontend Skills

> Run `detect-stack.sh` → set `IS_MOBILE`. Then `check-frontend-skill.sh`. If output has `❌`, STOP.
> **ONLY IF** needing exact bash:
> Read `references/start-platform-detect.md`.

### Step 2.5: Repository Readiness (short)

Must run inside an existing git repo (never creates external apps). Detect `freshly_scaffolded` (0–1 commits, no specs/features).
No `.git` → AskUserQuestion to init or relocate. Full scenario table: `references/new-app-scaffolding.md` if improvising.

### Step 2.6: Cleanup Scaffolding Samples (lazy-loaded)

> **ONLY IF** `freshly_scaffolded=true`:
> Read `references/start-scaffolding-cleanup.md` (sample cleanup + essential-file checks).
> Otherwise skip to Step 3.

### Step 3: Scaffolding + Stack Detection

> Run `detect-scaffolding-status.sh` then `detect-stack.sh` (reuse Step 2 result if mobile).
> Pre-populate meta.md technology/platform/build/test. Brownfield with existing `sdd/specs` → never cleanup samples.
> **ONLY IF** needing parse bash:
> Read `references/start-stack-detect.md`.

### Step 4: Detect Project Mode

`freshly_scaffolded` or empty → greenfield; else if `sdd/specs|features` or real code → brownfield.
> Brownfield path: Read `references/start-brownfield.md` (ONLY IF brownfield).

### Step 5: Project Type Selection

> Ask once (prototype | mvp | production). Prototypes skip heavy PROJECT.md prompts.
> **ONLY IF** showing comparison table / AskUserQuestion payload:
> Read `references/start-project-type.md`.
> Store choice in `meta.md` → `project_type`.

### Step 5.5: User Profile Selection

> Resolve profile: global `user-profile.yaml` → PROJECT.md defaults → AskUserQuestion.
> Persist technical vs non-technical (+ plan-mode prefs for technical).
> **ONLY IF** writing/updating profile files or AskUserQuestion payloads:
> Read `references/start-user-profile.md`.

### Step 6: Load PROJECT.md (CONDITIONAL)

> **ONLY IF** `project_type != prototype` and `sdd/PROJECT.md` exists (or needs creation):
> Read `references/start-project-md.md` (load, GenAI validate, doctor tip).
> Prototype: skip or minimal defaults. Missing PROJECT.md → recommend `/sdd.project` then continue.

### Step 6.5: Configure Local MCPs (lazy-loaded)

> **ONLY IF** PROJECT.md / stack requires local MCP setup that is not yet configured:
> Read `references/start-local-mcps.md`.
> Otherwise skip.

### Step 7: Create Feature Structure

1. Uniqueness across wip/features/cancelled (name without date). On collision: derive better name or `-v2`, show warning, proceed.
2. Folder: `YYYYMMDD-feature-name` (never legacy `001-` prefixes).
3. Create WIP tree (1-functional … 5-implementation, meta.md placeholder).
> **ONLY IF** needing mkdir tree / collision bash:
> Read `references/start-feature-structure.md`.

### Step 8: Create meta.md

Write meta from template: name, mode, project_type, profile, stack, `spec_language` from PROJECT.md (default `en`), stages pending.
> **ONLY IF** needing field checklist:
> Read `references/start-meta.md`.

### Step 9: Git Branch Management

If on default branch (master/main/develop per PROJECT.md): create/checkout `feature/<name>` (or project gitflow pattern).
If already on feature branch: keep it. Never force-push.
> **ONLY IF** needing gitflow variants:
> Read `references/start-git-branch.md`.

### Step 9.5: CLAUDE.md (lazy-loaded)

> **ONLY IF** Claude Code session and CLAUDE.md integration needed:
> Read `references/start-claude-md.md`. Mobile CLAUDE extras: `references/start-mobile-claude.md`.

### Step 10: Load PATTERNS.md (lazy-loaded)

> **ONLY IF** `sdd/PATTERNS.md` exists:
> Read `references/start-patterns.md` and surface relevant conventions for this feature.
> Otherwise skip.

### Step 11: Output Success Message

```
✅ Feature '[feature-name]' initialized (YYYYMMDD)
   📁 Location: sdd/wip/[YYYYMMDD]-[feature-name]/

[Mode-specific guidance]
```

**Conditional (only for Prototype projects)**:
```
   💡 For rapid prototyping: /sdd.go --resume (switches to express mode)
```

### Step 12: Interactive Next Steps (lazy-loaded)

> After success message: AskUserQuestion for next command (usually `/sdd.spec`).
> **ONLY IF** presenting next-steps UX:
> Read `references/start-next-steps.md`.

## Validations & References

Pre: valid input; unique feature name; repo ready. Post: WIP + meta.md; stack/mode set; branch OK.
Templates: `framework/templates/meta.md`. Scripts: `detect-stack.sh`, `detect-scaffolding-status.sh`.
Shared: `framework/_shared/agent-instructions.md`. Pipeline: `framework/PIPELINE.md`.

## AI Agent Instructions

1. Flag-first: if `--help`/`--reopen`/`--rename`/`--from-backlog`/`--audio` → load matching ref, do not run full happy path.
2. Order: Steps 0→12; never skip profile (Step 0/5.5) or input validation (Step 1).
3. Infer kebab-case feature name from description; confirm only if ambiguous.
4. Critical: Application name ≠ feature name; never invent external app registration; stack from detection + PROJECT.md.

## Optional flags (lazy-loaded)

Read the matching reference **ONLY IF** the flag/condition is present. Never load all refs.

| Flag / condition | Reference |
|------------------|-----------|
| `--reopen` | `references/reopen-workflow.md` |
| `--rename` | `references/start-rename.md` |
| `--from-backlog` | `references/start-from-backlog.md` |
| `--audio` | `references/start-audio.md` / `audio-capture-flow.md` |
| CLAUDE.md (Claude Code) | `references/start-claude-md.md` |
| Mobile CLAUDE extras | `references/start-mobile-claude.md` |
| Platform/frontend detect bash | `references/start-platform-detect.md` |
| Scaffolding/stack detect bash | `references/start-stack-detect.md` |
| Feature folder creation | `references/start-feature-structure.md` |
| Git branch variants | `references/start-git-branch.md` |
| `freshly_scaffolded=true` | `references/start-scaffolding-cleanup.md` |
| `project_mode == brownfield` | `references/start-brownfield.md` |
| Project type AskUserQuestion | `references/start-project-type.md` |
| Profile AskUserQuestion / yaml | `references/start-user-profile.md` |
| Load/validate PROJECT.md | `references/start-project-md.md` |
| Local MCP setup needed | `references/start-local-mcps.md` |
| `sdd/PATTERNS.md` exists | `references/start-patterns.md` |
| Next-steps UX | `references/start-next-steps.md` |
