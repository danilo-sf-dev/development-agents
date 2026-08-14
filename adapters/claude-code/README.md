# Adapter: Claude Code

**Declared support level: Supported (native).** Every capability the SDD pipeline needs (`DELEGATE_ISOLATED`, `DELEGATE_OFFLOAD`, `ISOLATED_WORKSPACE`, `ASK_USER`, `INVOKE_PROCEDURE`, `WRITE_PROJECT_INSTRUCTIONS`, `OFFLOAD_READ`, `OFFLOAD_REASONING`, `INTERACTIVE_OFFLOAD`, `VALIDATOR_ISOLATED`) is Full on this harness — see `framework/_shared/harness-capabilities.md` for the full matrix.

**No `agents/` folder exists in this pack anymore.** All 12 former agent roles are Skills under `skills/`. Where a Skill's execution requirement (`OFFLOAD_READ`, `OFFLOAD_REASONING`, `INTERACTIVE_OFFLOAD`, `VALIDATOR_ISOLATED`, `ISOLATED_WORKSPACE`) calls for a fresh-context worker, this adapter uses a general-purpose or read-only-shaped subagent invocation — the specific worker type/name is this adapter's implementation detail, not something the core Skill files or `harness-capabilities.md` reference by name.

## What this adapter installs

| Destination                | Source                                                                                                              |
| -------------------------- | ------------------------------------------------------------------------------------------------------------------- |
| `.claude/commands/`        | `development-agents/commands/*.md` — **byte-for-byte verbatim**, `model_role:` frontmatter included as-is (see "Model Routing" below) |
| `.claude/skills/<name>/`   | `development-agents/skills/<name>/` (verbatim copy, including its `model_role:` frontmatter)  |
| `CLAUDE.md` (project root) | Idempotent, section-scoped merge of the `## SDD Kit` block — see `commands/references/project-instructions-sync.md` |

The installer has **no Model Routing responsibility whatsoever** — it never reads
`config/model-routing.yaml`, never resolves a role, never rewrites a frontmatter field. Every file it
touches is a plain copy.

## Model Routing — `RESOLVED`, 100% runtime, no install step

Canonical policy: `framework/_shared/model-routing.md`. Concrete values: `config/model-routing.yaml`,
looked up via `framework/tools/resolve-model.sh claude-code <STRONG|EXECUTION>` — this adapter does
**not** keep its own copy of the mapping, and nothing in this mechanism is generated at install time.

**One mechanism, resolved fresh at every dispatch**: before running the substantive content of any
`/sdd.<command>` or delegated Skill, the currently-running session reads that command's/Skill's own
`model_role:` frontmatter, resolves it to a concrete model by running
`resolve-model.sh claude-code <role>` (or reading `config/model-routing.yaml` directly — it's two
levels of flat YAML, cheap to parse without shelling out) **at that exact moment**, and dispatches the
substantive work to a fresh-context subagent pinned to that resolved model. A single continuous turn
cannot change its own active model mid-turn — there is no in-turn self-switch — so this per-dispatch
subagent call is what makes the resolved model real, not a description of intent. This applies
uniformly: a standalone `/sdd.spec` invocation and each phase of `/sdd.go`/`/sdd.hub` (see below) both
go through the exact same resolution-then-dispatch step, at the exact moment they're about to run,
every time — never once at install time, never cached.

**This is why editing `config/model-routing.yaml` alone is sufficient**: the very next dispatch reads
the file fresh. There is no generated artifact anywhere in this mechanism to regenerate, and
`/sdd.install` is never involved — reinstalling has no effect on Model Routing one way or the other.

**Live-tested this round**: a subagent dispatched with the model resolved to `"haiku"` reported back
as `claude-haiku-4-5-20251001`; one resolved to `"sonnet"` reported back as `Claude Sonnet 5` — the
override is real, not documentation-only. A full interactive round-trip (dispatch → blocked on human
input → real answer → persisted → **fresh, independent** re-dispatch resolving the model again from
scratch → correct completion) was also run end-to-end this round — see `framework/_shared/model-routing.md`
§ "Interactive dispatch" for the protocol and this adapter's own section below for what that proved.

**Effort is not part of the per-dispatch resolution**: the subagent-dispatch mechanism exposes a
model parameter only — there is no per-dispatch effort parameter (verified against this session's own
dispatch tool, not assumed). `effort: high` in `config/model-routing.yaml`'s `claude-code.STRONG`
entry has no execution path on this harness today — track this as an open, narrow gap if Claude
Code's dispatch mechanism ever exposes a per-call effort parameter; do not simulate it by any other
means (e.g. reintroducing an install-time step) since that would violate "no install step" above.

**`AskUserQuestion` is not available inside a dispatched subagent** (verified: a subagent instructed
to call it receives an immediate tool error, it does not pause or forward the question) — see
"`/sdd.go` and `/sdd.hub`" below and `framework/_shared/model-routing.md` § "Interactive dispatch" for
how Gates are handled around this.

## `/sdd.go` and `/sdd.hub` — real per-phase model switching

`/sdd.go`/`/sdd.hub` declare `model_role: inherit` because they don't pin one model for the whole
express run — each phase has its own `model_role` (from that phase's own command frontmatter), and
each one goes through the exact same resolve-then-dispatch step described above, independently, right
before it runs. This works cleanly with the pipeline's existing file-based state
(`sdd/wip/<feature>/*.md`, `meta.md`): phases already read/write their state to disk rather than
relying on shared conversation context, which is exactly what per-phase dispatch needs.

**A dispatched phase cannot itself answer a Gate.** `AskUserQuestion` is unavailable inside a
dispatched subagent (verified: calling it from inside one errors immediately rather than pausing). So
a phase that reaches Gate 1/2/2.5/3 or any other `AskUserQuestion` point stops there and returns
`{"status": "NEEDS_USER_INPUT", ...}` instead of asking; the orchestrator session running `/sdd.go`
asks it, persists the answer to the same state file, and dispatches a **new**, independent subagent
(resolving the model fresh again, same role) to continue that phase past the gate — see
`framework/_shared/model-routing.md` § "Interactive dispatch" for the full protocol and
`commands/sdd.go.md` § "Model Routing — automatic per-phase dispatch" for the phase-by-phase mapping.

**Live-tested end-to-end this round, with a fixture (not a real feature)**: a first dispatch read a
state file, found no answer recorded, and correctly returned `NEEDS_USER_INPUT` instead of guessing
or attempting the unavailable question tool. The orchestrator (this session) asked the real question
via the real interactive tool, got a real answer, wrote it to the state file, and issued a **second,
fully independent dispatch** (a different subagent instance with no memory of the first) that read the
updated state file and produced a result reflecting the actual human answer — not a default, not an
inference. This confirms the state-file handoff is sufficient for a correct resume, not merely a
plausible design.

## How each execution requirement is satisfied

| Capability | Claude Code mechanism (this adapter's choice, not a core dependency) |
| --- | --- |
| `OFFLOAD_READ` (`sdd-explorer`, `sdd-layer-analysis`) | Fresh-context subagent invocation with no `Write`/`Edit` in its tool grant, given the Skill's content as its task. `sdd-layer-analysis` historically had no `Bash`; if the subagent type used grants `Bash`, that is a documented permission increase, not silent. |
| `OFFLOAD_REASONING` (`sdd-debugger`, `sdd-system-design`) | Same shape as `OFFLOAD_READ`, with a per-call `model` override resolved from the Skill's `model_role: STRONG` via `resolve-model.sh`. |
| `INTERACTIVE_OFFLOAD` (`sdd-project-wizard`, `sdd-mcp-setup`) | Fresh-context subagent invocation with `model` resolved from `model_role: EXECUTION`; runs inline when invoked as a standalone entry point. |
| `ISOLATED_WORKSPACE` (`sdd-implementation`, `sdd-test-writing`) | Per-call workspace isolation (dedicated git worktree), invoked alongside a fresh-context subagent with `Write`/`Edit`/`Bash` and `model` resolved from that Skill's `model_role` (`EXECUTION` default for implementation, `STRONG` always for test-writing — see `model-routing.md` for escalation). |
| `VALIDATOR_ISOLATED` (`sdd-validator` isolated mode) | Fresh-context subagent invocation with a caller-built scrubbed prompt (file paths + rules only), no `Write`/`Edit` in its tool grant, and `model` resolved from `model_role: STRONG` (always — isolation and model strength are independent guarantees, see `model-routing.md`). |

**Frontmatter stays verbatim, including `model_role:`** — see `framework/_shared/harness-capabilities.md` § "What stays literal, and what doesn't" for the full reasoning. `tools:`/`isolation:` are copied verbatim because there is no translation step _for them_ on any harness — Claude Code and Cursor read them directly from disk, Codex CLI and Generic don't read them at all. `model_role:` is copied verbatim too, exactly like every other field: it is never translated, on this harness or any other — resolution happens entirely at dispatch time (see "Model Routing" above), never as a frontmatter rewrite.

Canonical files (`skills/`, `commands/`, `framework/`) never contain a literal `Task(...)` call, subagent-type name, or `resolve-model.sh` invocation — those only ever appear here, in this adapter's own documentation, as this harness's concrete resolution of a capability name (`DELEGATE_ISOLATED`, `ASK_USER`, etc.) declared in the canonical file. If you find one in `skills/`, `commands/`, or elsewhere in `framework/`, that's a bug in that file — fix it by naming the capability and pointing here, not by leaving the literal call in place.

## Known gaps

None — this is the reference implementation every other adapter is compared against.
