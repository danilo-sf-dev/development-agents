# Reference: Build Anti-Gaming Detection

**Used by**: `/sdd.build` when approved tests appear in the diff.

### Detection (run per task, as part of Step 5)

```bash
approved_test_files=$(jq -r '.tests[].file' sdd/wip/[feature]/4-tests/tests-manifest.json 2>/dev/null)
changed_files=$(git diff --name-only; git diff --cached --name-only)

touched_approved_tests=false
for f in $approved_test_files; do
    if echo "$changed_files" | grep -qF "$f"; then
        echo "🚫 Approved test file modified: $f"
        touched_approved_tests=true
    fi
done
```

**If `touched_approved_tests=true`** — STOP the task cycle, do not commit, do not mark task completed:

**⛔ INVOKE TOOL (do not print this, CALL the tool)**:

```
AskUserQuestion(
  questions=[{
    "question": "Um teste aprovado foi alterado durante a implementação. Isso pode indicar que o teste está sendo ajustado pra passar, em vez do código ser corrigido. Como proceder?",
    "header": "Test Integrity",
    "options": [
      {"label": "Reverter o teste e corrigir o código (Recommended)", "description": "Descarta o diff no arquivo de teste, implementação continua até bater no teste original"},
      {"label": "O teste está realmente errado — escalar para /sdd.test --refine", "description": "Pausa o build, volta ao gate de testes com novo ciclo de aprovação humana"},
      {"label": "Ver o diff antes de decidir", "description": "Mostra o diff do arquivo de teste"}
    ],
    "multiSelect": false
  }]
)
```

> **NEVER** auto-approve a test file change — this check always pauses and asks, even in Express mode. Silent edits to approved tests are the exact failure mode this gate exists to prevent.

---
