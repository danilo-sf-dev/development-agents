# Reference: Technical Spec Approval Gate

**Used by**: `/sdd.spec` Step 6 (standard interactive approval). For `--approve` flag see `spec-approve.md`.

### Step 6: Show Summary + Approve (with Validation)

> **MANDATORY**: Run deterministic validation before approval - Saves ~3,000-5,000 tokens.

**Step 6a.0: Architect-First Self-Check (BLOCKING backend/web)**

> Before summary: confirm you invoked `sdd-system-designer` **before** writing DD/Services/Dependencies,
> and `sdd-implementer` per selected service. If not → STOP, invoke, regenerate, then continue. No retroactive ratification.

**Step 6a: Validate technical spec**

```bash
# Run deterministic validation BEFORE asking for approval
bash development-agents/framework/tools/validation/validate-technical.sh sdd/wip/[feature]

# If exit code != 0: Show errors, DO NOT proceed to approval
# If exit code == 0: Continue to security validation
```

**Step 6a.1: Validate security (OWASP Top 10)**

> **MANDATORY**: Security validation catches OWASP Top 10 vulnerabilities. Never skip.

```bash
bash development-agents/framework/tools/validation/validate-security.sh sdd/wip/[feature] --spec
# If exit code != 0: Show security issues, DO NOT proceed to approval
# If exit code == 0: Continue to summary
```

**Step 6b: Show concise summary** (if validation passed):
```markdown
## Technical Specification Summary
### Architecture: [1-2 lines]
### Endpoints (N): [list]
### Database: [services + tables]
### Project Services: [list]
### Key Decisions: [list]
### Secrets: [count + names]
```

**Step 6b.1: Architecture Diagram (ASCII)**

> **MANDATORY**: After the text summary, show a compact ASCII architecture diagram (apps, stores, queues, externals, arrows).
> **ONLY IF** you need shapes/examples: Read `references/spec-architecture-diagram.md`.

**Step 6c: Context Check**

If context >50% before approval, warn: after approve, consider `/clear` before `/sdd.plan` (spec is saved).

**Step 6d: Approve** (only if validation passed)

**⛔ INVOKE TOOL (do not print this, CALL the tool)**:

```
AskUserQuestion(
  questions=[{
    "question": "The technical spec is ready. What would you like to do?",
    "header": "Approval",
    "options": [
      {"label": "Approve", "description": "Approve and continue to /sdd.plan"},
      {"label": "View full spec", "description": "Display the complete technical spec"},
      {"label": "Request changes", "description": "Iterate on the spec with /sdd.spec --iterate"}
    ],
    "multiSelect": false
  }]
)
```

**If user selects "View full spec"**:
- Read and display the entire file: `sdd/wip/[feature]/2-technical/spec.md`
- After displaying, loop back to the approval question (ask again)

**If user selects "Request changes"**:
- Ask what changes they want to make
- Apply changes using `--iterate` flow

**On approval - Update meta.md:**
```bash
# Get user identity and timestamp (single line to avoid multi-line permission prompts)
approver=$(git config user.name || echo "Unknown"); timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ"); echo "Approver: $approver | Timestamp: $timestamp"
```

Update `meta.md` stages.technical:
- `status: approved`
- `approved_by: <user from git config>` ← NEVER "AI Agent"
- `approved_at: <ISO-8601 timestamp>`

#### After Technical Spec Approval - Interactive Next Steps

> **MANDATORY**: Always offer interactive selection after approval.

**Model advisory**: Read `references/model-suggestion-advisory.md` — full box for `phase_key`: `technical→plan`.

**⛔ INVOKE TOOL (do not print this, CALL the tool)**:

```
AskUserQuestion(
  questions=[{
    "question": "Technical spec approved. What's next?",
    "header": "Next",
    "options": [
      {"label": "/sdd.plan (Recommended)", "description": "Generate implementation tasks — sugere modelo forte"},
      {"label": "/sdd.spec --iterate", "description": "Refine specs before planning"},
      {"label": "/sdd.check", "description": "View current status"}
    ],
    "multiSelect": false
  }]
)
```

**On user selection**:

| Selection | Action |
|-----------|--------|
| /sdd.plan (Recommended) | `Skill(skill="sdd.plan")` |
| /sdd.spec --iterate | `Skill(skill="sdd.spec", args="--iterate")` |
| /sdd.check | `Skill(skill="sdd.check")` |
| Other | User types custom input |
