# Reference: Brownfield Start Path

**Used by**: `/sdd.start` Step 4 when brownfield is detected.

#### Step 4.2: Brownfield Without Specs Warning

> **INFO**: Non-blocking recommendation for better results.

When brownfield is detected WITHOUT existing specs:

```bash
if [ "$project_mode" = "brownfield" ] && [ ! -d "sdd/specs" ] && [ ! -d "sdd/extracted" ]; then
    # Show informative warning
fi
```

**Display to user**:

```
┌─────────────────────────────────────────────────────────────────────────┐
│  ⚠️  BROWNFIELD DETECTED WITHOUT SPECS                                  │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  This repository has existing code but no generated specs.               │
│                                                                          │
│  For better results, consider running:                                   │
│                                                                          │
│    /sdd.reverse-eng                                                     │
│                                                                          │
│  This will:                                                              │
│  • Extract specs from existing code                                      │
│  • Document current architecture                                         │
│  • Identify patterns and conventions                                     │
│  • Help avoid conflicts with new features                                │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

**⛔ INVOKE TOOL (do not print this, CALL the tool)**:

```
AskUserQuestion(
  questions=[{
    "question": "How would you like to proceed?",
    "header": "Setup",
    "options": [
      {"label": "Run /sdd.reverse-eng first (Recommended)", "description": "Generate specs from existing code before starting"},
      {"label": "Continue without specs", "description": "Feature will work but with less context"},
      {"label": "What does reverse-eng do?", "description": "Show brief explanation"}
    ],
    "multiSelect": false
  }]
)
```

**Behavior by choice**:

| Choice | Action |
|--------|--------|
| Run reverse-eng first | Exit `/sdd.start`, show: "Run `/sdd.reverse-eng` then retry `/sdd.start`" |
| Continue without specs | Proceed to Step 4.1, add warning to meta.md |
| What does it do? | Explain benefits, re-ask question |

**If user chooses "Continue without specs"**, add to meta.md:

```yaml
brownfield_context:
  has_specs: false
  warning_acknowledged: true
  recommendation: "Consider running /sdd.reverse-eng for better context"
```

#### Step 4.1: Analyze Existing Structure (Brownfield Only)

> **FOR BROWNFIELD**: Analyze existing codebase structure to understand patterns.

```bash
if [ "$project_mode" = "brownfield" ]; then
    echo "🔍 Analyzing existing codebase structure..."

    # Run structure analysis
    structure_result=$(bash development-agents/framework/tools/extraction/analyze-structure.sh . --json)

    # Extract key information
    entry_points=$(echo "$structure_result" | grep -o '"entry_points":\[[^]]*\]')
    patterns=$(echo "$structure_result" | grep -o '"patterns":\[[^]]*\]')
    dependencies=$(echo "$structure_result" | grep -o '"external_dependencies":\[[^]]*\]')
    test_patterns=$(echo "$structure_result" | grep -o '"test_patterns":\[[^]]*\]')

    echo "📊 Structure Analysis:"
    echo "   Entry points: $entry_points"
    echo "   Patterns detected: $patterns"
    echo "   External dependencies: $dependencies"
    echo "   Test patterns: $test_patterns"

    # Store in meta.md for use in /sdd.spec
    # This provides context about existing code patterns
fi
```

**Structure analysis provides**:
- Entry points (main classes, handlers, routes)
- Code patterns (MVC, layered, hexagonal)
- External service dependencies
- Test organization patterns
- Package/module structure
