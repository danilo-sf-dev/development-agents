# Reference: Load / Validate PROJECT.md

**Used by**: `/sdd.start` Step 6.

### Step 6: Load PROJECT.md (CONDITIONAL)

**If `project_type == "prototype"`**:
  → Skip PROJECT.md prompt entirely
  → Use framework defaults for all settings
  → Show: "⏭️ PROJECT.md skipped (prototype mode)"
  → Continue to Step 7

**If `sdd/PROJECT.md` exists**:
  → Load defaults (e2e_enabled, atlassian_mcp_enabled, etc.)
  → **Validate PROJECT.md** (GenAI Offloaded):

```bash
# Validate PROJECT.md via GenAI Gateway
validation_result=$(bash development-agents/framework/tools/genai/genai-validate-project.sh .)
genai_exit=$?

if [ "$genai_exit" -eq 0 ]; then
    status=$(echo "$validation_result" | grep -o '"status":"[^"]*"' | cut -d'"' -f4)
    if [ "$status" != "PASSED" ]; then
        echo "PROJECT.md validation: $status"
        echo "$validation_result" | grep -o '"recommendations":\[[^]]*\]'
    fi
elif [ "$genai_exit" -eq 2 ]; then
    # Fallback to deterministic validation
    validation_result=$(bash development-agents/framework/tools/validation/validate-project.sh sdd/PROJECT.md --json)
    is_valid=$(echo "$validation_result" | grep -o '"valid":[^,}]*' | cut -d: -f2)
    if [ "$is_valid" != "true" ]; then
        echo "PROJECT.md validation warnings:"
        echo "$validation_result" | grep -o '"warnings":\[[^]]*\]'
    fi
fi
# Continue regardless - not blocking for start
```

**If missing AND `project_type != "prototype"`**:
  → Use AskUserQuestion:
    1. Create PROJECT.md now (delegate to `sdd-project-wizard` subagent)
    2. Continue with framework defaults
    3. What is PROJECT.md?

#### Step 6.1: Doctor Tip (Non-blocking, ⭐ v1.7.3)

> **Purpose**: surface project-config health issues that would otherwise inflate specs.
> **Behavior**: deterministic, fast (<1s), prints at most one line, NEVER blocks `/sdd.start`.

```bash
# Run the doctor's heuristic scanner only. No LLM, no questions.
doctor_result=$(bash development-agents/framework/tools/doctor/scan-config.sh . --json 2>/dev/null || echo '{}')

# Trigger the tip if any of these heuristics fire:
#   - any phrase hit on rule X1 or X4 (anti-elegance / disables kit)
#   - any shadowed command (O1) or agent (O2)
#   - combined always-on footprint over the soft threshold (S3)
trip_x=$(echo "$doctor_result" | grep -oE '"rule":"(X1|X4)"' | head -1)
trip_o=$(echo "$doctor_result" | grep -oE '"rule":"(O1|O2)"' | head -1)
footprint=$(echo "$doctor_result" | grep -o '"always_on_lines":[0-9]*' | cut -d: -f2)
threshold=$(echo "$doctor_result" | grep -o '"threshold":[0-9]*' | head -1 | cut -d: -f2)

if [ -n "$trip_x" ] || [ -n "$trip_o" ] || { [ -n "$footprint" ] && [ -n "$threshold" ] && [ "$footprint" -gt "$threshold" ]; }; then
    echo "💡 Tip: tu config de proyecto puede estar afectando al kit (footprint=${footprint} líneas o conflicto detectado). Considera ejecutar /sdd.doctor antes de continuar."
fi
# Continue regardless — this tip is informational only.
```

> **Rules**:
> - This step does NOT pause, does NOT use AskUserQuestion, and does NOT modify anything.
> - If the scanner fails or is missing, silently skip (the empty JSON fallback ensures all triggers stay false).
