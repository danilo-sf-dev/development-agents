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
