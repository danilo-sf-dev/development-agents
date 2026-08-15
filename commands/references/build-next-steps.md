# Reference: Build Interactive Next Steps

**Used by**: `/sdd.build` Step 8.

### Step 8: Interactive Next Steps (After All Tasks Complete)

> **MANDATORY (Standard mode only)**: Offer interactive selection after all tasks complete.
> **EXPRESS MODE**: Skip this — auto-advance to `/sdd.check` (next mandatory phase).
>
> Next step is ALWAYS `/sdd.check` — do NOT offer `/sdd.finish` here.

**Model Routing (automatic, informational only)**: `/sdd.check` next runs at `model_role: EXECUTION` —
resolved and dispatched automatically, no confirmation needed. Optionally print the one-line
observability format from `references/model-suggestion-advisory.md`.

**⛔ INVOKE TOOL (do not print this, CALL the tool)** (only in Standard mode):

```
AskUserQuestion(
  questions=[{
    "question": "Todas as tasks concluídas e validadas. Próximo: /sdd.check.",
    "header": "Próximo",
    "options": [
      {"label": "/sdd.check (Recomendado)", "description": "Verificar status e consistência antes de finalizar — comando em EXECUTION"},
      {"label": "/sdd.check --sync", "description": "Verificação completa de consistência specs/tasks/código"},
      {"label": "/sdd.build --layer 3", "description": "Rodar de novo os quality checks"},
      {"label": "Outros", "description": "Descreva o que você vai fazer ou sugira outro caminho (texto livre)"}
    ],
    "multiSelect": false
  }]
)
```

**On user selection**:

| Selection                 | Action                                      |
| ------------------------- | ------------------------------------------- |
| /sdd.check (Recomendado)  | `CONTINUE_WORKFLOW("/sdd.check")`           |
| /sdd.check --sync         | `CONTINUE_WORKFLOW("/sdd.check --sync")`    |
| /sdd.build --layer 3      | `CONTINUE_WORKFLOW("/sdd.build --layer 3")` |
| Outros                    | User types custom input                     |

**MODE BEHAVIOR**: In Express mode this section is skipped — `/sdd.check` is auto-invoked directly,
dispatched at its resolved `EXECUTION` role (see `commands/sdd.go.md` § Model Routing).

---
