---
name: sdd.pr
description: Draft a pull request from SDD artifacts, get human approval, then open it on GitHub via gh. Use after implementation (typically after /sdd.finish or when ready to merge).
model: sonnet
argument-hint: "[feature-name]"
---

> **Shared agent instructions**: Read `development-agents/framework/_shared/agent-instructions.md` before executing this command.

# Command: /sdd.pr

**Description**: Monta rascunho de PR a partir dos artefatos SDD, pausa para revisão humana e abre o PR no GitHub (manual autorizado).

**Usage**:
- `/sdd.pr` → feature WIP ativa ou única em `sdd/wip/`
- `/sdd.pr [feature-name]` → feature específica
- `/sdd.pr --draft` → abre PR como draft no GitHub

---

## Quick Help

**Syntax**: `/sdd.pr [feature] [--draft]`

| Flag | Description |
|------|-------------|
| (none) | Gera rascunho, aprovação humana, abre PR |
| `[feature]` | Pasta em `sdd/wip/` ou `sdd/features/` |
| `--draft` | `gh pr create --draft` |

**Pre-requisite**: Implementação concluída; commits na branch de feature; `gh` autenticado.

**See also**: `framework/templates/pull-request-template.md`, `references/pr-*.md`

---

## Purpose

Fecha o loop até o GitHub **sem** automação cega: o agente **preenche** o modelo de PR; o dev **aprova, nega ou pede ajuste**; só então o PR sobe.

Não substitui review de código nem merge — apenas cria o PR com corpo consistente SDD.

---

## Workflow (happy path)

### Step 1: Resolve feature

1. If arg → `sdd/wip/[feature]` or archived `sdd/features/[feature]`
2. Else → read active WIP (`meta.md` com stage recente) or AskUserQuestion se ambíguo
3. Read `meta.md`, specs, `tasks.json`, `4-tests/test-plan.md`, `tests-manifest.json`, `implementation-summary.md` se existir

### Step 2: Pre-checks (BLOCKING)

| Check | If fail |
|-------|---------|
| Not on `main`/`master` (feature branch) | STOP — peça checkout na branch de feature |
| `git status` limpo ou só untracked gitignored | WARN se staged não commitado |
| Commits existem vs base provável | WARN se branch vazia |
| `gh auth status` | STOP — instruir login; oferecer Outros (PR manual) |

> **ONLY IF** needing gh/auth/branch details:
> Read `references/pr-prechecks.md`.

### Step 3: Resolve template

Ordem:

1. `.github/pull_request_template.md` no **projeto alvo** (se existir — base estrutural)
2. Senão → `development-agents/framework/templates/pull-request-template.md`

Mesclar seções SDD (Contexto, Testes) mesmo quando o template do repo for minimalista.

> **ONLY IF** needing fill rules per section:
> Read `references/pr-generate-draft.md`.

### Step 4: Generate draft

Write **`sdd/wip/[feature]/pr-draft.md`** (ou `sdd/features/...` se arquivada).

Preencher com dados reais — não deixar placeholders genéricos onde a info existe.

Show the full draft in chat (summary + path).

### Step 5: Human review (MANDATORY)

**⛔ INVOKE TOOL** — gate; always include **Outros**:

```
AskUserQuestion(
  questions=[{
    "question": "Revise o rascunho do PR (sdd/wip/.../pr-draft.md). Como proceder?",
    "header": "PR Draft",
    "options": [
      {"label": "Aprovar e abrir PR (Recommended)", "description": "Próximo passo: escolher branch base e publicar via gh"},
      {"label": "Negar / cancelar", "description": "Não abrir PR; manter rascunho para edição manual"},
      {"label": "Outros", "description": "Descreva ajustes no texto, título, escopo ou outro caminho (texto livre)"}
    ],
    "multiSelect": false
  }]
)
```

Shape: `references/ask-user-question-outros.md`.

| Resposta | Ação |
|----------|------|
| Aprovar | → Step 6 |
| Negar | STOP; informar path do rascunho |
| Outros | Aplicar ajustes pedidos → regenerar/atualizar `pr-draft.md` → **voltar Step 5** |

Nunca chamar `gh pr create` sem aprovação explícita neste passo.

> **ONLY IF** needing iteration examples:
> Read `references/pr-approval-flow.md`.

### Step 6: Target base branch (MANDATORY)

Antes de publicar, **sempre** perguntar branch **base** (merge target):

```
AskUserQuestion(
  questions=[{
    "question": "Para qual branch base este PR deve apontar? (head = branch atual)",
    "header": "Base branch",
    "options": [
      {"label": "master", "description": "Branch principal do repo"},
      {"label": "main", "description": "Branch principal (main)"},
      {"label": "develop", "description": "Branch de integração develop"},
      {"label": "Outros", "description": "Informe o nome exato da branch base (texto livre)"}
    ],
    "multiSelect": false
  }]
)
```

Confirmar com `git branch -a` / `git remote show origin` quando útil. Não assumir base sem resposta.

### Step 7: Push + create PR

1. `git push -u origin HEAD` se upstream ausente (pedir confirmação se push não foi solicitado)
2. Título: Conventional ou `[JIRA-1234] resumo` conforme `sdd/PROJECT.md`
3. Corpo: conteúdo de `pr-draft.md`
4. `gh pr create --base <base> --title "..." --body-file <path>` (+ `--draft` se flag)

> **ONLY IF** needing exact gh commands / PowerShell:
> Read `references/pr-create-gh.md`.

### Step 8: Result

Informar URL do PR, base, head, e que review/merge são manuais.

Opcional: anotar link em `meta.md` notes ou `implementation-summary.md`.

---

## Behavior by Mode

| Mode | Behavior |
|------|----------|
| Standard | Sempre Steps 5–6 (aprovação + base branch) |
| Express | **Mesmo gate** — PR nunca auto-abre sem aprovação humana |

---

## Optional flags (lazy-loaded)

| Flag / condition | Reference |
|------------------|-----------|
| Pre-checks gh/auth | `references/pr-prechecks.md` |
| Fill draft from artifacts | `references/pr-generate-draft.md` |
| Review loop | `references/pr-approval-flow.md` |
| gh create | `references/pr-create-gh.md` |

## AI Agent Instructions

1. Draft first, publish last — never skip Step 5.
2. Always ask base branch (Step 6) — never guess `master` vs `main`.
3. Prefer project `.github/pull_request_template.md` when present.
4. Use `gh` for create; if blocked, save draft and STOP with Outros path (abrir manual no GitHub).
5. Do not commit `development-agents/`, `.cursor/`, `.claude/`, `sdd/` — warn if staged.

## Related Commands

`/sdd.finish`, `/sdd.build`, skill `commit-workflow`, `framework/PLAYBOOK.md`
