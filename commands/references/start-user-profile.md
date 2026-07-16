# Reference: User Profile Selection

**Used by**: `/sdd.start` Step 5.5.

### Step 5.5: User Profile Selection

> **PURPOSE**: Determine technical vs non-technical profile ONCE and persist for future sessions.
> **CRITICAL**: Non-technical profile triggers EXPRESS MODE automatically.

**Check for existing profile (hierarchy)**:

```bash
# 1. Check global user preference (persistent across all projects)
profile_file="$HOMEdevelopment-agents/framework/user-profile.yaml"
if [ -f "$profile_file" ]; then
    profile=$(grep "^profile:" "$profile_file" | cut -d: -f2 | tr -d ' ')
    if [ -n "$profile" ]; then
        echo "✓ Using saved profile: $profile"
        # Skip asking, use existing
    fi
fi

# 2. If no global profile, check PROJECT.md defaults
# 3. If still no profile, ask user
```

#### First-time Profile Selection (if no existing profile)

**BEFORE ASKING**, display this behavior summary:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
👤 User Profile Configuration
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Your profile determines how much technical detail you see.

┌─────────────────────────────────────────────────────────────────┐
│ BUSINESS/PRODUCT FOCUS                                          │
├─────────────────────────────────────────────────────────────────┤
│ • Focus on WHAT to build, agent handles HOW                     │
│ • Simplified output (no layers, project services, code snippets)        │
│ • Agent makes all technical decisions automatically             │
│ • Express mode always active (fastest flow)                     │
│ • Simplified effort labels instead of complexity ratings        │
│ • Questions in plain language                                   │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│ TECHNICAL FOCUS                                                 │
├─────────────────────────────────────────────────────────────────┤
│ • Full control over architecture decisions                      │
│ • See layers, project services, code snippets                      │
│ • Choose execution mode (express/standard)                      │
│ • Complexity ratings (Low/Medium/High)                          │
│ • Plan Mode for complex operations (configurable)               │
│ • Detailed error messages with stack traces                     │
└─────────────────────────────────────────────────────────────────┘
```

**⛔ INVOKE TOOL (do not print this, CALL the tool)**:

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

#### Step 5.5.1: Plan Mode Preferences (Technical Profile Only)

> **SKIP IF**: User selected "Business/Product focus" (non-technical)

If user selects "Technical focus", show Plan Mode configuration:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚙️ Plan Mode Preferences
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Plan Mode pauses before complex operations for your approval.
(Only available in Claude Code CLI)
```

**⛔ INVOKE TOOL (do not print this, CALL the tool)**:

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

> **Default behavior**: If user selects "None", all plan_mode options set to false.
> If user doesn't select "None", selected options are enabled.

#### Step 5.5.2: Store Profile with Plan Mode Settings

**Store profile persistently**:

```bash
# Create development-agents/framework/user-profile.yaml
mkdir -p "$HOME/.sdd-kit"

if [ "$selected_profile" = "technical" ]; then
    # Technical profile with plan_mode settings
    cat > "$HOMEdevelopment-agents/framework/user-profile.yaml" << EOF
# SDD Kit User Profile
# Generated: $(date -Iseconds)
#
# To update these settings:
#   /sdd.project profile        → View current settings
#   /sdd.project profile --edit → Interactive update
#   Delete this file            → Re-select from scratch

profile: technical  # technical | non-technical

# Plan Mode settings (technical profile only)
# These control when the agent pauses for your approval
plan_mode:
  fix_complex_bugs: $fix_complex_bugs           # DESIGN_FLAW, FEATURE_GAP errors
  spec_technical_brownfield: $spec_brownfield   # Explore code before architecture
  build_complex_tasks: $build_complex           # High complexity, >5 files, Layer 2
  build_layer_transitions: false                # L1→L2, context >50%, 10+ tasks
  build_ci_test_recovery: false               # Ambiguous project CI test failures
EOF
else
    # Non-technical profile (no plan_mode)
    cat > "$HOMEdevelopment-agents/framework/user-profile.yaml" << EOF
# SDD Kit User Profile
# Generated: $(date -Iseconds)
#
# To update these settings:
#   /sdd.project profile        → View current settings
#   /sdd.project profile --edit → Interactive update
#   Delete this file            → Re-select from scratch

profile: non-technical  # technical | non-technical

# Non-technical profile: Express mode always active
# Agent handles all technical decisions automatically
EOF
fi
```

#### Step 5.5.3: Confirmation Message

**After saving profile, show confirmation**:

For **Technical profile**:
```
✅ Profile saved: technical

📋 Your settings:
   • Full technical detail in outputs
   • Plan Mode enabled for: [list enabled options]
   • Execution mode: your choice per feature

💡 To update later:
   /sdd.project profile        → View current settings
   /sdd.project profile --edit → Change settings
```

For **Non-technical profile**:
```
✅ Profile saved: non-technical

📋 Your settings:
   • Simplified output (business focus)
   • Express mode always active
   • Agent handles all technical decisions

💡 To update later:
   /sdd.project profile        → View current settings
   /sdd.project profile --edit → Change settings
```

**Profile behavior mapping**:

| Profile | Execution Mode | Technical Questions | Display |
|---------|----------------|---------------------|---------|
| `non-technical` | **AUTO-EXPRESS** | Agent decides | Simplified |
| `technical` | User's choice | Ask user | Full detail |

**⚠️ CRITICAL: Non-Technical = Express Mode**:

```
IF user_profile == "non-technical":
    execution_mode = "express"  # FORCED, no matter what flag was passed
    show: "📋 Express mode activated (non-technical profile)"
    show: "   Agent will handle all technical decisions automatically"
```

**Store in meta.md**:

```yaml
user_profile:
  type: non-technical  # or technical
  source: global       # global | project | selected
  selected_at: 2026-01-22T10:30:00Z
```
