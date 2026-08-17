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
