# Reference: Finish Interactive Next Steps

**Used by**: `/sdd.finish` after archive.

## What's Next?

After `/sdd.finish` completes successfully:

1. **Your feature is archived** in `sdd/features/[feature-name]/`
2. **Telemetry** captured automatically in `~/.claude/logs/` or `~/.cursor/logs/` (when supported)
3. **Documentation generated** (README.md, implementation-summary.md)

### Interactive Next Steps (After Archive Complete)

> **MANDATORY (Standard mode only)**: Offer interactive selection after archiving.
> **EXPRESS MODE**: Skip this - show brief completion message only.

**Model advisory** (Standard mode): Read `references/model-suggestion-advisory.md` — full box for `phase_key`: `finish→pr` (user may pick `/sdd.start` → use `finish→start` row if they choose start).

**⛔ INVOKE TOOL (do not print this, CALL the tool)** (only in Standard mode):

```
AskUserQuestion(
  questions=[{
    "question": "Feature arquivada! Qual o próximo passo?",
    "header": "Próximo",
    "options": [
      {"label": "/sdd.pr (Recomendado)", "description": "Rascunhar o PR a partir dos artefatos SDD → você aprova → publicar — comando em haiku"},
      {"label": "/sdd.start", "description": "Começar uma nova feature — comando em haiku (sonnet de novo no spec)"},
      {"label": "/sdd.start --reopen", "description": "Reabrir esta feature depois para iterar"},
      {"label": "Outros", "description": "Descreva o que você vai fazer ou sugira outro caminho (texto livre)"}
    ],
    "multiSelect": false
  }]
)
```

Shape: `ask-user-question-outros.md` — **Outros** is mandatory on gates.

**On user selection**:

| Selection | Action |
|-----------|--------|
| /sdd.pr (Recomendado) | Run `/sdd.pr` for archived or last feature |
| /sdd.start | `Skill(skill="sdd.start")` |
| /sdd.start --reopen | Show: "Para reabrir depois: `/sdd.start --reopen [feature-name]`" |
| Outros | Read user intent — e.g. `/sdd.backlog list`, `/sdd.list`, PR manual |

> **MODE BEHAVIOR**: In Express mode, just show completion message without prompting.

---
