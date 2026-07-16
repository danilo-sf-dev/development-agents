# development-agents — Time SDD (hub)

Fonte canônica dos agents do time. Pack **language-/platform-agnostic**: specs e código ficam no projeto alvo; stack vem de detection + `sdd/PROJECT.md`.

## Pipeline

```
/sdd.start
   → /sdd.spec          (Gate 1: aprovar spec)
   → /sdd.plan          (Gate 2: aprovar tasks)
   → /sdd.build         (implement → test → validate)
   → /sdd.check
   → /sdd.finish        (Gate 3: conclusão)
```

Atalho: `/sdd.go` orquestra start→…→finish em modo express.

## Papéis

| Papel | Onde |
|-------|------|
| Spec Writer | command `/sdd.spec` (+ agent `sdd-explorer`) |
| Arquiteto | agent `sdd-system-designer` + `/sdd.plan` |
| Developer | agent `sdd-implementer` |
| Test Writer | agents `sdd-small-test-writer`, `sdd-large-test-writer` (E2E opcional) |
| Code Reviewer | skill `sdd-code-reviewer` + agent `sdd-validator-runner` |
| Orquestrador | commands `/sdd.go`, `/sdd.start` + skill `sdd-kit-expert` |
| Instalador | command `/sdd.install` + agent `development-agents-installer` (alternativa a `install.ps1`) |
| Commit | skill `commit-workflow` com 4 opções e Graphify opcional |

## Paths

- **Hub (este repo):** pack na raiz — `agents/`, `commands/`, `framework/`
- **Projeto alvo (após install):** pack em `development-agents/` + adapters `.cursor/`, `.claude/`, `sdd/` — **tudo gitignored**, repo sobe limpo
- **SDD no dia a dia:** `sdd/PROJECT.md`, `sdd/backlog.md`, `sdd/wip/…`

## Direção (ainda não implementada)

Inserir gate **tests-first** entre plan e build: escrever/aprovar testes → falhar primeiro → só então implementar.
