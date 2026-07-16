# Reference: Start Scaffolding & Stack Detection

**Used by**: `/sdd.start` Step 3.

### Step 3: Detect Scaffolding Status

> **PURPOSE**: Detect if app was created externally but is freshly scaffolded.
> **IMPORTANT**: If `sdd/specs` already exists, it's brownfield - NEVER cleanup.

After moving contents, use the `detect-scaffolding-status.sh` script:

```bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../tools" && pwd)"
result=$("$SCRIPT_DIR/detect-scaffolding-status.sh" "." --json)

# Parse JSON result
project_mode=$(echo "$result" | grep -o '"project_mode":"[^"]*"' | cut -d'"' -f4)
freshly_scaffolded=$(echo "$result" | grep -o '"freshly_scaffolded":[^,}]*' | cut -d: -f2)
detected_tech=$(echo "$result" | grep -o '"technology":"[^"]*"' | cut -d'"' -f4)
reason=$(echo "$result" | grep -o '"reason":"[^"]*"' | cut -d'"' -f4)

# Use detected technology if not already set
if [ -z "$technology" ] && [ -n "$detected_tech" ] && [ "$detected_tech" != "unknown" ]; then
    technology="$detected_tech"
    echo "   → Detected technology: $technology"
fi

echo "🔍 Scaffolding Status: $project_mode (freshly_scaffolded=$freshly_scaffolded)"
echo "   Reason: $reason"
```

#### 3.1 Detect Full Stack (Deterministic)

Use script for comprehensive stack detection - Saves ~2,000-3,000 tokens vs LLM inference.

```bash
# Detect full technology stack (language, framework, database, project services, platform)
# NOTE: if IS_MOBILE=true, stack_result was already fetched in Step 2 — reuse it
[ -z "$stack_result" ] && stack_result=$(bash development-agents/framework/tools/detection/detect-stack.sh . --json)

# Parse JSON result
language=$(echo "$stack_result" | grep -o '"language":"[^"]*"' | cut -d'"' -f4)
build_tool=$(echo "$stack_result" | grep -o '"buildTool":"[^"]*"' | cut -d'"' -f4)
framework=$(echo "$stack_result" | grep -o '"framework":"[^"]*"' | cut -d'"' -f4)
database=$(echo "$stack_result" | grep -o '"database":"[^"]*"' | cut -d'"' -f4)
platform_services=$(echo "$stack_result" | grep -o '"platformServices":\[[^]]*\]')
[ -z "$platform" ] && platform=$(echo "$stack_result" | grep -o '"platform":"[^"]*"' | cut -d'"' -f4)

echo "📊 Stack Detection: language=$language platform=${platform:-backend} build=$build_tool framework=${framework:-none} db=${database:-none} services=$platform_services"
```

**Use stack info in meta.md**: pre-populate `technology:`/`platform:` fields, set build/test commands, list project services to configure (skip for mobile).
