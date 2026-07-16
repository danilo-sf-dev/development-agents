# Reference: `/sdd.check` Flag Rules

**Used by**: `/sdd.check --sync`, `--compliance`, `--project`, or `--version`.

For output format examples, also read `references/check-output-examples.md`.

---

## `--sync` rules

1. **Phase-aware**: Only check layers that exist at current phase
2. **Bidirectional**: Check both directions (Spec→Code AND Code→Spec)
3. **Evidence-based**: Provide specific line numbers and quotes
4. **Atomic fixes**: Apply all related fixes together

## `--compliance` rules

1. **Run actual commands**: Execute test suite, linter, etc.
2. **Check runtime requirements**: Dockerfile, `/ping` or health endpoint, version consistency
3. **Actionable fixes**: Provide specific code changes, not just descriptions

## `--project` rules

1. **Validate via GenAI**: Use `genai-validate-project.sh`, fallback to `validate-project.sh`
2. **Compare against standards**: Check all `development-agents/framework/standards/` files
3. **Track overrides**: Distinguish between registered and unregistered overrides
4. **Assist registration**: Help user register overrides with proper documentation

## `--version` rules

1. **Scan ALL specs**: Not just current feature — scan `sdd/specs/`, `sdd/features/`, `sdd/wip/`
2. **Validate against current templates**: Load templates from `development-agents/framework/templates/`
3. **Check required sections**: Each spec type has required sections per version
4. **Detect deprecated patterns**: Look for patterns that were valid in old versions
5. **Handle legacy features**: If `framework.version_created` missing, flag for update
6. **Offer auto-fixes**: Where possible, offer to add missing sections/update patterns

## Validation implementation (`--version`)

```bash
# Scan all spec locations
spec_locations=(
    "sdd/specs"
    "sdd/features"
    "sdd/wip"
)

for location in "${spec_locations[@]}"; do
    if [ -d "$location" ]; then
        find "$location" -name "spec.md" -o -name "*.yaml" | while read spec_file; do
            validate_spec "$spec_file"
        done
        find "$location" -name "meta.md" | while read meta_file; do
            check_version_tracking "$meta_file"
        done
    fi
done
```

### Section extraction from templates

```bash
extract_required_sections() {
    template_file="$1"
    grep -E "^##+ " "$template_file" | \
        grep -v "Optional" | \
        grep -v "Conditional" | \
        sed 's/^#* //'
}

validate_sections() {
    spec_file="$1"
    template_file="$2"
    required=$(extract_required_sections "$template_file")
    actual=$(grep -E "^##+ " "$spec_file" | sed 's/^#* //')
    echo "$required" | while read section; do
        if ! echo "$actual" | grep -q "$section"; then
            echo "MISSING: $section"
        fi
    done
}
```
