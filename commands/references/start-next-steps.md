# Reference: Start Interactive Next Steps

**Used by**: `/sdd.start` Step 12.

### Step 12: Interactive Next Steps

> **MANDATORY**: Always offer interactive selection, never just show text.

**Model advisory** (before AskUserQuestion): Read `references/model-suggestion-advisory.md` and show the full box for `phase_key`: `start→spec`.

**Model confirm** (BLOCKING): Run **Critical switch — model confirm** for `start→spec` **before** the next-steps AskUserQuestion below (two-question payload if the host supports it; otherwise model-confirm first).

After displaying success message, use **AskUserQuestion** to offer next actions:

**Determine options based on context**:

```pseudocode
if saved_description exists in meta.md:
    option_1_label = "/sdd.spec (with saved context)"
    option_1_description = "Usa a descrição salva para iniciar a spec — comando em STRONG"
else:
    option_1_label = "/sdd.spec (Recomendado)"
    option_1_description = "Criar a spec de forma interativa — comando em STRONG"
```

**⛔ INVOKE TOOL (do not print this, CALL the tool)** - options vary by context:

```
AskUserQuestion(
  questions=[{
    "question": "Feature inicializada. O que deseja fazer agora?",
    "header": "Próximo",
    "options": [
      {"label": "/sdd.spec (Recomendado)", "description": "Criar a spec de forma interativa — comando em STRONG"},
      {"label": "/sdd.spec --audio", "description": "Descrever a feature por voz"},
      {"label": "/sdd.check", "description": "Ver status da feature"},
      {"label": "Outros", "description": "Descreva o que você vai fazer ou sugira outro caminho (texto livre)"}
    ],
    "multiSelect": false
  }]
)
```

> **Note**: If saved description exists in meta.md, first option label should be "/sdd.spec (com contexto salvo)" with description "Usa a descrição salva para iniciar a spec — comando em STRONG".
> **On user selection**:

| Selection                      | Action                                                                        |
| ------------------------------ | ----------------------------------------------------------------------------- |
| /sdd.spec (com contexto salvo) | `CONTINUE_WORKFLOW("/sdd.spec")` - description auto-loaded from meta.md       |
| /sdd.spec (Recomendado)        | `CONTINUE_WORKFLOW("/sdd.spec")`                                              |
| /sdd.spec --audio              | `CONTINUE_WORKFLOW("/sdd.spec --audio")`                                      |
| /sdd.check                     | `CONTINUE_WORKFLOW("/sdd.check")`                                             |
| Outros                         | User types custom input (e.g., `/sdd.spec "nova descrição"`, questions, etc.) |

> **NOTE**: AskUserQuestion ALWAYS includes "Other" option automatically.
> Users can write ANY text: another command, a question, feedback, etc.

---
