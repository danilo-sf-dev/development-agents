# Reference: Build Interactive Next Steps

**Used by**: `/sdd.build` Step 8.

### Step 8: Interactive Next Steps (After All Tasks Complete)

> **MANDATORY (Standard mode only)**: Offer interactive selection after all tasks complete.
> **EXPRESS MODE**: Skip this - auto-invoke `/sdd.finish`.

**Model advisory** (Standard mode): Read `references/model-suggestion-advisory.md` — full box for `phase_key`: `build→finish`, then **model-confirm** AskUserQuestion (BLOCKING).

**⛔ INVOKE TOOL (do not print this, CALL the tool)** (only in Standard mode):

```
AskUserQuestion(
  questions=[{
    "question": "Todas as tasks concluídas e validadas. Pronto para finalizar?",
    "header": "Próximo",
    "options": [
      {"label": "/sdd.finish (Recomendado)", "description": "Arquivar a feature e concluir — comando em sonnet (code review final)"},
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

**MODE BEHAVIOR**: In Express mode, automatically invoke `/sdd.finish` **after** the model-confirm gate for `build→finish` (still show full box + confirm — do not skip the critical switch). On "Seguir com o modelo do comando", proceed to `/sdd.finish`.

---
