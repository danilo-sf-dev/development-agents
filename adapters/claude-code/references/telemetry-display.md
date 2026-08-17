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

## Per-phase display and Final summary — format authority moved (corrected this round)

**`commands/references/phase-transition-observability.md` § "Usage / Telemetry block" and §
"Total / coverage" are the single, exclusive format authority for both the per-phase Usage block
and the end-of-run Total — for every harness, Claude Code included.** This file previously
specified its own, different bullet-list format here (`- model: <model>` instead of the canonical
`model: <model>`, a one-line `Usage: unavailable` fallback instead of the canonical two-line
`Usage` / `telemetry: unavailable (interactive session)`, cache fields gated behind a `verbose`
flag the canonical field-order rule doesn't mention, and a `SDD USAGE SUMMARY` table format
instead of the canonical `Usage Total` block) — a real, silent divergence from the shared spec
that went unnoticed until this round's audit. Do not follow the old format from memory or from
any cached copy of this file; the sections below were removed for exactly this reason.

Executing `EMIT_PHASE_OBSERVABILITY` — the canonical file's § "Enforcement" — at every phase
closure (this adapter's contribution: capturing `claude -p ... --output-format stream-json
--verbose` and parsing it) is what makes the Usage block actually print. This reference
describing the data source is necessary but not sufficient; the calling command's own explicit,
situated instruction is what fires it — see each `commands/sdd.*.md` file's own
`EMIT_PHASE_OBSERVABILITY` line.

What stays specific to Claude Code, and is not restated in the canonical file:

- `cost`, when reported, is always 4 decimal places (`$0.0474`, not `$0.047400`) and always the
  last field — the canonical file already states "last field," this adds the decimal-formatting
  detail.
- `duration` is one decimal place in seconds (`7.3s`), converted from `duration_ms / 1000`.
- Verbose mode (`telemetry.verbose: true` in `sdd/PROJECT.md`, § "Verbose mode" above) is an
  opt-in **display density** choice — cache read/write are part of the canonical block whenever
  the parser reports them (canonical rule: "only if the parser reported it," no verbose gate);
  what verbose mode actually changes is whether the *Final summary table* (below) grows cache
  columns, not whether a single phase's Usage block shows cache fields.

---

## Total / coverage

Governed entirely by the canonical file's § "Total / coverage" — the `Usage Total` block, summing
only phases whose telemetry was `available`, with `coverage: N/M measured phases` mandatory for
`/sdd.go` (M=7) and `/sdd.reverse-eng` (M up to 4 conceptual phases, per that command's own
telemetry section). `/sdd.finish` is single-phase in the canonical mapping — its one Usage block
is its own total; no separate Total/coverage section there.

### Which dispatches count as phases

Each top-level `claude -p` dispatch from the adapter counts as one phase row. Sub-dispatches
inside a single phase (e.g. the validator sub-step inside `/sdd.build`) appear as separate rows
labeled `/sdd.build (validator)` — this determines what `M` counts in `coverage: N/M`, it does
not change the canonical Total block's field format.

---

## Resilience rules

These are mandatory — violating them turns a telemetry problem into a feature problem:

1. **Never block on telemetry**: if `parse-telemetry.sh` returns unavailable — or no `claude -p`
   subprocess was dispatched at all (inline work in the interactive session) — show the canonical
   `telemetry: unavailable (interactive session)` text and proceed anyway; never fall back to a
   different unavailable string.
2. **Never invent values**: no estimation, no approximation, no "calculated from prompt length"
3. **Never propagate exit codes**: the parser always exits 0; the calling session should not
   treat a telemetry parse failure as a dispatch failure
4. **SDD result is independent**: a green dispatch with unavailable telemetry is still green;
   a red dispatch with available telemetry is still red
5. **Printing is not automatic**: this file describes what data exists and how it's formatted;
   the calling command's own explicit `EMIT_PHASE_OBSERVABILITY` instruction (per
   `commands/references/phase-transition-observability.md` § "Enforcement") is what actually
   triggers the print at each phase closure — do not assume this reference being read once is
   enough.
