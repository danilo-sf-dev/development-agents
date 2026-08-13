# Adapter: Claude Code

**Declared support level: Supported (native).** Every capability the SDD pipeline needs (`DELEGATE_ISOLATED`, `DELEGATE_OFFLOAD`, `ISOLATED_WORKSPACE`, `ASK_USER`, `INVOKE_PROCEDURE`, `WRITE_PROJECT_INSTRUCTIONS`, `OFFLOAD_READ`, `OFFLOAD_REASONING`, `INTERACTIVE_OFFLOAD`, `VALIDATOR_ISOLATED`) is Full on this harness — see `framework/_shared/harness-capabilities.md` for the full matrix.

**No `agents/` folder exists in this pack anymore.** All 12 former agent roles are Skills under `skills/`. Where a Skill's execution requirement (`OFFLOAD_READ`, `OFFLOAD_REASONING`, `INTERACTIVE_OFFLOAD`, `VALIDATOR_ISOLATED`, `ISOLATED_WORKSPACE`) calls for a fresh-context worker, this adapter uses a general-purpose or read-only-shaped subagent invocation (`Task(subagent_type=..., prompt="follow skills/<name>/SKILL.md ...")`) — the specific worker type/name is this adapter's implementation detail, not something the core Skill files or `harness-capabilities.md` reference by name.

## What this adapter installs

| Destination                | Source                                                                                                              |
| -------------------------- | ------------------------------------------------------------------------------------------------------------------- |
| `.claude/commands/`        | `development-agents/commands/*.md`, with one field translated — see "Model Routing" below (rest copied verbatim)   |
| `.claude/skills/<name>/`   | `development-agents/skills/<name>/` (verbatim copy, including its `model_role:` frontmatter — see "Model Routing")  |
| `CLAUDE.md` (project root) | Idempotent, section-scoped merge of the `## SDD Kit` block — see `commands/references/project-instructions-sync.md` |

## Model Routing

Canonical policy: `framework/_shared/model-routing.md` (`STRONG`/`EXECUTION`, no concrete names).
This adapter's concrete mapping:

| Model Role | Claude Code model |
| --- | --- |
| `STRONG` | Sonnet 5, effort `high` |
| `EXECUTION` | Haiku 4.5 |

**Mechanism**: Claude Code's real, native mechanism for pinning a command's model is the `model:`
frontmatter key on the installed `.claude/commands/*.md` file — `model_role:` is not a key Claude
Code itself reads. So this is the one frontmatter field this adapter does **not** copy verbatim: at
install time, `sdd-installer` translates each command's `model_role: STRONG|EXECUTION|inherit` into
a concrete `model: sonnet|haiku|inherit` line in the generated `.claude/commands/*.md`, using the
table above (`inherit` passes through unchanged — it already is a real Claude Code frontmatter
value, meaning "follow the session's current model"). Skills keep `model_role:` as informational
metadata in their frontmatter (Claude Code doesn't read a per-Skill model field the way it does for
commands); when a Skill is dispatched through a fresh-context subagent call (see the capability table
below), that call's own `model` parameter is set from the same table.

## How each execution requirement is satisfied

| Capability | Claude Code mechanism (this adapter's choice, not a core dependency) |
| --- | --- |
| `OFFLOAD_READ` (`sdd-explorer`, `sdd-layer-analysis`) | Fresh-context subagent invocation with no `Write`/`Edit` in its tool grant, given the Skill's content as its task. `sdd-layer-analysis` historically had no `Bash`; if the subagent type used grants `Bash`, that is a documented permission increase, not silent. |
| `OFFLOAD_REASONING` (`sdd-debugger`, `sdd-system-design`) | Same shape as `OFFLOAD_READ`, with a per-call `model` override resolved from the Skill's `model_role: STRONG` per the Model Routing table below. |
| `INTERACTIVE_OFFLOAD` (`sdd-project-wizard`, `sdd-mcp-setup`) | Fresh-context subagent invocation with `model` resolved from `model_role: EXECUTION`; runs inline when invoked as a standalone entry point. |
| `ISOLATED_WORKSPACE` (`sdd-implementation`, `sdd-test-writing`) | Per-call workspace isolation (dedicated git worktree), invoked alongside a fresh-context subagent with `Write`/`Edit`/`Bash` and `model` resolved from that Skill's `model_role` (`EXECUTION` default for implementation, `STRONG` always for test-writing — see `model-routing.md` for escalation). |
| `VALIDATOR_ISOLATED` (`sdd-validator` isolated mode) | Fresh-context subagent invocation with a caller-built scrubbed prompt (file paths + rules only), no `Write`/`Edit` in its tool grant, and `model` resolved from `model_role: STRONG` (always — isolation and model strength are independent guarantees, see `model-routing.md`). |

**Two different things are true here, not one** — see `framework/_shared/harness-capabilities.md` § "What actually stays literal in the core" for the full reasoning:

1. Frontmatter `tools:`/`isolation:` is copied verbatim because there is no translation step _for it_ on any harness — Claude Code and Cursor read it directly from disk, Codex CLI and Generic don't read it at all. This is a structural fact, not a design choice this adapter made. `model_role:` is the one exception on commands: it **is** translated (to `model:`) at install time, because Claude Code's real per-command model mechanism is the `model:` key, not `model_role:` — see "Model Routing" above.
2. Literal `Task(subagent_type=...)`/`AskUserQuestion(...)` call blocks in agent/command _body text_ are the concrete Claude Code resolution of a conceptual capability (`DELEGATE_ISOLATED`, `ASK_USER`, etc.) — every such block in the canonical files is annotated with the capability name it implements, precisely so it does **not** read as "the only way to do this" on a harness where it isn't.

## Known gaps

None — this is the reference implementation every other adapter is compared against.
