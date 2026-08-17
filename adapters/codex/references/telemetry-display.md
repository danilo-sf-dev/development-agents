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

## Per-phase display and Final summary — format authority moved (corrected this round)

**`commands/references/phase-transition-observability.md` § "Usage / Telemetry block" and §
"Total / coverage" are the single, exclusive format authority for both the per-phase Usage block
and the end-of-run Total.** This file previously specified its own, different bullet-list format
here (an `effort` field the canonical format doesn't have, a one-line `Usage: unavailable`
fallback instead of the canonical two-line `Usage` / `telemetry: unavailable (interactive
session)`, and a `SDD USAGE SUMMARY (Codex)` block format instead of the canonical `Usage Total`)
— a real, silent divergence from the shared spec that went unnoticed until this round's audit.
Do not follow the old format from memory or from any cached copy of this file; the sections below
were removed for exactly this reason.

What stays specific to Codex, and is not restated in the canonical file:

- The `--effort` value is Codex-only context (Claude Code has no equivalent CLI flag); when
  showing the per-phase Usage block, this adapter's dispatch code MAY still surface it, but only
  as an annotation on the `model:` line (e.g. `model: gpt-5.6-sol (effort: high)`), never as a
  separate field that shifts the canonical field order.
- **No cost row or dollar amount, ever** — not per-phase, not in the Total. This is already
  stated in the canonical file's "Field order" section, restated here because it is the one rule
  most likely to be violated by copying a Claude Code example.
- Verbose mode (`telemetry.verbose: true` in `sdd/PROJECT.md`) adds `cache write` to the fields
  the canonical format already shows conditionally — see "Verbose mode" above for the detection
  script; the field itself follows the canonical block's placement (immediately after `cached
  input`).

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

If a phase's parser output is `{"available":false,...}` — or the phase ran inline / via the
native in-session subagent fallback with no captured stream at all — that phase's Usage block is
the canonical `Usage` / `telemetry: unavailable (interactive session)` two-line form (§ "Per-phase
display and Final summary" above), and it contributes nothing to the `Usage Total` sum. This is
the same "excluded, not zero" rule the canonical file states under "Total / coverage" — not a
separate Codex-specific rule.

### `/sdd.finish` summary scope

`/sdd.finish` is a single-phase command in the canonical mapping — its one Usage block **is**
its total; no separate Total/coverage section (canonical rule: single-phase commands don't need
one). `/sdd.go` and `/sdd.reverse-eng` are the multi-phase commands that print a `Usage Total`
with `coverage: N/M`, per the canonical file.

---

## Resilience rules

These are mandatory — a telemetry problem must never become a pipeline problem:

1. **Never block on telemetry**: `{"available":false}` → show `telemetry: unavailable
   (interactive session)` (canonical text, § "Per-phase display and Final summary" above),
   continue
2. **Never invent values**: no token estimation, no pricing-table cost derivation
3. **Never propagate exit codes**: the parser always exits 0; never treat parse failure as dispatch failure
4. **SDD result is independent**: green dispatch + unavailable telemetry = still green
5. **Never show cost**: not for Codex, not as a derived value, not under any option
