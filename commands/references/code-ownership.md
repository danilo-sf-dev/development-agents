# Reference: Code Ownership Analysis

**Used by**: `/sdd.reverse-eng` Phase 4.5, when mode is `FULL` or `ENHANCE` (skipped for `UPDATE` — ownership rarely shifts on incremental re-runs).

---

## Purpose

Map which parts of the codebase are "owned" (in the sense of who last touched them / who'd be the natural reviewer) so that generated specs and PATTERNS.md can note ownership context, and so future `/sdd.fix` cross-feature-impact checks have something to point to.

## Analysis Steps

1. **Git blame/log aggregation** — for each top-level module/package, find the most frequent committers over the last N commits (or last 6-12 months, whichever the repo history supports):
   ```bash
   git log --format='%an' -- <path> | sort | uniq -c | sort -rn | head -3
   ```
2. **Map to modules, not files** — ownership at file granularity is too noisy; aggregate to the module/package/directory level that matches the codebase's own structure (e.g. `src/payments/`, not every file inside it).
3. **Flag orphaned modules** — code with no clear owner (very old, single ancient commit, or committer no longer active) should be flagged in DETECTION_REPORT.md as a risk area — future features touching it may need extra care/testing since there's no natural reviewer.
4. **Cross-check against any existing CODEOWNERS file** — if the repo already has one (GitHub/GitLab `CODEOWNERS`), reconcile with it rather than inventing a parallel scheme; note discrepancies instead of silently overriding.

## Output Format (added to DETECTION_REPORT.md)

```markdown
## Code Ownership Map

| Module | Primary contributor(s) | Last significant change | Notes |
|--------|------------------------|--------------------------|-------|
| src/payments/ | alice, bob | 2026-03 | Active |
| src/legacy-reports/ | (none active) | 2023-11 | Orphaned — extra care needed |
```

## What NOT to Do

- Don't treat commit count as a proxy for "understanding" — someone with one large well-reviewed commit may understand a module better than someone with many small drive-by commits.
- Don't surface individual names outside of this internal report if the project has privacy/anonymity conventions — check `PROJECT.md` first.
