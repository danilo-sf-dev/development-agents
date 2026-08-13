# Reference: Plan Interactive Next Steps

**Used by**: `/sdd.plan` Step 9.

### Step 9: Interactive Next Steps (After Tasks Approved)

> **MANDATORY**: Always offer interactive selection after tasks are approved.

**Model advisory**: Read `references/model-suggestion-advisory.md` — full box for `phase_key`: `plan→test`.

**⛔ INVOKE TOOL (do not print this, CALL the tool)**:

```
AskUserQuestion(
  questions=[{
    "question": "Tasks prontas. Escrever os testes primeiro?",
    "header": "Próximo",
    "options": [
      {"label": "/clear + /sdd.test (Recomendado)", "description": "Contexto limpo para o gate tests-first — comando em STRONG"},
      {"label": "/sdd.test", "description": "Escrever testes que falham antes da implementação — comando em STRONG"},
      {"label": "/sdd.test --refine", "description": "Só refinar se os testes já existirem"},
      {"label": "/sdd.check", "description": "Revisar a estrutura das tasks"},
      {"label": "Outros", "description": "Descreva o que você vai fazer ou sugira outro caminho (texto livre)"}
    ],
    "multiSelect": false
  }]
)
```

**On user selection**:

| Selection                        | Action                                        |
| -------------------------------- | --------------------------------------------- |
| /clear + /sdd.test (Recomendado) | Inform user to run `/clear`, then `/sdd.test` |
| /sdd.test                        | `CONTINUE_WORKFLOW("/sdd.test")`              |
| /sdd.test --refine               | `CONTINUE_WORKFLOW("/sdd.test --refine")`     |
| /sdd.check                       | `CONTINUE_WORKFLOW("/sdd.check")`             |
| Outros                           | User types custom input                       |

---

> **Lazy-loaded**: When `--view` is present, Read `references/plan-view.md` and follow it instead of the standard workflow.

---
