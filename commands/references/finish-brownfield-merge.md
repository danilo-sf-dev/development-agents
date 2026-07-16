# Reference: Finish Brownfield Spec Merge

**Used by**: `/sdd.finish` in brownfield projects.

## Brownfield: System Spec Merge

For brownfield projects, offers to merge changes back to system specs:

### Brownfield Merge Validation (Deterministic)

> **MANDATORY for brownfield**: Validate readiness before attempting merge.

```bash
# Check if brownfield project
project_mode=$(grep "project_mode:" sdd/wip/[feature]/meta.md | cut -d: -f2 | tr -d ' ')

if [ "$project_mode" = "brownfield" ]; then
    # Validate merge readiness
    merge_result=$(bash development-agents/framework/tools/validation/validate-brownfield-merge.sh sdd/wip/[feature] --json)
    merge_ready=$(echo "$merge_result" | grep -o '"ready":[^,}]*' | cut -d: -f2)
    conflicts=$(echo "$merge_result" | grep -o '"conflict_count":[0-9]*' | cut -d: -f2)

    if [ "$merge_ready" != "true" ]; then
        echo "⚠️ Brownfield merge has $conflicts potential conflicts:"
        echo "$merge_result" | grep -o '"conflicts":\[[^]]*\]'
        # Show conflicts for user review
    fi

    # Extract affected specs
    affected_specs=$(echo "$merge_result" | grep -o '"affected_specs":\[[^]]*\]')
    echo "📋 Affected system specs:"
    echo "$affected_specs"
fi
```

**Merge validation checks**:
- Identifies all system specs that need updates
- Detects potential merge conflicts
- Validates spec reference annotations
- Checks for breaking changes to existing APIs
- Lists affected downstream systems

```
This feature modified existing system specifications.

Affected specs (from meta.md):
• sdd/specs/api-contracts/auth-api.yaml
• sdd/specs/architecture.md

Merge changes back? [Y/n/manual]
```

- **Y**: Semi-automatic merge with Platform AI docs assistance
- **n**: Skip (manual later)
- **manual**: Show merge instructions

The functional and technical specs describe what changed - use them to update the system specs in `sdd/specs/`.

---
