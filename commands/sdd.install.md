---
name: sdd.install
description: Instala development-agents no projeto via agente (alternativa a install.ps1/install.sh). Cria .cursor/, .claude/, sdd/ e atualiza .gitignore para o repo do app subir limpo. Use quando scripts estiverem bloqueados.
model: sonnet
argument-hint: "[--cursor-only|--claude-only] [--target <path>] [--from <pack-path>]"
---

### HOW TO READ THIS COMMAND

When you see a block like this:

⛔ INVOKE TOOL (do not print this, CALL the tool):
AskUserQuestion(questions=[{...}])

This is a TOOL CALL you must execute, not content to display.

# Command: /sdd.install

**Description**: Instala o pack `development-agents` no projeto **sem rodar scripts** — cria pastas, copia arquivos e **atualiza `.gitignore`** para que `development-agents/`, `.cursor/`, `.claude/` e `sdd/` **nunca subam no commit** (mesmo resultado de `install.ps1` / `install.sh`).

**Uso**:
- `/sdd.install` → Cursor + Claude (pergunta se ambíguo)
- `/sdd.install --cursor-only` → só adapter Cursor
- `/sdd.install --claude-only` → só adapter Claude Code
- `/sdd.install --target E:\Projects\meu-app` → instalar em outro diretório
- `/sdd.install --from E:\packs\development-agents` → pack em caminho customizado

---

## Quick Help

| Flag | Descrição |
|------|-----------|
| (nenhuma) | Instala Cursor + Claude |
| `--cursor-only` | Só `.cursor/` + rule SDD |
| `--claude-only` | Só `.claude/commands|agents|skills` |
| `--target <path>` | Raiz do projeto alvo (default: workspace atual) |
| `--from <path>` | Raiz do pack (default: detecta `development-agents/` ou raiz do hub) |

**Exemplos**:

```bash
/sdd.install
/sdd.install --cursor-only
/sdd.install --target E:\Projects\meu-app
/sdd.install --from E:\Program Cursor\development-agents
```

**Ver também**: `development-agents/README.md` (instalação via script) · agent `development-agents-installer`

---

## Fluxo de execução

### 1. Delegar ao agente

Siga **integralmente** as instruções em (primeiro caminho que existir):

- `agents/development-agents-installer.md` (hub / pack na raiz)
- `development-agents/agents/development-agents-installer.md` (pack em subpasta no projeto)

Você é o executor: use Read, Write, Glob, Shell — **nunca** execute `install.ps1` nem `install.sh`.

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

| Flag | Efeito |
|------|--------|
| `--cursor-only` | Pular passo Claude (`.claude/`) |
| `--claude-only` | Pular passo Cursor (`.cursor/`) |
| `--target` | `TARGET_DIR` do agente |
| `--from` | `PACK_DIR` do agente |

### 4. Gate obrigatório — `.gitignore` (projeto da empresa)

⛔ **BLOCKING** — não finalize `/sdd.install` sem este passo quando o alvo **não** for o hub.

⛔ **NUNCA** `git add`, `git commit` ou `git push` durante a instalação — só se o usuário pedir explicitamente para commitar.

| `.gitignore` no projeto | O que fazer |
|-------------------------|-------------|
| **Já existe** | **Append** do snippet (não sobrescrever o arquivo) |
| **Não existe** | **Criar** `.gitignore` com o snippet |

1. Ler `PACK_DIR/framework/templates/project-gitignore.snippet`
2. Marker idempotente: `# development-agents pack (instalacao local`
3. Se marker já presente → skip
4. Alteração fica **só local** — usuário decide se commita o `.gitignore` depois

Pastas ignoradas:

```
development-agents/
.cursor/
.claude/
sdd/
```

5. **Não** criar `AGENTS.md` nem `CLAUDE.md` na raiz do projeto alvo.
6. Ao final: informar `git status` — pack/adapters não devem aparecer como untracked (após o ignore surtir efeito).

### 5. Após instalar

Sugerir ao usuário:

1. `git status` — confirmar repo limpo
2. `/sdd.doctor` — validar que nada conflita com o kit
3. `/sdd.project` — se não existir `sdd/PROJECT.md`
4. Fluxo normal: checkout main/master + pull (manual) → `/sdd.start`

---

## Comparação: script vs agente

| | `install.ps1` / `install.sh` | `/sdd.install` |
|--|------------------------------|----------------|
| Bloqueio de script | Pode falhar | Funciona (agente usa ferramentas) |
| Velocidade | Mais rápido | Um pouco mais lento |
| Interação | Nenhuma | Pode perguntar adapters / paths |
| Resultado | Idêntico (inclui `.gitignore`) | Idêntico (inclui `.gitignore`) |

**Recomendação**: script quando permitido; `/sdd.install` quando bloqueado ou preferência do usuário.

---

## Troubleshooting

| Problema | Solução |
|----------|---------|
| Pack não encontrado | Copiar `development-agents/` para a raiz do projeto ou usar `--from` |
| Shell bloqueado | Agente copia via Read/Write arquivo a arquivo |
| `.cursor/` já tem skills próprias | Pack sobrescreve só skills SDD com mesmo nome; avisar antes |
| Pastas aparecem no `git status` | Rodar install de novo ou adicionar manualmente o snippet em `framework/templates/project-gitignore.snippet` |
| Instalação parcial anterior | Rodar `/sdd.install` de novo — é idempotente |
