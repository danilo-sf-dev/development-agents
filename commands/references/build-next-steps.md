# Reference: Build Interactive Next Steps

**Used by**: `/sdd.build` Step 8.

### Step 8: Interactive Next Steps (After All Tasks Complete)

> **MANDATORY (Standard mode only)**: Offer interactive selection after all tasks complete.
> **EXPRESS MODE**: Skip this - auto-invoke `/sdd.finish`.

**Model Routing (automatic, informational only)**: `/sdd.finish` next runs at `model_role: STRONG` —
resolved and dispatched automatically, no confirmation needed. Optionally print the one-line
observability format from `references/model-suggestion-advisory.md`.

**⛔ INVOKE TOOL (do not print this, CALL the tool)** (only in Standard mode):

```
AskUserQuestion(
  questions=[{
    "question": "Todas as tasks concluídas e validadas. Pronto para finalizar?",
    "header": "Próximo",
    "options": [
      {"label": "/sdd.finish (Recomendado)", "description": "Arquivar a feature e concluir — comando em STRONG (code review final)"},
      {"label": "/sdd.check --sync", "description": "Checagem final de consistência"},
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
| /sdd.finish (Recomendado) | `CONTINUE_WORKFLOW("/sdd.finish")`          |
| /sdd.check --sync         | `CONTINUE_WORKFLOW("/sdd.check --sync")`    |
| /sdd.build --layer 3      | `CONTINUE_WORKFLOW("/sdd.build --layer 3")` |
| Outros                    | User types custom input                     |

**MODE BEHAVIOR**: In Express mode this whole section is skipped (see line 8) — `/sdd.finish` is auto-invoked directly, dispatched at its resolved `STRONG` role like any other Express phase (see `commands/sdd.go.md` § Model Routing).

---
