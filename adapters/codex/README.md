# Adapter: OpenAI Codex CLI

**Declared support level: Experimental.** Codex CLI has decent 2026 coverage (native `SKILL.md` support via the `agentskills.io` spec, real subagents, `AGENTS.md` as its native project-instructions convention, MCP client support), but two required capabilities have no real equivalent — `ASK_USER` as a structured tool and `ISOLATED_WORKSPACE` for true parallel isolation. This adapter has **not been validated end-to-end against a live Codex CLI session** by the pack's maintainers. Treat it as experimental until someone confirms the full pipeline works in practice, and say so explicitly to anyone who installs it.

## What this adapter installs

| Destination                                  | Source                                                                                                                                                                        |
| -------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `.agents/skills/<name>/`                     | `development-agents/skills/<name>/` (verbatim copy — same `SKILL.md` format, matches the `agentskills.io` discovery path Codex CLI reads)                                     |
| `AGENTS.md` (project root)                   | Idempotent, section-scoped merge of the `## SDD Kit` block — see `commands/references/project-instructions-sync.md`. This is Codex's **native** convention, not a workaround. |
| _(no commands/ folder populated)_            | See gap notes below                                                                                                                                                           |

No `.codex/` subfolder is created — Codex CLI's real convention is a root-level `AGENTS.md`, not a subfolder. (An earlier version of this pack incorrectly referenced `.codex/AGENTS.md`; that was a documentation bug, not a real Codex convention, and has been corrected.)

## Model Routing — `RESOLVED`

Canonical policy: `development-agents/framework/_shared/model-routing.md`. Concrete values:
`config/model-routing.yaml`, resolved via `framework/tools/resolve-model.sh codex <STRONG|EXECUTION>`
— this adapter does **not** keep its own copy of the mapping.

**Real mechanism (child CLI invocation, confirmed via current Codex CLI documentation)**: Codex CLI's
non-interactive `codex exec "<prompt>"` mode (`codex e` short form) is built for automation, and
supports selecting a model per invocation directly: `codex exec --model <model>
--model-reasoning-effort <level> "<prompt>"` (flags `-m`/`--model`; `model_reasoning_effort` accepts
`minimal|low|medium|high|xhigh`). This is a real per-call flag, not an interactive picker — exactly
the "CLI --model" / "child codex invocation" mechanism this pack's architecture allows an adapter to
use in place of switching the running session's own model. Before dispatching any command/Skill
content that declares a `model_role`, the calling session resolves it
(`resolve-model.sh codex STRONG` → e.g. `model=sol-5.6 effort=high`) and runs
`codex exec --model sol-5.6 --model-reasoning-effort high "<task>"` as a child process, rather than
executing that content inline under whatever model the parent session happens to be running.

**This upgrades `DELEGATE_ISOLATED`/`VALIDATOR_ISOLATED` from manual to automatic.** The previous
version of this adapter (before Model Routing) described the isolation procedure as "the operator
opens a fresh Codex CLI session by hand" — that was written without having verified `codex exec`'s
scriptability. It's now clear that's unnecessary: `codex exec` is precisely a synchronous
"spawn-a-fresh-process, get-a-result-back" primitive, callable by the parent session itself (which
has shell access) with no operator action. The Validator Independence Protocol now runs as:

1. The main Codex session does **not** validate its own work — same rule as before.
2. It builds the scrubbed prompt (file list + rule tables from `skills/sdd-validator/SKILL.md`, never
   the implementation rationale — identical scrubbing rule to the Claude Code `Task()` call).
3. It resolves `STRONG` → `codex exec codex STRONG` output, then runs
   `codex exec --model sol-5.6 --model-reasoning-effort high "<scrubbed prompt>"` itself, as a child
   process — a genuinely fresh process/context, not a continuation of its own conversation.
4. That child process follows `skills/sdd-validator/SKILL.md` directly and returns the JSON verdict
   per `framework/_shared/verdict-protocol.md` on stdout, which the parent session captures.
5. The parent session writes it to `sdd/wip/<feature>/verdicts/` as usual.

The **optional** `~/.codex/<profile>.config.toml` + `--profile <name>` mechanism (bundling `model`
and `model_reasoning_effort` together, so a call site only needs `--profile sdd-strong` instead of
two flags) remains available as an equivalent, slightly more convenient alternative — either form is
`RESOLVED`-class automation; this adapter defaults to the direct `--model`/`--model-reasoning-effort`
flags because they need no generated file and always match `config/model-routing.yaml` live, with
nothing to regenerate after an edit.

**Evidence and its limits**: `codex exec`, `-m`/`--model`, `--model-reasoning-effort`, and
`--profile` are corroborated from current official Codex documentation
(`developers.openai.com/codex/config-advanced`) cross-checked against multiple independent
third-party references in this session, all showing matching flag names and example syntax. It was
**not** live-round-trip-tested against a running Codex CLI session — this sandbox has no `codex`
binary installed and this session's `WebFetch` tool is fully blocked by network egress policy
(confirmed against several unrelated hosts, not just OpenAI's), so only search-result excerpts could
be checked, not the primary page directly. Treat the mechanism as **designed and documented as real
automation**, not a claim of a completed live test.

## Known gaps (do not silently degrade past these — tell the user)

- **No repo-shareable command surface.** Codex's `~/.codex/prompts/*.md` mechanism is explicitly user-local, not something this installer can populate on a teammate's behalf. The `/sdd.*` command surface is delivered as **skills** instead (Codex discovers `.agents/skills/` automatically), and `AGENTS.md` tells the operator to read `development-agents/commands/*.md` directly for the full command definitions — and, per "Model Routing" above, to dispatch that content via `codex exec --model ...` rather than running it inline.
- **No dedicated agent-role folder needed.** The pack has no `agents/` folder anymore — all 12 former agent roles are Skills, and Skills already install natively to `.agents/skills/` (row above), the real `agentskills.io` discovery path Codex CLI reads.
- **`ASK_USER` has no structured-tool equivalent.** Codex CLI only exposes binary command-approval dialogs. Every gate (`AskUserQuestion` in the canonical files) degrades to plain conversational text with listed options, always including a free-text choice — handled by the **interactive parent session**, after a `codex exec` child dispatch returns (headless `exec` mode cannot pause mid-run to ask the human anything, so gates never live inside the child call).
- **`ISOLATED_WORKSPACE` is not supported.** Codex subagents/child processes inherit the parent's sandbox policy; there is no per-subagent git-worktree equivalent. The (currently roadmap, not yet shipped) parallel-task execution mode described in `skills/sdd-implementation/SKILL.md` cannot run on this adapter — sequential execution only. Model Routing does not change this: each `codex exec` dispatch still runs sequentially, just under the correct model.
- **Model Routing mechanism is documented `RESOLVED` automation, not yet live-verified in this environment** — see "Model Routing" above for exactly what was and wasn't confirmed. This is a verification gap, not a "falls back to manual" gap.
