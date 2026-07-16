# Reference: /sdd.doctor Output Examples

**Used by**: `/sdd.doctor` Step 3 (Render) and Step 5 (`--explain`).

The default report layout and JSON shape are already shown inline in `sdd.doctor.md`. This file adds the variants not shown there.

---

## Clean Run (no issues)

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🩺 sdd.doctor — Kit Health Check
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Project: payments-api
Always-on footprint: 312 lines  ✓ (target: <400)
Issues: 0

✅ No contradictions, duplication, or context-waste detected in always-on config.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## --explain Output

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔎 Explaining [SEM-1]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Your file (CLAUDE.md:18):
  "Always write exhaustive, complete specs covering every edge case
   in full detail, no matter how long."

Conflicts with (framework/standards/elegance-principle.md#target-size):
  "Target size: 2-3 pages per feature. Prefer covering the common
   path thoroughly over cataloguing every conceivable edge case."

Axis: contradicts
Reasoning: Your directive optimizes for exhaustiveness; the kit's specs
are designed around a 2-3 page budget so agents don't drown in edge
cases before reaching the common path. Following your directive as
written will push every generated spec well past the kit's target
size and dilute focus on the primary flow.

Recipe: Remove the "no matter how long" clause, or scope the directive
to a specific artifact type where exhaustiveness is actually wanted
(e.g. a compliance checklist), rather than applying it to all specs.

If you disagree with this finding, it's safe to ignore — semantic
findings are advisory, not enforced.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## --apply Summary (all issues resolved)

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Applied: 3 fixes (O1, O2, K2)
Skipped: 0
Not auto-fixable: 0

✅ All fixable issues resolved. Re-run /sdd.doctor to confirm.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
