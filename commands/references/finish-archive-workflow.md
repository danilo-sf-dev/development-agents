# Reference: Finish Archival Workflow

**Used by**: `/sdd.finish` archive + PATTERNS promotion details.

### Archival Workflow (CRITICAL ORDER)

> **⚠️ WARNING**: The order of operations is CRITICAL. Generating files AFTER cleanup causes orphan files.

**CORRECT ORDER** (strictly follow this sequence):

```
Step 0: Clean up transient files (NOT archived)
        │
        └── rm -rf sdd/wip/[feature]/verdicts/  (quality gate verdicts)
        │
Step 1: Generate ALL documentation INSIDE wip/
        │
        ├── README.md
        ├── implementation-summary.md
        └── VALIDATION_REPORT.md (if validation ran)
        │
Step 2: Verify ALL files exist in wip/[feature]/
        │
        ├── ls -la sdd/wip/[feature]/
        └── Confirm: meta.md, specs, tasks, documentation
        │
Step 3: Move ENTIRE directory (NOT contents)
        │
        └── mv sdd/wip/[feature] sdd/features/[feature]
        │
        ⚠️ This moves the DIRECTORY ITSELF, not its contents.
        ⚠️ DO NOT use: mv sdd/wip/[feature]/* (globs can miss files!)
        │
Step 4: Verify archive completeness
        │
        └── ls -la sdd/features/[feature]/ (confirm all files present)
```

**⛔ NEVER DO THIS** (causes orphan files):
```
❌ WRONG: mv sdd/wip/[feature]/* ... (glob misses subdirs/dotfiles)
❌ WRONG: rm -rf sdd/wip/[feature]/ before verifying move
❌ WRONG: Generate files after move operation
❌ WRONG: Use separate mv commands for * and .*
```

**✅ CORRECT MOVE COMMAND** (single atomic operation):
```bash
# Move the entire directory - NOT its contents
mv sdd/wip/[feature] sdd/features/[feature]

# This is atomic and moves EVERYTHING including:
# - All files (meta.md, tasks.json, specs, etc.)
# - All subdirectories (1-functional/, 2-technical/, etc.)
# - All hidden files (.gitkeep, etc.)
```

**Verification Checklist** (run AFTER move):
```bash
FEATURE="[feature-name]"

# Verify source is GONE (not just empty - GONE)
if [ -d "sdd/wip/$FEATURE" ]; then
    echo "❌ CRITICAL: sdd/wip/$FEATURE still exists!"
    echo "   Files remaining:"
    ls -la "sdd/wip/$FEATURE"
    echo "   DO NOT proceed - investigate why move failed"
    exit 1
fi

# Verify destination has required files
FILES_REQUIRED=("meta.md" "README.md")
for file in "${FILES_REQUIRED[@]}"; do
    if [ ! -f "sdd/features/$FEATURE/$file" ]; then
        echo "❌ MISSING in archive: $file"
        exit 1
    fi
done

echo "✅ Archive complete - wip/ cleaned, features/ populated"
```

**Why `mv directory` instead of `mv directory/*`?**
- `mv dir/*` uses shell glob expansion which can fail with:
  - Subdirectories (1-functional/, 2-technical/, etc.)
  - Hidden files (dotfiles)
  - Special characters in filenames
  - Too many files (argument list too long)
- `mv dir` is atomic and moves EVERYTHING

---

### Promote Learnings to PATTERNS.md

> **PURPOSE**: Extract generalizable learnings so future features benefit.
> **NOTE**: Patterns can also be added manually via `/sdd.project patterns --add`.
> Auto-promotion adds to technology sections. Manual patterns go to "Team Conventions".

**After validations pass, BEFORE archiving**:

1. **Read** `sdd/wip/[feature]/4-implementation/progress.md`
2. **Extract** learnings from "Learnings per Task" section
3. **Filter** for generalizable patterns (see criteria below)
4. **Check for duplicates** (see deduplication below)
5. **Show** extracted patterns to user (excluding duplicates)
6. **Ask**: "Promote these to sdd/PATTERNS.md?" via AskUserQuestion
7. **If Y**: Append to `sdd/PATTERNS.md` with date stamp

**Promotion criteria** (must meet ALL):
- ✅ Applies to multiple features (not feature-specific)
- ✅ Non-obvious (not in official project/vendor docs)
- ✅ Saves significant time (avoids repeating mistakes)

### Duplicate Detection

**Before promoting each pattern**:

1. Read existing `sdd/PATTERNS.md`
2. For each extracted pattern:
   a. Check if similar pattern exists (fuzzy match on name/content)
   b. **Fuzzy match criteria**:
      - Same pattern name (case-insensitive)
      - Content similarity > 70% (key terms match)
      - Same "do/don't" directives
3. If duplicate found: Skip with note "Already in PATTERNS.md (from [section])"
4. If new: Include in promotion list

**Deduplication Output**:

```
Found 5 learnings in progress.md:

| # | Learning | Status |
|---|----------|--------|
| 1 | KeyValueStore explicit TTL | ✅ New (will promote) |
| 2 | Use project-go-toolkit | ⏭️ Already exists (Team Conventions) |
| 3 | MessageQueue manual ACK | ⏭️ Already exists (MessageQueue & Messaging) |
| 4 | Context propagation | ✅ New (will promote) |
| 5 | Check N+1 queries | ✅ New (will promote) |

Promoting 3 new patterns (2 skipped as duplicates).
```

**Merge with existing patterns** (when similar but not identical):

If a pattern is similar but adds new information:
- Show both versions to user
- Ask: "Merge new content into existing pattern?"
- If Y: Update existing pattern with combined content
- If N: Skip (don't add duplicate)

**Example extraction**:
```markdown
From progress.md "Learnings per Task":

  TASK-003: Configure KeyValueStore
  Patterns discovered:
  - KeyValueStore requires explicit TTL, default is 24h
  - Use project-go-toolkit for HTTP, not raw net/http

  Gotchas:
  - Don't use context.Background(), pass request context

→ These are GENERALIZABLE (apply to any Go + KeyValueStore feature)
```

**Promote to PATTERNS.md**:
```markdown
## Go

**KeyValueStore Usage**:
- ✅ Always set explicit TTL when writing to KeyValueStore
- ❌ Don't rely on default TTL (24h)
- Example: `client.Set(key, value, 3600)  // 1 hour TTL`

**Context Propagation**:
- ✅ Always pass request context through function calls
- ❌ Never use `context.Background()` in request handlers
- Why: Loses tracing, request ID, cancellation

**Last Updated**:
- 2026-01-13: Added KeyValueStore patterns from feature-payments
```

**DO NOT promote**:
- ❌ Feature-specific details ("Endpoint /users returns 200")
- ❌ Temporary workarounds
- ❌ Info already in existing project docs

**If no PATTERNS.md exists**: Create it using template from `development-agents/framework/templates/PATTERNS.md`

**If user says No**: Skip promotion, proceed to archiving

---
