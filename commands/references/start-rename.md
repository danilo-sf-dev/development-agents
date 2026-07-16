# Reference: `/sdd.start --rename`

**Used by**: `/sdd.start --rename [new-name]`.

> **PURPOSE**: Rename a feature after it has been created.

### Usage

```bash
/sdd.start --rename [new-name]
```

### What it does

1. **Validates new name** is kebab-case (lowercase, hyphens only)
2. **Renames folder** `sdd/wip/[old-name]/` → `sdd/wip/[new-name]/`
3. **Updates meta.md** with new feature name
4. **Updates tasks.json** references (if exists)

### Example

```bash
# Current feature: user-authentication
/sdd.start --rename oauth-login

# Result:
# ✓ Renamed: sdd/wip/20260320-user-authentication/ → sdd/wip/20260320-oauth-login/
# ✓ Updated: meta.md feature_name
# ✓ Updated: tasks.json references (if applicable)
```

### Restrictions

| Restriction | Reason |
|-------------|--------|
| Cannot rename if tasks in_progress | Avoid breaking active implementation |
| New name must be unique | Cannot conflict with existing features in `wip/` |
| Must be kebab-case | Framework naming convention |

### AI Agent Instructions for --rename

**WHEN** user runs `/sdd.start --rename [new-name]`:

1. **Find current feature** in `sdd/wip/`
2. **Validate new name**:
   - Is kebab-case? (lowercase, hyphens, 3-50 chars)
   - Is unique? (doesn't exist in `wip/`)
3. **Check for active tasks**:
   - Read `tasks.json` if exists
   - If any task has `status: "in_progress"` → BLOCK with message
4. **Perform rename**:
   ```bash
   old_path="sdd/wip/XXX-old-name"
   new_path="sdd/wip/XXX-new-name"
   mv "$old_path" "$new_path"
   ```
5. **Update meta.md**:
   - Change `feature_name:` field
6. **Update tasks.json** (if exists):
   - Update any references to old feature name
7. **Output success message**:
   ```
   ✓ Feature renamed: old-name → new-name
     📁 Location: sdd/wip/XXX-new-name/
   ```
