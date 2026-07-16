# Reference: Build Final Validation Steps

**Used by**: `/sdd.build` Step 6.

### Step 6: Final Validation

After ALL tasks complete:

| Step | Action | On Failure |
|------|--------|------------|
| A | Code Compliance (3-layer validation) | FIX |
| B | Layer 3 Quality Gates (via `sdd-validator-runner`) | FIX ALL |
| C | Code Pattern Validation (stack-specific patterns) | FIX |
| D | **Local CI Pipeline** — full pipeline: build, test, coverage, deps, SCA | Auto-fix where the pipeline supports it |

**Step B - Layer 3 Quality Gates** (consolidated):
```python
# Single agent call replaces 3 skill calls, saves ~5700 tokens
Task(
    subagent_type="sdd-validator-runner",
    prompt="""
    Final validation for all modified files.
    Run Layer 3 quality gates: performance, security, code-review
    Return unified JSON verdict.
    """
)
```

**Step C: Code Pattern Validation**:

```bash
# Run deterministic code pattern scan
code_result=$(bash development-agents/framework/tools/validation/validate-code.sh . --json)
is_valid=$(echo "$code_result" | grep -o '"valid":[^,}]*' | cut -d: -f2)
critical_issues=$(echo "$code_result" | grep -o '"critical_count":[0-9]*' | cut -d: -f2)

if [ "$is_valid" != "true" ] || [ "$critical_issues" -gt 0 ]; then
    echo "❌ Code pattern validation failed:"
    echo "$code_result" | grep -o '"issues":\[[^]]*\]'
    # Show specific issues and FIX before proceeding
fi
```

**Patterns validated**:
- Security anti-patterns (SQL injection risks, unsafe deserialization)
- Performance anti-patterns (N+1 queries, missing indexes)
-  SDK/client misuse patterns (per technical spec)
- Code quality anti-patterns (god classes, deep nesting)

### Step 6D: Local CI / Build Validation

> Run the project's CI or local build+test commands from PROJECT.md / package scripts / Makefile.
> Do **not** require a vendor release-process skill or marketplace plugin.

**Preferred order**:
1. Use scripts already in the repo (
pm test, make ci, ./gradlew check, go test ./..., etc.)
2. If PROJECT.md names a release/CI skill, invoke it optionally
3. On failure after reasonable retries → STOP build; user fixes and re-runs /sdd.build

**ALL PASS?** → Proceed to Step 7
