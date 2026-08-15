# Adapter: Google Antigravity (agy)

**Declared support level: Experimental.** Antigravity has native sub-agent dispatch, model selection (`--model`), and effort control (`--effort`), but several SDD pipeline capabilities have no confirmed equivalent: `ISOLATED_WORKSPACE` (per-call git worktree) is unconfirmed, `ASK_USER` as a structured multi-choice tool is unconfirmed for headless dispatches, and the adapter has **not been validated end-to-end against a live `agy` session** by the pack's maintainers. Treat this as experimental until someone confirms the full pipeline in practice, and say so explicitly to anyone who installs it.

## What this adapter installs

| Destination                | Source                                                                                                              |
| -------------------------- | ------------------------------------------------------------------------------------------------------------------- |
| `.antigravity/skills/<name>/` | `development-agents/skills/<name>/` (verbatim copy — same `SKILL.md` format; see gap note below on discovery)   |
| `ANTIGRAVITY.md` (project root) | Idempotent, section-scoped merge of the `## SDD Kit` block — Antigravity's native project-instructions file per `commands/references/project-instructions-sync.md` |

No `.antigravity/commands/` is populated — Antigravity reads commands from an `ANTIGRAVITY.md` block, not a commands folder. The operator reads `development-agents/commands/*.md` directly for command content and invokes it via `agy` interactively.

## Model Routing — `RESOLVED` (mechanism confirmed; live-tested gap noted)

Canonical policy: `development-agents/framework/_shared/model-routing.md`. Concrete values: `config/model-routing.yaml`, resolved via `framework/tools/resolve-model.sh antigravity <STRONG|EXECUTION>` — this adapter does **not** keep its own copy of the mapping.

**Dispatch mechanism (confirmed from 2026-08 Antigravity CLI changelog and multiple independent references; not live-tested end-to-end in this session)**: Antigravity CLI (`agy`) supports a headless/non-interactive prompt mode with per-invocation model and effort flags:

```bash
agy --model gemini-3.7-flash --effort high -p "<task>"
```

Before running substantive content of any `/sdd.<command>` or delegated Skill, the currently-running session resolves that command's `model_role:` via `resolve-model.sh antigravity <role>` (e.g., `model=gemini-3.7-flash effort=high` for STRONG), then dispatches the content to a fresh `agy` child process pinned to that resolved model and effort:

| Role | Resolved model | Effort flag |
| --- | --- | --- |
| `STRONG` | `gemini-3.7-flash` | `--effort high` |
| `EXECUTION` | `gemini-3.6-flash` | `--effort high` |

**Model IDs are confirmed runtime identifiers** (not UI display names): `gemini-3.7-flash` appears in `google-gemini/gemini-skills` SKILL.md as the recommended current agentic/multimodal model; `gemini-3.6-flash` is confirmed in LibreChat issue #14367 and multiple 2026 sources. **Effort values** (`low|medium|high`) are confirmed as the accepted parameter set from Antigravity CLI v1.1.5 changelog.

**Effort IS part of the per-dispatch call** on this harness (unlike Claude Code, where `effort` has no Task() execution path). The `--effort` flag was introduced in `agy` v1.1.5 and applies per-invocation — changing `config/model-routing.yaml` takes effect on the very next dispatch, no reinstall needed.

**`agy models` subcommand** (introduced in v1.0.5) lists the current supported model catalog. Run it before relying on the model IDs above in a new environment — the catalog evolves and this file may not reflect the very latest additions.

## Headless dispatch — read vs. write

The default sandbox behavior of `agy -p "..."` in headless mode has not been confirmed in this session (whether it is read-only by default, like `codex exec`, or write-capable). Pending confirmation:

| Dispatch is...     | Recommended invocation                                            | Rationale                                |
| ------------------ | ----------------------------------------------------------------- | ---------------------------------------- |
| Read-only analysis (`sdd-explorer`, `sdd-validator`, `sdd-debugger`) | `agy --model <m> --effort <e> -p "<task>"` | Confirm no write side-effects before shipping |
| Write-capable (`sdd-implementation`, `sdd-test-writing`, any phase that edits files) | `agy --model <m> --effort <e> -p "<task>"` + sandbox flag TBD | Verify the sandbox flag (if any) grants file writes |

**Before using this adapter in production, run:**

```bash
# Confirm read-only behavior (no file changes expected)
agy --model gemini-3.6-flash --effort high -p "List files in the current directory and explain one naming issue. Do not change any files."
# Expect: no disk mutations.

# Confirm write behavior
agy --model gemini-3.6-flash --effort high -p "Append a comment to README.md confirming this test ran."
# Expect: README.md actually modified.
```

Update this README with findings.

## Interactive handoff (`NEEDS_USER_INPUT`)

Headless `agy -p "..."` is non-interactive — it cannot pause mid-run to ask a human anything, so a dispatched command that reaches a Gate (1/2/2.5/3) or any other `AskUserQuestion` point cannot answer it itself and must not guess. The child process stops at that point and prints:

```json
{"status": "NEEDS_USER_INPUT", "gate": "<gate name>", "questions": [...]}
```

The **interactive parent session** (the `agy` session the user is actually talking to) presents the question via `AskUserQuestion` (or plain conversational text if the tool is unavailable in the TUI context), writes the human's answer to the state the phase expects (`sdd/wip/<feature>/meta.md` or the relevant gate file), and re-dispatches that phase — resolving the model fresh again, same role — via a new `agy --model ... --effort ... -p "<task>"` call. This is the same NEEDS_USER_INPUT → persist → re-dispatch protocol documented in `framework/_shared/model-routing.md` § "Interactive dispatch"; the only Antigravity-specific detail is the `agy -p` invocation form.

## How each execution requirement maps

| Capability | Antigravity mechanism (this adapter's choice) |
| --- | --- |
| `OFFLOAD_READ` (`sdd-explorer`, `sdd-layer-analysis`) | `agy --model gemini-3.6-flash --effort high -p "<task>"` headless, read-only dispatch |
| `OFFLOAD_REASONING` (`sdd-debugger`, `sdd-system-design`) | Same shape, `--model gemini-3.7-flash --effort high` (STRONG) |
| `INTERACTIVE_OFFLOAD` (`sdd-project-wizard`, `sdd-mcp-setup`) | `agy --model gemini-3.6-flash --effort high -p "<task>"` — or inline if the parent session is already interactive |
| `ISOLATED_WORKSPACE` (`sdd-implementation`, `sdd-test-writing`) | **UNCONFIRMED** — see Known Gaps |
| `VALIDATOR_ISOLATED` (`sdd-validator` isolated mode) | `agy --model gemini-3.7-flash --effort high -p "<scrubbed-prompt>"` (read-only — validator must never edit files); sandbox isolation TBD |
| `ASK_USER` | Interactive `agy` TUI sessions have conversational Q&A; structured multi-choice (`AskUserQuestion` tool) is unconfirmed for headless dispatches — the parent interactive session handles all gates |

## Known gaps (do not silently degrade past these)

- **Skill discovery path unconfirmed.** `.antigravity/skills/<name>/` is this adapter's best-guess install destination based on the Antigravity skill/plugin system. Verify with `agy --help` or the official docs that this path is what `agy` actually reads for Skills. Update the "What this adapter installs" table if different.
- **Sandbox / read-write behavior not confirmed.** `codex exec` is read-only by default; `agy -p` behavior is unknown. Until tested, treat every headless dispatch as potentially write-capable and choose tasks accordingly.
- **`ISOLATED_WORKSPACE` not confirmed.** True per-dispatch git-worktree isolation (as Claude Code provides via `isolation: worktree` subagent invocation) has no documented equivalent for `agy` child processes. Sequential-only until confirmed; the parallel `sdd-implementation` path described in `skills/sdd-implementation/SKILL.md` cannot be claimed working on this adapter.
- **`ASK_USER` structured tool in headless context.** Whether `AskUserQuestion` (or an Antigravity-native equivalent) is available inside a headless `agy -p` dispatch is unconfirmed. The interactive parent session handles all gates — headless dispatches never attempt it and always return `NEEDS_USER_INPUT` instead.
- **Not live-tested end-to-end.** Model dispatch, effort flag, headless mode, and the NEEDS_USER_INPUT handoff are all documented from 2026 changelog and third-party references, not from a real round-trip test in this environment. Before shipping, run the smoke tests in "Headless dispatch" above and the interactive handoff once with a real fixture.
