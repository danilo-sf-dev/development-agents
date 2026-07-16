# Reference: Start Feature Structure Creation

**Used by**: `/sdd.start` Step 7.

### Step 7: Create Feature Structure

**Validate name uniqueness** (BLOCKING):
```bash
# Check no other feature has the same name (regardless of date prefix)
existing=$(ls -1 sdd/wip sdd/features sdd/cancelled 2>/dev/null | sed 's/^[0-9]*-//' | sed 's/_[0-9]*$//' | grep -x "$feature_name" | head -1)
if [ -n "$existing" ]; then
    # Find the full directory name for context
    full_match=$(ls -1 sdd/wip sdd/features sdd/cancelled 2>/dev/null | grep -- "-${feature_name}\$" | head -1)
    echo "❌ Feature name '${feature_name}' already exists: ${full_match}"
fi
```

**On collision**: Do NOT stop and ask the user. Instead:
1. Derive a more specific name from the original user description (e.g., `auth` → `oauth-login`, `payment` → `payment-retry-mechanism`)
2. If the description is too vague to differentiate, append a qualifier: `{name}-v2`, `{name}-refactor`, `{name}-migration`
3. Show the user the alternative name and proceed: `⚠️ Name 'auth' already in use (20250601-auth). Using 'oauth-login' instead.`
4. If unable to derive a meaningful alternative, ask the user with AskUserQuestion

**Generate date prefix**:
```bash
feature_date=$(date +%Y%m%d)
feature_folder="${feature_date}-${feature_name}"
```

> **CRITICAL — folder naming format**: The folder name MUST be `YYYYMMDD-feature-name` (e.g., `20260326-user-auth`).
> Do NOT use sequential numbers like `001-`, `002-`, `003-` even if existing folders in `sdd/wip/` or `sdd/features/` use that format.
> Those are legacy folders from an older version. New features ALWAYS use the date prefix from `date +%Y%m%d`.

**Date Prefix Rules**:
- Date prefix is **organizational only** (for chronological ordering) — it is NOT an identifier
- Features are identified by **name** (e.g., `user-auth`) or **full name** (e.g., `20260325-user-auth`)
- Feature names are **globally unique** across `wip/`, `features/`, and `cancelled/`
- Date prefix **never changes** when feature moves from `wip/` to `features/`

**Create folders**:
```bash
mkdir -p "sdd/wip/$feature_folder"/{1-functional,2-technical,3-tasks,4-implementation/artifacts}
```
