---
name: sdd-installer
description: Instala o pack development-agents em um projeto alvo. Único caminho de instalação do pack — sem scripts .sh/.ps1. Detecta ou pergunta o harness (Claude Code / Cursor / Codex CLI / Genérico), instala o(s) adapter(s) correspondente(s) em adapters/<harness>/, cria sdd/ e atualiza .gitignore para repo limpo. Invocado via /sdd.install.
model_role: EXECUTION
---

# development-agents Installer — Bootstrap Skill

> **Execution requirement**: none — this runs inline (`INVOKE_PROCEDURE`), in the calling session's own context, using its own tools. There is nothing to offload: `/sdd.install`'s entire session purpose is installation, so there's no larger flow's context to protect. This Skill is invoked by **direct-file-follow** (the calling session reads and follows this file's instructions, per `CONTINUE_WORKFLOW` in `framework/_shared/harness-capabilities.md`), the same mechanism used for bootstrap before the pack is even installed — see "Bootstrap, before the pack exists in the target project" below.

Você instala o pack **development-agents** em um projeto alvo usando suas próprias ferramentas (Bash, Read, Write) — nunca busca nem executa um script de instalação externo. Este é o único mecanismo de instalação do pack.

**Importante sobre agnosticismo**: o pack (`skills/`, `commands/`, `framework/`) é harness-agnostic _na intenção_ — veja `framework/_shared/harness-capabilities.md`. Mas cada harness precisa do seu próprio adapter pra essa intenção virar comportamento real. Este Skill é o **compilador de adapter**: detecta ou pergunta qual(is) harness(es) o projeto alvo usa, e instala exatamente o adapter documentado em `adapters/<harness>/README.md` — nunca finja suporte que o adapter não documenta. Nível de suporte declarado por harness: Claude Code = Supported (native); Cursor = Supported (com gaps documentados); Codex CLI = Experimental; Genérico = Fallback only. Nunca anuncie um nível diferente do que `adapters/<harness>/README.md` diz.

## Bootstrap, antes do pack existir no projeto alvo

Este Skill **é** o mecanismo de bootstrap — não existe um passo separado. Antes de `/sdd.install` (ou de `.claude/skills/sdd-installer/`) existir no projeto alvo, invoque este arquivo diretamente:

```
Siga skills/sdd-installer/SKILL.md e instale o pack neste projeto.
```

(ou `development-agents/skills/sdd-installer/SKILL.md` se o pack estiver em subpasta.)

Isso funciona porque `commands/sdd.install.md` já delega para este arquivo via leitura direta (`CONTINUE_WORKFLOW`, não uma chamada de subagente nomeado) — o mesmo mecanismo funciona antes ou depois da instalação estar completa, em qualquer harness que consiga ler um arquivo e seguir instruções em texto.

## Quando usar

- Sempre — é o único instalador do pack, chamado via `/sdd.install`
- Pack já foi copiado manualmente e falta só "plugar" adapters

## O que NÃO fazer

> Regras canônicas: `framework/standards/boundaries.md` — section **`sdd-installer`** (B-02, B-14, B-15, B-16).

---

## Passo 0 — Resolver caminhos

1. **Pack source** (`PACK_DIR`):
   - Se `{workspace}/development-agents/skills/` existir → `PACK_DIR = {workspace}/development-agents/`
   - Senão, se `{workspace}/skills/` existir (hub na raiz) → `PACK_DIR = {workspace}/`
   - Senão, perguntar caminho absoluto ao usuário.

2. **Target** (`TARGET_DIR`): raiz do projeto onde instalar.
   - Default: workspace root atual.
   - Se o usuário passou outro caminho, usar esse.

3. Validar pack:

```
PACK_DIR/skills/     ✓
PACK_DIR/commands/   ✓
PACK_DIR/framework/  ✓
```

Se faltar algo → parar e reportar pack inválido.

4. **Hub vs projeto alvo** — definir `SKIP_PACK_COPY` e `SKIP_GITIGNORE`:

| Condição                                     | `SKIP_PACK_COPY` | `SKIP_GITIGNORE` |
| ----------------------------------------------- | ------------------- | ------------------- |
| `PACK_DIR` == `TARGET_DIR` (hub na raiz)     | true             | true             |
| Pack em subpasta e target é workspace do app | false            | false            |

---

## Passo 1 — Detectar ou perguntar harness

Fluxo: **detectar → confiável? → sim: confirmar / não: perguntar → selecionar adapter(s) → instalar.**

### 1a. Flag explícita (pula detecção inteiramente)

Se o usuário passou `--harness <lista>` (valores: `claude`, `cursor`, `codex`, `generic`, separados por vírgula para instalar mais de um — ex: `--harness claude,cursor`), use exatamente essa lista e vá para o Passo 2. As flags legadas `--claude-only`/`--cursor-only`/nenhuma-flag(=claude+cursor) continuam funcionando como alias de `--harness claude` / `--harness cursor` / `--harness claude,cursor`, para não quebrar automações existentes.

### 1b. Detecção automática (sem flag)

Verificar em `TARGET_DIR`, cada um é um **sinal independente**, não uma suposição isolada:

| Sinal                                                                                        | Aponta para                                         |
| ----------------------------------------------------------------------------------------------- | ------------------------------------------------------ |
| `.claude/` já existe (settings, commands, ou skills)                                         | Claude Code                                         |
| `.cursor/` já existe (rules, skills, ou commands)                                            | Cursor                                              |
| `AGENTS.md` na raiz já existe e **não** foi criado por este pack (sem o marker `## SDD Kit`) | Codex CLI (ou outro harness que já lê `AGENTS.md`)  |
| `.agents/skills/` já existe                                                                  | Codex CLI / harness compatível com `agentskills.io` |
| Nenhum dos acima                                                                             | Sem sinal confiável                                 |

**Não assumir o harness só porque uma pasta existe se houver ambiguidade** (mais de um sinal presente, ou sinal fraco). Regras:

- **Exatamente 1 sinal, sem ambiguidade** → tratar como detecção confiável. Confirmar com o usuário (não é blocking-perguntar-do-zero, é confirmar o achado) via `ASK_USER`:

  "Detectei **{harness}** neste projeto (evidência: {sinal}). Instalar o adapter {harness}?" com opções: `Sim, instalar {harness}` | `Selecionar outro harness` | `Instalar múltiplos` | `Outros`.

- **0 sinais, ou 2+ sinais (ambíguo)** → perguntar diretamente, sempre com opção livre, via `ASK_USER`:

  "Qual harness deseja configurar?" com opções: `Claude Code` | `Cursor` | `OpenAI Codex CLI` | `Genérico/Outro` (multiSelect — permitir mais de um, útil pra hub com times em harnesses diferentes) e sempre incluir `Outros` com texto livre.

Resultado do Passo 1: uma lista `HARNESS_LIST` com um ou mais de `claude`, `cursor`, `codex`, `generic`.

---

## Passo 2 — Sincronizar pack canônico

Garantir `TARGET_DIR/development-agents/` com:

- `skills/`, `commands/`, `framework/`, `adapters/`, `config/`, `docs/`
- `AGENTS.md`, `README.md`

**Se `SKIP_PACK_COPY`** (hub na raiz) → pular cópia; pack já está em `PACK_DIR`.

**Se `TARGET_DIR/development-agents/` já é o `PACK_DIR`** → pular cópia.

**Senão** → copiar recursivamente do source para `TARGET_DIR/development-agents/`.

Preferir Bash para cópia em massa (ou o equivalente do harness, se não houver Bash):

```powershell
# Windows
Copy-Item -Path "$PACK_DIR\*" -Destination "$TARGET_DIR\development-agents" -Recurse -Force
```

```bash
# Unix / Git Bash
cp -R "$PACK_DIR"/. "$TARGET_DIR/development-agents"/
```

Se não houver acesso a shell (política corporativa ou harness sem essa tool), copiar pasta a pasta com Read + Write.

---

## Passo 3 — Adapter Claude Code (se `claude` em `HARNESS_LIST`)

Detalhe completo: `adapters/claude-code/README.md`. Nível declarado: **Supported (native)**.

Criar/atualizar:

| Destino                  | Origem                    |
| --------------------------- | ---------------------------- |
| `.claude/commands/`      | `PACK_DIR/commands/*.md` (cópia verbatim — `model_role:` incluído como metadado, sem tradução) |
| `.claude/skills/<nome>/` | `PACK_DIR/skills/<nome>/` (cópia verbatim, `model_role:` incluído como metadado) |

Substituir conteúdo SDD nesses destinos. Também aplicar `WRITE_PROJECT_INSTRUCTIONS` pra `CLAUDE.md` na raiz — ver `commands/references/project-instructions-sync.md` (merge idempotente, seção `## SDD Kit`).

**Este instalador não tem responsabilidade nenhuma sobre Model Routing.** `model_role:` é copiado
verbatim, exatamente como qualquer outro campo de frontmatter — este Skill nunca lê nem resolve
`config/model-routing.yaml`. A resolução de `model_role` para um modelo concreto acontece inteiramente
em runtime, no momento de cada dispatch, pelo mecanismo que `adapters/claude-code/README.md` documenta
— nunca em tempo de instalação. Isso significa que editar `config/model-routing.yaml` já é suficiente
para a próxima execução usar o novo valor: **não há nenhum arquivo gerado por este instalador para
regenerar, e reinstalar não é necessário nem tem efeito algum sobre Model Routing.**

---

## Passo 4 — Adapter Cursor (se `cursor` em `HARNESS_LIST`)

Detalhe completo: `adapters/cursor/README.md`. Nível declarado: **Supported (adapter, com gaps documentados)** — `DELEGATE_ISOLATED`, `VALIDATOR_ISOLATED` e `ASK_USER` degradam, ver `framework/_shared/harness-capabilities.md`.

Criar/atualizar:

| Destino                          | Origem                                       |
| ----------------------------------- | ----------------------------------------------- |
| `.cursor/skills/<nome>/`         | `PACK_DIR/skills/<nome>/`                    |
| `.cursor/rules/sdd-workflow.mdc` | conteúdo fixo em `adapters/cursor/README.md` |

Cursor **não** recebe pasta `commands/` (não existe equivalente repo-compartilhável) — a regra `sdd-workflow.mdc` instrui a ler `development-agents/commands/*.md` diretamente. Isso é uma limitação documentada do harness, não um bug do adapter.

---

## Passo 4b — Adapter OpenAI Codex CLI (se `codex` em `HARNESS_LIST`)

Detalhe completo: `adapters/codex/README.md`. Nível declarado: **Experimental** — não valide como "supported" nesta instalação; avise o usuário explicitamente.

Criar/atualizar:

| Destino                       | Origem                                                                                                                       |
| -------------------------------- | ---------------------------------------------------------------------------------------------------------------------------- |
| `.agents/skills/<nome>/`      | `PACK_DIR/skills/<nome>/` (mesmo formato `SKILL.md`, path de descoberta real do `agentskills.io`)                            |
| `AGENTS.md` (raiz do projeto) | `WRITE_PROJECT_INSTRUCTIONS` — merge idempotente, seção `## SDD Kit`, ver `commands/references/project-instructions-sync.md` |

**Não** criar `.codex/` — a convenção real do Codex CLI é `AGENTS.md` na raiz, não uma subpasta. **Não** popular pasta de comandos — o formato de prompt do Codex (`~/.codex/prompts/`) não tem hoje um gerador neste instalador; a sessão principal deve ler `commands/*.md` como referência direta. Todas as 12 Skills migradas (`sdd-explorer`, `sdd-debugger`, etc.) **agora instalam de verdade** em `.agents/skills/` no Codex — diferente do formato `agents/` anterior, que nunca era copiado ali. Avisar essa melhoria no resumo final (Passo 8).

---

## Passo 4c — Adapter Genérico (se `generic` em `HARNESS_LIST`)

Detalhe completo: `adapters/generic/README.md`. Nível declarado: **Fallback only** — nenhuma automação, só instruções em Markdown.

Não criar pasta nenhuma além do próprio `development-agents/` (já sincronizado no Passo 2). Ao final (Passo 8), imprimir o bloco de instruções manuais definido em `adapters/generic/README.md`.

---

## Passo 5 — Diretórios SDD

Criar se não existirem:

```
sdd/wip/
sdd/features/
```

**Não** criar nem sobrescrever `sdd/PROJECT.md` nem `sdd/backlog.md`.

---

## Passo 6 — `.gitignore` (projeto alvo) ⛔ BLOCKING

**Pular somente** se `SKIP_GITIGNORE == true` (instalação no hub).

A maioria dos projetos **já tem** `.gitignore`. O instalador **não substitui** — só adiciona o bloco do pack.

### Procedimento obrigatório

1. Ler snippet: `PACK_DIR/framework/templates/project-gitignore.snippet`
2. Verificar `{TARGET_DIR}/.gitignore`:

| Situação                                       | Ação                                                   |
| ------------------------------------------------- | --------------------------------------------------------- |
| `.gitignore` **existe** e **não** tem o marker | **Append** do snippet ao final (linha em branco antes) |
| `.gitignore` **existe** e **já** tem o marker  | Skip — avisar que regras já estão lá                   |
| `.gitignore` **não existe**                    | **Criar** arquivo com conteúdo do snippet              |

3. Confirmar que contém (append ou arquivo novo):

```
development-agents/
.cursor/
.claude/
.agents/
sdd/
```

4. **Somente local** — a alteração no `.gitignore` fica no disco; **não** rodar `git add` nem `git commit`. O usuário decide depois se versiona o `.gitignore`.

5. Opcional: `git status` para mostrar ao usuário o que ficou ignorado vs modificado.

### Regras — `AGENTS.md`/`CLAUDE.md` na raiz (B-16 atualizada)

Escrever `AGENTS.md` (adapter Codex) ou `CLAUDE.md` (adapter Claude Code) na raiz do projeto alvo **é permitido**, mas **somente** via `WRITE_PROJECT_INSTRUCTIONS` (merge idempotente por seção marcada `## SDD Kit`, nunca overwrite do resto do arquivo) — ver `commands/references/project-instructions-sync.md` e `framework/standards/boundaries.md` regra B-16. **Nunca** sobrescrever um `AGENTS.md`/`CLAUDE.md` existente por completo; se a seção marcada já existir, apenas atualizá-la.

Se usuário já commitou pack/adapters antes → avisar: `git rm -r --cached development-agents .cursor .claude .agents sdd` (usuário executa; não commite por ele)

---

## Passo 7 — Verificação

Contar e reportar, para cada harness em `HARNESS_LIST`:

- **claude**: commands em `.claude/commands/`, skills em `.claude/skills/`, seção `## SDD Kit` em `CLAUDE.md`
- **cursor**: skills em `.cursor/skills/`, rule `sdd-workflow.mdc`
- **codex**: skills em `.agents/skills/`, seção `## SDD Kit` em `AGENTS.md`
- **generic**: só confirmar que `development-agents/` está sincronizado (nenhum outro artefato esperado)
- `sdd/wip/` e `sdd/features/` existem
- `.gitignore` contém regras `development-agents` (projeto alvo) — **obrigatório**
- `git status` limpo (pack/adapters não listados) — reportar ao usuário

Opcional: sugerir `/sdd.doctor` para validar configuração.

---

## Passo 8 — Resumo ao usuário

Responder em português com, adaptando as linhas de adapter para os harnesses efetivamente instalados e **incluindo o nível de suporte declarado de cada um** (nunca omitir isso — ver `framework/_shared/harness-capabilities.md`):

```
✓ development-agents instalado

  Pack     : {TARGET_DIR}/development-agents/
  Claude Code : sim/não — Supported (native)
  Cursor      : sim/não — Supported (com gaps: delegacao isolada e perguntas estruturadas degradam)
  Codex CLI   : sim/não — Experimental (sem ASK_USER estruturado, sem isolamento de workspace)
  Generico    : sim/não — Fallback only (sem automacao, so instrucoes em Markdown)
  Skills   : N (por harness que suporta pasta de skills)
  Commands : N (só Claude Code tem pasta commands/ dedicada)
  Gitignore: atualizado (pack local, nao versiona)

  O repositorio do app permanece limpo — apenas src/ e codigo sobem no commit.

Proximos passos:
  1. git status — confirmar repo limpo
  2. /sdd.project     (se não houver sdd/PROJECT.md)
  3. checkout main/master + pull (manual)
  4. /sdd.start "JIRA-1234 resumo"
  5. /sdd.spec functional --include "<card ou link>"
```

Se `codex` ou `generic` foram instalados, imprimir também as seções "Known gaps" de `adapters/codex/README.md` / `adapters/generic/README.md` — o usuário precisa saber exatamente onde a automação para.

## Cenários comuns

| Situação                                   | Ação                                            |
| ---------------------------------------------- | ---------------------------------------------------- |
| Só copiou `development-agents/` no projeto | Rodar este Skill: cria adapters + sdd/          |
| Pack no hub, projeto em outro path         | Perguntar `TARGET_DIR` absoluto                 |
| Reinstalar / atualizar pack                | Sobrescrever adapters SDD; preservar PROJECT.md |
| Script bloqueado                           | Este Skill é o caminho recomendado              |
