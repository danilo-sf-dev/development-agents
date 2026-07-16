# Resumo — development-agents

Documento de referência do que foi planejado, decidido e implementado neste repositório.

**Repositório:** https://github.com/danilo-sf-dev/development-agents  
**Data:** julho/2026

---

## 1. Objetivo

Criar um **time de desenvolvimento agêntico** portátil e **agnóstico** (linguagem e IDE) para executar tarefas de implementação e bugfix com workflow **Spec-Driven Development (SDD)**:

```
Spec → Plan → Test → Dev → Review → PR
```

Com **gates humanos** de aprovação (spec, plan/tasks, testes, conclusão) e foco em **arquivos soltos** (agents, skills, commands) que podem ser levados para Cursor, Claude Code, VS Code, Kiro ou outras ferramentas — sem depender de features nativas de uma plataforma.

---

## 2. Decisões de arquitetura

| Decisão | Motivo |
|---------|--------|
| Pack central em um único repo hub | Evitar copiar/colar agents de projeto em projeto |
| **Language-/platform-agnostic** | Funcionar com Java, TypeScript, Python, Go, Rust, mobile, etc. |
| Stack resolvida no **projeto alvo** | `detect-language.sh`, `detect-stack.sh`, `sdd/PROJECT.md` — não hardcoding corporativo |
| Hub na **raiz** do git (sem subpasta) | Clone = pack pronto; `development-agents/` só existe no projeto alvo após install |
| Instalação gera adapters locais | `.cursor/`, `.claude/`, `sdd/` — nunca versionados no repo da empresa |
| Agente **nunca commita** sozinho | `.gitignore` e pastas ficam locais; só o dev commita se quiser |
| Git main/master antes do `/sdd.start` | **Manual** pelo dev; o agente foca do `start` em diante |
| Graphify **opcional** | Atualiza contexto do graphify, não entra no commit |
| **Tests-first** entre plan e build | Testes aprovados e falhando (red) antes de implementar |

---

## 3. Origem do material

Export seletivo e limpeza a partir de duas pastas legadas (já **removidas** do repo):

- `sdd-kit/` — núcleo SDD (agents, skills, commands, framework)
- `cursor/` — agents/skills do Cursor, incluindo inspiração para `commit-workflow`

O que ficou foi generalizado; referências a Mercado Libre, Fury, Nordic, Everest, Andes, furycloud, LTP e paths `sdd-kit/` foram removidas ou substituídas.

---

## 4. Estrutura final do repositório (hub)

```
development-agents/          ← raiz do git (este repo)
├── AGENTS.md                # Pipeline e papéis do time
├── MANIFEST.md              # Inventário do export + cleanup
├── README.md                # Instalação e uso rápido
├── RESUMO.md                # Este documento
├── install.sh / install.ps1 # Instaladores
├── agents/                  # 11 subagents
├── skills/                  # 6 skills de processo
├── commands/                # 20 commands /sdd.*
└── framework/               # Templates, standards, tools SDD
```

### No projeto alvo (após instalação)

```
empresa-app/
├── src/                     ← código do app (versionado)
├── development-agents/      ← pack canônico (gitignored)
├── .cursor/                 ← adapter Cursor (gitignored)
├── .claude/                 ← adapter Claude Code (gitignored)
├── sdd/                     ← workflow local (gitignored)
│   ├── PROJECT.md
│   ├── backlog.md
│   ├── wip/
│   │   └── <feature>/
│   │       ├── 1-functional/
│   │       ├── 2-technical/
│   │       ├── 3-tasks/
│   │       └── 4-tests/     ← tests-first (novo)
│   └── features/
└── .gitignore               ← append com entradas do pack
```

---

## 5. Pipeline SDD

```
/sdd.start
  → /sdd.spec          (Gate 1: aprovar spec funcional/técnica)
  → /sdd.plan          (Gate 2: aprovar tasks)
  → /sdd.test          (Gate 2.5: aprovar testes — tests-first)
  → /sdd.build         (implementar até testes passarem → validar)
  → /sdd.check
  → /sdd.finish        (Gate 3: conclusão e arquivo)
```

**Atalho:** `/sdd.go` orquestra start → … → finish em modo express (inclui `/sdd.test`).

### Papéis mapeados

| Papel | Componente |
|-------|------------|
| Spec Writer | `/sdd.spec` + agent `sdd-explorer` |
| Arquiteto | `sdd-system-designer` + `/sdd.plan` |
| Test Writer | `/sdd.test` + agents `sdd-small-test-writer`, `sdd-large-test-writer` |
| Developer | `sdd-implementer` + `/sdd.build` |
| Code Reviewer | skill `sdd-code-reviewer` + agent `sdd-validator-runner` |
| Orquestrador | `/sdd.go`, `/sdd.start` + skill `sdd-kit-expert` |
| Instalador | `/sdd.install` + agent `development-agents-installer` |
| Commit | skill `commit-workflow` |

---

## 6. Inventário implementado

### Agents (11)

| Agent | Função |
|-------|--------|
| `development-agents-installer` | Instala pack sem script |
| `sdd-system-designer` | Spec técnica / arquitetura |
| `sdd-explorer` | Descoberta read-only (brownfield) |
| `sdd-implementer` | Implementação |
| `sdd-small-test-writer` | Testes unit/integration (`/sdd.test`) |
| `sdd-large-test-writer` | Testes E2E (opcional) |
| `sdd-validator-runner` | Gate automático pós-código |
| `sdd-layer-analyzer` | Consistência spec ↔ código |
| `sdd-debugger` | RCA / bugs profundos |
| `sdd-backlog-manager` | Ops de `sdd/backlog.md` |
| `sdd-project-wizard` | Setup `sdd/PROJECT.md` |

### Skills (6)

| Skill | Função |
|-------|--------|
| `sdd-kit-expert` | Manual do workflow SDD |
| `sdd-code-reviewer` | Code review bloqueante |
| `sdd-validator` | Build/compliance genérico |
| `sdd-performance-expert` | Review de performance |
| `context-guardian` | Controle de contexto/tokens |
| `commit-workflow` | Fluxo de commit agnóstico (4 opções) |

### Commands (20)

Inclui: `start`, `spec`, `plan`, **`test`**, `build`, `go`, `check`, `finish`, `fix`, `backlog`, `list`, `cancel`, `rollback`, `doctor`, `help`, `project`, `hub`, `import`, `reverse-eng`, **`install`**.

---

## 7. Commit workflow (`commit-workflow`)

Skill reescrita de forma agnóstica, inspirada no commit-workflow do Cursor original.

### Quatro opções

| Opção | Comportamento |
|-------|---------------|
| **Fluxo completo** | Formatação + testes + validações + commit |
| **Formatar e commit** | Formatação + validações leves + commit |
| **Commit direto** | Revisar diff/status e commitar |
| **Outros** | Usuário descreve fluxo personalizado |

### Regras

- Detecta formatador, testes e stack do **projeto alvo** (não assume Node/Java/etc.)
- Mensagens em **português**, formato **Conventional Commits**
- **Graphify opcional:** se existir no projeto, pergunta se quer atualizar contexto; não bloqueia o commit; `graphify-out/` nunca entra no commit
- Só executa `git commit` com confirmação explícita do usuário

---

## 8. Instalação

Duas formas com **mesmo resultado**:

### Opção A — Scripts

```powershell
# Windows
.\install.ps1 -TargetDir "E:\Projects\meu-app"
.\install.ps1 -TargetDir "E:\Projects\meu-app" -CursorOnly
```

```bash
# Bash / WSL / macOS / Linux
bash install.sh /path/to/meu-app
bash install.sh /path/to/meu-app --cursor-only
```

### Opção B — Agente (script bloqueado)

```
/sdd.install
/sdd.install --cursor-only
/sdd.install --target E:\Projects\meu-app
```

**Bootstrap (primeira vez, sem adapters):**

```
Siga development-agents/commands/sdd.install.md e instale o pack neste projeto.
```

### O que o instalador faz

1. Copia pack para `development-agents/` (exceto se já estiver no hub)
2. Cria adapters `.cursor/` e/ou `.claude/`
3. Cria `sdd/wip/` e `sdd/features/`
4. Atualiza `.gitignore`:
   - **Append** se já existir (nunca sobrescreve)
   - **Cria** se não existir
   - Entradas: `development-agents/`, `.cursor/`, `.claude/`, `sdd/`
5. **Nunca** roda `git add` / `git commit` / `git push`

Snippet canônico: `framework/templates/project-gitignore.snippet`

---

## 9. Fluxo Git acordado

### Manual (você faz antes de cada feature)

1. PR aprovado → branch remota apagada
2. Deleta branch local da feature (opcional)
3. `git checkout main` (ou `master`)
4. `git pull origin main` — traz o que já está em produção
5. A partir daí: `/sdd.start`

### Automático (`/sdd.start`)

- Detecta `main` ou `master`
- Checkout na branch principal
- `git pull --ff-only` (estratégia segura, sem rebase automático)
- Cria nova feature branch (nome da task / card Jira / descrição)

**Não implementado no agente:** fluxo pós-PR (voltar à main, pull) — permanece manual.

---

## 10. Cleanup v1 (generalização)

| Removido | Substituído por |
|----------|-----------------|
| Hardcoding Meli / Fury / Nordic / Everest / Andes | Stack do projeto alvo |
| Paths `sdd-kit/`, `meli/PROJECT.md` | `development-agents/`, `sdd/PROJECT.md` |
| Skills `fury-*`, LTP obrigatório | Opcionais se existirem no projeto |
| Detecção Melis-only | Detecção genérica multi-linguagem |
| Commit workflow acoplado a Next.js/impeccable | `commit-workflow` agnóstico |

### Resolução de stack (ordem canônica)

1. `framework/tools/detect-language.sh`
2. `framework/tools/detect-stack.sh`
3. `sdd/PROJECT.md`
4. Código e specs existentes no repo

---

## 11. Renomeações e reorganização

| Antes | Depois |
|-------|--------|
| Repo `times-agents-coding` | `development-agents` |
| Subpasta `timings-agent/` | Conteúdo na **raiz** do repo |
| Agent `timings-agent-installer` | `development-agents-installer` |
| Pastas `cursor/` e `sdd-kit/` | **Apagadas** (já exportadas) |
| README duplicado na raiz antiga | Removido; `README.md` único no hub |

---

## 12. Fluxo prático — novo no time + card Jira

Cenário: você entrou na empresa, não conhece o projeto, tem um card Jira mal escrito mas com evidências.

### Passo a passo

1. **Instalar o pack** no projeto da empresa (`install.ps1` ou `/sdd.install`)
2. **Configurar projeto:** `/sdd.project` (cria `sdd/PROJECT.md` se não existir)
3. **Atualizar main manualmente:** `git checkout master && git pull origin master`
4. **Iniciar feature:**
   ```
   /sdd.start "JIRA-1234 resumo da tarefa"
   ```
5. **Spec (Gate 1):** `/sdd.spec functional --include "<card>"`
6. **Plan (Gate 2):** `/sdd.plan` → aprovar tasks
7. **Tests (Gate 2.5):** `/sdd.test` → aprovar testes (devem falhar — red)
8. **Build:** `/sdd.build` ou `/sdd.go` (express)
9. **Verificar:** `/sdd.check`
10. **Concluir:** `/sdd.finish` (Gate 3)
11. **Commit:** skill `commit-workflow`
12. **PR:** manual (fora do escopo do pack)

Para brownfield, o agent `sdd-explorer` ajuda na fase de spec.  
Para **prototype**, `/sdd.test` pode ser ignorado automaticamente.

---

## 13. Gate tests-first (implementado)

| Componente | Descrição |
|------------|-----------|
| `/sdd.test` | Escreve testes a partir de specs + tasks; verifica fase **red** |
| Gate humano | Aprovação em `tests-manifest.json` + `meta.md` (`stages.tests`) |
| `/sdd.build` reordenado | Só implementa — não cria testes unit/integration novos |
| Artefatos | `sdd/wip/<feature>/4-tests/` (`test-plan.md`, `tests-manifest.json`) |
| `detect-phase.sh` | Novo stage `tests` (fase 4) antes de `implementation` (fase 5) |
| Prototype | Gate ignorado (`stages.tests.status: skipped`) |
| **Anti-gaming guard** | `/sdd.build` detecta se algum arquivo listado em `tests-manifest.json` foi alterado durante a implementação → bloqueia e pergunta (nunca edita/afrouxa teste aprovado silenciosamente) |

### Fluxo

```
/sdd.plan (aprovar tasks)
  → /sdd.test (escrever testes + edge cases)
  → [Gate humano: aprovar testes — contrato congelado]
  → /sdd.build (implementar até testes passarem)
       │
       └─ se algum teste aprovado for tocado → STOP + AskUserQuestion
            → reverter teste e corrigir código, ou
            → escalar para /sdd.test --refine (novo gate de aprovação)
```

Objetivo: evitar testes escritos só para passar (teste "vira-lata" que nunca falha) **e** evitar que a implementação depois afrouxe/edite o teste aprovado pra fingir sucesso — o contrato só muda passando de novo pelo gate humano.

---

## 14. O que ainda NÃO foi implementado

| Item | Descrição |
|------|-----------|
| Profiles de stack | `profiles/java`, `profiles/nextjs`, etc. (opcionais) |
| Playbook formal | Arquivo dedicado do "primeiro dia" |
| Integração PR automática | Abertura de PR via `gh` — fora do escopo atual |

### Redução de verbosidade — item 3 concluído (ramos raros)

- Fluxos condicionais extraídos para `commands/references/` com lazy-load por flag/condição.
- **10 comandos** com seção `Optional flags (lazy-loaded)` + roteamento flag-first onde aplicável.
- Ramo comum (~90% das chamadas) permanece no arquivo principal; flags (`--reopen`, `--rename`, `--from-backlog`, `--audio`, `--hub`, `--view`, `--batch`, `--focus`, mobile, etc.) só carregam referência quando batem.
- `audio-capture-flow.md` compartilhado entre 7 comandos com `--audio`.
- `start-mobile-claude.md` reutilizado por `/sdd.start` e `/sdd.reverse-eng`.
- Medição: ~13.900 linhas nos 20 comandos + 36 referências (~2.550 linhas) lazy-loaded.

### Cleanup v2 — resíduo quebrado + consolidação de docs (concluído)

Depois do Cleanup v1 (item 1, remoção de resíduo vendor-specific), uma varredura mais profunda
(procurando `**` vazio, espaço duplo, frases quebradas) achou que a limpeza **tinha ficado
incompleta**: um find-and-replace anterior tinha apagado nomes de vendors mas deixado buracos —
bullets com label vazio, frases sem sentido, e o pior: referências `Skill("project-services-architect")`,
`Skill("project-snippets-expert")`, `Skill("project-infra-operations")` e `PROJECT_SERVICES.json`
que **não existem** no pack (skills reais são `sdd-system-designer` e `sdd-implementer`).

O que foi corrigido (~25 arquivos):
- Bullets/frases quebradas em `commands/sdd.build.md`, `sdd.plan.md`, `sdd.start.md`, `sdd.spec.md`,
  `sdd.reverse-eng.md`, `sdd.finish.md`.
- Catálogo de serviços internos proprietário removido de `GLOSSARY.md` e `FAQ.md` — serviços agora
  vêm de `sdd/PROJECT.md`, não de uma lista hardcoded.
- Regra de Dockerfile "`your-registry/base-image` obrigatório" tornada condicional a `sdd/PROJECT.md`
  (não assume mais que todo projeto usa esse registry) em `QUICK_REFERENCE.md`, `AI_AGENT_GUIDELINES.md`,
  `check-rare-workflows.md`, `sdd-validator/SKILL.md`, `sdd-code-reviewer/SKILL.md`.
- Auth `TIGER_TOKEN` + `mcp-remote-proxy` hardcoded em `CONFIGURATION.md` → instrução genérica.
- **Diagrama de pipeline consolidado**: criado `framework/PIPELINE.md` como fonte única (diagrama
  Mermaid, gates, modos, papéis). `AGENTS.md`, `WORKFLOW.md`, `COMMANDS.md`, `QUICK_REFERENCE.md` e
  `skills/sdd-kit-expert/SKILL.md` agora linkam para lá em vez de duplicar o bloco completo.
- Bug real encontrado e corrigido: `WORKFLOW.md` tinha um exemplo "Standard Feature" sem `/sdd.test`
  (esquecido quando o gate tests-first foi adicionado — exatamente o custo de manutenção que motivou
  a consolidação). `COMMANDS.md` também tinha "Total Commands: 17" desatualizado (correto: 20) e a
  tabela de categorias sem `test`/`doctor`/`hub`/`install`.
- Validação: `rg -i 'meli|fury|nordic|everest|andes|furycloud|ltp'` → zero hits reais (fora de
  MANIFEST/RESUMO e falsos positivos de "timeline").

**Gap conhecido, não resolvido**: `COMMANDS.md` documenta `/sdd.skill` (gerenciamento de hooks de
terceiros) que não existe como comando real no pack (`commands/sdd.skill.md` não existe). Decidir se
é uma feature a implementar ou documentação morta a remover.

### P0 + P1 + P2 — Slim happy path (token budget) — concluído

Branch: `chore/slim-command-happy-path`. Meta: arquivo principal ≤400 linhas; refs só com `ONLY IF`.

| Comando | Antes | Depois | Status |
|---------|-------|--------|--------|
| `sdd.spec.md` | ~1805 | **~287** | ✅ P0 |
| `sdd.fix.md` | ~1834 | **~273** | ✅ P0 |
| `sdd.project.md` | ~1671 | **~158** | ✅ P0 |
| `sdd.start.md` | ~1097 | **~199** | ✅ P1 |
| `sdd.reverse-eng.md` | ~1125 | **~386** | ✅ P1 |
| `sdd.build.md` | ~937 | **~230** | ✅ P1 |
| `sdd.finish.md` | ~950 | **~168** | ✅ P1 |
| `sdd.plan.md` | ~672 | **~192** | ✅ P2 |
| `sdd.backlog.md` | ~540 | **~111** | ✅ P2 |

Todos os `commands/sdd*.md` estão ≤400. Detalhes em `commands/references/*`. Scripts one-shot de migração removidos após o corte.

---

## 15. Como validar o pack

1. Confirmar papéis do time em `AGENTS.md` e `MANIFEST.md`
2. Buscar resíduos legados:
   ```bash
   rg -i 'meli|fury|nordic|everest|andes|furycloud|ltp' .
   ```
3. Testar instalação em projeto dummy (script e `/sdd.install`)
4. Confirmar que `git status` no projeto alvo **não** lista `development-agents/`, `.cursor/`, `.claude/`, `sdd/`
5. Rodar fluxo completo: `/sdd.start` → spec → plan → **test** → build → finish

---

## 16. Referências internas

| Arquivo | Conteúdo |
|---------|----------|
| [README.md](./README.md) | Instalação e quick start |
| [AGENTS.md](./AGENTS.md) | Pipeline e papéis |
| [MANIFEST.md](./MANIFEST.md) | Inventário técnico do export |
| [commands/sdd.test.md](./commands/sdd.test.md) | Gate tests-first |
| [commands/sdd.install.md](./commands/sdd.install.md) | Instalação via agente |
| [skills/commit-workflow/SKILL.md](./skills/commit-workflow/SKILL.md) | Fluxo de commit |
| [framework/templates/test-plan.md](./framework/templates/test-plan.md) | Template do plano de testes |

---

## 17. Status atual

| Área | Status |
|------|--------|
| Hub agnóstico na raiz | ✅ Concluído |
| Export e cleanup sdd-kit/cursor | ✅ Concluído |
| Instalador script (PS1 + SH) | ✅ Concluído |
| Instalador agente (`/sdd.install`) | ✅ Concluído |
| Gitignore automático (append/create) | ✅ Concluído |
| Commit workflow 4 opções + Graphify opcional | ✅ Concluído |
| Repo renomeado `development-agents` | ✅ Concluído |
| Pastas legadas removidas | ✅ Concluído |
| Gate tests-first (`/sdd.test`) | ✅ Concluído (branch `feat/tests-first-gate`) |
| Redução de verbosidade e referências lazy-loaded | ✅ Concluído nesta etapa |
| Profiles de stack | ⏳ Pendente |

**Conclusão:** o núcleo do time agêntico SDD está **pronto para uso** em projetos reais, com pipeline tests-first entre plan e build.
