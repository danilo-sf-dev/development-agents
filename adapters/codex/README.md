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

**Real mechanism (child CLI invocation, confirmed via current Codex CLI documentation — flags
corrected this round)**: Codex CLI's non-interactive `codex exec "<prompt>"` mode (`codex e` short
form) is built for automation, and supports selecting a model per invocation directly via `-m`/
`--model`. **There is no `--model-reasoning-effort` flag** — an earlier version of this adapter
assumed one existed by analogy with `--model` and never verified it against the actual CLI surface.
The real mechanism for reasoning effort is the generic config-override flag `-c key=value`
(`codex -c model_reasoning_effort=high "<prompt>"`, confirmed in current official docs and
independently in multiple third-party references), which applies to `codex exec` the same way it
applies to `codex`. `model_reasoning_effort` accepts `minimal|low|medium|high|xhigh` — **not**
`extra-high`, which was this pack's own invented value and never a real accepted one; corrected to
`xhigh` in `config/model-routing.yaml`. This is a real per-call mechanism, not an interactive picker —
exactly the "CLI --model" / "child codex invocation" mechanism this pack's architecture allows an
adapter to use in place of switching the running session's own model. Before dispatching any
command/Skill content that declares a `model_role`, the calling session resolves it
(`resolve-model.sh codex STRONG` → `model=gpt-5.6-sol effort=high`) and runs

```bash
codex exec --model gpt-5.6-sol -c 'model_reasoning_effort="high"' --json "<task>"
```

as a child process, rather than executing that content inline under whatever model the parent session
happens to be running. Note the value is quoted inside the `-c` argument (`-c
'model_reasoning_effort="high"'`) — `-c` takes a raw TOML-style value, so a string needs its own
quotes; a bare `-c model_reasoning_effort=high` has been reported to work in most shells too, but the
quoted form is the one shown in official examples and is what this adapter uses.

**`--json` is mandatory on every `codex exec` dispatch, not optional.** It is the only source of
the `turn.completed` usage event that `adapters/codex/tools/parse-telemetry.sh` reads — see
"Telemetry" below. Capture stdout to a temp file (`... --json > "$STREAM_FILE"`) so the parser can
read it after the call completes; never omit `--json` "for simplicity" on a dispatch whose usage
should be observable.

**Sandbox — read vs. write dispatch, confirmed via current docs, corrected this round**:
`codex exec` is **read-only by default** (no network access, no writes outside temp — confirmed in
current official docs: "codex exec is read-only by default"). An earlier version of this adapter
dispatched every Skill through the same bare `codex exec --model ...` call with no sandbox override,
which would have made every "write" dispatch (implementation, test-writing) silently do nothing to the
filesystem while still returning a result — the same class of bug the Cursor adapter had with
`--force`. Fixed the same way: this adapter grants write access only to dispatches whose Skill/phase
actually writes files, and withholds it from everything else:

| Dispatch is...                                                                                    | Command                                                                                       | Why                                                                 |
| -------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------- |
| Read-only / analysis (`sdd-explorer`, `sdd-layer-analysis`, `sdd-system-design`, `sdd-debugger`, `sdd-validator` isolated mode) | `codex exec --model "<resolved>" -c 'model_reasoning_effort="<level>"' --json "<task>"` (default sandbox, no override) | Default `codex exec` is already read-only — nothing extra needed, and nothing here should mutate the working tree (`sdd-validator` must not, per `VALIDATOR_ISOLATED` property 3). |
| Write-capable (`sdd-implementation`, `sdd-test-writing`, `/sdd.build`, `/sdd.plan` writing `tasks.json`, any phase that creates/edits files) | `codex exec --model "<resolved>" -c 'model_reasoning_effort="<level>"' --sandbox workspace-write --ask-for-approval never --json "<task>"` | Without `--sandbox workspace-write`, the call is read-only and would silently do nothing to the filesystem while still reporting a result; `--ask-for-approval never` is required alongside it so the headless call doesn't block waiting for an approval prompt that will never come. |

`--sandbox workspace-write --ask-for-approval never` is granted per-dispatch based on what that
specific Skill/phase does, never blanket-applied to every call.

**`OFFLOAD_READ` / `sdd-explorer` — desambiguation (corrected this round).** `harness-capabilities.md`
describes this capability for Codex as "real subagents where available" — a phrase that, before this
correction, was ambiguous between two structurally different mechanisms: (a) a genuine child process
this session shells out to via `codex exec --json` (the "Read-only / analysis" row above — a real
OS-level subprocess whose stdout this session captures), and (b) a native, in-session subagent tool
that Codex CLI itself may expose inside an already-running interactive session (structurally
analogous to Claude Code's `Task()` tool) — which, if that is what actually runs, produces no
separate JSONL stream this session's own scripts can intercept, because it never leaves the parent
process. This is now resolved explicitly:

- **Preferred**: dispatch `sdd-explorer` (and every other `OFFLOAD_READ` Skill) as the child
  `codex exec --model "<resolved>" -c 'model_reasoning_effort="<level>"' --json "<task>"` form from
  the table above. This is what "real subagents" in `harness-capabilities.md` means for
  `OFFLOAD_READ`, and it is what makes the delegation's token usage measurable —
  `adapters/codex/tools/parse-telemetry.sh` can read its captured stream. Requires no extra
  operator action beyond the harness's normal command-approval flow — the calling session
  dispatches it the same way it dispatches any other child `codex exec` call.
- **Fallback**: if a genuinely fresh child process cannot be used for some reason and the delegation
  runs via Codex's own native in-session subagent mechanism instead, that is still an acceptable way
  to satisfy `OFFLOAD_READ` **behaviorally** (a compact result still comes back, context is still
  saved) — but its telemetry is **not** available, because there is no captured stream for
  `parse-telemetry.sh` to read. Report it as such (`telemetry: unavailable (interactive session)` —
  see `commands/references/phase-transition-observability.md`); never estimate a token count for it,
  and never try to scrape it from any UI or status output.
- The choice between these two is made at dispatch time by whether a child process was actually
  used — not declared in advance by this document, and not something a command file should decide
  by naming a mechanism; the command asks for `OFFLOAD_READ`, this adapter satisfies it via whichever
  of the two above actually happened, and whichever one it was determines whether telemetry exists
  for that call.

**This upgrades `DELEGATE_ISOLATED`/`VALIDATOR_ISOLATED` from manual to automatic.** The previous
version of this adapter (before Model Routing) described the isolation procedure as "the operator
opens a fresh Codex CLI session by hand" — that was written without having verified `codex exec`'s
scriptability. It's now clear that's unnecessary: `codex exec` is precisely a synchronous
"spawn-a-fresh-process, get-a-result-back" primitive, callable by the parent session itself (which
has shell access) with no operator action. The Validator Independence Protocol now runs as:

1. The main Codex session does **not** validate its own work — same rule as before.
2. It builds the scrubbed prompt (file list + rule tables from `skills/sdd-validator/SKILL.md`, never
   the implementation rationale — identical scrubbing rule to the Claude Code `Task()` call).
3. It resolves `STRONG` → `resolve-model.sh codex STRONG` → `model=gpt-5.6-sol effort=high`, then runs
   `codex exec --model gpt-5.6-sol -c 'model_reasoning_effort="high"' --json "<scrubbed prompt>"` itself
   (default read-only sandbox — no `--sandbox workspace-write`, see "Sandbox" above), as a child
   process — a genuinely fresh process/context, not a continuation of its own conversation, and
   **without** any file-editing instruction in the prompt (validator dispatches are read-only by
   role — see `VALIDATOR_ISOLATED` property 3). The read-only default sandbox is a second, independent
   enforcement of the same guarantee, not just the prompt's wording.
4. That child process follows `skills/sdd-validator/SKILL.md` directly and returns the JSON verdict
   per `framework/_shared/verdict-protocol.md` on stdout, which the parent session captures.
5. The parent session writes it to `sdd/wip/<feature>/verdicts/` as usual.

The **optional** `~/.codex/<profile>.config.toml` + `--profile <name>` mechanism (bundling `model`
and `model_reasoning_effort` together, so a call site only needs `--profile sdd-strong` instead of
two flags) remains available as an equivalent, slightly more convenient alternative — either form is
`RESOLVED`-class automation; this adapter defaults to the direct `--model`/`-c
model_reasoning_effort=...` flags because they need no generated file and always match
`config/model-routing.yaml` live, with nothing to regenerate after an edit.

**Interactive handoff (`NEEDS_USER_INPUT` / `codex exec resume`)**: `codex exec` is headless — it
cannot pause mid-run to ask a human anything, so a dispatched command that reaches a Gate
(1/2/2.5/3) or any other `AskUserQuestion` point cannot answer it itself and must not guess. The
child process stops at that point instead and prints a structured final line:

```json
{"status": "NEEDS_USER_INPUT", "gate": "<gate name>", "questions": [...]}
```

The **interactive parent session** (never the child) presents `questions` via `AskUserQuestion`
(degraded to plain text per `ASK_USER` in `harness-capabilities.md`), writes the human's answer to
the state the phase expects (`sdd/wip/<feature>/meta.md` or wherever that gate normally persists its
result), and resumes: `codex exec resume --last "<human's answer, verbatim>"` — `codex exec resume`
(with `--last`, or an explicit session ID) is a real, documented Codex CLI mechanism for continuing a
previous `codex exec` run non-interactively. **Known limitation, not silently glossed over**: current
Codex CLI has an open, acknowledged bug (`openai/codex` issue #3817) where `codex exec --json` does
not return a session ID in its output, so `codex exec resume <explicit-session-id>` cannot reliably
be scripted purely from a prior call's JSON output today. This adapter works around it by using
`codex exec resume --last` (resume the most recent `exec` session in the current working directory)
instead of resume-by-explicit-ID — which is sufficient because the pipeline already dispatches Codex
child processes **sequentially, one at a time** (the same constraint `ISOLATED_WORKSPACE` already
documents as "not supported" for this harness), so "the most recent session in this directory" is
unambiguous. If a future Codex CLI release fixes #3817, resume-by-explicit-ID becomes preferable and
removes the ordering assumption — track that issue before changing this.

**Evidence and its limits**: `codex exec`, `-m`/`--model`, `-c key=value` overrides (including
`model_reasoning_effort`), `--profile`, `--sandbox`/`--ask-for-approval`, and `codex exec resume
--last` are corroborated from current official Codex documentation
(`developers.openai.com/codex/config-advanced`, `developers.openai.com/codex/cli/reference`,
`developers.openai.com/codex/agent-approvals-security`, `developers.openai.com/codex/concepts/sandboxing`)
cross-checked against multiple independent third-party references in this session, all showing
matching flag names and example syntax. The `--json`/resume session-ID limitation is corroborated
directly from the upstream GitHub issue tracker, not inferred. It was **not**
live-round-trip-tested against a running Codex CLI session — this sandbox has no `codex` binary
installed and this session's `WebFetch` tool is fully blocked by network egress policy (confirmed
against several unrelated hosts, not just OpenAI's), so only search-result excerpts could be checked,
not the primary page directly. Treat the mechanism as **designed and documented as real automation**,
not a claim of a completed live test — before relying on this in production, run:

```bash
# READ dispatch — default sandbox (read-only), no file-editing instruction in the prompt
codex exec --model gpt-5.6-luna -c 'model_reasoning_effort="xhigh"' --json "List the files in the current directory and suggest one naming improvement, but do not change anything." --output-last-message /dev/stdout
# Expect: no change to any file on disk.

# WRITE dispatch — explicit workspace-write sandbox + no-prompt approval
codex exec --model gpt-5.6-luna -c 'model_reasoning_effort="xhigh"' --sandbox workspace-write --ask-for-approval never --json "Append a comment line to README.md confirming this test ran."
# Expect: README.md actually modified.

# Resume
codex exec resume --last "Looks good, proceed."
```

## Telemetry

Every `codex exec` dispatch that should be observable captures `--json` output to a temp file, then
`adapters/codex/tools/parse-telemetry.sh --model "<resolved>" --effort "<level>" --file "$STREAM_FILE"`
extracts the `turn.completed` usage event — full mechanics in `adapters/codex/references/
telemetry-display.md`. Display and aggregation (the actual per-phase Usage block, the Total/coverage
line at command end) are defined once, harness-agnostically, in `commands/references/
phase-transition-observability.md` — this adapter's contribution is only the capture step (`--json`
on every measurable dispatch) and the parser. No cost/dollar figure is ever shown for Codex (see
`parse-telemetry.sh`'s own header for why). A dispatch that ran via the native in-session subagent
fallback (see "OFFLOAD_READ" above) has no stream to parse — that phase's Usage block reads
`telemetry: unavailable (interactive session)`, never a guess.

**This capture/parse step only produces data — it does not, by itself, guarantee the Usage block
gets printed.** Printing it at each phase closure is the calling command's job. Two rounds of
this were needed: round 1 added a textual, situated "must print" instruction to every command
file, which a real Codex smoke test of `/sdd.reverse-eng` showed was still not enough — the run
used the native in-session subagent path documented above, and even the `unavailable` fallback
never printed, because a markdown instruction to compose a fallback string is not a verifiable
action. Round 2 replaced that with `framework/tools/emit-phase-observability.sh` — a real Bash
step every command runs, whose own deterministic logic prints `telemetry: unavailable
(interactive session)` whenever the command omits `--stream-file` (the honest thing to do when
the native-subagent path was used), rather than the LLM writing that string itself. This
adapter's job stops at documenting that the native-subagent fallback has no stream to parse;
`commands/references/phase-transition-observability.md` § "Helper mechanism" is the concrete
mechanism that turns that fact into printed output.

## Known gaps (do not silently degrade past these — tell the user)

- **No repo-shareable command surface.** Codex's `~/.codex/prompts/*.md` mechanism is explicitly user-local, not something this installer can populate on a teammate's behalf. The `/sdd.*` command surface is delivered as **skills** instead (Codex discovers `.agents/skills/` automatically), and `AGENTS.md` tells the operator to read `development-agents/commands/*.md` directly for the full command definitions — and, per "Model Routing" above, to dispatch that content via `codex exec --model ...` rather than running it inline.
- **No dedicated agent-role folder needed.** The pack has no `agents/` folder anymore — all 12 former agent roles are Skills, and Skills already install natively to `.agents/skills/` (row above), the real `agentskills.io` discovery path Codex CLI reads.
- **`ASK_USER` has no structured-tool equivalent.** Codex CLI only exposes binary command-approval dialogs. Every gate (`AskUserQuestion` in the canonical files) degrades to plain conversational text with listed options, always including a free-text choice — handled by the **interactive parent session**, after a `codex exec` child dispatch returns (headless `exec` mode cannot pause mid-run to ask the human anything, so gates never live inside the child call).
- **`ISOLATED_WORKSPACE` is not supported.** Codex subagents/child processes inherit the parent's sandbox policy; there is no per-subagent git-worktree equivalent. The (currently roadmap, not yet shipped) parallel-task execution mode described in `skills/sdd-implementation/SKILL.md` cannot run on this adapter — sequential execution only. Model Routing does not change this: each `codex exec` dispatch still runs sequentially, just under the correct model.
- **`--sandbox workspace-write --ask-for-approval never` must never be granted blanket-wide.** A
  dispatch's read/write status comes from the Skill's/phase's own nature (see the table under "Model
  Routing" § "Sandbox" above), not from a shortcut of "always allow writes to be safe" — that would
  let a read-only Skill like `sdd-validator` or `sdd-explorer` mutate files it has no business
  touching. Default `codex exec` (no sandbox override) is already read-only; that default is the
  correct choice for every non-write dispatch, not an oversight to "fix" by adding the flag everywhere.
- **Model Routing mechanism is documented `RESOLVED` automation, not yet live-verified in this environment** — see "Model Routing" above for exactly what was and wasn't confirmed. This is a verification gap, not a "falls back to manual" gap.
