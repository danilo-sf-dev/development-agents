# Reference: Start Project Mode Detection

**Used by**: `/sdd.start` Step 4.

### Step 4: Detect Project Mode

```bash
if [ "$freshly_scaffolded" = true ]; then
    project_mode="greenfield"
    echo "🆕 Freshly scaffolded → Greenfield mode"
elif [ -d "sdd/specs" ] || [ -d "sdd/features" ]; then
    project_mode="brownfield"
    echo "🔍 Existing specs found → Brownfield mode"
elif has_implementation_code; then
    project_mode="brownfield"
    echo "🔍 Existing code found → Brownfield mode"
else
    project_mode="greenfield"
    echo "🆕 Empty project → Greenfield mode"
fi
```

#### Step 4.1–4.2: Brownfield (lazy-loaded)

> **ONLY IF** `project_mode == brownfield`:
> Read `references/start-brownfield.md` (no-specs warning + structure analysis).
> Greenfield: skip to Step 5.
