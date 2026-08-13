# Reference: Model Routing Observability (informational only, never blocking)

**Used by**: any `/sdd.*` command that wants to surface which Model Role/model it's running under.

> Canonical policy: [`framework/_shared/model-routing.md`](../../framework/_shared/model-routing.md).
> Concrete values: [`config/model-routing.yaml`](../../config/model-routing.yaml), resolved via
> [`framework/tools/resolve-model.sh`](../../framework/tools/resolve-model.sh). Automatic dispatch
> mechanism per harness: `adapters/<harness>/README.md` § Model Routing.

## What changed here

This reference used to define a "model advisory" apparatus with a mandatory full-box display and
**BLOCKING** `AskUserQuestion` gates at command entry and at `start→spec`/`test→build`/`build→finish`
transitions, asking the operator to confirm or manually switch models before continuing. That
apparatus existed because model selection used to be a manual, operator-driven step.

**It no longer is.** Model Routing now resolves and dispatches automatically on every supported
harness (Claude Code, Cursor, Codex — see each adapter's README; `generic` is the one harness where
it's still a recommendation, not automation). Asking the operator to confirm a model the framework
already resolved and is about to execute automatically has no purpose — worse, it reintroduces a
manual step the whole point of Model Routing was to remove. **All model-confirm gates are removed.**
This file is now purely an optional observability line — informing, never asking, never blocking.

> **This is not a Gate.** Gate 1 (spec approval), Gate 2 (plan approval), Gate 2.5 (tests-first
> approval), and Gate 3 (finish approval) are unaffected by this change — they are methodological
> approvals of *what was produced*, not confirmations of *which model produced it*, and none of them
> were ever about model selection to begin with. Do not conflate the two.

## The one thing this reference still does

At command entry (and, optionally, once at the start of `/sdd.go`), print **one line**, no more:

```
ℹ️ Model Routing: <model_role> → <resolved model> (auto)
```

Example shape: `ℹ️ Model Routing: STRONG → <resolved model> (auto)`. The resolved model comes from whatever
the currently-installed harness's dispatch mechanism already used to execute this command — this
line reports what happened, it does not ask the operator to do anything about it. If the harness's
resolution mechanism doesn't expose the concrete model name back to the calling context for some
reason, it's fine to print just the role: `ℹ️ Model Routing: STRONG (auto)`.

**Rules for this line**:

- Never wrapped in `AskUserQuestion`.
- Never blocks — the command proceeds immediately regardless of whether anyone reads it.
- Shown at most once per command invocation (not once per internal Skill dispatch — that would be
  noisy; the top-level command's own role is what's informative to a human).
- Optional to show at all — a harness/installation may suppress it entirely (e.g. via a project
  preference) without that being a Model Routing regression, since suppressing an informational line
  changes nothing about whether the routing itself ran.
- Never contains language implying a choice ("would you like to switch", "confirm", "select a
  model") — that would resurrect exactly the manual step this file removed.

## Escalation/de-escalation observability (optional, same rules)

If a Skill escalates mid-task (`EXECUTION` → `STRONG`, per `model-routing.md` § Escalation) or
de-escalates back, the same one-line, non-blocking format applies if shown at all:

```
ℹ️ Model Routing: escalating EXECUTION → STRONG (ambiguity in approved task — see model-routing.md)
ℹ️ Model Routing: de-escalating STRONG → EXECUTION (hard decision resolved, resuming mechanical work)
```

Still purely informational. The escalation itself already happened by the time this prints — it does
not ask permission.

## What was removed, for anyone looking for the old sections

- The `BARATO`/`FORTE`/`EXTREMO` tier table and `haiku`/`sonnet`/`opus` alias table — replaced by
  `STRONG`/`EXECUTION` roles resolved via `config/model-routing.yaml` (see `model-routing.md`).
- The "full box" `MODEL ADVISORY` display and its per-`phase_key` catalog — removed. It existed to
  make a manual switch legible before asking the operator to perform it; there is no manual switch to
  make legible anymore.
- **`entry:start` BLOCKING entry model-confirm** (`Step 0: Model Confirm` in `sdd.start.md`) —
  removed. `/sdd.start` now just runs at its resolved `EXECUTION` role automatically.
- **`start→spec`, `test→build`, `build→finish` critical-switch BLOCKING model-confirm** — removed.
  These transitions still exist as phase boundaries with their own methodological next-steps
  `AskUserQuestion` (unaffected — see each command file), just without a second, model-specific
  confirmation stacked on top.
- The Express compact map's "Express pula pausas intermediárias" framing — no longer relevant,
  since Standard mode no longer has model-confirm pauses to skip either; Express and Standard now
  differ only in *methodological* pause count (spec interview depth, next-steps confirmations), not
  in model-confirmation count (zero in both).

If a future need arises to reintroduce a *methodological* (not model-selection) confirmation at a
phase boundary, that belongs in the relevant command's own gate logic, not in this file.
