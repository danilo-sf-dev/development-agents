# Reference: Project Validation

**Used by**: `/sdd.project` post-write checks.

## Validation

Before generating PROJECT.md, validate:

1. **Directory exists**: `sdd/` directory exists (create if not)
2. **No conflicts**: If PROJECT.md exists and not using `--edit`, ask for confirmation
3. **Values in range**: Coverage 0-100, PR lines > 0, etc.

---
