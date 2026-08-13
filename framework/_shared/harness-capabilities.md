# Harness Capabilities — Conceptual Vocabulary & Translation Map

**Used by**: any canonical skill/command file that needs to delegate work, ask the human a question, isolate a subtask, invoke a packaged procedure, or write project-level instructions. This file is the **single source of truth** for how those intents map onto each supported harness — canonical files should reference this map by name instead of repeating a translation table inline.

**Read this file when**: you see one of the capability names below (`DELEGATE_ISOLATED`, `DELEGATE_OFFLOAD`, `ISOLATED_WORKSPACE`, `ASK_USER`, `CONTINUE_WORKFLOW`, `INVOKE_PROCEDURE`, `WRITE_PROJECT_INSTRUCTIONS`, `OFFLOAD_READ`, `OFFLOAD_REASONING`, `INTERACTIVE_OFFLOAD`, `VALIDATOR_ISOLATED`) used in a Skill or command file and need to know what it actually does on the harness currently installed.

> **No dedicated Agent files remain in `agents/` as of this capability set's introduction.** All 12 former agent roles are now Skills under `skills/`, each declaring which of these capabilities its heavy-execution path requires. "Dedicated Agents in the core: 0" is a statement about *this pack's core*, not a universal claim — a given harness adapter may still materialize a capability through a named agent, a dedicated session, or another harness-specific mechanism where that harness has no lighter-weight equivalent. Read `adapters/<harness>/README.md` for what each harness actually does.
>
> **Model Role is a separate, independent axis from every capability below.** A Skill's execution
> requirement (this file) says *where/how isolated* it runs; its `model_role:` (`STRONG`/`EXECUTION`,
> see `framework/_shared/model-routing.md`) says *how much reasoning capacity* it needs. Neither
> implies the other — `VALIDATOR_ISOLATED` in particular always pairs with `model_role: STRONG`, but
> that pairing is declared explicitly, not inferred from the isolation requirement.

---

## Why this file exists

`development-agents` is **stack-agnostic** by design (it never hardcodes a language/framework — that's `sdd-explorer`'s job) and its execution mechanics are **harness-agnostic**: canonical files (`skills/`, `commands/`, `framework/`) describe _intent_ using the capability names in this file, never a literal harness primitive. Each `adapters/<harness>/` folder documents how that intent is actually carried out on that platform — including the exact call syntax, CLI flags, and worker/subagent shape. This keeps harness-specific mechanics out of the 22 commands / 16 skills and out of this file itself, concentrated in exactly one place: the adapter.

This is a **glossary and translation table, not a macro system or new DSL** — there is no parser, no literal `{{DELEGATE_AGENT}}` syntax to expand. Canonical files use these names in plain English prose; a human or an agent reading them resolves the row below for whichever harness is installed, then reads that harness's `adapters/<harness>/README.md` for the concrete mechanism.

## What stays literal, and what doesn't

**Frontmatter (`tools:`, `model:`, `isolation:`) stays literal, by necessity, not by oversight.** The installer (`skills/sdd-installer/SKILL.md`) copies Skill files **verbatim** — there is no compile/codegen step that rewrites frontmatter per adapter. Claude Code and Cursor both parse this YAML directly from the file on disk; there is nothing to "translate" it into, because the frontmatter _is_ the mechanism, not a description of one. Codex CLI and Generic simply don't read this frontmatter at all (see their adapter READMEs) — that's a real, documented gap, not something this capability map can paper over with a translation row. `model_role:` is the one frontmatter key that IS translated (to a concrete `model:` value), and only at install time, on Claude Code — see `framework/_shared/model-routing.md` § Resolution and `adapters/claude-code/README.md`.

**Everything else — call syntax, subagent/worker types, CLI flags, child-process invocations — is adapter-only.** No canonical file names a literal mechanism (`Task(...)`, a specific `subagent_type`, `agent -p ...`, `codex exec ...`, or a hardcoded `resolve-model.sh <harness> ...` call). A canonical file names the **capability** (this file's vocabulary) and, where relevant, the **Model Role** (`model-routing.md`'s vocabulary) — nothing more. If you find a literal harness call embedded in `skills/`, `commands/`, or elsewhere in `framework/`, that is a bug in that file, not a documented exception — fix it by naming the capability and pointing here, not by leaving the literal call in place.

---

## The three agnosticism levels (canonical definition — do not redefine elsewhere)

1. **Stack-agnostic**: the pack never hardcodes a programming language, framework, or infrastructure choice. Stack detection is delegated to `sdd-explorer` + `framework/tools/detect-stack.sh` / `detect-language.sh`, and every downstream Skill consumes the _result_, not an assumption.
2. **Harness-agnostic core**: the workflow, gates, rules, and Skill responsibilities (the _what_ and _when_ of the SDD pipeline) do not depend on which AI coding harness is running them. Canonical files (`skills/`, `commands/`, `framework/`) express intent using this capability map, never a literal harness primitive.
3. **Harness adapter**: the layer (`adapters/<name>/`) that translates core intent into the real primitives of one platform, and — critically — **documents where the translation is 1:1, where it's degraded, and where no equivalent exists.** This is the only place a concrete mechanism is allowed to appear. An adapter that silently pretends a missing capability exists is a bug, not a feature.

A file can be stack-agnostic without being harness-agnostic (that was development-agents' state before this round). Both are required for the "works in any harness" claim to be true.

---

## Capability vocabulary

Each row below describes **what the harness's mechanism is shaped like** (synchronous vs. child process, fresh context or not, structured tool or plain text) so a reader can judge fitness for purpose — it deliberately does not spell out the literal command, flag, or subagent type, which lives only in `adapters/<harness>/README.md` and changes independently of this conceptual shape.

### `DELEGATE_ISOLATED(skill, task, why)`

**Intent**: hand off work to a Skill whose context is deliberately scrubbed of the delegator's own reasoning, so its judgment can't be biased by knowing _why_ something was done. This is the mechanism behind the Validator Independence Protocol (`sdd-validator`) — the isolation is a **correctness requirement**, not an optimization.

| Harness     | Mechanism shape                                                                                                                                                                                 | Support level                                                       |
| ----------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------- |
| Claude Code | Synchronous, in-session, fresh-context dispatch with a scrubbed task (no rationale) — see `adapters/claude-code/README.md` for the exact call.                                                                                                                                                                                                                                                                                                                                                                                                                                                              | **Full**                                                            |
| Cursor      | No synchronous in-session delegate-and-return primitive exists; real isolation is achieved via an automated headless child process (a genuinely fresh context, a separate process) — see `adapters/cursor/README.md` for the exact command and its evidence/limits. Not live-round-trip-tested in this pack's development environment.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        | **Partial — automated via child CLI process, isolation real, live-verification pending** |
| Codex CLI   | Automated via a headless child process, dispatched by the calling session itself (no operator action) — see `adapters/codex/README.md` for the exact command, its sandbox/write implications, and its evidence/limits. Not live-round-trip-tested in this pack's development environment. If isolation isn't actually followed, the verdict does not satisfy the protocol — escalate to human review instead. | **Partial — automated via child CLI process, isolation real, live-verification pending** |
| Generic     | No tooling assumption. Instruct the human operator: "open a new session with only `<files>` and `<rules>`, no context from this conversation, and ask it to produce a verdict."                                                                                                                                                                                                                                                                                                                                                                                                                                | **Fallback — manual, honest, not automated**                        |

### `DELEGATE_OFFLOAD(skill, task, why)`

**Intent**: hand off work purely to save context/token budget in the calling session — no integrity requirement, unlike `DELEGATE_ISOLATED`. Used by `context-guardian`'s DELEGATE_MODE/CRITICAL recommendations, `sdd-system-design`'s SDK-doc lookups via `sdd-explorer`, and (optionally) `sdd-backlog` for large-backlog operations.

| Harness     | Mechanism shape                                                                                                                                                                                       | Support level                  |
| ----------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------ |
| Claude Code | Synchronous, in-session, fresh-context dispatch — see `adapters/claude-code/README.md` for the exact call.                                                                                                                                        | **Full**                       |
| Cursor      | Same async-only constraint as `DELEGATE_ISOLATED`, but since there's no integrity requirement here, it's acceptable to simply run the operation **inline** in the main session instead of delegating — the only cost is context usage, not correctness. | **Full (via inline fallback)** |
| Codex CLI   | Real subagents where available — see `adapters/codex/README.md`.                                                                                                                                               | **Full**                       |
| Generic     | Run inline; no delegation available.                                                                                                                                                                    | **Full (via inline fallback)** |

### `ISOLATED_WORKSPACE(scope)`

**Intent**: give a subtask its own filesystem workspace so concurrent/parallel execution can't clobber another task's uncommitted edits. Distinct from `DELEGATE_ISOLATED` — this protects **files**, not **reasoning**. Used today by `sdd-implementation` and `sdd-test-writing`'s `isolation: "worktree"` frontmatter for the (currently future/roadmap) parallel-task execution mode.

| Harness     | Mechanism shape                                                                                                                                                                   | Support level                                           |
| ----------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------- |
| Claude Code | Dedicated git worktree per subagent, auto-cleaned up — see `adapters/claude-code/README.md`.                                                                     | **Full**                                                |
| Cursor      | Cloud/Background Agents run in dedicated isolated VMs — real isolation, but asynchronous/out-of-session, not something a running task can spawn and get results back from inline. | **Full, different shape — async only**                  |
| Codex CLI   | Sandbox policy is inherited by subagents; no per-subagent git-worktree equivalent.                                                                    | **Not currently supported for true parallel isolation** |
| Generic     | Not supported — disable parallel-task mode; run sequentially in the single workspace.                                                                                             | **Not supported — sequential fallback**                 |

### `ASK_USER(options, allow_freetext=true)`

**Intent**: present the human with a small set of choices and always leave a free-text ("Outros") escape hatch. This is the pack's universal gate mechanism (Gate 1/2/2.5/3, architecture-option selection, install-time harness selection, etc.) — see `commands/references/ask-user-question-outros.md` for the "Outros is mandatory" house rule.

| Harness     | Mechanism shape                                                                                                                                                                                                                                               | Support level                                                |
| ----------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------ |
| Claude Code | Structured multiple-choice tool, stays open until answered — see `adapters/claude-code/README.md`.                                                                                                                                                          | **Full**                                                     |
| Cursor      | Structured clarifying questions exist only inside Plan Mode, not as a general callable tool at arbitrary points. Degrade to: ask the question as plain conversational text, list the options (always include a free-text option), and wait for the reply. | **Partial — degraded to plain-text prompt**                  |
| Codex CLI   | No structured multiple-choice tool; only binary command-approval dialogs exist. Degrade to plain conversational text, same as Cursor.                                                                                                                     | **Not supported as a structured tool — plain-text fallback** |
| Generic     | Plain conversational text; no tooling assumption.                                                                                                                                                                                                         | **Fallback — plain-text prompt**                             |

> **A dispatched/isolated worker cannot itself satisfy `ASK_USER`, on any harness.** This was verified
> directly on Claude Code: a subagent instructed to call the structured question tool gets an
> immediate error, it does not pause or forward the question. Cursor's and Codex's headless child
> processes are non-interactive by design for the same structural reason. See "Interactive dispatch"
> under `framework/_shared/model-routing.md` for the resulting protocol (`NEEDS_USER_INPUT` + resume),
> which governs every dispatched execution on every harness, not just the degraded ones.

### `CONTINUE_WORKFLOW(command)`

**Intent**: after a next-step gate (`ASK_USER`) resolves to "run the next pipeline command," continue the session directly into that command instead of making the human retype it — a workflow transition, not a procedure invocation. **This is not `INVOKE_PROCEDURE`** — commands (`/sdd.spec`, `/sdd.check`, etc.) are not skills.

| Harness     | Mechanism shape                                                                                                                                                                                                                                                                                        | Support level                               |
| ----------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------- |
| Claude Code | If a native command-continuation tool is available in the session, use it. Otherwise, read and follow `commands/sdd.<name>.md` directly in the current context.                                                                                                                                     | **Full (via direct file-follow fallback)**  |
| Cursor      | No `commands/` folder is installed (see `adapters/cursor/README.md`) — read and follow `development-agents/commands/sdd.<name>.md` directly.                                                                                                                                                       | **Full (via direct file-follow)**           |
| Codex CLI   | No repo-shareable command-continuation tool — read and follow `development-agents/commands/sdd.<name>.md` directly.                                                                                                                                                                                | **Full (via direct file-follow)**           |
| Generic     | Print the next command name and let the operator run it, or read the command file directly if the harness supports following file instructions inline.                                                                                                                                             | **Fallback — manual or direct file-follow** |

### `INVOKE_PROCEDURE(name)`

**Intent**: run a named, packaged, reusable procedure (a "skill") without spawning an isolated agent — the procedure runs inline in the calling context. Used for `sdd-code-reviewer`, `sdd-performance-expert`, `sdd-validator`, `context-guardian`, `commit-workflow`, `sdd-kit-expert`.

| Harness     | Mechanism shape                                                                                                                                            | Support level                   |
| ----------- | ------------------------------------------------------------------------------------------------------------------------------------------------------ | -------------------------------- |
| Claude Code | Native Skill-invocation tool, by name.                                                                                                                    | **Full**                        |
| Cursor      | Native `SKILL.md` support (`.cursor/skills/<name>/SKILL.md`) — **same file format**, directly copyable, no translation needed beyond the install path. | **Full**                        |
| Codex CLI   | Native `SKILL.md` support per the open `agentskills.io` spec (`.agents/skills/`, `~/.agents/skills/`) — same format.                                   | **Full**                        |
| Generic     | No invocation mechanism assumed. Point the operator at the `SKILL.md` file directly: "read and follow `skills/<name>/SKILL.md`."                       | **Fallback — manual reference** |

### `WRITE_PROJECT_INSTRUCTIONS(content)`

**Intent**: inject/sync SDD-specific session-bootstrap instructions into the target project so any future session (in that harness) picks up pipeline rules automatically. Must always be an **idempotent, section-scoped merge** — create-or-append-or-replace only the marked SDD section, never overwrite the rest of a user's file. See `commands/references/project-instructions-sync.md`.

| Harness     | Mechanism shape                                                                                                                                                            | Support level         |
| ----------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------- |
| Claude Code | `CLAUDE.md` at project root, marked `## SDD Kit` section, idempotent merge.                                                                                            | **Full**              |
| Cursor      | `.cursor/rules/sdd-workflow.mdc` (primary) — Cursor also reads root `AGENTS.md`/`CLAUDE.md` if present, so the Cursor adapter does not need its own root file.         | **Full**              |
| Codex CLI   | `AGENTS.md` at project root, marked `## SDD Kit` section, same idempotent merge pattern as `CLAUDE.md`. This is Codex's native convention.                             | **Full**              |
| Generic     | No file written automatically. Installer prints the section content and instructs the operator to paste it into whatever instructions file their harness uses, if any. | **Fallback — manual** |

> **Governing rule for this capability** (see `framework/standards/boundaries.md`, rule B-16): writing any of these files is only permitted via the idempotent, section-scoped merge described above. Blind overwrite of a user's root instructions file remains forbidden regardless of harness.

### `OFFLOAD_READ(skill, task, why)`

**Intent**: move work that is predominantly reading/searching/analyzing (codebase exploration, cross-layer consistency checks) out of the calling session's context, so large volumes of intermediate tool output (grep hits, file reads, comparison tables) don't consume the caller's budget — only a compact result comes back. Used by the `sdd-explorer` and `sdd-layer-analysis` Skills.

**Not a filesystem guarantee.** `OFFLOAD_READ` does **not** mean the execution environment is sandboxed read-only. Tested directly (Claude Code, 2026): an execution context with no write tool can still mutate files via a shell tool if instructed to. The absence of file-editing tools is not enforced at the filesystem level — it is a **behavioral policy**: the Skill instructs the execution context not to mutate files, and nothing beyond that instruction currently blocks it on any harness tested. Any core file, Skill, or adapter that claims "read-only" in the sandboxing sense is making a false claim and must be corrected. If a specific harness *does* provide real filesystem-level read isolation (e.g. a read-only container mount), that is an **additional guarantee that harness's adapter documents explicitly** — never assumed by the core or by another harness's adapter.

**Permission-footprint note**: `sdd-explorer` has historically needed shell access (for `git log`/`find`/detector scripts). `sdd-layer-analysis` has historically **not** needed it — its analysis is pure file comparison. Adapters implementing `OFFLOAD_READ` must preserve this distinction where the harness allows it, and must **not** silently grant `sdd-layer-analysis` a broader tool footprint than it had before. If a harness's available worker/session types can't reproduce that narrower footprint, the adapter must say so explicitly as a documented gap, not absorb it silently.

| Harness     | Mechanism shape                                                                                                                                                                                                                                                        | Support level                          |
| ----------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------- |
| Claude Code | A fresh-context worker without write tools, given the Skill's content as its task. Tested: a worker of this shape successfully ran both the `sdd-explorer` and `sdd-layer-analysis` procedures and returned a compact report. `sdd-explorer`'s shell-access need is preserved by this shape; for `sdd-layer-analysis`, no worker type with an even narrower footprint was found — document the resulting shell-access grant as a known permission increase versus the historical profile until/unless a narrower option exists. See `adapters/claude-code/README.md`. | **Full for behavior, partial for exact historical permission parity on `sdd-layer-analysis`** |
| Cursor      | No synchronous isolated worker; run inline in the current session (same reasoning as `DELEGATE_OFFLOAD` — no integrity requirement here, so inline is a full substitute for behavior, though it does not save context).                                          | **Full (via inline fallback)**          |
| Codex CLI   | Real subagents where available; otherwise read and follow the Skill directly in the current session.                                                                                                                                                   | **Full**                                |
| Generic     | Run inline; no delegation available.                                                                                                                                                                                                                               | **Full (via inline fallback)**          |

### `OFFLOAD_REASONING(skill, task, why)`

**Intent**: move work that requires deep, iterative, multi-hypothesis reasoning (root-cause debugging, architecture/trade-off analysis) out of the calling session, optionally on a stronger model (`model_role: STRONG` — see `model-routing.md`), so the exploratory dead-ends and research don't dominate the caller's context. Used by the `sdd-debugger` and `sdd-system-design` Skills.

**Process boundary, not a tool restriction.** Both Skills follow a "diagnose/decide, don't silently act" rule — `sdd-debugger` produces a report and proposed fix rather than editing code directly; `sdd-system-design` produces ADRs/recommendations rather than implementing before the corresponding Gate. This is enforced the same way as `OFFLOAD_READ`'s boundary: by the Skill's own instructions, not by a technical block that has been proven to exist.

| Harness     | Mechanism shape                                                                                                                                                                                                                                       | Support level                   |
| ----------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------- |
| Claude Code | A fresh-context worker with read/search/run tools (and, for `sdd-system-design`, research tools) and no write tools, invoked at the resolved Model Role via a per-call model override. Tested: a worker of this shape successfully ran both procedures, and a per-call model override to a stronger model was confirmed to work. See `adapters/claude-code/README.md`. | **Full**                        |
| Cursor      | Same async-only constraint as other offload capabilities; acceptable to run inline (no integrity requirement) when Model Routing isn't in play — model selection for the session applies instead of a per-call override. When Model Routing requires a specific role, dispatch per `adapters/cursor/README.md` § Model Routing instead.                                                        | **Full (via inline fallback), model override not per-call** |
| Codex CLI   | Real subagents where available, otherwise inline in the current session; dispatch per `adapters/codex/README.md` § Model Routing when a specific Model Role is required.                                                                                                                                                              | **Full**                        |
| Generic     | Run inline; no delegation or model-override mechanism available.                                                                                                                                                                                  | **Full (via inline fallback)**  |

### `INTERACTIVE_OFFLOAD(skill, task, why)`

**Intent**: run a multi-turn `ASK_USER` wizard-style dialogue (gathering several small decisions) out of the calling session, returning only a compact summary — used when the dialogue itself (not just its result) would otherwise dominate the caller's context. Used by the `sdd-project-wizard` and `sdd-mcp-setup` Skills. Composed of `ASK_USER` (the question mechanism) + the offload/return-compact-summary pattern of `DELEGATE_OFFLOAD` — not a new primitive, a named combination of the two for the specific "wizard embedded inside a larger flow" shape.

**When it degrades to a complete substitute, not a degraded one**: when the Skill is invoked as its own standalone entry point (the user explicitly asked for just this wizard, e.g. running the MCP setup command directly), there is no larger flow to protect — running inline is a full substitute, not a degraded fallback, on every harness including Claude Code. The offload only has a real benefit when the Skill is invoked **embedded** inside a larger flow (e.g. project-wizard triggered mid-`/sdd.start`) whose own context is worth protecting.

| Harness     | Mechanism shape                                                                                                                                    | Support level                                     |
| ----------- | ------------------------------------------------------------------------------------------------------------------------------------------------------ | -------------------------------------------------- |
| Claude Code | Fresh-context worker (optionally at `model_role: EXECUTION` for low-complexity wizards), invoked with the Skill's instructions. Tested: dry-run confirmed with a model override and a compact structured return. See `adapters/claude-code/README.md`.                             | **Full**                                            |
| Cursor      | No structured multi-turn tool outside Plan Mode; degrade `ASK_USER` to plain-text prompts (see `ASK_USER` row above) and run inline (no synchronous isolated worker).                                                                             | **Partial — degraded `ASK_USER`, inline execution** |
| Codex CLI   | No structured multi-choice tool; plain-text prompts, inline or via real subagents if available.                                                                                                                                                          | **Partial — plain-text fallback**                   |
| Generic     | Plain conversational text, inline; no delegation available.                                                                                                                                                                                        | **Fallback — plain-text prompt**                    |

### `VALIDATOR_ISOLATED`

**Intent**: the complete execution contract for independent, unbiased validation of code changes and pipeline process compliance. This is the strictest capability in the vocabulary — a specialization of `DELEGATE_ISOLATED` with additional properties that are **all mandatory, never individually optional**:

1. Fresh context (no memory of the calling session)
2. Scrubbed prompt input (file paths + rules only — never the implementer's rationale)
3. No exposure to the implementer's reasoning at any point
4. Independent execution (the verdict is not influenced by who is asking or why)
5. Process compliance checking (the `PROC-*` rule set: phase-order, immutable-tests, immutable-specs, no-impl-in-test-phase, no-new-tests-in-build)
6. Verification that approved tests are immutable (not merely assumed — checked against the diff)
7. Structured, machine-parseable verdict (fixed JSON schema)
8. The calling orchestrator **must obey the verdict literally** — it may not reinterpret, soften, or override a `CANNOT_PROCEED` verdict
9. No rationalization based on "why" the implementation was done a certain way

**Always pairs with `model_role: STRONG`** (see `model-routing.md` § "Isolation is not a substitute for Model Role") — isolation and reasoning capacity are independent guarantees, declared together explicitly, neither substituting for the other.

**Honest limit, established by direct testing**: property 3/"no mutation of production" is enforced today, on every harness, as a **behavioral + audited** guarantee, not a filesystem sandbox. An execution context without write tools can still mutate files via a shell tool if instructed to (tested on Claude Code — see `OFFLOAD_READ`). What actually protects production code from an isolated validator "helpfully fixing" something is: the scrubbed prompt gives it no rationale to want to change anything, its own instructions tell it to report rather than act, and any accidental mutation would surface as an unexplained diff on the next Process Compliance pass. This document will not claim a stronger guarantee than what has been tested.

The concrete mechanism satisfying all 9 properties is entirely an **adapter decision** — the core and the `sdd-validator` Skill's isolated-mode content never name a specific harness worker type, call syntax, or flag.

| Harness     | Mechanism shape                                                                                                                                                                                                                                                                       | Support level                                                        |
| ----------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------- |
| Claude Code | A fresh-context worker, invoked with a scrubbed prompt (file paths + rules only, built by the caller), given the `sdd-validator` Skill's isolated-mode content as its instructions, with no write tools in its grant, at `model_role: STRONG`. Tested directly: fresh context, scrubbed-prompt sufficiency, and structured-verdict output were all confirmed working with a worker of this shape. The exact worker type/name is an `adapters/claude-code/README.md` implementation detail, not a core dependency. | **Full**                                                               |
| Cursor      | Headless child process, read-only (no write flag granted), at `model_role: STRONG` — see `adapters/cursor/README.md` for the exact command. Automated, real fresh context, not live-verified in this environment.                                                                                                        | **Partial — automated via child CLI process, live-verification pending**       |
| Codex CLI   | Automated child process, default (read-only) sandbox, at `model_role: STRONG`, following the `sdd-validator` Skill's isolated-mode content directly and returning the verdict — see `adapters/codex/README.md` for the exact command. Not live-verified in this environment. | **Partial — automated via child CLI process, live-verification pending**   |
| Generic     | No tooling assumption. Instruct the human operator to open a new session with only the files and rules, no context from the current conversation, and produce a verdict.                                                                                                         | **Fallback — manual, honest, not automated**                          |

### `RUN_COMMAND` / `READ_FILE` / `WRITE_FILE` / `SEARCH_FILES`

**Intent**: baseline operations every harness is assumed to support at parity. No translation table needed — every harness this pack supports provides equivalents (shell execution, file read/write/search). The only per-harness variance is _approval/sandbox UX_, which adapters should note but do not need a capability entry for.

---

## Capability support matrix (summary)

| Capability                                            | Claude Code                       | Cursor                 | Codex CLI                                  | Generic                          |
| ----------------------------------------------------- | --------------------------------- | ---------------------- | ------------------------------------------ | -------------------------------- |
| `DELEGATE_ISOLATED`                                   | Full                              | Partial (automated child process, live-verification pending) | Partial (automated child process, live-verification pending) | Fallback (manual)                |
| `DELEGATE_OFFLOAD`                                    | Full                              | Full (inline fallback) | Full                                       | Full (inline fallback)           |
| `ISOLATED_WORKSPACE`                                  | Full                              | Full (async only)      | Not supported                              | Not supported                    |
| `ASK_USER`                                            | Full                              | Partial (plain-text)   | Not supported as tool (plain-text)         | Fallback (plain-text)            |
| `CONTINUE_WORKFLOW`                                   | Full (native tool or file-follow) | Full (file-follow)     | Full (file-follow)                         | Fallback (manual or file-follow) |
| `INVOKE_PROCEDURE`                                    | Full                              | Full                   | Full                                       | Fallback (manual)                |
| `WRITE_PROJECT_INSTRUCTIONS`                          | Full                              | Full                   | Full                                       | Fallback (manual)                |
| `OFFLOAD_READ`                                        | Full (partial permission-parity gap on `sdd-layer-analysis`, see above) | Full (inline fallback) | Full | Full (inline fallback) |
| `OFFLOAD_REASONING`                                   | Full                              | Full (inline fallback, no per-call model override) | Full | Full (inline fallback) |
| `INTERACTIVE_OFFLOAD`                                 | Full                              | Partial (degraded `ASK_USER`, inline) | Partial (plain-text fallback) | Fallback (plain-text) |
| `VALIDATOR_ISOLATED`                                  | Full                              | Partial (automated child process, live-verification pending) | Partial (automated child process, live-verification pending) | Fallback (manual)                |
| `RUN_COMMAND`/`READ_FILE`/`WRITE_FILE`/`SEARCH_FILES` | Full                              | Full                   | Full                                       | Assumed                          |

One gap has **no real equivalent today and must never be simulated as if it did**: a structured
multiple-choice tool in Codex CLI (`ASK_USER` degrades to plain text everywhere it's needed). A
synchronous isolated-delegate-with-return in Cursor previously belonged in this list too — that was
corrected once the Cursor CLI's headless mode was verified against current documentation: a child CLI
process the calling session shells out to and waits on **is** a synchronous delegate-and-return
primitive, just realized as a subprocess rather than an in-session tool call (see
`DELEGATE_ISOLATED`/`VALIDATOR_ISOLATED` rows above and `adapters/cursor/README.md`). What's still
real about the Cursor gap is narrower than before: not "no synchronous primitive exists," but "the
mechanism is a documented CLI flag, not yet live-round-trip-verified in this pack's development
environment." Every adapter that hits a real gap must say so explicitly in its own docs, not silently
degrade and claim parity.

---

## Declared support level per harness (documentation language — use exactly this wording elsewhere)

- **Claude Code — Supported (native).** Every required capability is Full.
- **Cursor — Supported (adapter, with documented capability gaps).** Skills/commands/rules and Model Routing are Full/automated via a headless child-process dispatch (live-verification pending — see `adapters/cursor/README.md`); structured questions (`ASK_USER`) still degrade gracefully with an explicit warning.
- **Codex CLI — Experimental.** Good 2026 coverage (skills, `AGENTS.md`, real subagents, MCP, an automated child-process dispatch for Model Routing and `DELEGATE_ISOLATED`/`VALIDATOR_ISOLATED` — see `adapters/codex/README.md`), but no structured `ASK_USER` and no `ISOLATED_WORKSPACE` (parallel task execution) — those two gaps are unrelated to validator isolation and remain real regardless of the Model Routing work. Not validated against a live Codex CLI session by this pack's maintainers; treat as experimental until someone confirms it end-to-end.
- **Generic — Fallback only.** Plain-Markdown instructions, no tool-call automation, no false sense of compatibility. Exists so an unsupported harness still gets an honest, literal description of what to do.

Never describe a harness as "supported" if its adapter has an undocumented gap. See `framework/GLOSSARY.md` for the harness glossary entries and `adapters/*/README.md` for the per-adapter detail — including every literal command, flag, and worker/subagent type, none of which is repeated here.
