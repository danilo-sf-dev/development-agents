# Reference: Load PATTERNS.md at Start

**Used by**: `/sdd.start` Step 10.

### Step 10: Load PATTERNS.md

If `sdd/PATTERNS.md` exists, load accumulated wisdom from previous features.

**Display pattern summary with origins**:

```
📋 Project Patterns Loaded:
   • N from feature learnings (auto-promoted via /sdd.finish)
   • M from team conventions (manually added via /sdd.project patterns)
   Total: X patterns influencing this feature
```

**Pattern counting algorithm**:

```bash
# Count patterns in "Team Conventions (Manually Added)" section
manual_count=$(grep -c "^\*\*.*\*\*:" sdd/PATTERNS.md | head -1)

# Count patterns in other sections (technology sections from /sdd.finish)
# Sections: Go, Database Patterns, MessageQueue, Testing, etc.
auto_count=$(grep -c "^\*\*.*\*\*:" sdd/PATTERNS.md)
auto_count=$((auto_count - manual_count))

total=$((manual_count + auto_count))
```

**If no PATTERNS.md exists**: Skip this output (no patterns to load).

**Example output**:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 Project Patterns Loaded
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

   • 3 from team conventions (manual)
   • 6 from feature learnings (auto)
   Total: 9 patterns influencing this feature

   Tip: Add more conventions with /sdd.project patterns --add
```
