---
name: sdd.backlog
description: Manage technical backlog with TODO, DEBT, and IDEA categories. Use when user wants to track, add, or manage backlog items.
model_role: EXECUTION
argument-hint: "[action] [item]"
---

> **Shared agent instructions**: Read `development-agents/framework/_shared/agent-instructions.md` before executing this command.

# Command: /sdd.backlog

> **Note**: Previously known as `/sdd.todos`. The old name still works as an alias.

**Description**: Manage technical backlog (TODOs, Technical Debt, Ideas)

**Usage**:

- `/sdd.backlog` → List all backlog items
- `/sdd.backlog add` → Add new item interactively
- `/sdd.backlog add --audio` → Add item via voice description
- `/sdd.backlog pick` → Select item and create feature
- `/sdd.backlog resolve <ID>` → Mark item as resolved

---

## Quick Help

> `/sdd.backlog help` → Shows this summary

**Syntax**: `/sdd.backlog [action] [options]`

| Flag             | Description                        |
| ---------------- | ---------------------------------- |
| (none)           | List all backlog items             |
| `add`            | Add new item interactively         |
| `add --audio`    | Add new item via voice description |
| `pick`           | Select item and create feature     |
| `resolve <ID>`   | Mark item as resolved              |
| `--type <T>`     | Filter by type (TODO/DEBT/IDEA)    |
| `--priority <P>` | Filter by priority                 |

**See also**: `/sdd.help backlog`. Actions: list | add | pick | resolve.

---

## Purpose

Track **TODO** / **DEBT** / **IDEA** in `sdd/backlog.md`. Actions: list (default), `add`, `pick`, `resolve <ID>`.

## List (default `/sdd.backlog`)

Show `sdd/backlog.md` items by priority (TODO/DEBT/IDEA). Empty → offer `add`.

> **ONLY IF** needing list UI / empty-state copy:
> Read `references/backlog-list.md`.

## Add (`/sdd.backlog add`)

Interactive: type → title → priority → details. Append to `sdd/backlog.md` with next ID.
`--audio` → `references/audio-capture-flow.md`.

> **ONLY IF** field tables / AskUserQuestion:
> Read `references/backlog-add.md`.

## Pick (`/sdd.backlog pick`)

Select item → create feature via `/sdd.start` flow (or equivalent WIP). DEBT/TODO may use workflow modes.

> Read `references/backlog-pick.md`. Modes: `workflow-modes.md` / `auto-spec-template.md` ONLY IF DEBT/TODO pick path needs them.

## Resolve (`/sdd.backlog resolve <ID>`)

Move item to Resolved with date/feature link. Missing ID → error.

> **ONLY IF** needing format:
> Read `references/backlog-resolve.md`.

## Auto-capture During Build (lazy-loaded)

> **ONLY IF** build/fix suggests capturing debt/todo:
> Read `references/backlog-auto-capture.md` (fix now vs add criteria).

## File Format (lazy-loaded)

Canonical file: `sdd/backlog.md` (TODO / DEBT / IDEA / Resolved sections).

> Read `references/backlog-file-format.md` when creating or rewriting the file.

## Delegating to `sdd-backlog` (optional, context-saving)

The steps above (list/add/pick/resolve via lazy-loaded `references/backlog-*.md`)
remain the default path for normal-sized backlogs — nothing here replaces that.
For a **large** `sdd/backlog.md` (roughly 50+ items, or the file itself is a
large read) or when context usage is already elevated, prefer offloading the
CRUD operation to the `sdd-backlog` Skill instead of doing it inline:
it owns the same schema (see `commands/references/backlog-file-format.md`,
also the schema `sdd-backlog` itself documents) and is cheaper to run
than reading/rewriting a big file directly in this session.

- **When to delegate**: use the same trigger logic as `context-guardian`'s
  ELEVATED/DELEGATE_MODE thresholds (see `skills/context-guardian/SKILL.md`)
  — i.e. once estimated context usage is ~40%+, or the backlog file is large
  enough that reading/rewriting it inline is itself a "heavy operation."
  Below that, stay inline; delegation is an optimization, not a requirement.
- **How to delegate**: this is `DELEGATE_OFFLOAD`, not `DELEGATE_ISOLATED` —
  see `framework/_shared/harness-capabilities.md` for the full capability
  map. There is no correctness/isolation requirement here, only a
  token-budget one, so on a harness without real subagent delegation the
  honest fallback is simply to run the operation inline (same result as not
  delegating at all).
- **On Claude Code**: `Task(subagent_type="sdd-backlog", prompt="<action + item details>")`.
- **On harnesses without a delegate primitive** (Cursor, Codex CLI degraded
  cases, Generic): fall back to inline handling per the "Full (via inline
  fallback)" row for `DELEGATE_OFFLOAD` in `harness-capabilities.md` — do not
  pretend delegation happened.

## AI Agent Instructions

1. Action-first: list | add | pick | resolve — load matching ref.
2. Never invent IDs; append with next sequential TODO/DEBT/IDEA number.
3. `pick` creates a feature (start flow); does not implement code.
4. During build, offer capture only when criteria in `backlog-auto-capture.md` match.
5. For large backlogs or elevated context, prefer delegating to `sdd-backlog` (see "Delegating to `sdd-backlog`" above) instead of handling the operation inline.

## Related Commands

`/sdd.start`, `/sdd.fix`, `/sdd.build`, `/sdd.list`.

## Examples (lazy-loaded)

> Read `references/backlog-examples.md` ONLY IF user asks for walkthroughs.

## Optional flags (lazy-loaded)

| Flag / condition         | Reference                            |
| ------------------------ | ------------------------------------ |
| `add --audio`            | `references/audio-capture-flow.md`   |
| List UI                  | `references/backlog-list.md`         |
| Add fields               | `references/backlog-add.md`          |
| Pick → feature           | `references/backlog-pick.md`         |
| Resolve                  | `references/backlog-resolve.md`      |
| Auto-capture in build    | `references/backlog-auto-capture.md` |
| File format              | `references/backlog-file-format.md`  |
| DEBT/TODO workflow modes | `references/workflow-modes.md`       |
| modes 2/3 auto-spec      | `references/auto-spec-template.md`   |
