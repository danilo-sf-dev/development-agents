# Reference: Output Examples by Profile

**Used by**: `/sdd.finish`, whenever `PROFILE == TECHNICAL_ONLY` or `PROFILE == NON_TECHNICAL_ONLY` (from `development-agents/framework/user-profile.yaml`, set during `/sdd.start` Step 0).

The default/mixed profile output is already shown inline in `sdd.finish.md`. This file has the profile-specific variants.

---

## § Standard Mode Flow

### TECHNICAL_ONLY
Keep all technical detail (file paths, service names, config keys) exactly as the default flow shows it — this profile wants the full detail, so the inline default example already applies as-is. No simplification needed.

### NON_TECHNICAL_ONLY
Strip file paths, service/library names, and config keys. Describe outcomes, not implementation:

```
────────────────────────────────────────
📚 What We Learned
────────────────────────────────────────

While building this, we found a couple of things worth remembering for next time:
  • Data expiration settings need to line up with how long we keep event history
  • Some changes need to notify other parts of the system automatically

Want to save these lessons for future features? [Yes/No] → Yes

✅ Saved for next time.

Ready to wrap up this feature? [Yes/No] → Yes

Writing up what was built...
Filing this feature as done...
```

## § Completion Output

### TECHNICAL_ONLY
Same as the default inline example (backlog items resolved, spec references, file counts) — no changes needed for this profile.

### NON_TECHNICAL_ONLY

```
────────────────────────────────────────
📋 Related To-Dos Closed
────────────────────────────────────────

This work also took care of:
  • "Clean up how payments get double-checked" (from your backlog)

────────────────────────────────────────
🎉 Feature Complete: <feature-name>
────────────────────────────────────────

What shipped:
  • [1-2 sentence plain-language summary of what the feature does]

Everything checked out — tests passed, nothing looks broken, and the work is filed away.
```

## § Validation Examples

### TECHNICAL_ONLY (validation failure)

```
❌ Validation FAILED — cannot archive

Broken spec reference:
  sdd/wip/checkout-v2/2-technical/spec.md
  → references sdd/features/checkout-v1/functional-spec.md#refund-flow
  → section "#refund-flow" not found in target file

Fix: correct the anchor, or remove the reference if it's stale. Re-run /sdd.check --sync after fixing.
```

### NON_TECHNICAL_ONLY (validation failure)

```
⚠️ We found a loose end before we can close this out.

Something this feature depends on (from an earlier feature) seems to have moved or changed.
Someone technical will need to take a quick look before we can finish — want me to flag it for them?
```

## Choosing the Right Level of Detail

If `PROFILE` is unset or mixed (some team members technical, some not), default to the **TECHNICAL_ONLY** style — it's safer to over-inform than to hide details someone actually needed. Only switch to the NON_TECHNICAL_ONLY style when the profile was explicitly set that way in `user-profile.yaml`.
