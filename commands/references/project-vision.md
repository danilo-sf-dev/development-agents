# Reference: Project Vision Management

**Used by**: `/sdd.project vision*`.

## Mode 6: Vision Management

When user runs `/sdd.project vision` (with or without flags):

### Subcommand Detection

```
IF args contains "vision":
    IF args contains "--edit":
        → Mode 6b: Edit Vision
    ELSE:
        → Mode 6a: Vision Wizard
```

---

### Mode 6a: Vision Wizard (`vision`)

Interactive 3-step wizard for defining product vision:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎯 Defining Product Vision
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Product vision helps ensure all features align with your product's purpose.
I'll ask 3 quick questions to define it.
```

**Step V1: Product Summary**

**⛔ INVOKE TOOL (do not print this, CALL the tool):**

```
AskUserQuestion(
  questions=[{
    "question": "What does your product do in one sentence? (e.g., 'A CLI tool that helps developers implement features using spec-driven development')",
    "header": "Summary",
    "options": [
      {"label": "Other", "description": "Enter product summary"}
    ],
    "multiSelect": false
  }]
)
```

**Step V2: Value Proposition**

**⛔ INVOKE TOOL (do not print this, CALL the tool):**

```
AskUserQuestion(
  questions=[{
    "question": "What problem does it solve and why should users care?",
    "header": "Value",
    "options": [
      {"label": "Other", "description": "Enter value proposition"}
    ],
    "multiSelect": false
  }]
)
```

**Step V3: Guiding Principles (Optional)**

**⛔ INVOKE TOOL (do not print this, CALL the tool):**

```
AskUserQuestion(
  questions=[{
    "question": "What 2-3 principles should guide all features? (Examples: 'Simplicity over features', 'User privacy first')",
    "header": "Principles",
    "options": [
      {"label": "Enter principles now", "description": "I'll provide 2-3 guiding principles"},
      {"label": "Skip for now", "description": "I can add principles later"}
    ],
    "multiSelect": false
  }]
)
```

**If user enters principles**: Ask for free text input.

**Step V4: Confirmation**

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 Vision Summary
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

**Summary**: [user's summary]
**Value Proposition**: [user's value proposition]
**Principles**: [user's principles or "Not defined"]

Save this vision to PROJECT.md?
```

**⛔ INVOKE TOOL (do not print this, CALL the tool):**

```
AskUserQuestion(
  questions=[{
    "question": "Save this vision to PROJECT.md?",
    "header": "Confirm",
    "options": [
      {"label": "Yes, save vision", "description": "Write to PROJECT.md"},
      {"label": "Edit before saving", "description": "Go back and modify"},
      {"label": "Cancel", "description": "Don't save vision"}
    ],
    "multiSelect": false
  }]
)
```

**On Confirmation**:
1. Read `sdd/PROJECT.md` (or create if doesn't exist)
2. Find or create `## Project Vision` section
3. Uncomment/populate the vision YAML block
4. Write updated file

**Success Output**:
```
✅ Vision saved to sdd/PROJECT.md

Your features will now be guided by:
• Summary: [summary]
• Value: [value proposition]
• Principles: [principles count] defined

Vision will be used during /sdd.spec to align features with product goals.
```

---

### Mode 6b: Edit Vision (`vision --edit`)

When editing existing vision:

1. Read current vision from PROJECT.md
2. Display current values
3. Use AskUserQuestion for each field with current value as default
4. Show diff of changes
5. Confirm and save

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✏️  Editing Product Vision
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Current vision:
• Summary: [current summary]
• Value: [current value proposition]
• Principles: [current principles]

Which field would you like to edit?
```

**⛔ INVOKE TOOL (do not print this, CALL the tool):**

```
AskUserQuestion(
  questions=[{
    "question": "Which field would you like to edit?",
    "header": "Edit Vision",
    "options": [
      {"label": "Summary", "description": "Edit product summary"},
      {"label": "Value proposition", "description": "Edit value proposition"},
      {"label": "Principles", "description": "Edit guiding principles"},
      {"label": "All fields", "description": "Re-run full wizard"},
      {"label": "Exit", "description": "Keep current vision"}
    ],
    "multiSelect": false
  }]
)
```

---

### Vision Section Format in PROJECT.md

```yaml
## Project Vision

vision:
  summary: "A CLI tool that helps developers implement features using spec-driven development"
  target_users: "Developers and technical leads at your team"
  value_proposition: "Reduces cognitive load by automating spec-to-code workflow while maintaining quality"
  principles:
    - "Simplicity over features"
    - "Convention over configuration"
    - "Fail fast, recover gracefully"
  anti_goals:
    - "Not a replacement for human code review"
    - "Not for non-technical users"
```

---
