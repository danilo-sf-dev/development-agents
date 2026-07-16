# Reference: Build Anti-Gaming Detection

**Used by**: `/sdd.build` when approved tests appear in the diff.

> No OS hard gate (`bash`/`jq`/pre-commit). Enforcement = agent check + `sdd-validator-runner` Process Compliance + human AskUserQuestion.
> Always include **Outros** — see `ask-user-question-outros.md`.

## Soft detection (run per task, as part of Step 5)

Prefer reading `tests-manifest.json` with the Read tool and comparing paths to `git diff --name-only` / `git diff --cached --name-only` (any shell available). Pseudocode:

```
approved_test_files = tests from sdd/wip/[feature]/4-tests/tests-manifest.json
changed_files = git working tree + staged names
if any approved_test_files ⊆ changed_files → STOP
```

Optional bash helper (only if bash works on this machine — never required):

```bash
approved_test_files=$(jq -r '.tests[].file' sdd/wip/[feature]/4-tests/tests-manifest.json 2>/dev/null)
changed_files=$(git diff --name-only; git diff --cached --name-only)
```

**If an approved test file was touched** — STOP the task cycle, do not commit, do not mark task completed:

**⛔ INVOKE TOOL (do not print this, CALL the tool)**:

```
AskUserQuestion(
  questions=[{
    "question": "Um teste aprovado foi alterado durante a implementação. Isso pode indicar que o teste está sendo ajustado pra passar, em vez do código ser corrigido. Como proceder? (Pode trocar de modelo antes de revalidar.)",
    "header": "Test Integrity",
    "options": [
      {"label": "Reverter o teste e corrigir o código (Recommended)", "description": "Descarta o diff no arquivo de teste; implementação continua até bater no teste original"},
      {"label": "O teste está realmente errado — escalar para /sdd.test --refine", "description": "Pausa o build, volta ao gate de testes com novo ciclo de aprovação humana"},
      {"label": "Ver o diff antes de decidir", "description": "Mostra o diff do arquivo de teste"},
      {"label": "Outros", "description": "Descreva o que você vai fazer ou sugira outro caminho (texto livre)"}
    ],
    "multiSelect": false
  }]
)
```

> **NEVER** auto-approve a test file change — this check always pauses and asks, even in Express mode.

## Validator cross-check

Also invoke `sdd-validator-runner` with Process Compliance enabled (see agent). If verdict is `CANNOT_PROCEED` on process rules → same STOP + AskUserQuestion pattern (incl. Outros).
