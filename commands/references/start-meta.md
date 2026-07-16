# Reference: Start meta.md Creation

**Used by**: `/sdd.start` Step 8.

### Step 8: Create meta.md

Use template from `development-agents/framework/templates/meta.md` with:
- Feature name, date prefix, ID
- Project mode (greenfield/brownfield)
- Execution mode (express/standard)
- Framework version
- Project type and testing config
- **Spec language**: Read `language.specs` from `sdd/PROJECT.md` and set `spec_language` field in meta.md

```bash
# Read spec language from PROJECT.md (fallback to en)
spec_lang=$(grep "specs:" sdd/PROJECT.md 2>/dev/null | head -1 | awk '{print $2}')
if [ -z "$spec_lang" ]; then spec_lang="en"; fi
# Write to meta.md spec_language field
```

**Conditional**: Delete "Brownfield Context" section if greenfield.
