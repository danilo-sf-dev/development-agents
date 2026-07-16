# Reference: `/sdd.fix` Dangerous Flags

**Used by**: `/sdd.fix --code-only` or `/sdd.fix --layer <N>`.

## Warning

**`--code-only` and `--layer` flags can cause spec drift:**

| Flag | What Happens | Risk |
|------|--------------|------|
| `--code-only` | Only updates code, skips all specs | Specs become outdated, future features built on wrong assumptions |
| `--layer technical` | Only updates technical spec | Functional spec and tasks become inconsistent |

## When are these flags "safe"?

- **Almost never.** If your fix changes behavior, specs should be updated.
- The ONLY safe use case: pure implementation bug with no spec impact (e.g., fix a typo in variable name)

**If you're tempted to use these flags**, ask yourself:
1. Does this fix add ANY new behavior? → If yes, don't use these flags
2. Does this fix change ANY API response? → If yes, don't use these flags
3. Does this fix affect ANY user-visible output? → If yes, don't use these flags

**Consequences of misuse:**
- `/sdd.check --sync` will later detect inconsistencies
- Future developers will be confused by undocumented behavior
- Tests may fail when specs are eventually updated
