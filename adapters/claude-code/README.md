# Adapter: Claude Code

**Declared support level: Supported (native).** Every capability the SDD pipeline needs (`DELEGATE_ISOLATED`, `DELEGATE_OFFLOAD`, `ISOLATED_WORKSPACE`, `ASK_USER`, `INVOKE_PROCEDURE`, `WRITE_PROJECT_INSTRUCTIONS`, `OFFLOAD_READ`, `OFFLOAD_REASONING`, `INTERACTIVE_OFFLOAD`, `VALIDATOR_ISOLATED`) is Full on this harness — see `framework/_shared/harness-capabilities.md` for the full matrix.

**No `agents/` folder exists in this pack anymore.** All 12 former agent roles are Skills under `skills/`. Where a Skill's execution requirement (`OFFLOAD_READ`, `OFFLOAD_REASONING`, `INTERACTIVE_OFFLOAD`, `VALIDATOR_ISOLATED`, `ISOLATED_WORKSPACE`) calls for a fresh-context worker, this adapter uses a general-purpose or read-only-shaped subagent invocation (`Task(subagent_type=..., prompt="follow skills/<name>/SKILL.md ...")`) — the specific worker type/name is this adapter's implementation detail, not something the core Skill files or `harness-capabilities.md` reference by name.

## What this adapter installs

| Destination                | Source                                                                                                              |
| -------------------------- | ------------------------------------------------------------------------------------------------------------------- |
| `.claude/commands/`        | `development-agents/commands/*.md` (verbatim copy)                                                                  |
| `.claude/skills/<name>/`   | `development-agents/skills/<name>/` (verbatim copy)                                                                 |
| `CLAUDE.md` (project root) | Idempotent, section-scoped merge of the `## SDD Kit` block — see `commands/references/project-instructions-sync.md` |

## How each execution requirement is satisfied

| Capability | Claude Code mechanism (this adapter's choice, not a core dependency) |
| --- | --- |
| `OFFLOAD_READ` (`sdd-explorer`, `sdd-layer-analysis`) | Fresh-context subagent invocation with no `Write`/`Edit` in its tool grant, given the Skill's content as its task. `sdd-layer-analysis` historically had no `Bash`; if the subagent type used grants `Bash`, that is a documented permission increase, not silent. |
| `OFFLOAD_REASONING` (`sdd-debugger`, `sdd-system-design`) | Same shape as `OFFLOAD_READ`, optionally with a per-call model override to a stronger model. |
| `INTERACTIVE_OFFLOAD` (`sdd-project-wizard`, `sdd-mcp-setup`) | Fresh-context subagent invocation, optionally with a cheaper model override; runs inline when invoked as a standalone entry point. |
| `ISOLATED_WORKSPACE` (`sdd-implementation`, `sdd-test-writing`) | Per-call workspace isolation (dedicated git worktree), invoked alongside a fresh-context subagent with `Write`/`Edit`/`Bash`. |
| `VALIDATOR_ISOLATED` (`sdd-validator` isolated mode) | Fresh-context subagent invocation with a caller-built scrubbed prompt (file paths + rules only) and no `Write`/`Edit` in its tool grant, given `skills/sdd-validator/SKILL.md`'s isolated-mode content as its task. |

**Two different things are true here, not one** — see `framework/_shared/harness-capabilities.md` § "What actually stays literal in the core" for the full reasoning:

1. Frontmatter (`tools:`/`model:`/`isolation:`) is copied verbatim because there is no translation step _for it_ on any harness — Claude Code and Cursor read it directly from disk, Codex CLI and Generic don't read it at all. This is a structural fact, not a design choice this adapter made.
2. Literal `Task(subagent_type=...)`/`AskUserQuestion(...)` call blocks in agent/command _body text_ are the concrete Claude Code resolution of a conceptual capability (`DELEGATE_ISOLATED`, `ASK_USER`, etc.) — every such block in the canonical files is annotated with the capability name it implements, precisely so it does **not** read as "the only way to do this" on a harness where it isn't.

## Known gaps

None — this is the reference implementation every other adapter is compared against.
