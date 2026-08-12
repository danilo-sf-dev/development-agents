# Adapter: Claude Code

**Declared support level: Supported (native).** Every capability the SDD pipeline needs (`DELEGATE_ISOLATED`, `DELEGATE_OFFLOAD`, `ISOLATED_WORKSPACE`, `ASK_USER`, `INVOKE_PROCEDURE`, `WRITE_PROJECT_INSTRUCTIONS`) is Full on this harness — see `framework/_shared/harness-capabilities.md` for the full matrix.

## What this adapter installs

| Destination                | Source                                                                                                              |
| -------------------------- | ------------------------------------------------------------------------------------------------------------------- |
| `.claude/commands/`        | `development-agents/commands/*.md` (verbatim copy)                                                                  |
| `.claude/agents/`          | `development-agents/agents/*.md` (verbatim copy — frontmatter used as-is)                                           |
| `.claude/skills/<name>/`   | `development-agents/skills/<name>/` (verbatim copy)                                                                 |
| `CLAUDE.md` (project root) | Idempotent, section-scoped merge of the `## SDD Kit` block — see `commands/references/project-instructions-sync.md` |

**Two different things are true here, not one** — see `framework/_shared/harness-capabilities.md` § "What actually stays literal in the core" for the full reasoning:

1. Frontmatter (`tools:`/`model:`/`isolation:`) is copied verbatim because there is no translation step _for it_ on any harness — Claude Code and Cursor read it directly from disk, Codex CLI and Generic don't read it at all. This is a structural fact, not a design choice this adapter made.
2. Literal `Task(subagent_type=...)`/`AskUserQuestion(...)` call blocks in agent/command _body text_ are the concrete Claude Code resolution of a conceptual capability (`DELEGATE_ISOLATED`, `ASK_USER`, etc.) — every such block in the canonical files is annotated with the capability name it implements, precisely so it does **not** read as "the only way to do this" on a harness where it isn't.

## Known gaps

None — this is the reference implementation every other adapter is compared against.
