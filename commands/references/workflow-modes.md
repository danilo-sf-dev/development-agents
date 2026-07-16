# Reference: Workflow Mode Definitions (Backlog → Feature)

**Used by**: `/sdd.backlog`, when converting a `DEBT` or `TODO` item into a feature (not applicable to `IDEA` items, which always go through the normal `/sdd.start` → `/sdd.spec` flow).

---

## The Three Modes

| Mode | `workflow_mode` value | What gets auto-generated | When to use |
|------|------------------------|---------------------------|-------------|
| **Full** | `full` | Nothing — functional spec written interactively like any new feature | The DEBT/TODO description is too thin to auto-draft a spec from (needs real discovery/interview) |
| **Technical-only** | `technical-only` | Functional spec auto-drafted from the backlog item's description; technical spec still written interactively | The problem is well understood from the backlog description, but the *how* needs architectural thought |
| **Tasks-only** | `tasks-only` | Both functional and technical specs auto-drafted; only tasks/plan is written interactively | The fix is well-scoped and low-risk (e.g. a known refactor, a documented tech-debt item with a clear approach already implied by the backlog entry) |

## Mode Selection Logic

```
IF backlog item has < 2 sentences of context AND no affected_files listed:
    → mode = full (not enough to auto-draft anything reliably)
ELIF backlog item has clear problem statement + affected files, but no proposed solution:
    → mode = technical-only
ELIF backlog item has problem statement + affected files + an explicit proposed approach:
    → mode = tasks-only
```

Always let the user override the suggested mode via `AskUserQuestion` — this heuristic is a starting suggestion, not a hard rule.

## Processing Rules

1. **Auto-generated content must be marked as such** in `meta.md` (`auto_generated.functional: true`, etc.) so `/sdd.spec` and `/sdd.plan` know to treat it as a draft needing review, not an already-approved artifact.
2. **Auto-generated specs still go through the normal approval gate** — `tasks-only` mode does NOT mean "skip spec approval," it means "the draft was pre-filled, approval still required before `/sdd.test`/`/sdd.build`."
3. **If auto-generation produces a spec that's clearly wrong or too thin**, fall back to the next-more-manual mode rather than forcing a bad draft through — e.g. `tasks-only` degrading to `technical-only` if the auto-drafted technical spec doesn't hold together.
