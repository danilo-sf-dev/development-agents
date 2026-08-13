# Shared Agent Instructions

**Used by**: All `/sdd.*` command files. Read once at the start of any command invocation.

---

## How to read command files

When you see a block like this:

⛔ INVOKE TOOL (do not print this, CALL the tool):
AskUserQuestion(questions=[{...}])

This is a **tool call** you must execute, not content to display.

> **Capability note (applies to every `AskUserQuestion(...)` block in `commands/`,
> `skills/`, and `framework/`, whether or not the specific block repeats this pointer)**: this is
> the conceptual `ASK_USER` capability — structured multi-choice + mandatory free-text "Outros" —
> not a Claude-Code-only primitive. `AskUserQuestion(...)` is the correct, literal Claude Code
> implementation; other harnesses translate it per `framework/_shared/harness-capabilities.md`
> (e.g. numbered-list + free-text on harnesses with no structured choice tool). You do not need to
> find a per-block "ASK_USER" tag to know this — this file, read at the start of every command, is
> the blanket rule.

| WRONG                      | CORRECT                                |
| -------------------------- | -------------------------------------- |
| Bash(echo "1. Option A")   | Directly call the AskUserQuestion tool |
| Print the JSON to terminal | Pass the parameters shown to the tool  |

---

## User interaction rules

When a command shows JSON for `AskUserQuestion`, you MUST:

1. CALL the `AskUserQuestion` tool with that exact JSON
2. DO NOT print options using Bash (no echo, cat, printf)
3. DO NOT ask "Which option?" as plain text
4. Tables marked **REFERENCE ONLY** are documentation — do NOT print them to the user

---

## AskUserQuestion format reminder

Blocks marked with ⛔ INVOKE TOOL are executable tool calls. Pass the JSON parameters exactly as written; never simulate the prompt in chat or terminal output.

### Outros (mandatory on gates)

Every **gate** AskUserQuestion (approve / process failure / anti-gaming / ambiguous next step) MUST include an option labeled **Outros** with free-text intent: the user describes what they will do or suggests another path. See `commands/references/ask-user-question-outros.md`.

---

## Model Routing (automatic — informative only, never blocking)

Model selection is automatic on every supported harness (Claude Code, Cursor, Codex) — see
`framework/_shared/model-routing.md` and each `adapters/<harness>/README.md` § Model Routing. There
is no model-confirm gate anywhere in the pipeline; the optional one-line observability format
(`ℹ️ Model Routing: <role> → <resolved model> (auto)`) may be shown at command entry, never wrapped
in `AskUserQuestion`, never blocking.

> Read `commands/references/model-suggestion-advisory.md` for the exact observability format and
> what was removed (the former manual-confirm apparatus).
> Model resolution = `model_role:` frontmatter (`STRONG`/`EXECUTION`) → `config/model-routing.yaml`
> via `framework/tools/resolve-model.sh` → dispatched automatically by the adapter's mechanism.

---

## Agent boundaries (mandatory)

At the **start of every** `/sdd.*` command:

1. Read `framework/standards/boundaries.md` — at minimum the **decision tree** and scan 🚫 Never Do IDs.
2. Before any **Shell** command that deletes files, changes git remotes, touches database schema/data, deploys, or uses elevated privileges → re-read **⚠️ Ask First** and **🚫 Never Do** in that file.
3. Before `/sdd.start`, `/sdd.spec`, or `/sdd.build` → also read `framework/standards/pre-execution-checks.md`.

> **Single source of truth** — do not rely on duplicated boundary lists in command files; they point here.

---

## Single delivery path (mandatory)

There is **one** feature pipeline: `start → spec → plan → test → build → check → finish → pr`
(canonical: `framework/PIPELINE.md`).

- Do **not** invent, ask for, or honor prototype / MVP / production “project types”.
- Do **not** skip `/sdd.test`, security validation, or quality gates because work “feels experimental”.
- If legacy `project_type` appears in an old `meta.md`, ignore it for routing and follow the full pipeline; prefer removing the field on touch.
