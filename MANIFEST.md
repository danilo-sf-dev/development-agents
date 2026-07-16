# development-agents — Manifest (export v1 + Cleanup v1)

Pack canônico de SDD language-/platform-agnostic.  
Objetivo: hub limpo para editar o time; stack e paths vêm do **projeto alvo**.

## Incluído

### agents/ (11)

| Agent | Papel no time |
|-------|----------------|
| `development-agents-installer` | Instala pack em projetos (alternativa ao script) |
| `sdd-system-designer` | Arquiteto (spec técnica) |
| `sdd-explorer` | Descoberta read-only (brownfield) |
| `sdd-implementer` | Developer |
| `sdd-small-test-writer` | Test Writer (unit/integration) |
| `sdd-large-test-writer` | Test Writer (E2E opcional) |
| `sdd-validator-runner` | Gate automático pós-código |
| `sdd-layer-analyzer` | Consistência spec ↔ code |
| `sdd-debugger` | RCA / bugs profundos |
| `sdd-backlog-manager` | Ops de backlog (`sdd/backlog.md`) |
| `sdd-project-wizard` | Setup `sdd/PROJECT.md` |

### skills/ (6) — núcleo de processo

| Skill | Função |
|-------|--------|
| `sdd-kit-expert` | Manual do workflow |
| `sdd-code-reviewer` | Code review bloqueante |
| `sdd-validator` | Build/compliance (genérico) |
| `sdd-performance-expert` | Review de performance |
| `context-guardian` | Controle de contexto/tokens |
| `commit-workflow` | Formatação, validação e commit agnósticos |

### commands/ (20) — orquestração `/sdd.*`

Inclui: start, spec, plan, **test**, build, go, check, finish, fix, backlog, etc.

Medição atual da redução de verbosidade:
- 20 comandos: caminho comum enxuto; ramos raros lazy-loaded
- `commands/references/`: **~120** referências lazy-loaded (P0 `spec-*` + P1 `start-*`/`build-*`/`finish-*`/`reverse-eng-*`)
- `framework/_shared/agent-instructions.md`: instruções compartilhadas — **1 referência** substituindo 18 cópias
- `sdd.spec.md`: 2.223 → **~287 linhas** (P0 ≤400)
- `sdd.fix.md`: ~1834 → **~273 linhas** (P0 ≤400)
- `sdd.project.md`: ~1671 → **~158 linhas** (P0 ≤400)
- `sdd.start.md`: 1.689 → **~199 linhas** (P1 ≤400)
- `sdd.reverse-eng.md`: ~1125 → **~386 linhas** (P1 ≤400)
- `sdd.build.md`: ~975 → **~230 linhas** (P1 ≤400; anti-gaming no principal)
- `sdd.finish.md`: ~950 → **~168 linhas** (P1 ≤400)
- `sdd.plan.md`: ~672 → **~192 linhas** (P2 ≤400; next → `/sdd.test`)
- `sdd.backlog.md`: ~540 → **~111 linhas** (P2 ≤400)
- `sdd.check.md`: ~800 → **~305 linhas**
- **P0 + P1 + P2 concluídos** — nenhum `commands/sdd*.md` acima de 400 linhas

### framework/

Templates, standards, tools e docs do SDD (necessário para os commands).

- `framework/PIPELINE.md`: **fonte canônica** do diagrama/gates/modos do pipeline — `AGENTS.md`, `WORKFLOW.md`, `COMMANDS.md`, `QUICK_REFERENCE.md` e `skills/sdd-kit-expert/SKILL.md` linkam para lá em vez de duplicar o diagrama completo (reduz custo de manutenção ao adicionar/mudar gates).

Paths do pack:
- **Hub (este repo):** raiz — `agents/`, `commands/`, `framework/`
- **Projeto alvo:** `development-agents/` (criado pelo instalador)

---

## Cleanup v1 (language- / platform-agnostic)

O que foi generalizado nesta passagem:

| Removido / substituído | Em favor de |
|------------------------|-------------|
| Hardcoding Mercado Libre / Meli / Fury / Nordic / Everest / Andes / furycloud | Stack e infra do **projeto alvo** |
| Paths `sdd-kit/` | `development-agents/` |
| `meli/backlog.md`, `meli/PROJECT.md` | `sdd/backlog.md`, `sdd/PROJECT.md` |
| Protocolo Fury INFRA Tier A/B/C + `fury` CLI + web.furycloud.io | Passo curto de infra via technical spec + PROJECT.md + IaC/CLI do repo |
| Skills obrigatórias `fury-*`, LTP MCP obrigatório | Opcionais se PROJECT.md / tooling existirem |
| Preambles Android/iOS Everest/Andes obrigatórios | Opcionais quando `platform.type` + skills no PROJECT.md |
| Catálogos fixos de serviços corporativos | “project services / platform services from technical spec” |
| Detecção Melis-only em `detect-stack.sh` (soft) | Detecção genérica (Android/iOS/web/Java/TS/Go/Python/Rust) |

**Resolução de stack (canônica):**

1. `development-agents/framework/tools/detect-language.sh`
2. `development-agents/framework/tools/detect-stack.sh`
3. `sdd/PROJECT.md`
4. Código e specs existentes no repo alvo

Menções residuais a marcas legadas devem ser **zero** no pack, exceto nesta seção “Cleanup v1 / removed”.

### Cleanup v2 (resíduo quebrado + consolidação de docs)

Uma segunda varredura (além do Cleanup v1) encontrou **resíduo de find-and-replace malsucedido** deixado pela limpeza inicial: bullets com label vazio (`- ****: ...`), frases quebradas com espaço duplo (`in  Systems model`, `use  Secrets`), tabelas com células vazias, e referências a skills/artefatos que **não existem no pack** (`project-services-architect`, `project-snippets-expert`, `project-infra-operations`, `PROJECT_SERVICES.json`). Corrigido em ~25 arquivos (`commands/`, `framework/`, `agents/`, `skills/`):

| Problema | Correção |
|----------|----------|
| Labels/frases vazias (`****`, `in  X`, `for  Y`) | Texto genérico correto gramaticalmente |
| Regra de Dockerfile hardcoded (`your-registry/base-image`) | Condicional a `sdd/PROJECT.md` (só valida se o projeto declarar um prefixo) |
| Catálogo de serviços internos proprietário (`GLOSSARY.md`, `FAQ.md`) | Removido — serviços vêm de `sdd/PROJECT.md` |
| `Skill("project-services-architect")` / `project-snippets-expert` / `project-infra-operations` (não existem) | `Skill("sdd-system-designer")` / `Skill("sdd-implementer")` (skills reais) ou lógica condicional a `sdd/PROJECT.md` |
| Auth `TIGER_TOKEN` + `mcp-remote-proxy` hardcoded (`CONFIGURATION.md`) | Instrução genérica — configure o que seu MCP exigir |
| Diagrama de pipeline duplicado em 5+ docs | `framework/PIPELINE.md` (fonte canônica) + demais docs linkam |
| `WORKFLOW.md` exemplo "Standard Feature" sem `/sdd.test` | Corrigido (bug real causado pela duplicação) |
| `COMMANDS.md` "Total Commands: 17" e tabela sem `test/doctor/hub/install` | Corrigido para 20, categorias atualizadas |

Validação: `rg -i 'meli|fury|nordic|everest|andes|furycloud|ltp\b'` (ignorando falsos positivos de "timeline") → zero hits fora do MANIFEST/RESUMO.

**Gap conhecido, não corrigido nesta rodada**: `COMMANDS.md` documenta `/sdd.skill` (hooks de terceiros) que não existe como comando no pack, e não tem seções para `/sdd.doctor`, `/sdd.hub`, `/sdd.install`. Decidir se `/sdd.skill` é uma feature a implementar ou doc morta a remover.

### Commit workflow

O `commit-workflow` foi reescrito para o hub:

- quatro opções: fluxo completo, formatar e commit, commit direto e outros;
- descoberta de formatador/testes conforme o projeto alvo;
- Conventional Commits;
- Graphify opcional apenas para atualizar contexto;
- `graphify-out/` nunca entra no commit.

---

## Excluído de propósito (export inicial)

| Item | Motivo |
|------|--------|
| Skills de stack de outro produto (Next/Supabase, impeccable, graphify commit) | Projeto-específico |
| Profiles Java/Python opcionais | Entram depois se o time precisar |

## Instalador

- `install.sh` — Bash (Git Bash / WSL / macOS / Linux)
- `install.ps1` — PowerShell (Windows)
- `/sdd.install` — agente (alternativa quando script estiver bloqueado)

Repositório hub: https://github.com/danilo-sf-dev/development-agents

Exporta pack + adapters `.claude/` e `.cursor/` + `sdd/`.  
No **projeto alvo**, append em `.gitignore` — `development-agents/`, `.cursor/`, `.claude/`, `sdd/` **não sobem no commit**.

## Ainda não feito

- [ ] Profiles opcionais de stack (`profiles/java`, `profiles/nextjs`, …)

## Como validar

1. Confirmar papéis do time (agents + commands).
2. `rg -i 'meli|fury|nordic|everest|andes|furycloud|ltp'` em `development-agents/` → só MANIFEST Cleanup notes (se houver).
3. Stack resolution = detection scripts + PROJECT.md.
