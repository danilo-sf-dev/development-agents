# Reference: Project Profile Management

**Used by**: `/sdd.project profile*`.

## Mode 5: Profile Management

When user runs `/sdd.project profile` (with or without flags):

### Subcommand Detection

```
IF args contains "profile":
    IF args contains "--edit":
        → Mode 5b: Edit Profile Interactively
    ELSE:
        → Mode 5a: View Profile
```

---

### Mode 5a: View Profile (`profile`)

When user runs `/sdd.project profile`:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
👤 Current User Profile
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Profile: technical
Selected: 2026-01-29

Plan Mode Settings:
  ✅ Complex bug fixes (fix_complex_bugs)
  ✅ Technical spec in brownfield (spec_technical_brownfield)
  ❌ Complex build tasks (build_complex_tasks)
  ❌ Layer transitions (build_layer_transitions)
  ❌  test recovery (build_ci_test_recovery)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

To update: /sdd.project profile --edit
Config file: development-agents/framework/user-profile.yaml
```

**For non-technical profile**:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
👤 Current User Profile
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Profile: non-technical (Business/Product focus)
Selected: 2026-01-29

Behavior:
  • Express mode always active
  • Agent handles all technical decisions
  • Simplified output (no layers, project services, code snippets)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

To update: /sdd.project profile --edit
Config file: development-agents/framework/user-profile.yaml
```

**If no profile exists**:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
👤 No User Profile Found
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

You haven't selected a profile yet.
A profile will be created automatically during /sdd.start.

To create one now: /sdd.project profile --edit
```

---

### Mode 5b: Edit Profile (`profile --edit`)

Interactive profile update flow:

#### Step 1: Show Current Profile (if exists)

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✏️  Editing User Profile
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Current settings:
  Profile: technical
  Plan Mode: fix_complex_bugs, spec_technical_brownfield
```

#### Step 2: Profile Type Selection

Display behavior summary (same as /sdd.start Step 5.5):

```
┌─────────────────────────────────────────────────────────────────┐
│ BUSINESS/PRODUCT FOCUS                                          │
├─────────────────────────────────────────────────────────────────┤
│ • Focus on WHAT to build, agent handles HOW                     │
│ • Simplified output (no layers, project services, code snippets)        │
│ • Agent makes all technical decisions automatically             │
│ • Express mode always active (fastest flow)                     │
│ • Time estimates instead of complexity ratings                  │
│ • Questions in plain language                                   │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│ TECHNICAL FOCUS                                                 │
├─────────────────────────────────────────────────────────────────┤
│ • Full control over architecture decisions                      │
│ • See layers, project services, code snippets                      │
│ • Choose execution mode (express/standard/expert)               │
│ • Complexity ratings (Low/Medium/High)                          │
│ • Plan Mode for complex operations (configurable)               │
│ • Detailed error messages with stack traces                     │
└─────────────────────────────────────────────────────────────────┘
```

**⛔ INVOKE TOOL (do not print this, CALL the tool):**

```
AskUserQuestion(
  questions=[{
    "question": "Which profile matches how you want to work?",
    "header": "Profile",
    "options": [
      {"label": "Business/Product focus", "description": "Focus on WHAT to build. Agent handles technical decisions."},
      {"label": "Technical focus", "description": "Full control. See layers, project services, architecture details."}
    ],
    "multiSelect": false
  }]
)
```

#### Step 3: Plan Mode Settings (Technical Only)

If user selects "Technical focus", show Plan Mode configuration:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚙️ Plan Mode Preferences
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Plan Mode pauses before complex operations for your approval.
(Only available in Claude Code CLI)
```

**⛔ INVOKE TOOL (do not print this, CALL the tool):**

```
AskUserQuestion(
  questions=[{
    "question": "Enable Plan Mode for which scenarios?",
    "header": "Plan Mode",
    "options": [
      {"label": "Complex bug fixes (Recommended)", "description": "Pause before investigating DESIGN_FLAW or FEATURE_GAP errors"},
      {"label": "Technical spec in brownfield (Recommended)", "description": "Explore existing code before architecture decisions"},
      {"label": "Complex build tasks", "description": "Pause before high-complexity tasks or Layer 2"},
      {"label": "None", "description": "Never pause - implement directly"}
    ],
    "multiSelect": true
  }]
)
```

#### Step 4: Save and Confirm

Update `development-agents/framework/user-profile.yaml` with new settings.

**Success output**:
```
✅ Profile updated: technical

📋 Your settings:
   • Full technical detail in outputs
   • Plan Mode enabled for: complex bugs, brownfield specs
   • Execution mode: your choice per feature

Config file: development-agents/framework/user-profile.yaml
```

---

### Profile File Format

**Technical profile** (`development-agents/framework/user-profile.yaml`):

```yaml
# SDD Kit User Profile
# Generated: 2026-01-29T10:30:00Z
#
# To update these settings:
#   /sdd.project profile        → View current settings
#   /sdd.project profile --edit → Interactive update
#   Delete this file            → Re-select from scratch

profile: technical  # technical | non-technical

# Plan Mode settings (technical profile only)
# These control when the agent pauses for your approval
plan_mode:
  fix_complex_bugs: true           # DESIGN_FLAW, FEATURE_GAP errors
  spec_technical_brownfield: true  # Explore code before architecture
  build_complex_tasks: false       # High complexity, >5 files, Layer 2
  build_layer_transitions: false   # L1→L2, context >50%, 10+ tasks
  build_ci_test_recovery: false  # Ambiguous project CI test failures
```

**Non-technical profile**:

```yaml
# SDD Kit User Profile
# Generated: 2026-01-29T10:30:00Z
#
# To update these settings:
#   /sdd.project profile        → View current settings
#   /sdd.project profile --edit → Interactive update
#   Delete this file            → Re-select from scratch

profile: non-technical  # technical | non-technical

# Non-technical profile: Express mode always active
# Agent handles all technical decisions automatically
```

---
