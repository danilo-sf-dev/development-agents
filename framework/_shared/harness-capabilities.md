# Harness Capabilities — Conceptual Vocabulary & Translation Map

**Used by**: any canonical agent/skill/command file that needs to delegate work, ask the human a question, isolate a subtask, invoke a packaged procedure, or write project-level instructions. This file is the **single source of truth** for how those intents map onto each supported harness — canonical files should reference this map by name instead of repeating a translation table inline.

**Read this file when**: you see one of the capability names below (`DELEGATE_ISOLATED`, `DELEGATE_OFFLOAD`, `ISOLATED_WORKSPACE`, `ASK_USER`, `CONTINUE_WORKFLOW`, `INVOKE_PROCEDURE`, `WRITE_PROJECT_INSTRUCTIONS`) used in an agent, skill, or command file and need to know what it actually does on the harness currently installed.

---

## Why this file exists

`development-agents` is **stack-agnostic** by design (it never hardcodes a language/framework — that's `sdd-explorer`'s job) but its execution mechanics were originally written directly against Claude Code primitives (`Task(subagent_type=...)`, `AskUserQuestion(...)`, YAML frontmatter `tools:`/`model:`/`isolation:`). Canonical files now describe _intent_ using the names in this table; each `adapters/<harness>/` folder documents how that intent is actually carried out on that platform. This keeps harness-specific mechanics out of the 12 agents / 22 commands / skills, concentrated in one map + the adapters.

This is a **glossary and translation table, not a macro system or new DSL** — there is no parser, no literal `{{DELEGATE_AGENT}}` syntax to expand. Canonical files use these names in plain English prose; a human or an agent reading them resolves the row below for whichever harness is installed.

---

## What actually stays literal in the core, and why (read this before "fixing" a `Task(...)`/`AskUserQuestion(...)` you find)

Two different things in the canonical files look like "Claude Code primitives leaking into core," but only one of them actually is. Getting this distinction right matters — over-abstracting the first kind would break the pack, and under-abstracting the second kind is the bug this file exists to prevent.

**1. YAML frontmatter (`tools:`, `model:`, `isolation:`) — stays literal, by necessity, not by oversight.** The installer (`agents/development-agents-installer.md`) copies agent/skill files **verbatim** — there is no compile/codegen step that rewrites frontmatter per adapter. Claude Code and Cursor both parse this YAML directly from the file on disk to know what tools an agent may use and which model runs it; there is nothing to "translate" it into, because the frontmatter _is_ the mechanism, not a description of one. This is why `adapters/claude-code/README.md` correctly says frontmatter "maps 1:1 with no translation loss" — there was never a conceptual layer to put between the file and the harness for this specific field. Codex CLI and Generic simply don't read this frontmatter at all (see their adapter READMEs) — that's a real, documented gap, not something this capability map can paper over with a translation row.

**2. Literal `Task(subagent_type=...)` / `AskUserQuestion(...)` call blocks in body prose — these ARE meant to be conceptual first.** Unlike frontmatter, these appear in the agent/command's _instructions_, where the intent ("delegate to X in isolation," "ask the user to choose") is what actually matters, and the exact call syntax is one harness's concrete implementation of that intent. Every such block in the canonical files must be preceded or followed by a short note naming the capability (`DELEGATE_ISOLATED`, `DELEGATE_OFFLOAD`, `ASK_USER`, etc.) and pointing here — the literal block itself stays (it's still the correct, necessary Claude Code implementation, and rewriting it into pseudo-code would make the file useless on Claude Code), but it must never be presented as the _only_ way to satisfy the requirement. `adapters/claude-code/README.md`'s "canonical files already speak Claude Code's primitives natively" line applied this reasoning too broadly — it was true for frontmatter, not for body-text call blocks, and has been corrected.

**In short**: frontmatter is structural and stays Claude-Code/Cursor-native because no translation layer exists for it (a real, permanent constraint, not a violation of the architecture). Body-text primitive calls are conceptual-first with the literal syntax kept as the labeled Claude Code example. If you find a `Task(...)`/`AskUserQuestion(...)` in prose with no capability-name annotation nearby, that's a gap to fix, not frontmatter — fix it by adding the annotation, not by deleting the literal block.

---

## The three agnosticism levels (canonical definition — do not redefine elsewhere)

1. **Stack-agnostic**: the pack never hardcodes a programming language, framework, or infrastructure choice. Stack detection is delegated to `sdd-explorer` + `framework/tools/detect-stack.sh` / `detect-language.sh`, and every downstream agent consumes the _result_, not an assumption.
2. **Harness-agnostic core**: the workflow, gates, rules, and agent responsibilities (the _what_ and _when_ of the SDD pipeline) do not depend on which AI coding harness is running them. Canonical files (`agents/`, `skills/`, `commands/`, `framework/`) express intent using this capability map, never a literal harness primitive.
3. **Harness adapter**: the layer (`adapters/<name>/`) that translates core intent into the real primitives of one platform, and — critically — **documents where the translation is 1:1, where it's degraded, and where no equivalent exists.** An adapter that silently pretends a missing capability exists is a bug, not a feature.

A file can be stack-agnostic without being harness-agnostic (that was development-agents' state before this round). Both are required for the "works in any harness" claim to be true.

---

## Capability vocabulary

### `DELEGATE_ISOLATED(agent, task, why)`

**Intent**: hand off work to a sub-agent whose context is deliberately scrubbed of the delegator's own reasoning, so its judgment can't be biased by knowing _why_ something was done. This is the mechanism behind the Validator Independence Protocol (`sdd-validator-runner`) — the isolation is a **correctness requirement**, not an optimization.

| Harness     | Translation                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    | Support level                                                       |
| ----------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------- |
| Claude Code | `Task(subagent_type="<agent>", prompt="<scrubbed task, no rationale>")`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        | **Full**                                                            |
| Cursor      | No synchronous delegate-and-return primitive exists (only asynchronous Background/Cloud Agents, which run out-of-session). Degrade to: run the validation in a **fresh conversation/tab** with only the file paths + rules pasted in, no implementation rationale, and paste the verdict back manually.                                                                                                                                                                                                                                                                                                                                                                                                        | **Partial — degraded, must warn "reduced isolation guarantee"**     |
| Codex CLI   | **Manual by default**: open a fresh `codex` session/context, paste a scrubbed prompt (file list + rules, no rationale) built by the calling session, let it follow `agents/sdd-validator-runner.md` directly, paste the verdict back. Real subagents exist (`/agent`, custom TOML agents in `~/.codex/agents/`) as an optional, faster shortcut to the same manual procedure, but `/sdd.install` does not generate that TOML file and it has not been validated against a live session — see `adapters/codex/README.md` § "`DELEGATE_ISOLATED` on this adapter" for the full step-by-step. If isolation isn't actually followed, the verdict does not satisfy the protocol — escalate to human review instead. | **Partial — manual/documented procedure, not automated end-to-end** |
| Generic     | No tooling assumption. Instruct the human operator: "open a new session with only `<files>` and `<rules>`, no context from this conversation, and ask it to produce a verdict."                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                | **Fallback — manual, honest, not automated**                        |

### `DELEGATE_OFFLOAD(agent, task, why)`

**Intent**: hand off work purely to save context/token budget in the calling session — no integrity requirement, unlike `DELEGATE_ISOLATED`. Used by `context-guardian`'s DELEGATE_MODE/CRITICAL recommendations, `sdd-system-designer`'s SDK-doc lookups via `sdd-explorer`, and (optionally) `sdd-backlog-manager` for large-backlog operations.

| Harness     | Translation                                                                                                                                                                                                                                             | Support level                  |
| ----------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------ |
| Claude Code | `Task(subagent_type="<agent>", prompt="<task>")`                                                                                                                                                                                                        | **Full**                       |
| Cursor      | Same async-only constraint as `DELEGATE_ISOLATED`, but since there's no integrity requirement here, it's acceptable to simply run the operation **inline** in the main session instead of delegating — the only cost is context usage, not correctness. | **Full (via inline fallback)** |
| Codex CLI   | Real subagents (`/agent`), same as above.                                                                                                                                                                                                               | **Full**                       |
| Generic     | Run inline; no delegation available.                                                                                                                                                                                                                    | **Full (via inline fallback)** |

### `ISOLATED_WORKSPACE(scope)`

**Intent**: give a subtask its own filesystem workspace so concurrent/parallel execution can't clobber another task's uncommitted edits. Distinct from `DELEGATE_ISOLATED` — this protects **files**, not **reasoning**. Used today by `sdd-implementer` and `sdd-small-test-writer`'s `isolation: "worktree"` frontmatter for the (currently future/roadmap) parallel-task execution mode.

| Harness     | Translation                                                                                                                                                                       | Support level                                           |
| ----------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------- |
| Claude Code | `isolation: "worktree"` frontmatter / `EnterWorktree` — dedicated git worktree per subagent, auto-cleaned up.                                                                     | **Full**                                                |
| Cursor      | Cloud/Background Agents run in dedicated isolated VMs — real isolation, but asynchronous/out-of-session, not something a running task can spawn and get results back from inline. | **Full, different shape — async only**                  |
| Codex CLI   | Sandbox policy is inherited by subagents (read-only / workspace-write / full-access); no per-subagent git-worktree equivalent.                                                    | **Not currently supported for true parallel isolation** |
| Generic     | Not supported — disable parallel-task mode; run sequentially in the single workspace.                                                                                             | **Not supported — sequential fallback**                 |

### `ASK_USER(options, allow_freetext=true)`

**Intent**: present the human with a small set of choices and always leave a free-text ("Outros") escape hatch. This is the pack's universal gate mechanism (Gate 1/2/2.5/3, architecture-option selection, install-time harness selection, etc.) — see `commands/references/ask-user-question-outros.md` for the "Outros is mandatory" house rule.

| Harness     | Translation                                                                                                                                                                                                                                               | Support level                                                |
| ----------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------ |
| Claude Code | `AskUserQuestion(questions=[...])` — structured multiple-choice tool, stays open until answered.                                                                                                                                                          | **Full**                                                     |
| Cursor      | Structured clarifying questions exist only inside Plan Mode, not as a general callable tool at arbitrary points. Degrade to: ask the question as plain conversational text, list the options (always include a free-text option), and wait for the reply. | **Partial — degraded to plain-text prompt**                  |
| Codex CLI   | No structured multiple-choice tool; only binary command-approval dialogs exist. Degrade to plain conversational text, same as Cursor.                                                                                                                     | **Not supported as a structured tool — plain-text fallback** |
| Generic     | Plain conversational text; no tooling assumption.                                                                                                                                                                                                         | **Fallback — plain-text prompt**                             |

### `CONTINUE_WORKFLOW(command)`

**Intent**: after a next-step gate (`ASK_USER`) resolves to "run the next pipeline command," continue the session directly into that command instead of making the human retype it — a workflow transition, not a procedure invocation. **This is not `INVOKE_PROCEDURE`** — commands (`/sdd.spec`, `/sdd.check`, etc.) are not skills, and the pack previously had ~28 places that incorrectly wrote `Skill(skill="sdd.spec")` for this; those have been corrected to name this capability explicitly.

| Harness     | Translation                                                                                                                                                                                                                                                                                        | Support level                               |
| ----------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------- |
| Claude Code | If a native command-continuation tool is available in the session (e.g. a `SlashCommand`-style tool), use it. Otherwise, read and follow `commands/sdd.<name>.md` directly in the current context — the same pattern the installer and hub commands already use to delegate between command files. | **Full (via direct file-follow fallback)**  |
| Cursor      | No `commands/` folder is installed (see `adapters/cursor/README.md`) — read and follow `development-agents/commands/sdd.<name>.md` directly.                                                                                                                                                       | **Full (via direct file-follow)**           |
| Codex CLI   | No repo-shareable command-continuation tool — read and follow `development-agents/commands/sdd.<name>.md` directly.                                                                                                                                                                                | **Full (via direct file-follow)**           |
| Generic     | Print the next command name and let the operator run it, or read the command file directly if the harness supports following file instructions inline.                                                                                                                                             | **Fallback — manual or direct file-follow** |

### `INVOKE_PROCEDURE(name)`

**Intent**: run a named, packaged, reusable procedure (a "skill") without spawning an isolated agent — the procedure runs inline in the calling context. Used for `sdd-code-reviewer`, `sdd-performance-expert`, `sdd-validator`, `context-guardian`, `commit-workflow`, `sdd-kit-expert`.

| Harness     | Translation                                                                                                                                            | Support level                   |
| ----------- | ------------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------------------- |
| Claude Code | `Skill("<name>")` / `Skill(skill="<name>")`                                                                                                            | **Full**                        |
| Cursor      | Native `SKILL.md` support (`.cursor/skills/<name>/SKILL.md`) — **same file format**, directly copyable, no translation needed beyond the install path. | **Full**                        |
| Codex CLI   | Native `SKILL.md` support per the open `agentskills.io` spec (`.agents/skills/`, `~/.agents/skills/`) — same format.                                   | **Full**                        |
| Generic     | No invocation mechanism assumed. Point the operator at the `SKILL.md` file directly: "read and follow `skills/<name>/SKILL.md`."                       | **Fallback — manual reference** |

### `WRITE_PROJECT_INSTRUCTIONS(content)`

**Intent**: inject/sync SDD-specific session-bootstrap instructions into the target project so any future session (in that harness) picks up pipeline rules automatically. Must always be an **idempotent, section-scoped merge** — create-or-append-or-replace only the marked SDD section, never overwrite the rest of a user's file. See `commands/references/project-instructions-sync.md`.

| Harness     | Translation                                                                                                                                                            | Support level         |
| ----------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------- |
| Claude Code | `CLAUDE.md` at project root, marked `## SDD Kit` section, idempotent merge.                                                                                            | **Full**              |
| Cursor      | `.cursor/rules/sdd-workflow.mdc` (primary) — Cursor also reads root `AGENTS.md`/`CLAUDE.md` if present, so the Cursor adapter does not need its own root file.         | **Full**              |
| Codex CLI   | `AGENTS.md` at project root, marked `## SDD Kit` section, same idempotent merge pattern as `CLAUDE.md`. This is Codex's native convention.                             | **Full**              |
| Generic     | No file written automatically. Installer prints the section content and instructs the operator to paste it into whatever instructions file their harness uses, if any. | **Fallback — manual** |

> **Governing rule for this capability** (see `framework/standards/boundaries.md`, rule B-16): writing any of these files is only permitted via the idempotent, section-scoped merge described above. Blind overwrite of a user's root instructions file remains forbidden regardless of harness.

### `RUN_COMMAND` / `READ_FILE` / `WRITE_FILE` / `SEARCH_FILES`

**Intent**: baseline operations every harness is assumed to support at parity. No translation table needed — Claude Code (`Bash`/`Read`/`Write`/`Glob`/`Grep`), Cursor (terminal + file tools), Codex CLI (sandboxed shell + file tools) and any reasonable "generic" harness all provide these. The only per-harness variance is _approval/sandbox UX_ (e.g. Codex's `untrusted`/`on-request`/`on-failure`/`never` approval policy), which adapters should note but do not need a capability entry for.

---

## Capability support matrix (summary)

| Capability                                            | Claude Code                       | Cursor                 | Codex CLI                                  | Generic                          |
| ----------------------------------------------------- | --------------------------------- | ---------------------- | ------------------------------------------ | -------------------------------- |
| `DELEGATE_ISOLATED`                                   | Full                              | Partial (degraded)     | Partial (manual/documented, not automated) | Fallback (manual)                |
| `DELEGATE_OFFLOAD`                                    | Full                              | Full (inline fallback) | Full                                       | Full (inline fallback)           |
| `ISOLATED_WORKSPACE`                                  | Full                              | Full (async only)      | Not supported                              | Not supported                    |
| `ASK_USER`                                            | Full                              | Partial (plain-text)   | Not supported as tool (plain-text)         | Fallback (plain-text)            |
| `CONTINUE_WORKFLOW`                                   | Full (native tool or file-follow) | Full (file-follow)     | Full (file-follow)                         | Fallback (manual or file-follow) |
| `INVOKE_PROCEDURE`                                    | Full                              | Full                   | Full                                       | Fallback (manual)                |
| `WRITE_PROJECT_INSTRUCTIONS`                          | Full                              | Full                   | Full                                       | Fallback (manual)                |
| `RUN_COMMAND`/`READ_FILE`/`WRITE_FILE`/`SEARCH_FILES` | Full                              | Full                   | Full                                       | Assumed                          |

Two gaps have **no real equivalent today and must never be simulated as if they did**: a synchronous isolated-delegate-with-return in Cursor, and a structured multiple-choice tool in Codex CLI. Every adapter that hits one of these must say so explicitly in its own docs, not silently degrade and claim parity.

---

## Declared support level per harness (documentation language — use exactly this wording elsewhere)

- **Claude Code — Supported (native).** Every required capability is Full.
- **Cursor — Supported (adapter, with documented capability gaps).** Skills/commands/rules are Full; delegation isolation and structured questions degrade gracefully with an explicit warning.
- **Codex CLI — Experimental.** Good 2026 coverage (skills, `AGENTS.md`, real subagents, MCP), but no structured `ASK_USER` and no `ISOLATED_WORKSPACE` — the Validator Independence Protocol runs degraded. Not validated against a live Codex CLI session by this pack's maintainers; treat as experimental until someone confirms it end-to-end.
- **Generic — Fallback only.** Plain-Markdown instructions, no tool-call automation, no false sense of compatibility. Exists so an unsupported harness still gets an honest, literal description of what to do.

Never describe a harness as "supported" if its adapter has an undocumented gap. See `framework/GLOSSARY.md` for the harness glossary entries and `adapters/*/README.md` for the per-adapter detail.
