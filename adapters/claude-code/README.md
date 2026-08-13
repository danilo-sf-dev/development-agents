# Adapter: Claude Code

**Declared support level: Supported (native).** Every capability the SDD pipeline needs (`DELEGATE_ISOLATED`, `DELEGATE_OFFLOAD`, `ISOLATED_WORKSPACE`, `ASK_USER`, `INVOKE_PROCEDURE`, `WRITE_PROJECT_INSTRUCTIONS`, `OFFLOAD_READ`, `OFFLOAD_REASONING`, `INTERACTIVE_OFFLOAD`, `VALIDATOR_ISOLATED`) is Full on this harness — see `framework/_shared/harness-capabilities.md` for the full matrix.

**No `agents/` folder exists in this pack anymore.** All 12 former agent roles are Skills under `skills/`. Where a Skill's execution requirement (`OFFLOAD_READ`, `OFFLOAD_REASONING`, `INTERACTIVE_OFFLOAD`, `VALIDATOR_ISOLATED`, `ISOLATED_WORKSPACE`) calls for a fresh-context worker, this adapter uses a general-purpose or read-only-shaped subagent invocation (`Task(subagent_type=..., prompt="follow skills/<name>/SKILL.md ...")`) — the specific worker type/name is this adapter's implementation detail, not something the core Skill files or `harness-capabilities.md` reference by name.

## What this adapter installs

| Destination                | Source                                                                                                              |
| -------------------------- | ------------------------------------------------------------------------------------------------------------------- |
| `.claude/commands/`        | `development-agents/commands/*.md`, with one field translated — see "Model Routing" below (rest copied verbatim)   |
| `.claude/skills/<name>/`   | `development-agents/skills/<name>/` (verbatim copy, including its `model_role:` frontmatter — see "Model Routing")  |
| `CLAUDE.md` (project root) | Idempotent, section-scoped merge of the `## SDD Kit` block — see `commands/references/project-instructions-sync.md` |

## Model Routing — `RESOLVED`

Canonical policy: `framework/_shared/model-routing.md`. Concrete values: `config/model-routing.yaml`,
looked up via `framework/tools/resolve-model.sh claude-code <STRONG|EXECUTION>` — this adapter does
**not** keep its own copy of the mapping.

**Two real, automatic mechanisms, both `RESOLVED` (zero operator action)**:

1. **Command-level (install-time translation).** Claude Code's native mechanism for pinning a
   command's model is the `model:` frontmatter key on the installed `.claude/commands/*.md` file —
   `model_role:` is not a key Claude Code itself reads. So this is the one frontmatter field this
   adapter does **not** copy verbatim: at install time, `sdd-installer` runs
   `resolve-model.sh claude-code STRONG` / `EXECUTION` for each command and writes the resolved
   `model:` value into the generated `.claude/commands/*.md` (`inherit` passes through unchanged —
   see `/sdd.go` below for what it actually does instead of pinning one model). Re-running
   `/sdd.install` after editing `config/model-routing.yaml` regenerates these files with the new
   value — this is the one point in the whole pipeline where a config change needs a reinstall to
   propagate, because command frontmatter is a static file, not resolved live.
2. **Sub-dispatch (call-time resolution, live-tested this round).** Every `Task()` call that
   delegates a Skill or a phase — `OFFLOAD_READ`, `OFFLOAD_REASONING`, `INTERACTIVE_OFFLOAD`,
   `ISOLATED_WORKSPACE`, `VALIDATOR_ISOLATED`, and each `/sdd.go`/`/sdd.hub` phase (see below) — sets
   its own `model` parameter to the value `resolve-model.sh claude-code <role>` returns for that
   Skill's/phase's `model_role`, resolved fresh at call time. **Verified live in this session**: a
   subagent dispatched with `model: "haiku"` reported back as `claude-haiku-4-5-20251001`; a subagent
   dispatched with `model: "sonnet"` reported back as `Claude Sonnet 5` — the override is real, not
   documentation-only.
   **Effort is not part of this**: the `Task()` call's parameters expose `model` only — there is no
   call-time `effort` parameter (verified against this tool's own schema, not assumed). `effort:
   high` in `config/model-routing.yaml`'s `claude-code.STRONG` entry only takes effect through
   mechanism 1 above (baked into `.claude/commands/*.md` frontmatter at install time, where a static
   subagent/command definition genuinely can declare `effort:`); a `/sdd.go`/`/sdd.hub` per-phase
   `Task()` dispatch gets the right **model** but runs at that model's default effort, not the
   `effort:` value from the YAML. This is a real, narrow gap in this mechanism, not a documentation
   omission — track it if Claude Code's `Task` tool ever exposes a call-time effort parameter.
   **`AskUserQuestion` is not available inside a dispatched subagent either** (verified: a subagent
   instructed to call it receives an immediate tool error, it does not pause or forward the
   question) — see "`/sdd.go` and `/sdd.hub`" below and `framework/_shared/model-routing.md` §
   "Interactive dispatch" for how Gates are handled around this.

## `/sdd.go` and `/sdd.hub` — real per-phase model switching

A single Claude Code turn cannot change its own model mid-turn — there is no in-turn `/model` the
agent can call on itself. So `/sdd.go`/`/sdd.hub` do **not** run every phase inline in one continuous
turn (which is what they did before this round, and which made `model_role: inherit` on those two
commands true but not automatic). Instead, each phase is dispatched as its own `Task()` call —
`Task(subagent_type="general-purpose", prompt="Follow development-agents/commands/sdd.<phase>.md for feature <name>, express-mode overrides apply. Read state from sdd/wip/<feature>/, write results back the same way that command already specifies.", model=resolve-model.sh claude-code <phase's model_role>)`
— so each phase genuinely executes under its own resolved model. This works cleanly with the
pipeline's existing file-based state (`sdd/wip/<feature>/*.md`, `meta.md`): phases already read/write
their state to disk rather than relying on shared conversation context, which is exactly what
isolated dispatch needs.

**A dispatched phase cannot itself answer a Gate.** `AskUserQuestion` is unavailable inside a
`Task()`-dispatched subagent (verified: calling it from inside one errors immediately rather than
pausing). So a phase that reaches Gate 1/2/2.5/3 or any other `AskUserQuestion` point stops there and
returns `{"status": "NEEDS_USER_INPUT", ...}` instead of asking; the orchestrator session running
`/sdd.go` asks it, persists the answer to the same state file, and issues a **new** `Task()` call
(same resolved `model=`) to continue that phase past the gate — see
`framework/_shared/model-routing.md` § "Interactive dispatch" for the full protocol and
`commands/sdd.go.md` § "Model Routing — automatic per-phase dispatch" for the phase-by-phase mapping
and worked-through gate-handling detail.

## How each execution requirement is satisfied

| Capability | Claude Code mechanism (this adapter's choice, not a core dependency) |
| --- | --- |
| `OFFLOAD_READ` (`sdd-explorer`, `sdd-layer-analysis`) | Fresh-context subagent invocation with no `Write`/`Edit` in its tool grant, given the Skill's content as its task. `sdd-layer-analysis` historically had no `Bash`; if the subagent type used grants `Bash`, that is a documented permission increase, not silent. |
| `OFFLOAD_REASONING` (`sdd-debugger`, `sdd-system-design`) | Same shape as `OFFLOAD_READ`, with a per-call `model` override resolved from the Skill's `model_role: STRONG` via `resolve-model.sh`. |
| `INTERACTIVE_OFFLOAD` (`sdd-project-wizard`, `sdd-mcp-setup`) | Fresh-context subagent invocation with `model` resolved from `model_role: EXECUTION`; runs inline when invoked as a standalone entry point. |
| `ISOLATED_WORKSPACE` (`sdd-implementation`, `sdd-test-writing`) | Per-call workspace isolation (dedicated git worktree), invoked alongside a fresh-context subagent with `Write`/`Edit`/`Bash` and `model` resolved from that Skill's `model_role` (`EXECUTION` default for implementation, `STRONG` always for test-writing — see `model-routing.md` for escalation). |
| `VALIDATOR_ISOLATED` (`sdd-validator` isolated mode) | Fresh-context subagent invocation with a caller-built scrubbed prompt (file paths + rules only), no `Write`/`Edit` in its tool grant, and `model` resolved from `model_role: STRONG` (always — isolation and model strength are independent guarantees, see `model-routing.md`). |

**Two different things are true here, not one** — see `framework/_shared/harness-capabilities.md` § "What actually stays literal in the core" for the full reasoning:

1. Frontmatter `tools:`/`isolation:` is copied verbatim because there is no translation step _for it_ on any harness — Claude Code and Cursor read it directly from disk, Codex CLI and Generic don't read it at all. This is a structural fact, not a design choice this adapter made. `model_role:` is the one exception on commands: it **is** translated (to `model:`) at install time, because Claude Code's real per-command model mechanism is the `model:` key, not `model_role:` — see "Model Routing" above.
2. Literal `Task(subagent_type=...)`/`AskUserQuestion(...)` call blocks in agent/command _body text_ are the concrete Claude Code resolution of a conceptual capability (`DELEGATE_ISOLATED`, `ASK_USER`, etc.) — every such block in the canonical files is annotated with the capability name it implements, precisely so it does **not** read as "the only way to do this" on a harness where it isn't.

## Known gaps

None — this is the reference implementation every other adapter is compared against.
