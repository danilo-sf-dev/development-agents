# Adapter: Claude Code

**Declared support level: Supported (native).** Every capability the SDD pipeline needs (`DELEGATE_ISOLATED`, `DELEGATE_OFFLOAD`, `ISOLATED_WORKSPACE`, `ASK_USER`, `INVOKE_PROCEDURE`, `WRITE_PROJECT_INSTRUCTIONS`, `OFFLOAD_READ`, `OFFLOAD_REASONING`, `INTERACTIVE_OFFLOAD`, `VALIDATOR_ISOLATED`) is Full on this harness — see `framework/_shared/harness-capabilities.md` for the full matrix.

**No `agents/` folder exists in this pack anymore.** All 12 former agent roles are Skills under `skills/`. Where a Skill's execution requirement (`OFFLOAD_READ`, `OFFLOAD_REASONING`, `INTERACTIVE_OFFLOAD`, `VALIDATOR_ISOLATED`, `ISOLATED_WORKSPACE`) calls for a fresh-context worker, this adapter uses a `claude -p` subprocess invocation — the specific tool-allowlist and read/write mode are this adapter's implementation detail, not something the core Skill files or `harness-capabilities.md` reference by name.

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

**Primary dispatch mechanism: `claude -p` subprocess (live-verified this round)**

Before running the substantive content of any `/sdd.<command>` or delegated Skill, the
currently-running session resolves that command's/Skill's own `model_role:` frontmatter, then
dispatches the substantive work as a child `claude` process pinned to the resolved model and effort.
The resolution step: `resolve-model.sh claude-code <role>` → `{"model":"claude-sonnet-4-6","effort":"medium"}` for STRONG, `{"model":"claude-haiku-4-5","effort":"medium"}` for EXECUTION.

**Why subprocess, not Task()/Agent tool**: the in-session Agent/Task() tool only accepts four model
aliases (`sonnet|opus|haiku|fable`) and exposes no effort parameter — both verified live this round
(see "Fallback" below). The `claude -p` subprocess form accepts full versioned model IDs and a
per-invocation `--effort` flag, giving complete control over both dimensions.

**Live-tested this round**: `claude -p "..." --model claude-sonnet-4-6 --effort medium --output-format stream-json --verbose` executed successfully; `"model":"claude-sonnet-4-6"` confirmed in the stream event's `message_start` and in `modelUsage` output. Similarly, `--model claude-haiku-4-5` accepted and confirmed as `canonicalModel: claude-haiku-4-5` in `modelUsage`. `--allowedTools` blocks denied at invocation — `permission_denials` in the result confirms the specific tool call that was rejected; the filesystem was not modified.

**This is why editing `config/model-routing.yaml` alone is sufficient**: the very next dispatch
resolves the file fresh. There is no generated artifact anywhere in this mechanism to regenerate.

## Dispatch form per capability

```bash
# Generic read-only — OFFLOAD_READ, OFFLOAD_REASONING, analysis phases
claude -p "<task>" \
  --model <resolved-model> \
  --effort <resolved-effort> \
  --allowedTools "Read,Glob,Grep" \
  --output-format stream-json --verbose

# VALIDATOR_ISOLATED — sdd-validator, isolated mode, always STRONG
# Must NEVER have Edit, Write, or unrestricted Bash.
claude -p "<scrubbed-task>" \
  --model claude-sonnet-4-6 \
  --effort medium \
  --allowedTools "Read,Glob,Grep" \
  --output-format stream-json --verbose

# Write-capable — ISOLATED_WORKSPACE (sdd-implementation, sdd-test-writing)
# Tools are task-specific; never grant more than needed.
claude -p "<task>" \
  --model <resolved-model> \
  --effort <resolved-effort> \
  --allowedTools "Edit,Write,Read,Glob,Grep,Bash(git add *),Bash(git commit *),Bash(npm test),Bash(mvn *)" \
  --output-format stream-json --verbose

# INTERACTIVE_OFFLOAD (sdd-project-wizard, sdd-mcp-setup)
# These run as interactive sessions or inline when the parent is already interactive.
claude --model <resolved-model> --effort <resolved-effort>
```

`--output-format stream-json --verbose` is mandatory on all subprocess dispatches — the JSON result
envelope contains `modelUsage` (per-model token breakdown) and `usage` (totals), which are the
telemetry foundation for future per-SDD-phase token accounting. Never omit them.

## Read vs. Write dispatch

| Dispatch is...                                    | `--allowedTools` minimum                                                          | Rationale |
| ------------------------------------------------- | --------------------------------------------------------------------------------- | --------- |
| Read-only analysis (`sdd-explorer`, `sdd-layer-analysis`, `sdd-debugger`, `sdd-system-design`) | `"Read,Glob,Grep"` | No filesystem mutation needed; absence of Edit/Write/Bash enforced by the allowlist, not just the prompt wording |
| `VALIDATOR_ISOLATED` (`sdd-validator`, isolated mode) | `"Read,Glob,Grep"` — **no Bash** | Validator must not edit files (property 3 of VALIDATOR_ISOLATED); absence of unrestricted Bash is the second independent enforcement beyond the prompt |
| Write-capable (`sdd-implementation`, `sdd-test-writing`, any phase writing to disk) | `"Edit,Write,Read,Glob,Grep"` + project-specific `Bash(...)` patterns | Bash patterns should be as specific as the project's build/test commands allow — `Bash(npm test)` not `Bash(*)` |

The distinction between read and write dispatches is **per-capability**, not a global setting.
Granting `Edit` or `Write` to every dispatch "for safety" would let a read-only Skill like
`sdd-validator` silently mutate files — do not do that.

## `/sdd.go` and `/sdd.hub` — real per-phase model switching

`/sdd.go`/`/sdd.hub` declare `model_role: inherit` because they don't pin one model for the whole
express run — each phase has its own `model_role` (from that phase's own command frontmatter), and
each goes through the same resolve-then-subprocess step described above, independently, right before it
runs. File-based state (`sdd/wip/<feature>/*.md`, `meta.md`) is the handoff medium — phases
read/write to disk rather than relying on shared conversation context, which is exactly what
per-phase subprocess dispatch needs.

**A dispatched subprocess cannot answer a Gate.** `/effort` and `AskUserQuestion` require interactive
context that a `claude -p` subprocess does not have. A subprocess that reaches a Gate stops and returns:

```json
{"status": "NEEDS_USER_INPUT", "gate": "<gate name>", "questions": [...]}
```

The orchestrator session asks the question via `AskUserQuestion`, persists the answer to the state
file, and re-dispatches a new subprocess for that phase — resolving the model fresh again, same role —
to continue past the gate. See `framework/_shared/model-routing.md` § "Interactive dispatch" for the
full protocol.

## Fallback: Task()/Agent tool

When the `claude` binary is not available in the current environment (confirmed by `which claude`
returning nothing), the adapter may fall back to the in-session `Agent(model: <alias>)` tool with
**explicit degradation** — never silently:

| Dimension | Subprocess (primary) | Task()/Agent (fallback) |
| --- | --- | --- |
| Model ID | Full versioned ID (`claude-sonnet-4-6`) | Short alias only (`sonnet`, `haiku`, `opus`, `fable`) |
| Model accuracy | Exact — `claude-sonnet-4-6` confirmed | Alias resolves to latest; `sonnet` → Sonnet 5 (not 4.6) |
| Effort per dispatch | `--effort medium` accepted and applied | No effort parameter — `effort` field is ignored at dispatch time |
| Tool allowlist | `--allowedTools` blocks hard at invocation | Agent tool grant set at spawn time; granularity varies |
| Telemetry | `modelUsage` + `usage` in JSON result | No structured token breakdown available |

**On fallback, the adapter MUST report degradation explicitly** — output this before the fallback dispatch:

```
⚠ Model Routing degraded: claude binary not found. Falling back to Task()/Agent.
  Requested: claude-sonnet-4-6 / effort:medium → dispatching: sonnet (Sonnet 5, effort ignored)
  Token telemetry unavailable in this mode.
```

Never silently switch from `claude-sonnet-4-6` to `sonnet` without this notice. A silent substitution
is a routing lie — the user may be paying for Sonnet 5 and assuming Sonnet 4.6.

## How each execution requirement is satisfied

| Capability | Claude Code mechanism (this adapter's choice, not a core dependency) |
| --- | --- |
| `OFFLOAD_READ` (`sdd-explorer`, `sdd-layer-analysis`) | `claude -p` subprocess with `--allowedTools "Read,Glob,Grep"` and EXECUTION model |
| `OFFLOAD_REASONING` (`sdd-debugger`, `sdd-system-design`) | Same subprocess shape, STRONG model (`claude-sonnet-4-6 --effort medium`) |
| `INTERACTIVE_OFFLOAD` (`sdd-project-wizard`, `sdd-mcp-setup`) | Interactive `claude` session with EXECUTION model; or inline when parent is already interactive |
| `ISOLATED_WORKSPACE` (`sdd-implementation`, `sdd-test-writing`) | `claude -p` subprocess with write-capable `--allowedTools` (Edit, Write, project Bash patterns) and per-task git worktree |
| `VALIDATOR_ISOLATED` (`sdd-validator`, isolated mode) | `claude -p` subprocess with STRONG model, `--allowedTools "Read,Glob,Grep"` only — no Edit, no Write, no Bash |

**Frontmatter stays verbatim** — `model_role:` is never rewritten at install time. Resolution happens
entirely at dispatch time via `resolve-model.sh`.

## Telemetry

Per-phase usage is extracted from the `--output-format stream-json --verbose` result of every
`claude -p` dispatch. This is the **only** source of telemetry data — no token estimation, no
re-tokenization, no pricing-table lookups. All three dimensions (tokens, cost, duration) come from
the result envelope produced by the subprocess itself.

### Stream-json result structure (live-verified)

```json
{
  "type": "result",
  "duration_ms": 7300,
  "total_cost_usd": 0.0474,
  "usage": {
    "input_tokens": 4,
    "cache_creation_input_tokens": 4870,
    "cache_read_input_tokens": 49816,
    "output_tokens": 214
  },
  "modelUsage": {
    "claude-sonnet-4-6": {
      "inputTokens": 4, "outputTokens": 214,
      "cacheReadInputTokens": 49816, "cacheCreationInputTokens": 4870,
      "costUSD": 0.0474
    },
    "claude-haiku-4-5-20251001": {
      "inputTokens": 563, "outputTokens": 13,
      "cacheReadInputTokens": 27082, "cacheCreationInputTokens": 0,
      "costUSD": 0.0002
    }
  }
}
```

`modelUsage` contains two entries: the **task model** (the ID passed to `--model`, e.g.
`claude-sonnet-4-6`) and an **orchestration model** (always `claude-haiku-4-5-20251001` with a
date suffix — the routing layer). The task model is looked up by the exact ID the adapter resolved
via `resolve-model.sh` and passed to `--model` at dispatch time.

### Parser: `adapters/claude-code/tools/parse-telemetry.sh`

Extracts per-dispatch telemetry. Always exits 0 — parse failures return `{"available":false,...}`,
never propagate as errors that would abort the calling pipeline.

```bash
# After a dispatch that captured stream-json to $STREAM_FILE:
TELEMETRY=$(bash adapters/claude-code/tools/parse-telemetry.sh \
    --model "$RESOLVED_MODEL" \
    --file  "$STREAM_FILE")
# → {"available":true,"model":"...","input":N,"output":N,"cache_read":N,"cache_write":N,"cost_usd":N.NN,"duration_ms":N}
```

**Identity strategy**: `--model` takes the same resolved ID the adapter passed to `claude -p`. This
is the direct key into `modelUsage` — no heuristic, no date-suffix stripping. Live-verified: passing
`--model claude-sonnet-4-6` → `modelUsage["claude-sonnet-4-6"]` present and correct.

### Display: `adapters/claude-code/references/telemetry-display.md`

Defines the per-phase UX and final summary format. Key points:

**Default per-phase** (appended to the `✓ concluído` block):
```
Usage
- model: <resolved-model>
- input: <N> tokens
- output: <N> tokens
- duration: <X.Xs>
- cost: $<N.NNNN>
```
Cache fields hidden by default. Cost is always the last field.

**Verbose per-phase** (when `sdd/PROJECT.md` contains `telemetry: { verbose: true }`):
```
Usage
- model: <resolved-model>
- input: <N> tokens
- output: <N> tokens
- cache read: <N> tokens
- cache write: <N> tokens
- duration: <X.Xs>
- cost: $<N.NNNN>
```

**Final summary** (at end of `/sdd.finish` and `/sdd.go`): per-phase table with columns
model/input/output/duration/cost; TOTAL block shows input/output/duration then `total cost` last
(separated by a rule). Cache columns and rows appear only in verbose mode.
See `references/telemetry-display.md` for exact format.

### Verbose mode

Configured via `sdd/PROJECT.md` — the existing project configuration mechanism, no new concept:

```yaml
telemetry:
  verbose: true   # add cache read/write to per-phase display and summary
```

Checked by a single `grep -qE '^\s+verbose:\s+true' sdd/PROJECT.md`. If absent or false: default
mode. In default mode, cache is hidden everywhere — per-phase and summary TOTAL.

### Resilience rules (live-enforced)

- Parse failure (`{"available":false}`) → show `Usage: unavailable`, proceed with the dispatch result
- A green dispatch with unavailable telemetry is still green; telemetry never gates SDD correctness
- Parser always exits 0; no error propagation into the SDD pipeline

## Known gaps

- **`claude` binary required for primary dispatch.** If the binary is not on PATH, the adapter falls back to Task()/Agent with the explicit degradation notice above. The binary is available at `/opt/node22/bin/claude` in this environment (v2.1.233, confirmed).
- **Effort is accepted but not independently verifiable for trivial tasks.** `--effort medium` is accepted by the CLI without error. Its effect on output quality is only observable for reasoning-heavy tasks (thinking tokens appear in `output_tokens_details.thinking_tokens`). For simple tasks, the flag is accepted but the output is the same.
- **Bash allowlist is project-specific.** `Bash(npm test)` vs `Bash(mvn *)` vs `Bash(gradle *)` depends on the project stack. The adapter documents the principle (specific patterns, not `Bash(*)`); the operator fills in the concrete commands from `PROJECT.md`.
- **ISOLATED_WORKSPACE git worktree.** Per-task git worktree isolation (via `--worktree` or equivalent) has not been confirmed as a flag on `claude -p`. The subprocess runs in the current working directory by default. Worktree isolation uses `EnterWorktree`/`ExitWorktree` tools in the parent session before the subprocess dispatch, not inside the subprocess itself.
