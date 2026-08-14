# development-agents — Time SDD (hub)

Fonte canônica do time SDD — contexto/instrução para humanos **e** para agentes de IA que leem este arquivo. Pack **language-/platform-agnostic**: specs e código ficam no projeto alvo; stack vem de detection + `sdd/PROJECT.md`.

> **Nota de terminologia**: não existe mais pasta `agents/` neste pack. Os 12 papéis que antes eram
> "Agents" dedicados (frontmatter `tools:`/`model:`/`isolation:` + `Task(subagent_type=...)`) foram
> migrados para **Skills** (`skills/*/SKILL.md`) — decisão registrada em
> [`docs/adr/0001-agent-skill-execution-architecture.md`](./docs/adr/0001-agent-skill-execution-architecture.md).
> Este arquivo se chama `AGENTS.md` porque é a convenção que vários harnesses (Codex CLI, etc.) leem
> automaticamente como instrução de projeto — não porque o pack ainda tenha uma entidade "Agent".

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
| Test Writer                       | `/sdd.test` + Skill `sdd-test-writing` (E2E absorvido como branch lazy-loaded, não é uma Skill separada) |
| Code Reviewer / Process Validator | skill `sdd-code-reviewer` + Skill `sdd-validator` (qualidade **e** integridade do pipeline)        |
| Orquestrador                      | commands `/sdd.go`, `/sdd.start` + skill `sdd-kit-expert`                                                 |
| Instalador                        | command `/sdd.install` + Skill `sdd-installer` (único caminho de instalação — sem scripts) |
| MCP / integrações                 | command `/sdd.mcp` + Skill `sdd-mcp-setup` (Jira/Confluence read-only; host-agnóstico)                    |
| Commit                            | skill `commit-workflow` com 4 opções e Graphify opcional                                                  |
| Pull Request                      | command `/sdd.pr` — rascunho SDD → aprovação humana → `gh pr create`                                      |

> Tabela acima é resumida (papéis "guarda-chuva"). Inventário completo das 16 Skills (com Execution
> requirement e Model Role de cada uma): [`docs/reference/MANIFEST.md`](./docs/reference/MANIFEST.md).
> Tabela de papéis com Model Role por linha: [`framework/PIPELINE.md`](./framework/PIPELINE.md) § Roles.

> Playbook primeiro dia: [`framework/PLAYBOOK.md`](./framework/PLAYBOOK.md)

## Model Role (`STRONG` / `EXECUTION`)

Cada Skill/command declara `model_role: STRONG` (reasoning mais forte — decisão, arquitetura,
testes, validação) ou `model_role: EXECUTION` (execução mecânica — já foi decidido, agora é seguir o
plano). A resolução para um modelo concreto por harness é automática, nunca manual:

- **Política canônica** (harness-agnostic, sem nomes de modelo): [`framework/_shared/model-routing.md`](./framework/_shared/model-routing.md)
- **Valores concretos por harness** (única fonte editável): [`config/model-routing.yaml`](./config/model-routing.yaml)
- **Vocabulário de execution requirements** (`DELEGATE_ISOLATED`, `OFFLOAD_READ`, `VALIDATOR_ISOLATED`, etc.) e tabela de suporte por harness: [`framework/_shared/harness-capabilities.md`](./framework/_shared/harness-capabilities.md)
- **Tradução para Claude Code** (nomes reais de modelo, effort, custo): [`docs/reference/SUGESTAO-MODELOS.md`](./docs/reference/SUGESTAO-MODELOS.md)

## Paths

- **Hub (este repo):** pack na raiz — `skills/`, `commands/`, `framework/`, `adapters/`, `config/`, `docs/`
- **Projeto alvo (após install):** pack em `development-agents/` + adapter(s) do(s) harness(es) instalado(s) (`.claude/`, `.cursor/`, `.agents/`, ou nenhum no Generic) + `sdd/` — **tudo gitignored**, repo sobe limpo. Harnesses suportados hoje: Claude Code, Cursor, Codex CLI (experimental), Generic (fallback) — ver `adapters/<harness>/README.md`.
- **SDD no dia a dia:** `sdd/PROJECT.md`, `sdd/backlog.md`, `sdd/wip/…`

## Gate tests-first

Entre `plan` e `build`: `/sdd.test` escreve testes a partir das specs/tasks, verifica fase **red** (falham), humano aprova → `/sdd.build` só implementa (não cria testes novos).
