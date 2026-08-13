# Reference: Functional Spec Approval Gate

**Used by**: `/sdd.spec` Step 3 (standard interactive approval). For `--approve` flag see `spec-approve.md`.

### Step 3: Show Summary + Approve (with Validation)

> **MANDATORY**: Run deterministic validation before approval - Saves ~3,000-5,000 tokens.

**Step 3a.0: No-Architecture-Leak Self-Check (BLOCKING)**

> **STOP before generating the summary**: Confirm the functional spec is free of premature
> architecture decisions.
>
> Verify in your own working memory:
>
> ```
> [ ] The Dependencies section does NOT name concrete project services
>     (no specific message-queue/database/cache product names). It lists CAPABILITIES instead
>     (e.g. "async event processing", "key-value storage", "immutable audit trail").
> [ ] No gap question exposed implementation jargon to the user
>     (no "at-least-once delivery", "TTL", "consumer", "producer", "topic", "container").
> [ ] If any architectural classification was needed (async vs sync, storage type, etc.),
>     I delegated to `sdd-system-design` (Skill — `DELEGATE_OFFLOAD`, see `framework/_shared/harness-capabilities.md`) to inform candidate selection — and
>     surfaced the candidates as "tentative — to be confirmed in technical spec",
>     NOT as final dependencies.
> ```
>
> If ANY checkbox is unchecked: STOP. Reword the offending sections in product terms
> (or delegate to the missing agent) before proceeding to Step 3a.
>
> ❌ ANTI-PATTERN: outputting "Dependencies: MessageQueueX · KeyValueStoreY · AuditServiceZ" (concrete
> product/service names) in the functional summary. Service selection belongs to the technical spec.
> ✅ CORRECT: "Dependencies (capabilities): async event processing, key-value storage,
> immutable audit trail. Concrete services to be selected in technical spec."

**Step 3a: Validate functional spec**

```bash
# Run deterministic validation BEFORE asking for approval
bash development-agents/framework/tools/validation/validate-functional.sh sdd/wip/[feature]

# If exit code != 0: Show errors, DO NOT proceed to approval
# If exit code == 0: Continue to summary
```

**Step 3b: Show concise summary** (if validation passed):

```markdown
## Functional Specification Summary
### Problem: [2-3 lines]
### User Stories (N): [list titles]
### Scope: In/Out
### Dependencies (capabilities): [list of capabilities, NOT project service names]
  e.g. "async event processing, key-value storage, immutable audit trail"
  Concrete services chosen in technical spec via the sdd-system-design skill.
```

**Step 3c: Context Check Before Approval**

Before presenting the approval question, estimate context usage. If > 50%, prepend a context advisory:

```
╔═══════════════════════════════════════════════════════╗
║  CONTEXT ADVISORY                                     ║
╠═══════════════════════════════════════════════════════╣
║                                                       ║
║  Context usage: ~[XX]%                                ║
║                                                       ║
║  Tip: After approving, consider /clear before         ║
║  running /sdd.spec technical. Your spec is saved —   ║
║  a fresh context will give higher quality output.      ║
║                                                       ║
╚═══════════════════════════════════════════════════════╝
```

**Step 3d: Approve** (only if validation passed)

**⛔ INVOKE TOOL (do not print this, CALL the tool)**:

```
AskUserQuestion(
  questions=[{
    "question": "A spec funcional está pronta. O que deseja fazer?",
    "header": "Aprovação",
    "options": [
      {"label": "Aprovar", "description": "Aprovar e seguir para a spec técnica"},
      {"label": "Ver spec completa", "description": "Exibir a spec funcional inteira"},
      {"label": "Pedir mudanças", "description": "Iterar na spec com /sdd.spec --iterate"},
      {"label": "Outros", "description": "Descreva o que você vai fazer ou sugira outro caminho (texto livre)"}
    ],
    "multiSelect": false
  }]
)
```

**If user selects "Ver spec completa"**:

- Read and display the entire file: `sdd/wip/[feature]/1-functional/spec.md`
- After displaying, loop back to the approval question (ask again)

**If user selects "Pedir mudanças"**:

- Ask what changes they want to make
- Apply changes using `--iterate` flow

**On approval - Update meta.md:**

```bash
# Get user identity and timestamp (single line to avoid multi-line permission prompts)
approver=$(git config user.name || echo "Unknown"); timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ"); echo "Approver: $approver | Timestamp: $timestamp"
```

Update `meta.md` stages.functional:

- `status: approved`
- `approved_by: <user from git config>` ← NEVER "AI Agent"
- `approved_at: <ISO-8601 timestamp>`

> **CRITICAL**: The `approved_by` field MUST be the human user who approved, obtained via `git config user.name`. The Platform AI docs agent facilitates the process but does NOT approve specs.

#### After Functional Spec Approval - Interactive Next Steps

> **MANDATORY**: Always offer interactive selection after approval.

**Model advisory**: Read `references/model-suggestion-advisory.md` — full box for `phase_key`: `functional→technical`.

**⛔ INVOKE TOOL (do not print this, CALL the tool)**:

```
AskUserQuestion(
  questions=[{
    "question": "Spec funcional aprovada. Qual o próximo passo?",
    "header": "Próximo",
    "options": [
      {"label": "/sdd.spec technical (Recomendado)", "description": "Criar a especificação técnica — comando em sonnet"},
      {"label": "/sdd.spec --iterate", "description": "Refinar a spec funcional antes"},
      {"label": "/sdd.check", "description": "Ver status atual"},
      {"label": "Outros", "description": "Descreva o que você vai fazer ou sugira outro caminho (texto livre)"}
    ],
    "multiSelect": false
  }]
)
```

**On user selection**:

| Selection                         | Action                                     |
| --------------------------------- | ------------------------------------------ |
| /sdd.spec technical (Recomendado) | `CONTINUE_WORKFLOW("/sdd.spec technical")` |
| /sdd.spec --iterate               | `CONTINUE_WORKFLOW("/sdd.spec --iterate")` |
| /sdd.check                        | `CONTINUE_WORKFLOW("/sdd.check")`          |
| Outros                            | User types custom input                    |
