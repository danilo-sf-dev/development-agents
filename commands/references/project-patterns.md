# Reference: Project Patterns Management

**Used by**: `/sdd.project patterns*`.

## Mode 4: Patterns Management

When user runs `/sdd.project patterns` (with any subcommand):

### Subcommand Detection

```
IF args contains "patterns":
    IF args contains "--add":
        → Mode 4a: Add Pattern Wizard
    ELSE IF args contains "--edit":
        → Mode 4b: Direct Edit
    ELSE IF args matches "patterns "<description>"":
        → Mode 4c: Prompt Inference
    ELSE:
        → Mode 4d: View Patterns
```

---

### Mode 4a: Add Pattern Wizard (`patterns --add`)

Interactive 4-step wizard for adding a new pattern:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
➕ Adding New Pattern to PATTERNS.md
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Step 1/4: Category
```

**Step 1: Category Selection**

**⛔ INVOKE TOOL (do not print this, CALL the tool):**

```
AskUserQuestion(
  questions=[{
    "question": "Which category does this pattern belong to?",
    "header": "Category",
    "options": [
      {"label": "Go", "description": "Go language patterns with "},
      {"label": "Java", "description": "Java/Kotlin patterns with "},
      {"label": "Node.js", "description": "Node/TypeScript patterns"},
      {"label": "Database Patterns", "description": "DB, KeyValueStore, SQL patterns"},
      {"label": "Other", "description": "Custom category (will prompt for name)"}
    ],
    "multiSelect": false
  }]
)
```

> **Note**: If user selects "Other", prompt for custom category name.

**Step 2: Pattern Name**

**⛔ INVOKE TOOL (do not print this, CALL the tool):**

```
AskUserQuestion(
  questions=[{
    "question": "What should this pattern be called? (e.g., 'HTTP Client Usage', 'Prefer axios')",
    "header": "Name",
    "options": [
      {"label": "Other", "description": "Enter pattern name"}
    ],
    "multiSelect": false
  }]
)
```

**Step 3: Pattern Content**

Display guidance then request content:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Step 3/4: Pattern Content
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Describe the pattern. Include:
• What to DO
• What NOT to do
• Why (rationale)
• Example (optional)
```

**⛔ INVOKE TOOL (do not print this, CALL the tool):**

```
AskUserQuestion(
  questions=[{
    "question": "Describe the pattern. Include what to DO, what NOT to do, why (rationale), and optionally an example.",
    "header": "Content",
    "options": [
      {"label": "Other", "description": "Enter pattern content"}
    ],
    "multiSelect": false
  }]
)
```

**Step 4: Confirmation**

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Step 4/4: Confirmation
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Preview:

**[Pattern Name]**:
- [What to do]
- [What not to do]
- Why: [Rationale]
- Added: YYYY-MM-DD via /sdd.project patterns
```

**⛔ INVOKE TOOL (do not print this, CALL the tool):**

```
AskUserQuestion(
  questions=[{
    "question": "Add this pattern to PATTERNS.md?",
    "header": "Confirm",
    "options": [
      {"label": "Yes, add pattern", "description": "Append to Team Conventions section"},
      {"label": "Edit before adding", "description": "Go back and modify"},
      {"label": "Cancel", "description": "Don't add pattern"}
    ],
    "multiSelect": false
  }]
)
```

**On Confirmation**:
1. Read `sdd/PATTERNS.md` (or create from template if doesn't exist)
2. Format pattern as markdown
3. Append to "Team Conventions (Manually Added)" section
4. Add timestamp: `- Added: YYYY-MM-DD via /sdd.project patterns`
5. Write updated file

**Success Output**:
```
✅ Pattern added to sdd/PATTERNS.md

Added to "Team Conventions (Manually Added)":
   • [Pattern Name]

Total patterns: N from team conventions, M from feature learnings
```

---

### Mode 4b: Direct Edit (`patterns --edit`)

Opens PATTERNS.md for direct editing:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✏️  Editing PATTERNS.md
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Opening sdd/PATTERNS.md...
```

**Actions**:
1. If file doesn't exist, create from `development-agents/framework/templates/PATTERNS.md`
2. Read current content and display structure summary
3. Open file for editing (use Read tool to show content, user edits via IDE)
4. Validate format after edit

---

### Mode 4c: Prompt Inference (`patterns "<description>"`)

When user provides a description:

```
/sdd.project patterns "en nuestro equipo usamos axios para HTTP,
date-fns para fechas (moment.js prohibido), y siempre repository pattern"
```

**Inference Process**:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔍 Analyzing description...
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Patterns detected:

| # | Category     | Pattern              | Type        |
|---|--------------|----------------------|-------------|
| 1 | HTTP/API     | Use axios            | Preferred   |
| 2 | Utilities    | Use date-fns         | Preferred   |
| 3 | Utilities    | Forbidden: moment.js | Forbidden   |
| 4 | Architecture | Repository pattern   | Convention  |
```

**Pattern Detection Rules**:

| Text Pattern | Detected Pattern |
|--------------|------------------|
| "usar X", "use X", "siempre X" | Preferred: X |
| "prohibido X", "forbidden X", "never X", "no usar X" | Forbidden: X |
| "X pattern", "pattern X" | Architecture convention: X |
| "X en vez de Y", "X instead of Y" | Preferred: X, Forbidden: Y |

**Confirmation**:

**⛔ INVOKE TOOL (do not print this, CALL the tool):**

```
AskUserQuestion(
  questions=[{
    "question": "What would you like to do with these N patterns?",
    "header": "Action",
    "options": [
      {"label": "Add all N patterns", "description": "Append all to Team Conventions"},
      {"label": "Review individually", "description": "Confirm each pattern"},
      {"label": "Cancel", "description": "Don't add patterns"}
    ],
    "multiSelect": false
  }]
)
```

**On "Add all"**: Append all patterns to PATTERNS.md with timestamps.

---

### Mode 4d: View Patterns (`patterns`)

When user runs `/sdd.project patterns` without flags:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 Current Project Patterns
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Location: sdd/PATTERNS.md

| Category              | Count | Last Updated |
|-----------------------|-------|--------------|
| Team Conventions      | 3     | 2026-01-29   |
| Go    | 4     | 2026-01-20   |
| Database Patterns     | 2     | 2026-01-15   |

Total: 9 patterns
```

**⛔ INVOKE TOOL (do not print this, CALL the tool):**

```
AskUserQuestion(
  questions=[{
    "question": "What would you like to do?",
    "header": "Action",
    "options": [
      {"label": "Add new pattern", "description": "Interactive wizard"},
      {"label": "Edit patterns", "description": "Open PATTERNS.md for editing"},
      {"label": "Exit", "description": "Close patterns view"}
    ],
    "multiSelect": false
  }]
)
```

**If file doesn't exist**:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 No PATTERNS.md found
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

sdd/PATTERNS.md doesn't exist yet.

Create it now?
```

**⛔ INVOKE TOOL (do not print this, CALL the tool):**

```
AskUserQuestion(
  questions=[{
    "question": "Create PATTERNS.md now?",
    "header": "Create",
    "options": [
      {"label": "Create and add pattern", "description": "Create file and start wizard"},
      {"label": "Create empty", "description": "Create file from template"},
      {"label": "Cancel", "description": "Don't create file"}
    ],
    "multiSelect": false
  }]
)
```

---

### Pattern Format Validation

Before writing to PATTERNS.md, validate:

1. **Category exists**: Pattern must be under a valid section header (`## Category Name`)
2. **Name format**: Pattern name must be bold (`**Name**:`)
3. **Content present**: At least one line of content
4. **No duplicates**: Check if pattern with same name already exists

**If duplicate detected**:
```
⚠️ Pattern "[Name]" already exists in PATTERNS.md

What would you like to do?
1. Update existing pattern
2. Add as new (with suffix)
3. Cancel
```

---

### PATTERNS.md Update Rules

**Section order**:
1. Header + purpose
2. "Team Conventions (Manually Added)" - patterns from `/sdd.project patterns`
3. Technology sections (Go, Java, etc.) - patterns from `/sdd.finish`
4. Last Updated section

**Adding to "Team Conventions"**:
```markdown
## Team Conventions (Manually Added)

**[Pattern Name]**:
- [What to do]
- [What not to do]
- Why: [Rationale]
- Added: YYYY-MM-DD via /sdd.project patterns
```

**Compatibility with /sdd.finish**:
- `/sdd.finish` adds patterns to technology-specific sections
- `/sdd.project patterns` adds to "Team Conventions" section
- Both coexist without conflict

---
