# Reference: Claude Code Telemetry Display Protocol

**Adapter**: Claude Code only. Cursor, Codex, and Antigravity adapters have their own telemetry
contract — do not extend this reference beyond Claude Code.

**Used by**: the interactive session (orchestrator) after every `claude -p` subprocess dispatch.

---

## Source of data

Every `claude -p ... --output-format stream-json --verbose` call produces a final JSON result
line (`"type":"result"`) containing `modelUsage`, `duration_ms`, and `total_cost_usd`. This is
the **only** data source for telemetry. Do not estimate tokens, re-tokenize prompts, or invent
costs from pricing tables.

Parsing is handled by `adapters/claude-code/tools/parse-telemetry.sh`. Always pass the
**resolved model ID** (the value returned by `resolve-model.sh`, which was also passed as
`--model` to the `claude -p` call) as `--model`. The parser uses this as the direct key into
`modelUsage` — no heuristic, no date-suffix stripping.

```bash
# Typical call pattern after capturing subprocess stream-json to a file:
TELEMETRY=$(bash adapters/claude-code/tools/parse-telemetry.sh \
    --model "$RESOLVED_MODEL" \
    --file  "$STREAM_JSON_FILE")
```

`TELEMETRY` is always valid JSON: either `{"available":true,...}` or `{"available":false,...}`.

---

## Verbose mode

Check `sdd/PROJECT.md` (project root) for:

```yaml
telemetry:
  verbose: true
```

If this key is present and set to `true`, enable verbose mode for per-phase display.
If the file doesn't exist, the key is absent, or the value is anything other than `true`,
default mode applies. Checking is a simple line scan — no YAML parser required:

```bash
VERBOSE=false
if grep -qE '^\s+verbose:\s+true' "sdd/PROJECT.md" 2>/dev/null; then
    VERBOSE=true
fi
```

---

## Per-phase display (after every successful dispatch)

Print the phase completion block defined in
`commands/references/phase-transition-observability.md`, then immediately append the Usage block.
The two blocks are one contiguous output — no extra blank line between them.

### Default mode

```
✓ concluído: /sdd.<phase>
▶ próxima fase: /sdd.<next>

Usage
- model: <model>
- input: <N> tokens
- output: <N> tokens
- duration: <X.Xs>
- cost: $<N.NNNN>
```

### Verbose mode (telemetry.verbose: true in sdd/PROJECT.md)

```
✓ concluído: /sdd.<phase>
▶ próxima fase: /sdd.<next>

Usage
- model: <model>
- input: <N> tokens
- output: <N> tokens
- cache read: <N> tokens
- cache write: <N> tokens
- duration: <X.Xs>
- cost: $<N.NNNN>
```

### Telemetry unavailable

If the parser returns `{"available":false,...}`, show a single degraded line instead of the
full usage block. **Never fail the phase** — the underlying dispatch result is valid even if
telemetry parsing failed:

```
✓ concluído: /sdd.<phase>
▶ próxima fase: /sdd.<next>

Usage: unavailable
```

Do NOT show the reason string to the user unless debugging — it is diagnostic, not actionable.

### Formatting rules

- `cost`: always 4 decimal places, `$0.0474` (not `$0.047400`)
- `duration`: one decimal place in seconds, `7.3s` (convert from `duration_ms / 1000`)
- `input` / `output` / `cache read` / `cache write`: plain integer, no thousands separator
- `/sdd.finish` uses `Pipeline: START → SPEC → PLAN → TEST → BUILD → CHECK → FINISH ✓` with no
  "próxima fase" line (see `phase-transition-observability.md`) — the Usage block still appears
  immediately after

---

## Final summary

Show after `/sdd.finish` completes and after `/sdd.go` completes. Collect the telemetry from
every `claude -p` dispatch during that session run. Cache fields always appear in the summary
regardless of verbose mode (they are relevant to real cost).

**Default mode:**

```
SDD USAGE SUMMARY
─────────────────────────────────────────────────────────────────
  Phase       Model                    Input    Output   Duration       Cost
  ──────────  ───────────────────────  ───────  ───────  ─────────  ──────────
  /sdd.spec   claude-sonnet-4-6            4       214      7.3s    $0.0474
  /sdd.build  claude-haiku-4-5            18       419      7.9s    $0.0152
  /sdd.finish claude-sonnet-4-6            4       193      9.8s    $0.0485

  TOTAL
  - input:    26 tokens
  - output:   826 tokens
  - duration: 25.0s
  ──────────────────
  - total cost: $0.1111
─────────────────────────────────────────────────────────────────
```

**Verbose mode** (adds cache columns to the table and cache rows to TOTAL):

```
SDD USAGE SUMMARY
─────────────────────────────────────────────────────────────────────────────────────────────
  Phase       Model                    Input    Output   Cache Read   Cache Write  Duration       Cost
  ──────────  ───────────────────────  ───────  ───────  ──────────   ───────────  ─────────  ──────────
  /sdd.spec   claude-sonnet-4-6            4       214      49,816       4,870       7.3s    $0.0474
  /sdd.build  claude-haiku-4-5            18       419      53,145       3,898       7.9s    $0.0152
  /sdd.finish claude-sonnet-4-6            4       193      52,323       4,988       9.8s    $0.0485

  TOTAL
  - input:       26 tokens
  - output:      826 tokens
  - cache read:  155,284 tokens
  - cache write: 13,756 tokens
  - duration:    25.0s
  ──────────────────────────
  - total cost:  $0.1111
─────────────────────────────────────────────────────────────────────────────────────────────
```

### Aggregation rules

- For each phase row: use the telemetry from that phase's `parse-telemetry.sh` output
- `TOTAL input`: sum of all phase `input` values
- `TOTAL output`: sum of all phase `output` values
- `TOTAL cache read`: sum of all phase `cache_read` values (verbose only)
- `TOTAL cache write`: sum of all phase `cache_write` values (verbose only)
- `TOTAL duration`: sum of all phase `duration_ms` values, converted to seconds
- `total cost`: sum of all phase `cost_usd` values, formatted to 4 decimal places — always last

Cache values use thousands separators (e.g. `155,284`). Token values in per-phase rows do not.

### Phases with unavailable telemetry

If a phase's telemetry is `{"available":false,...}`, that phase appears in the summary as:

```
  /sdd.test   (telemetry unavailable)
```

That phase's tokens and cost are excluded from TOTAL — no estimation, no substitution.
Clearly note below the table if any phase was excluded:

```
  (!) /sdd.test excluded from TOTAL — telemetry was unavailable for that dispatch.
```

### Which dispatches count as phases

Each top-level `claude -p` dispatch from the adapter counts as one phase row. Sub-dispatches
inside a single phase (e.g. the validator sub-step inside `/sdd.build`) appear as separate rows
labeled `/sdd.build (validator)`.

### `/sdd.finish` summary scope

`/sdd.finish` shows the summary of its own session's dispatches (validation, code review, and
any other delegated sub-steps that phase ran). It does not aggregate the entire pipeline from
`/sdd.start` to `/sdd.finish` — that scope is `/sdd.go`'s summary.

---

## Resilience rules

These are mandatory — violating them turns a telemetry problem into a feature problem:

1. **Never block on telemetry**: if `parse-telemetry.sh` returns unavailable, proceed anyway
2. **Never invent values**: no estimation, no approximation, no "calculated from prompt length"
3. **Never propagate exit codes**: the parser always exits 0; the calling session should not
   treat a telemetry parse failure as a dispatch failure
4. **SDD result is independent**: a green dispatch with unavailable telemetry is still green;
   a red dispatch with available telemetry is still red
