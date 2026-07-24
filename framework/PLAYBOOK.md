# Playbook — Primeiro dia com SDD

Guia linear para **primeira feature real** no projeto alvo. Pipeline canônico: [`PIPELINE.md`](./PIPELINE.md).

---

## Antes de começar

| Pré-requisito | Quem faz | Notas |
|---------------|----------|-------|
| Repo git inicializado | Dev | `main`/`master` estável |
| Card Jira (ou equivalente) | Dev | Link ou ID para `/sdd.spec --include` |
| IDE com agent (Cursor / Claude Code) | Dev | Chat onde roda `/sdd.*` |
| `gh` instalado e logado (opcional) | Dev | Só necessário para `/sdd.pr` |
| Branch `master`/`main` atualizada | Dev | **Manual** — pull antes do `/sdd.start` |

O pack **não** commita sozinho. Pastas `development-agents/`, `.cursor/`, `.claude/`, `sdd/` ficam **gitignored** no projeto alvo.

---

## Passo 0 — Instalar o pack (uma vez por projeto)

**Opção A — Script** (se a máquina permite):

```powershell
# Windows
.\install.ps1 -TargetDir "E:\Projects\meu-app"
```

```bash
# Git Bash / WSL / macOS / Linux
bash install.sh /path/to/meu-app
```

**Opção B — Agente** (script bloqueado):

```
/sdd.install
```

Verificar: pastas `development-agents/`, `.cursor/` ou `.claude/`, `sdd/wip`, `sdd/features`.

---

## Passo 1 — Configurar o projeto (`sdd/PROJECT.md`)

Se ainda não existe:

```
/sdd.project
```

Defina: stack, comandos de teste/build, convenções de branch/commit, review.

Sem `PROJECT.md`, `/sdd.start` pode bloquear ou inferir stack de forma incompleta.

### Passo 1.1 — MCP Jira/Confluence (opcional)

Se for usar cards/epics via URL em `/sdd.spec --include` (sem colar o texto à mão):

```
/sdd.mcp
```

Wizard agnóstico ao IDE: detecta o host, guia plugin nativo ou `.mcp.json`, OAuth, smoke test read-only. Ver [`MCP_SETUP_GUIDE.md`](./MCP_SETUP_GUIDE.md).

---

## Passo 2 — Preparar git (manual)

```bash
git checkout master   # ou main
git pull origin master
git checkout -b feature/JIRA-1234-resumo-curto
```

Regra: feature branch **antes** de `/sdd.start` (conforme gitflow do time).

---

## Passo 3 — Iniciar feature

```
/sdd.start "JIRA-1234 resumo da feature"
```

Cria `sdd/wip/<feature>/` com `meta.md` e estrutura de fases.

---

## Passo 4 — Especificação (Gate 1)

```
/sdd.spec functional --include "JIRA-1234 ou link"
/sdd.spec functional --approve

/sdd.spec technical
/sdd.spec technical --approve
```

Humano aprova spec funcional e técnica antes de plan.

---

## Passo 5 — Plano de tasks (Gate 2)

```
/sdd.plan
/sdd.plan --approve
```

Gera `tasks.json`. Aprovar antes de testes.

---

## Passo 6 — Testes primeiro (Gate 2.5)

```
/sdd.test
/sdd.test --approve
```

- Agentes escrevem testes a partir de specs/tasks
- Testes devem **falhar** (red) antes da implementação
- Humano aprova o conjunto de testes
- **Não** implementar feature nesta fase
- Este gate é **obrigatório** — nunca pular

---

## Passo 7 — Implementação

```
/sdd.build
```

- Implementa até testes aprovados passarem (green)
- **Não** cria testes unitários novos (salvo E2E deferido)
- **Não** altera testes aprovados — se errado, escalar `/sdd.test --refine`
- Validação via `sdd-validator-runner` (qualidade + Process Compliance)

Commits: skill `commit-workflow` (4 opções; sempre **Outros** disponível).

---

## Passo 8 — Revisão de status (opcional)

```
/sdd.check
```

Progresso, tasks, consistência entre camadas.

---

## Passo 9 — Finalizar e arquivar (Gate 3)

```
/sdd.finish
```

Valida, gera documentação, move `sdd/wip/` → `sdd/features/`.

---

## Passo 10 — Abrir Pull Request

```
/sdd.pr
```

1. Agent monta `pr-draft.md` — **template do projeto** (GitHub/GitLab/outro) se existir; senão template do pack
2. Você **aprova**, **nega** ou pede ajuste (**Outros**)
3. Agent pergunta **branch base** (`master`, `main`, `develop`, ou Outros)
4. Publica com `gh pr create` (se autorizado)

Merge e code review no GitHub continuam **manuais**.

Template pack: [`templates/pull-request-template.md`](./templates/pull-request-template.md)

---

## Fluxo resumido (cola na parede)

```
install → /sdd.project → [/sdd.mcp opcional] → git branch → /sdd.start
  → /sdd.spec → /sdd.plan → /sdd.test → /sdd.build
  → /sdd.finish → /sdd.pr
```

Atalho express (features simples): `/sdd.go "descrição"` — inclui test gate quando aplicável.

---

## Onde ler mais

| Tópico | Arquivo |
|--------|---------|
| Pipeline e gates | [`PIPELINE.md`](./PIPELINE.md) |
| Todos os commands | [`COMMANDS.md`](./COMMANDS.md) |
| Process gates / validator | [`HARD_GATES.md`](./HARD_GATES.md) |
| Tutorial detalhado | [`TUTORIAL.md`](./TUTORIAL.md) |
| FAQ / recovery | [`FAQ.md`](./FAQ.md), [`RECOVERY.md`](./RECOVERY.md) |
| MCP / Jira opcional | [`MCP_SETUP_GUIDE.md`](./MCP_SETUP_GUIDE.md) · `/sdd.mcp` |
| Papéis do time | [`../AGENTS.md`](../AGENTS.md) |

---

## Problemas comuns

| Situação | Ação |
|----------|------|
| `PROJECT.md` ausente | `/sdd.project` |
| Jira URL sem auto-fetch | `/sdd.mcp` ou colar conteúdo no `--include` |
| Teste aprovado foi alterado no build | STOP → `/sdd.test --refine` |
| `gh` não funciona | Copiar `pr-draft.md` e abrir PR manual no GitHub |
| Pack no commit por engano | Nunca add `sdd/`, `development-agents/` — revisar `.gitignore` |
| Quer reabrir feature fechada | `/sdd.start --reopen [feature]` |

---

## Decisões explícitas deste playbook

| Item | Decisão |
|------|---------|
| Profiles de stack | **Não usar** — evita confusão; stack via detection + `PROJECT.md` |
| PR automático sem revisão | **Não** — `/sdd.pr` sempre pausa para aprovação |
| Hard gates OS (bash/jq/hooks) | **Não** — Process Compliance via `sdd-validator-runner` |
