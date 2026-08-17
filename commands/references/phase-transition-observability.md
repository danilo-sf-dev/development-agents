# Reference: Pipeline Phase Transition Observability

**Used by**: All `/sdd.*` commands (universal rule in `framework/_shared/agent-instructions.md`).

## Purpose

After each command completes its final step successfully, print a short transition block so the
user always knows where they are in the pipeline and what comes next.
Observability only — never blocking, never inside `AskUserQuestion`, never on error.

## Format

Print exactly these lines (no extra blank lines, no extra emoji):

```
✓ concluído: /sdd.<current>
▶ próxima fase: /sdd.<next>
Pipeline: START → SPEC → PLAN → TEST → BUILD → CHECK → FINISH
```

Use `[brackets]` around the **next** phase in the pipeline string.

## Per-command mapping

| Command completing | `<current>` | `<next>`  | Pipeline string (bracketed = next phase)                    |
| ------------------ | ----------- | --------- | ----------------------------------------------------------- |
| `/sdd.start`       | start       | spec      | `START → [SPEC] → PLAN → TEST → BUILD → CHECK → FINISH`    |
| `/sdd.spec`        | spec        | plan      | `START → SPEC → [PLAN] → TEST → BUILD → CHECK → FINISH`    |
| `/sdd.plan`        | plan        | test      | `START → SPEC → PLAN → [TEST] → BUILD → CHECK → FINISH`    |
| `/sdd.test`        | test        | build     | `START → SPEC → PLAN → TEST → [BUILD] → CHECK → FINISH`    |
| `/sdd.build`       | build       | check     | `START → SPEC → PLAN → TEST → BUILD → [CHECK] → FINISH`    |
| `/sdd.check`       | check       | finish    | `START → SPEC → PLAN → TEST → BUILD → CHECK → [FINISH]`    |

## `/sdd.finish` — pipeline complete

```
✓ concluído: /sdd.finish
Pipeline: START → SPEC → PLAN → TEST → BUILD → CHECK → FINISH ✓
```

No "próxima fase" line — pipeline is complete. The `AskUserQuestion` in `finish-next-steps.md`
surfaces what to do next (PR, new feature, etc.).

## `/sdd.go` — auto-advancing orchestrator

`/sdd.go` dispatches all phases without pausing. Before dispatching each phase, print one line:

```
▶ [N/7] /sdd.<phase> (Pipeline: START → ... → [PHASE] → ... → FINISH)
```

Example sequence:
```
▶ [1/7] /sdd.start  (Pipeline: [START] → SPEC → PLAN → TEST → BUILD → CHECK → FINISH)
▶ [2/7] /sdd.spec   (Pipeline: START → [SPEC] → PLAN → TEST → BUILD → CHECK → FINISH)
▶ [3/7] /sdd.plan   (Pipeline: START → SPEC → [PLAN] → TEST → BUILD → CHECK → FINISH)
▶ [4/7] /sdd.test   (Pipeline: START → SPEC → PLAN → [TEST] → BUILD → CHECK → FINISH)
▶ [5/7] /sdd.build  (Pipeline: START → SPEC → PLAN → TEST → [BUILD] → CHECK → FINISH)
▶ [6/7] /sdd.check  (Pipeline: START → SPEC → PLAN → TEST → BUILD → [CHECK] → FINISH)
▶ [7/7] /sdd.finish (Pipeline: START → SPEC → PLAN → TEST → BUILD → CHECK → [FINISH])
```

Then, when the full pipeline completes:
```
✓ concluído: /sdd.finish
Pipeline: START → SPEC → PLAN → TEST → BUILD → CHECK → FINISH ✓
```

Do NOT pause between phases for this logging — it is output only, never a gate.

## Rules

1. Print BEFORE any `AskUserQuestion` at command end.
2. Never block — command proceeds regardless.
3. Never print mid-command, on error, or when a gate blocks (command didn't complete successfully).
4. One block per command invocation — never repeat within the same run.
5. `[brackets]` mark the NEXT phase (not the current one) in all cases except `/sdd.go` where they mark the phase being dispatched NOW.
6. `/sdd.spec` internal sub-phases (functional → technical) do NOT trigger a pipeline line — only the full spec approval (both phases done) triggers the `spec → [PLAN]` line.

---

## Enforcement — `EMIT_PHASE_OBSERVABILITY` is an executable action, not a convention

**Root cause history — read before changing this section again.** Round 1 of this fix added the
"blocking, not optional" language below as a *textual* reminder, situated in every command file
instead of only in `agent-instructions.md`. A real Codex smoke test of `/sdd.reverse-eng` *after*
that fix landed showed it was still not enough: no Usage block, and not even the `unavailable`
fallback, printed for any phase — the run used Codex's native in-session subagent path, and
nothing forced the fallback text to be written once nothing was captured to report. More textual
reinforcement ("must", "blocking", "always") was explicitly ruled out as a next step, because it
is the same class of fix that had just failed. **`EMIT_PHASE_OBSERVABILITY` is therefore not a
"thing to remember to write" — it is a concrete script the command invokes as a real Bash step**,
`framework/tools/emit-phase-observability.sh` (§ "Helper mechanism" below). The unavailable
fallback is now produced by that script's own deterministic logic when nothing measurable was
handed to it — never by the LLM composing the fallback string from memory.

**Where it fires:**

- Every **single-phase command** (`/sdd.start`, `/sdd.spec`, `/sdd.plan`, `/sdd.test`,
  `/sdd.build`, `/sdd.check`, `/sdd.finish`) has exactly one closure point: its own final step.
  That command's own `## AI Agent Instructions` section carries an explicit line pointing at
  the concrete invocation below — not just the inherited pointer from `agent-instructions.md`.
- Every **multi-phase command** (`/sdd.reverse-eng`, `/sdd.go`) has one closure point per
  internal phase, plus one final `total` call. Each such command's own workflow section carries
  the same explicit, concrete invocation at each phase boundary and at the end of the run.

`EMIT_PHASE_OBSERVABILITY`, when it fires, always does both of the following, in order, for the
phase that just closed:

1. Print the transition block (§ Format, above) — still a direct print, no script involved;
   it carries no measurable data, there is nothing for a script to get wrong here.
2. Immediately after — no blank line — run `emit-phase-observability.sh phase ...`
   (§ "Helper mechanism") for that phase's own dispatch(es); its stdout **is** the Usage block.

There are exactly three outcomes for step 2, and the helper always produces one of them — never
a fourth outcome where the block is skipped, because the script always exits 0 and always prints
something:

1. A real, measurable child dispatch happened (`claude -p ... --output-format stream-json
   --verbose`, or Codex `codex exec --json`), its stream was captured to a file, and that file
   path was passed via `--stream-file` → the helper shells out to the existing parser → real
   Usage block.
2. The phase ran inline in the interactive session, **or** — Codex-specific — via the native
   in-session subagent fallback described in `adapters/codex/README.md` § `OFFLOAD_READ` — no
   captured child stream exists either way, so the command simply **omits** `--stream-file` →
   the helper deterministically prints `telemetry: unavailable (interactive session)`. Both
   cases collapse to the same text and the same code path inside the helper: from its point of
   view "no stream file was given" and "a native subagent produced nothing to capture" are the
   same input. The command's own markdown never has to distinguish them or compose the fallback
   text itself.
3. A `--stream-file` was given but the parser it invokes reports `available:false` for any
   reason (malformed stream, missing file, empty file) → same `unavailable` text as outcome 2;
   the phase's own result (green/red) is unaffected.

This section is the single definition of what `EMIT_PHASE_OBSERVABILITY` means. Command files
reference the concrete invocation below by pointing here; none of them re-describe the helper's
internals or hand-write the unavailable text.

---

## Helper mechanism — `framework/tools/emit-phase-observability.sh`

This is what a command file actually runs — a real Bash tool call, not prose. Full contract and
rationale in the script's own header; summarized here for command authors.

**Per phase**, immediately after a dispatch attempt (whether or not it produced a capturable
stream):

```bash
# Real, measurable child dispatch (stream captured to $STREAM_FILE):
bash framework/tools/emit-phase-observability.sh phase \
  --harness codex --model "$RESOLVED_MODEL" --effort "$RESOLVED_EFFORT" \
  --duration-ms "$DURATION_MS" --stream-file "$STREAM_FILE" \
  [--phase-label "Phase <N> — <name>"] [--state-file "$SDD_TELEMETRY_STATE"]

# Claude Code equivalent (no --effort, no --duration-ms — the parser reads duration from the
# stream itself):
bash framework/tools/emit-phase-observability.sh phase \
  --harness claude-code --model "$RESOLVED_MODEL" --stream-file "$STREAM_FILE" \
  [--phase-label "Phase <N> — <name>"] [--state-file "$SDD_TELEMETRY_STATE"]

# Inline work, or a native/in-session subagent with nothing to intercept — omit
# --stream-file entirely, do not try to pass an empty or fabricated path:
bash framework/tools/emit-phase-observability.sh phase \
  --harness <claude-code|codex> [--phase-label "Phase <N> — <name>"] \
  [--state-file "$SDD_TELEMETRY_STATE"]
```

`--phase-label` is omitted for single-phase commands (matches "Per-phase block" below).
`--state-file` is omitted for single-phase commands (no Total to build) and required for
`/sdd.reverse-eng`/`/sdd.go` — pick one path with `mktemp` once at the start of the run
(`SDD_TELEMETRY_STATE="$(mktemp)"`), reuse it for every phase call, pass it once more to `total`
at the end. This is local, disposable, per-run state — never versioned, never required to exist
ahead of time, never depends on any tool beyond bash.

**Once, at the end of a multi-phase command**, after all phases:

```bash
bash framework/tools/emit-phase-observability.sh total \
  --harness <claude-code|codex> --state-file "$SDD_TELEMETRY_STATE"
```

Its stdout **is** the `Usage Total` + `coverage: N/M measured phases` block (§ "Total / coverage"
below) — sums only records the helper itself marked available, in the fixed field order, never
a cost line for Codex.

The helper never reimplements token extraction — it shells out to the existing, already-tested
`adapters/claude-code/tools/parse-telemetry.sh` / `adapters/codex/tools/parse-telemetry.sh` and
only reads their small, fixed-shape JSON output. Real execution tests (fixtures, not markdown
grep): `framework/tools/emit-phase-observability.test.sh`.

---

## Usage / Telemetry block (mandatory alongside the transition block)

**This is the single wiring point for telemetry in the whole pipeline.** No command file
reimplements this — `framework/_shared/agent-instructions.md` § "Pipeline Transition
Observability" points here for both the transition block above and this Usage block; a command
file that prints its own ad-hoc Usage format instead of following this section is a bug.

Immediately after the transition block (no blank line between them), append a Usage block for
the dispatch(es) that just ran. Source of truth per harness — never estimated, never scraped:

- **Claude Code**: `adapters/claude-code/tools/parse-telemetry.sh` reading a captured
  `claude -p ... --output-format stream-json --verbose` stream. Full mechanics:
  `adapters/claude-code/references/telemetry-display.md`.
- **Codex**: `adapters/codex/tools/parse-telemetry.sh` reading a captured `codex exec ... --json`
  stream. Full mechanics: `adapters/codex/references/telemetry-display.md`. `--json` is mandatory
  on the dispatch for this to work at all — see `adapters/codex/README.md` § Telemetry.
- Other harnesses: no parser exists yet — treat every phase as `unavailable` (§ "Inline /
  unavailable" below), same rule as a harness with no captured stream.

### Field order (mandatory, identical for both harnesses)

```
model
input
cached input      (only if the parser reported it)
output
reasoning         (only if the parser reported it)
duration
cost              (Claude Code only, only if the parser reported it — ALWAYS last)
```

Codex **never** shows a `cost` line, under any circumstance — Codex runs under a subscription,
not per-token billing, and this pipeline never invents a dollar figure from token counts. This
is the one field-order difference between the two harnesses; everything else is identical.

### Per-phase block, when a real dispatch was captured

```
Phase <N> — <name>

Usage
model: <resolved model>
input: <N>
cached input: <N>       ← omit the line entirely if the parser didn't report it
output: <N>
reasoning: <N>           ← omit the line entirely if the parser didn't report it
duration: <X.Xs>
cost: $<N.NNNN>          ← Claude Code only, only if reported, always last
```

For single-phase commands (`/sdd.start`, `/sdd.spec`, `/sdd.plan`, `/sdd.build`, `/sdd.check`,
`/sdd.finish` — one command-level dispatch each, per each command's own Model Routing section),
omit the `Phase <N> — <name>` header — the Usage block stands alone, immediately after the
`✓ concluído` / `▶ próxima fase` lines. Multi-phase commands (`/sdd.go`, `/sdd.reverse-eng`) use
the header per internal phase — see each command's own telemetry section for its phase breakdown.

### Inline / unavailable — never omit silently

If the work just completed ran inline (no child process was dispatched — the interactive session
itself did the work, or a fallback mechanism produced no captured stream — e.g. Codex's native
in-session subagent path, see `adapters/codex/README.md` § OFFLOAD_READ), there is no real usage
data. Show this instead of the full block, and **never** just omit the Usage section entirely:

```
Usage
telemetry: unavailable (interactive session)
```

No token estimate, no context-window-delta calculation, no `/status`/UI scraping — ever, for any
harness. If a parser call fails for any other reason (malformed stream, missing file), same rule
applies: `telemetry: unavailable`, and the phase's own result is unaffected — a green phase with
unavailable telemetry is still green.

### Total / coverage — multi-phase commands only (`/sdd.go`, `/sdd.reverse-eng`)

At the end of the command, after all phases:

```
Usage Total
input: <sum of available phases>
cached input: <sum of available phases>   ← omit if no phase reported it
output: <sum of available phases>
reasoning: <sum of available phases>      ← omit if no phase reported it
duration: <sum of available phases>
cost: $<sum>                              ← Claude Code only, only if any phase reported it, last
coverage: <N>/<M> measured phases
```

- Sum **only** phases whose telemetry was `available` — an `unavailable` phase contributes
  nothing to the sum and is not silently treated as zero.
- `coverage: N/M` is mandatory whenever `M > 1` (multi-phase commands) — it is what prevents the
  Total from being misread as "the whole session's usage." `N` = phases with real data, `M` =
  total phases attempted (measurable + inline combined).
- Never mix an estimate into a sum with real data. Never round a coverage gap away.
- Single-phase commands don't need a "Total" section — their one Usage block **is** the total;
  no `coverage` line needed there (it would always read `1/1` or `0/1`, which is not
  informative enough to justify the extra line for a single dispatch).
