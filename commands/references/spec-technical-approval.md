# Reference: Technical Spec Approval Gate

**Used by**: `/sdd.spec` Step 6 (standard interactive approval). For `--approve` flag see `spec-approve.md`.

### Step 6: Show Summary + Approve (with Validation)

> **MANDATORY**: Run deterministic validation before approval - Saves ~3,000-5,000 tokens.

**Step 6a.0: Architect-First Self-Check (BLOCKING backend/web)**

> Before summary: confirm you invoked `sdd-system-design` **before** writing DD/Services/Dependencies,
> and `sdd-implementation` per selected service. If not → STOP, invoke, regenerate, then continue. No retroactive ratification.

**Step 6a: Validate technical spec**

```bash
# Run deterministic validation BEFORE asking for approval
bash development-agents/framework/tools/validate-technical.sh sdd/wip/[feature]

# If exit code != 0: Show errors, DO NOT proceed to approval
# If exit code == 0: Continue to security validation
```

**Step 6a.1: Validate security (OWASP Top 10)**

> **MANDATORY**: Security validation catches OWASP Top 10 vulnerabilities. Never skip.

```bash
bash development-agents/framework/tools/validate-security.sh sdd/wip/[feature] --spec
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
    "question": "A spec técnica está pronta. O que deseja fazer?",
    "header": "Aprovação",
    "options": [
      {"label": "Aprovar", "description": "Aprovar e seguir para /sdd.plan"},
      {"label": "Ver spec completa", "description": "Exibir a spec técnica inteira"},
      {"label": "Pedir mudanças", "description": "Iterar na spec com /sdd.spec --iterate"},
      {"label": "Outros", "description": "Descreva o que você vai fazer ou sugira outro caminho (texto livre)"}
    ],
    "multiSelect": false
  }]
)
```

**If user selects "Ver spec completa"**:

- Read and display the entire file: `sdd/wip/[feature]/2-technical/spec.md`
- After displaying, loop back to the approval question (ask again)

**If user selects "Pedir mudanças"**:

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

**Model Routing (automatic, informational only)**: `/sdd.plan` next runs at `model_role: EXECUTION` — resolved and dispatched automatically, no confirmation needed. Optionally print the one-line observability format from `references/model-suggestion-advisory.md`.

**⛔ INVOKE TOOL (do not print this, CALL the tool)**:

```
AskUserQuestion(
  questions=[{
    "question": "Spec técnica aprovada. Qual o próximo passo?",
    "header": "Próximo",
    "options": [
      {"label": "/sdd.plan (Recomendado)", "description": "Gerar as tasks de implementação — comando em EXECUTION"},
      {"label": "/sdd.spec --iterate", "description": "Refinar as specs antes de planejar"},
      {"label": "/sdd.check", "description": "Ver status atual"},
      {"label": "Outros", "description": "Descreva o que você vai fazer ou sugira outro caminho (texto livre)"}
    ],
    "multiSelect": false
  }]
)
```

**On user selection**:

| Selection               | Action                                     |
| ----------------------- | ------------------------------------------ |
| /sdd.plan (Recomendado) | `CONTINUE_WORKFLOW("/sdd.plan")`           |
| /sdd.spec --iterate     | `CONTINUE_WORKFLOW("/sdd.spec --iterate")` |
| /sdd.check              | `CONTINUE_WORKFLOW("/sdd.check")`          |
| Outros                  | User types custom input                    |
