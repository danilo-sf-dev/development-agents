---
name: sdd.install
description: Instala development-agents no projeto via agente — único caminho de instalação, sem scripts .sh/.ps1. Detecta ou pergunta o harness (Claude Code / Cursor / Codex CLI / Genérico) e instala o adapter correspondente, cria sdd/ e atualiza .gitignore para o repo do app subir limpo.
model: sonnet
argument-hint: "[--harness claude|cursor|codex|generic[,...]] [--target <path>] [--from <pack-path>]"
---

### HOW TO READ THIS COMMAND

When you see a block like this:

⛔ INVOKE TOOL (do not print this, CALL the tool):
AskUserQuestion(questions=[{...}])

This is a TOOL CALL you must execute, not content to display.

# Command: /sdd.install

**Description**: Instala o pack `development-agents` no projeto **sem rodar scripts** — cria pastas, copia arquivos e **atualiza `.gitignore`** para que `development-agents/`, `.cursor/`, `.claude/`, `.agents/` e `sdd/` **nunca subam no commit**. É o único caminho de instalação do pack.

O pack (`agents/`, `skills/`, `commands/`, `framework/`) é harness-agnostic na intenção — ver `framework/_shared/harness-capabilities.md`. Este comando é o ponto onde a intenção vira um adapter real: ele detecta ou pergunta qual harness o projeto usa, e instala **só** o que está documentado em `adapters/<harness>/README.md` para aquele harness. Nível de suporte declarado hoje: **Claude Code** = Supported (native) · **Cursor** = Supported (com gaps documentados) · **Codex CLI** = Experimental · **Genérico** = Fallback only. Ver seção "Suporte por harness" abaixo antes de prometer algo ao usuário.

**Uso**:

- `/sdd.install` → detecta o harness automaticamente; pergunta se ambíguo (sempre com opção "Outros")
- `/sdd.install --harness claude` → instala só o adapter Claude Code, sem perguntar (bootstrap não-interativo)
- `/sdd.install --harness cursor` → instala só o adapter Cursor
- `/sdd.install --harness codex` → instala só o adapter Codex CLI (experimental)
- `/sdd.install --harness generic` → instala sem adapter automatizado (só copia o pack + instruções manuais)
- `/sdd.install --harness claude,cursor` → instala mais de um adapter numa chamada só (ex: hub com times em harnesses diferentes)
- `/sdd.install --target E:\Projects\meu-app` → instalar em outro diretório
- `/sdd.install --from E:\packs\development-agents` → pack em caminho customizado

`--cursor-only` e `--claude-only` continuam funcionando como alias de `--harness cursor` / `--harness claude` (compatibilidade com scripts/automações existentes).

---

## Quick Help

| Flag                              | Descrição                                                                     |
| --------------------------------- | ----------------------------------------------------------------------------- |
| (nenhuma)                         | Detecta o harness no projeto alvo; pergunta se ambíguo ou sem sinal confiável |
| `--harness claude`                | Só adapter Claude Code — Supported (native)                                   |
| `--harness cursor`                | Só adapter Cursor — Supported (gaps documentados)                             |
| `--harness codex`                 | Só adapter Codex CLI — **Experimental**                                       |
| `--harness generic`               | Sem adapter automatizado — Fallback only, só instruções                       |
| `--harness a,b`                   | Múltiplos adapters numa instalação só                                         |
| `--cursor-only` / `--claude-only` | Alias legado de `--harness cursor` / `--harness claude`                       |
| `--target <path>`                 | Raiz do projeto alvo (default: workspace atual)                               |
| `--from <path>`                   | Raiz do pack (default: detecta `development-agents/` ou raiz do hub)          |

**Exemplos**:

```bash
/sdd.install
/sdd.install --harness cursor
/sdd.install --harness claude,cursor --target E:\Projects\meu-app
/sdd.install --from E:\Program Cursor\development-agents
```

## Suporte por harness (não prometa mais do que isto)

| Harness     | Nível declarado          | O que falta (se algo falta)                                                                                                                                                  |
| ----------- | ------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Claude Code | **Supported (native)**   | Nada — implementação de referência                                                                                                                                           |
| Cursor      | **Supported (com gaps)** | Sem pasta `commands/` compartilhável; delegação isolada e perguntas estruturadas degradam — ver `adapters/cursor/README.md`                                                  |
| Codex CLI   | **Experimental**         | Sem `ASK_USER` estruturado, sem isolamento de workspace, sem pasta de agentes/comandos própria — ver `adapters/codex/README.md`. Não validado end-to-end pelos mantenedores. |
| Genérico    | **Fallback only**        | Nenhuma automação — só o pack copiado + instruções em texto — ver `adapters/generic/README.md`                                                                               |

**Ver também**: `development-agents/README.md` · `framework/_shared/harness-capabilities.md` · agent `development-agents-installer`

---

## Fluxo de execução

### 1. Delegar ao agente

Siga **integralmente** as instruções em (primeiro caminho que existir):

- `agents/development-agents-installer.md` (hub / pack na raiz)
- `development-agents/agents/development-agents-installer.md` (pack em subpasta no projeto)

Você é o executor: use Read, Write, Glob, Bash — nunca busque ou execute um script de instalação externo.

### 2. Pré-requisito mínimo

O pack precisa existir em algum lugar acessível:

- Raiz do workspace com `agents/`, `skills/`, `commands/`, `framework/` (clone do hub), **ou**
- `{workspace}/development-agents/` (pack copiado no projeto), **ou**
- caminho passado em `--from`

Se não houver pack → instruir o usuário a clonar https://github.com/danilo-sf-dev/development-agents e rodar `/sdd.install` de novo.

**Bootstrap (sem adapters ainda):** use no chat:

```
Siga commands/sdd.install.md e instale o pack neste projeto.
```

(ou `development-agents/commands/sdd.install.md` se o pack estiver em subpasta.)

### 3. Flags → comportamento do agente

| Flag                | Efeito                                                                                                       |
| ------------------- | ------------------------------------------------------------------------------------------------------------ |
| `--harness <lista>` | Define `HARNESS_LIST` diretamente — pula a detecção/pergunta do Passo 1 do agente (bootstrap não-interativo) |
| `--cursor-only`     | Alias de `--harness cursor`                                                                                  |
| `--claude-only`     | Alias de `--harness claude`                                                                                  |
| `--target`          | `TARGET_DIR` do agente                                                                                       |
| `--from`            | `PACK_DIR` do agente                                                                                         |

Sem nenhuma flag de harness → o agente roda a detecção automática descrita em `agents/development-agents-installer.md` Passo 1 (sinais `.claude/`, `.cursor/`, `AGENTS.md`/`.agents/skills/` já existentes no projeto alvo; confirma se um sinal confiável for encontrado, pergunta com opção "Outros" se ambíguo ou sem sinal).

### 4. Gate obrigatório — `.gitignore` (projeto da empresa)

⛔ **BLOCKING** — não finalize `/sdd.install` sem este passo quando o alvo **não** for o hub.

⛔ **NUNCA** `git add`, `git commit` ou `git push` durante a instalação — só se o usuário pedir explicitamente para commitar.

| `.gitignore` no projeto | O que fazer                                        |
| ----------------------- | -------------------------------------------------- |
| **Já existe**           | **Append** do snippet (não sobrescrever o arquivo) |
| **Não existe**          | **Criar** `.gitignore` com o snippet               |

1. Ler `PACK_DIR/framework/templates/project-gitignore.snippet`
2. Marker idempotente: `# development-agents pack (instalacao local`
3. Se marker já presente → skip
4. Alteração fica **só local** — usuário decide se commita o `.gitignore` depois

Pastas ignoradas:

```
development-agents/
.cursor/
.claude/
.agents/
sdd/
```

5. `AGENTS.md`/`CLAUDE.md` na raiz do projeto alvo **podem** ser escritos, mas só via merge idempotente de seção marcada (`## SDD Kit`) — nunca overwrite do arquivo inteiro. Ver `commands/references/project-instructions-sync.md` e regra B-16 em `framework/standards/boundaries.md`.
6. Ao final: informar `git status` — pack/adapters não devem aparecer como untracked (após o ignore surtir efeito).

### 5. Após instalar

Sugerir ao usuário:

1. `git status` — confirmar repo limpo
2. `/sdd.doctor` — validar que nada conflita com o kit
3. `/sdd.project` — se não existir `sdd/PROJECT.md`
4. Fluxo normal: checkout main/master + pull (manual) → `/sdd.start`

---

## Troubleshooting

| Problema                          | Solução                                                                                                     |
| --------------------------------- | ----------------------------------------------------------------------------------------------------------- |
| Pack não encontrado               | Copiar `development-agents/` para a raiz do projeto ou usar `--from`                                        |
| Bash indisponível no harness      | Agente copia via Read/Write arquivo a arquivo                                                               |
| `.cursor/` já tem skills próprias | Pack sobrescreve só skills SDD com mesmo nome; avisar antes                                                 |
| Pastas aparecem no `git status`   | Rodar install de novo ou adicionar manualmente o snippet em `framework/templates/project-gitignore.snippet` |
| Instalação parcial anterior       | Rodar `/sdd.install` de novo — é idempotente                                                                |
