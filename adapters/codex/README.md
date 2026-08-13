# Adapter: OpenAI Codex CLI

**Declared support level: Experimental.** Codex CLI has decent 2026 coverage (native `SKILL.md` support via the `agentskills.io` spec, real subagents, `AGENTS.md` as its native project-instructions convention, MCP client support), but two required capabilities have no real equivalent — `ASK_USER` as a structured tool and `ISOLATED_WORKSPACE` for true parallel isolation. This adapter has **not been validated end-to-end against a live Codex CLI session** by the pack's maintainers. Treat it as experimental until someone confirms the full pipeline works in practice, and say so explicitly to anyone who installs it.

## What this adapter installs

| Destination                                  | Source                                                                                                                                                                        |
| -------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `.agents/skills/<name>/`                     | `development-agents/skills/<name>/` (verbatim copy — same `SKILL.md` format, matches the `agentskills.io` discovery path Codex CLI reads)                                     |
| `AGENTS.md` (project root)                   | Idempotent, section-scoped merge of the `## SDD Kit` block — see `commands/references/project-instructions-sync.md`. This is Codex's **native** convention, not a workaround. |
| _(no commands/ folder populated)_            | See gap notes below                                                                                                                                                           |

No `.codex/` subfolder is created — Codex CLI's real convention is a root-level `AGENTS.md`, not a subfolder. (An earlier version of this pack incorrectly referenced `.codex/AGENTS.md`; that was a documentation bug, not a real Codex convention, and has been corrected.)

## Known gaps (do not silently degrade past these — tell the user)

- **No repo-shareable command surface.** Codex's `~/.codex/prompts/*.md` mechanism is explicitly user-local, not something this installer can populate on a teammate's behalf. The `/sdd.*` command surface is delivered as **skills** instead (Codex discovers `.agents/skills/` automatically), and `AGENTS.md` tells the operator to read `development-agents/commands/*.md` directly for the full command definitions.
- **No dedicated agent-role folder needed.** The pack has no `agents/` folder anymore — all 12 former agent roles are Skills, and Skills already install natively to `.agents/skills/` (row above), the real `agentskills.io` discovery path Codex CLI reads. Where a Skill's execution requirement (`OFFLOAD_READ`, `OFFLOAD_REASONING`, `INTERACTIVE_OFFLOAD`, `VALIDATOR_ISOLATED`, `ISOLATED_WORKSPACE`) calls for a fresh-context worker, Codex CLI's own subagent mechanism (`/agent`, `~/.codex/agents/*.toml`) is an optional, faster path this adapter does not yet auto-generate — see the `DELEGATE_ISOLATED` procedure below for the manual default and the optional shortcut.
- **`ASK_USER` has no structured-tool equivalent.** Codex CLI only exposes binary command-approval dialogs. Every gate (`AskUserQuestion` in the canonical files) degrades to plain conversational text with listed options, always including a free-text choice.
- **`ISOLATED_WORKSPACE` is not supported.** Codex subagents inherit the parent's sandbox policy; there is no per-subagent git-worktree equivalent. The (currently roadmap, not yet shipped) parallel-task execution mode described in `skills/sdd-implementation/SKILL.md` cannot run on this adapter — sequential execution only.

## `DELEGATE_ISOLATED` on this adapter — the concrete, end-to-end procedure (not just a capability claim)

The Validator Independence Protocol (`skills/sdd-validator/SKILL.md`) requires `DELEGATE_ISOLATED`: the validator must not see the implementer's reasoning, only file paths + rules. This is the highest-stakes capability gap in the pack, so it does not get a one-line "Partial" label — here is exactly what happens today, step by step, and what does not.

**Default procedure (works today, zero extra setup, fully manual):**

1. The main Codex session does **not** validate its own work. It stops and hands off instead.
2. The **calling session** builds the scrubbed prompt itself — same scrubbing rule as the Claude Code `Task(subagent_type="sdd-validator", prompt=...)` call: only the file list + the Security/Performance/Quality tables from `skills/sdd-validator/SKILL.md` (or, for Layer 3 mode, the extended check categories), **never** the implementation rationale.
3. The operator opens a **fresh Codex CLI session/context** in the same repo (a new `codex` invocation, not a continuation of the implementer's session) and pastes that scrubbed prompt.
4. That fresh session follows `skills/sdd-validator/SKILL.md`'s instructions directly (it's plain Markdown — Codex can read and follow it like any other file) and returns the JSON verdict per `framework/_shared/verdict-protocol.md`.
5. The operator (or the main session, once handed the verdict) writes it to `sdd/wip/<feature>/verdicts/` as usual.

**Optional, faster path — not generated by this installer today:** an operator can hand-author a `~/.codex/agents/sdd-validator.toml` (or the project-level equivalent, per Codex CLI's custom-agent convention) whose prompt embeds the same scrubbed instructions, then invoke it via `/agent sdd-validator <task>` instead of opening a fresh session by hand. This is a real, documented shortcut to the same manual procedure above — **`/sdd.install` does not generate this TOML file**; building one is on the operator, and doing so has not been validated against a live Codex CLI session by this pack's maintainers. Treat it as an unverified convenience, not a supported feature.

**If isolation cannot be guaranteed** (the operator skips the fresh-session step, or the same session that wrote the code also validates it): the resulting verdict does **not** satisfy the Validator Independence Protocol, full stop. Do not treat a `CAN_PROCEED` from a non-isolated run as equivalent to one from Claude Code's `Task()` isolation. In that case, escalate to a human code review instead of trusting the self-validated pass — this is a documented adapter limitation, not a workaround to paper over.

**Summary**: `DELEGATE_ISOLATED` on Codex CLI is **manual by default, real subagents optional-and-unverified**, delegation depth capped at 1 (no recursive delegation), and costs more tokens than a single-agent run even when the TOML shortcut is used. This is why the adapter's overall status stays **Experimental** — not because the mechanism doesn't exist, but because it isn't automated end-to-end and hasn't been confirmed working against a live session.
