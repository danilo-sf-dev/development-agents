# Reference: `/sdd.reverse-eng --focus`

**Used by**: `/sdd.reverse-eng --focus <component>` (optionally with `--audio` for voice input of the focus scope).

## Critical rule

**`--focus` ALWAYS updates base spec files.** It NEVER creates `-{component}.md` suffixed files.

| Scenario | Files Updated |
|----------|---------------|
| Fresh repo + `--focus ComponentA` | Creates `functional-spec.md`, `technical-spec.md` |
| Existing specs + `--focus ComponentB` | Updates existing `functional-spec.md`, `technical-spec.md` |
| Re-run with same `--focus` | Updates same files (UPDATE MODE) |
| Re-run with different `--focus` | Enriches same files with new component detail |

## What `--focus` does

1. Extracts deep detail about the specified component
2. **Merges** that detail into existing specs (or creates if none exist)
3. Marks sections as `[Focused: ComponentName]` for traceability

## What `--focus` does NOT do

- Create `functional-spec-{component}.md` files
- Create parallel spec versions
- Delete existing content from other components

## UPDATE MODE + `--focus`

When `sdd/extracted/` exists and `--focus` is used: **enrich** existing specs with focused component detail (do not create parallel files).

## Anti-pattern: no `-UPDATED` suffixes

```
❌ WRONG: functional-spec-UPDATED.md alongside original
✅ CORRECT: replace functional-spec.md directly
```

Update Mode MUST:
1. Show diff summary of changes
2. Ask for confirmation if >20% changes detected
3. **REPLACE files directly** — no suffixes, no side-by-side versions
4. Update both `sdd/extracted/` AND `sdd/specs/`
