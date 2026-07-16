# development-agents — Time SDD (hub)

Fonte canônica dos agents do time. Pack **language-/platform-agnostic**: specs e código ficam no projeto alvo; stack vem de detection + `sdd/PROJECT.md`.

## Pipeline

```
/sdd.start → /sdd.spec → /sdd.plan → /sdd.test → /sdd.build → /sdd.check → /sdd.finish → /sdd.pr
```

Atalho: `/sdd.go` orquestra start→…→finish em modo express (inclui `/sdd.test`).

> **Fonte canônica completa** (diagrama Mermaid, gates, modos, papéis): [`framework/PIPELINE.md`](./framework/PIPELINE.md). Atualize lá primeiro se o pipeline mudar.

**Process gates** (LLM, sem dependência de bash/jq/hooks): [`framework/HARD_GATES.md`](./framework/HARD_GATES.md) — `sdd-validator-runner` (Process Compliance) + AskUserQuestion (sempre com **Outros**).

## Papéis

| Papel | Onde |
|-------|------|
| Spec Writer | command `/sdd.spec` (+ agent `sdd-explorer`) |
| Arquiteto | agent `sdd-system-designer` + `/sdd.plan` |
| Developer | agent `sdd-implementer` |
| Test Writer | `/sdd.test` + agents `sdd-small-test-writer`, `sdd-large-test-writer` (E2E opcional) |
| Code Reviewer / Process Validator | skill `sdd-code-reviewer` + agent `sdd-validator-runner` (qualidade **e** integridade do pipeline) |
| Orquestrador | commands `/sdd.go`, `/sdd.start` + skill `sdd-kit-expert` |
| Instalador | command `/sdd.install` + agent `development-agents-installer` (alternativa a `install.ps1`) |
| Commit | skill `commit-workflow` com 4 opções e Graphify opcional |
| Pull Request | command `/sdd.pr` — rascunho SDD → aprovação humana → `gh pr create` |

> Playbook primeiro dia: [`framework/PLAYBOOK.md`](./framework/PLAYBOOK.md)

## Paths

- **Hub (este repo):** pack na raiz — `agents/`, `commands/`, `framework/`
- **Projeto alvo (após install):** pack em `development-agents/` + adapters `.cursor/`, `.claude/`, `sdd/` — **tudo gitignored**, repo sobe limpo
- **SDD no dia a dia:** `sdd/PROJECT.md`, `sdd/backlog.md`, `sdd/wip/…`

## Gate tests-first

Entre `plan` e `build`: `/sdd.test` escreve testes a partir das specs/tasks, verifica fase **red** (falham), humano aprova → `/sdd.build` só implementa (não cria testes novos).
