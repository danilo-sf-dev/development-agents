# development-agents — Time SDD (hub)

Fonte canônica dos agents do time. Pack **language-/platform-agnostic**: specs e código ficam no projeto alvo; stack vem de detection + `sdd/PROJECT.md`.

## Pipeline

```
/sdd.start → /sdd.spec → /sdd.plan → /sdd.test → /sdd.build → /sdd.check → /sdd.finish → /sdd.pr
```

Atalho: `/sdd.go` orquestra start→…→finish em modo express (inclui `/sdd.test`).

> **Fonte canônica completa** (diagrama Mermaid, gates, modos, papéis): [`framework/PIPELINE.md`](./framework/PIPELINE.md). Atualize lá primeiro se o pipeline mudar.

**Process gates** (LLM, sem dependência de bash/jq/hooks): [`framework/HARD_GATES.md`](./framework/HARD_GATES.md) — `sdd-validator` (Process Compliance) + AskUserQuestion (sempre com **Outros**).

## Papéis

| Papel                             | Onde                                                                                                      |
| --------------------------------- | --------------------------------------------------------------------------------------------------------- |
| Spec Writer                       | command `/sdd.spec` (+ Skill `sdd-explorer`)                                                              |
| Arquiteto                         | Skill `sdd-system-design` + `/sdd.plan`                                                                 |
| Developer                         | Skill `sdd-implementation`                                                                                   |
| Test Writer                       | `/sdd.test` + agents `sdd-test-writing`, `sdd-test-writing` (E2E opcional)                      |
| Code Reviewer / Process Validator | skill `sdd-code-reviewer` + Skill `sdd-validator` (qualidade **e** integridade do pipeline)        |
| Orquestrador                      | commands `/sdd.go`, `/sdd.start` + skill `sdd-kit-expert`                                                 |
| Instalador                        | command `/sdd.install` + Skill `sdd-installer` (único caminho de instalação — sem scripts) |
| MCP / integrações                 | command `/sdd.mcp` + Skill `sdd-mcp-setup` (Jira/Confluence read-only; host-agnóstico)                    |
| Commit                            | skill `commit-workflow` com 4 opções e Graphify opcional                                                  |
| Pull Request                      | command `/sdd.pr` — rascunho SDD → aprovação humana → `gh pr create`                                      |

> Playbook primeiro dia: [`framework/PLAYBOOK.md`](./framework/PLAYBOOK.md)

## Paths

- **Hub (este repo):** pack na raiz — `skills/`, `commands/`, `framework/`
- **Projeto alvo (após install):** pack em `development-agents/` + adapters `.cursor/`, `.claude/`, `sdd/` — **tudo gitignored**, repo sobe limpo
- **SDD no dia a dia:** `sdd/PROJECT.md`, `sdd/backlog.md`, `sdd/wip/…`

## Gate tests-first

Entre `plan` e `build`: `/sdd.test` escreve testes a partir das specs/tasks, verifica fase **red** (falham), humano aprova → `/sdd.build` só implementa (não cria testes novos).
