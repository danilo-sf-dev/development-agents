# Reference: Codex CLI Telemetry Display Protocol

**Adapter**: Codex CLI only. Claude Code, Cursor, and Antigravity adapters have their own
telemetry contracts — do not extend this reference beyond Codex.

**Used by**: the interactive parent session (orchestrator) after every `codex exec --json`
child dispatch.

---

## Source of data

Every `codex exec --json` call produces a JSONL stream. The `type:"turn.completed"` event
carries the `usage` object with token counts. This is the **only** data source for telemetry.
Do not estimate tokens, re-tokenize prompts, or derive cost from subscription pricing.

Parsing is handled by `adapters/codex/tools/parse-telemetry.sh`. Always pass:
- `--model`: the ID returned by `resolve-model.sh codex <ROLE>` (same value passed to `--model` in the `codex exec` call)
- `--effort`: the effort level from `resolve-model.sh` (same value passed via `-c model_reasoning_effort=...`)
- `--duration-ms`: wall-clock milliseconds measured by the caller around the `codex exec` call. The Codex CLI does not emit duration in its JSONL output; measure externally:
  ```bash
  T0=$(date +%s%3N)
  codex exec --json --model "$MODEL" -c "model_reasoning_effort=\"$EFFORT\"" "$TASK" > "$STREAM_FILE"
  DURATION_MS=$(( $(date +%s%3N) - T0 ))
  ```

```bash
TELEMETRY=$(bash adapters/codex/tools/parse-telemetry.sh \
    --model       "$RESOLVED_MODEL" \
    --effort      "$RESOLVED_EFFORT" \
    --duration-ms "$DURATION_MS" \
    --file        "$STREAM_FILE")
```

`TELEMETRY` is always valid JSON: either `{"available":true,...}` or `{"available":false,...}`.

**No cost field is ever emitted.** Codex CLI runs under a ChatGPT Plus subscription.
There is no per-call dollar amount to report; do not invent one.

---

## Verbose mode

Check `sdd/PROJECT.md` (project root) for:

```yaml
telemetry:
  verbose: true
```

If present and `true`, enable verbose mode (adds `cache write` to the per-phase display).
Checking is a simple line scan — no YAML parser required:

```bash
VERBOSE=false
if grep -qE '^\s+verbose:\s+true' "sdd/PROJECT.md" 2>/dev/null; then
    VERBOSE=true
fi
```

---

## Per-phase display (after every successful dispatch)

Print the phase completion block, then immediately append the Usage block.

### Default mode

```
✓ concluído: /sdd.<phase>
▶ próxima fase: /sdd.<next>

Usage
- model: gpt-5.6-sol
- effort: high
- input: 26,549
- cached input: 22,272
- output: 1,590
- reasoning: 413
- duration: 18.4s
```

### Verbose mode (`telemetry.verbose: true`)

Adds `cache write` between `cached input` and `output`:

```
✓ concluído: /sdd.<phase>
▶ próxima fase: /sdd.<next>

Usage
- model: gpt-5.6-sol
- effort: high
- input: 26,549
- cached input: 22,272
- cache write: 4,100
- output: 1,590
- reasoning: 413
- duration: 18.4s
```

### Telemetry unavailable

If the parser returns `{"available":false,...}`, show a single degraded line.
Never fail the phase — the underlying dispatch result is valid even if telemetry failed:

```
✓ concluído: /sdd.<phase>
▶ próxima fase: /sdd.<next>

Usage: unavailable
```

Do NOT show the `reason` string to the user; it is diagnostic, not actionable.

### Field ordering and presence rules

Fields appear in this fixed order; a field is **omitted entirely** if not present in the
parser output (the parser omits a field when the Codex CLI did not provide it in `usage`):

```
model       — always present
effort      — always present (from --effort arg)
input       — always present
cached input — present when parser output contains "cached_input"
cache write  — present only in verbose mode AND parser output contains "cache_write"
output      — always present
reasoning   — present when parser output contains "reasoning"
duration    — present when parser output contains "duration_ms"
```

**Never show `cost` or any dollar amount.** No exceptions.

### Formatting rules

- `input`, `output`, `cached input`, `cache write`, `reasoning`: integer with thousands
  separator — `26,549` not `26549`
- `duration`: one decimal place in seconds — `18.4s` (convert `duration_ms / 1000`)
- `/sdd.finish` has no "próxima fase" line; the Usage block still appears immediately after

---

## Final summary

Show after `/sdd.finish` completes and after `/sdd.go` completes. Collect the parser output
from every `codex exec --json` dispatch during the session run.

The summary uses a **block-per-phase format** (not a table). This accommodates the variable
set of optional fields (reasoning, cached input) without producing ragged table columns.

### Format

```
SDD USAGE SUMMARY (Codex)
─────────────────────────────────────────────────────────────
  /sdd.spec
  - model:        gpt-5.6-sol
  - effort:       high
  - input:        26,549
  - cached input: 22,272
  - output:       1,590
  - reasoning:    413
  - duration:     18.4s

  /sdd.plan
  - model:        gpt-5.6-sol
  - effort:       high
  - input:        14,102
  - cached input: 11,780
  - output:       834
  - duration:     9.2s

  /sdd.build
  - model:        gpt-5.6-luna
  - effort:       xhigh
  - input:        38,441
  - cached input: 34,200
  - output:       2,218
  - reasoning:    891
  - duration:     31.7s

  ──────────────────────────────────────────────────
  TOTAL
  - input:        79,092
  - cached input: 68,252
  - output:       4,642
  - reasoning:    1,304
  - duration:     59.3s
  - total tokens: 83,734
─────────────────────────────────────────────────────────────
```

**Verbose mode** adds `cache write` after `cached input` in every phase block and in TOTAL.

### Aggregation rules

- Per-phase values come from that phase's `parse-telemetry.sh` output
- `TOTAL input`: sum of all phase `input` values
- `TOTAL cached input`: sum of all phase `cached_input` values (omit row if no phase has it)
- `TOTAL cache write`: sum of all phase `cache_write` values (verbose mode only; omit row if no phase has it)
- `TOTAL output`: sum of all phase `output` values
- `TOTAL reasoning`: sum of all phase `reasoning` values (omit row if no phase has it)
- `TOTAL duration`: sum of all phase `duration_ms` values, converted to seconds (1 decimal)
- `TOTAL total tokens`: `TOTAL input` + `TOTAL output`
- **No cost row** — ever

### Counting semantics

`codex exec --json` is a **single-turn** invocation: one prompt → one `turn.completed` event
per call. The parser always takes the last `turn.completed` in the stream (in case of resume
flows). For this benchmark, prefer **independent `codex exec` calls per phase** rather than
resume, so each phase's token count is unambiguous and not cumulative across the session.

If a resume flow is used and it produces multiple `turn.completed` events in a single JSONL
stream, the parser takes only the last one (assumed to represent that turn's usage, not the
session cumulative). This assumption is documented but NOT independently verified against
a live Codex CLI session — validate before relying on aggregated resume-based counts.

### Phases with unavailable telemetry

If a phase's parser output is `{"available":false,...}`, show:

```
  /sdd.test
  (telemetry unavailable)
```

Exclude that phase's tokens from TOTAL. Note below the summary:

```
  (!) /sdd.test excluded from TOTAL — telemetry was unavailable for that dispatch.
```

### `/sdd.finish` summary scope

`/sdd.finish` shows telemetry from its own dispatches only. `/sdd.go` shows the full
pipeline summary.

---

## Resilience rules

These are mandatory — a telemetry problem must never become a pipeline problem:

1. **Never block on telemetry**: `{"available":false}` → show `Usage: unavailable`, continue
2. **Never invent values**: no token estimation, no pricing-table cost derivation
3. **Never propagate exit codes**: the parser always exits 0; never treat parse failure as dispatch failure
4. **SDD result is independent**: green dispatch + unavailable telemetry = still green
5. **Never show cost**: not for Codex, not as a derived value, not under any option
