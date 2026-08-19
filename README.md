# development-agents

Hub do time SDD — **language- and platform-agnostic**.
Não é um app: é o pack exportável de workflow Spec-Driven Development.

## Stack resolution

Stack, linguagem e infra **nunca** vêm de defaults corporativos neste pack. Resolva a partir do **projeto alvo**:

1. `framework/tools/detect-language.sh`
2. `framework/tools/detect-stack.sh`
3. `sdd/PROJECT.md` no repo alvo
4. Código e technical spec existentes

Suporte multi-linguagem (Java, TypeScript, Go, Python, Rust, mobile) é via **detecção**, não via hardcoding.

## Estrutura (este repositório)

O repo **é** o pack — sem subpasta:

```
development-agents/          ← raiz do git (clone = pack pronto)
├── README.md                ← este arquivo (porta de entrada humana)
├── AGENTS.md                ← contexto/instrução lida por agentes de IA (Codex CLI, etc.)
├── skills/                  ← 16 Skills (comportamento + procedimento)
├── commands/                ← 22 comandos /sdd.*
├── framework/                ← pipeline, gates, standards, tools, Model Routing, capabilities
├── adapters/                 ← 1 README por harness: mecanismo concreto de dispatch
│   ├── claude-code/
│   ├── cursor/
│   ├── codex/
│   └── generic/
├── config/
│   └── model-routing.yaml   ← modelos concretos por harness/role
└── docs/
    ├── adr/                  ← decisões de arquitetura
    └── reference/             ← guias de referência (fluxo, manifest, dica de modelo)
```

## Model Role — `STRONG` / `EXECUTION`

Cada Skill/command declara `model_role: STRONG` (decisão, arquitetura, testes, validação — reasoning
mais forte) ou `model_role: EXECUTION` (implementação mecânica do que já foi decidido). A resolução
para um modelo concreto por harness é **automática**, nunca uma escolha manual do operador:

- **Política canônica** (harness-agnostic): [`framework/_shared/model-routing.md`](./framework/_shared/model-routing.md)
- **Modelos concretos por harness** (única fonte editável): [`config/model-routing.yaml`](./config/model-routing.yaml)
- **Vocabulário de execution requirements** (`DELEGATE_ISOLATED`, `OFFLOAD_READ`, `VALIDATOR_ISOLATED`, etc.) e tabela de suporte por harness: [`framework/_shared/harness-capabilities.md`](./framework/_shared/harness-capabilities.md)

## Instalar em um projeto alvo

Instalação é feita pela Skill `sdd-installer` (via `/sdd.install`) — sem script, sem depender de permissão pra rodar `.sh`/`.ps1`. Suporta 4 harnesses, com nível de suporte declarado:

| Harness | Nível | O que é materializado no projeto alvo |
| --- | --- | --- |
| Claude Code | Supported (native) | `.claude/commands/` (22 comandos) + `.claude/skills/` (16 Skills) |
| Cursor | Supported (com gaps documentados) | `.cursor/skills/` (16 Skills) + `.cursor/rules/sdd-workflow.mdc` |
| Codex CLI | Experimental | `.agents/skills/` (16 Skills, formato `agentskills.io`) + seção `## SDD Kit` em `AGENTS.md` |
| Generic | Fallback only | Nenhum adapter automatizado — só o pack copiado + instruções em Markdown |

Nenhum harness recebe pasta `agents/` — essa pasta não existe mais no pack (ver `docs/adr/0001-agent-skill-execution-architecture.md`).

1. Clone ou copie este repo para o projeto (ou rode `/sdd.install` a partir do clone).
2. Abra o projeto alvo no harness escolhido.
3. No chat:

```
/sdd.install                          # detecta o harness automaticamente
/sdd.install --harness claude         # só Claude Code, sem perguntar
/sdd.install --harness cursor,codex   # múltiplos harnesses numa chamada
/sdd.install --target E:\Projects\meu-app
```

(`--cursor-only`/`--claude-only` continuam funcionando como alias legado de `--harness cursor`/`--harness claude`.)

A Skill `sdd-installer` cria as pastas do pack (`development-agents/`, adapter(s) do harness, `sdd/`) usando as próprias ferramentas de leitura/escrita do harness — nunca executa scripts de shell.

**Primeira vez (bootstrap):** se ainda não tem `.cursor/`, `.claude/` nem `.agents/`, use no chat:

```
Siga development-agents/commands/sdd.install.md e instale o pack neste projeto.
```

(Se o pack está na **raiz** do workspace aberto, use `commands/sdd.install.md`.)

Depois da primeira instalação, `/sdd.install` passa a funcionar normalmente.

### O que mais é criado no projeto alvo

| Destino                   | Conteúdo                                          |
| -------------------------- | ------------------------------------------------- |
| `development-agents/`      | Pack canônico (cópia completa)                     |
| `sdd/wip`, `sdd/features`  | Working dirs SDD                                  |
| `.gitignore`                | **Append** se já existir; **cria** se não existir |

O instalador **nunca** roda `git commit`. Só você commita se quiser — inclusive o `.gitignore` atualizado.

Depois:

1. `/sdd.project` (se não houver `sdd/PROJECT.md`)
2. `/sdd.reverse-eng` (brownfield — uma vez por serviço)
3. checkout `main`/`master` + pull (manual)
4. Abrir o card com `/sdd.start "JIRA-1234 resumo"`
5. Seguir o fluxo certo — ver [`docs/reference/FLUXOS-FEATURE-E-FIX.md`](./docs/reference/FLUXOS-FEATURE-E-FIX.md):
   - **Feature** → `spec → plan → test → build → check → finish → pr`
   - **Bug** → `fix → finish → pr`
6. Playbook completo: [`framework/PLAYBOOK.md`](./framework/PLAYBOOK.md)

## Documentação

| Documento | O que é |
| --- | --- |
| [`framework/PIPELINE.md`](./framework/PIPELINE.md) | **Fonte canônica** do pipeline: diagrama, gates, modos, papéis |
| [`docs/reference/FLUXOS-FEATURE-E-FIX.md`](./docs/reference/FLUXOS-FEATURE-E-FIX.md) | Mapa rápido: fluxo Feature vs. fluxo Fix/bug |
| [`docs/reference/MANIFEST.md`](./docs/reference/MANIFEST.md) | Inventário do pack: Skills, commands, o que foi incluído/excluído |
| [`docs/reference/SUGESTAO-MODELOS.md`](./docs/reference/SUGESTAO-MODELOS.md) | Tradução de `STRONG`/`EXECUTION` para modelos reais no Claude Code |
| [`docs/adr/0001-agent-skill-execution-architecture.md`](./docs/adr/0001-agent-skill-execution-architecture.md) | Por que `agents/` foi eliminado em favor de Skills + execution requirements |

Este README é uma visão de alto nível — para detalhe operacional, siga os links acima em vez de duplicá-los aqui.

## Origem

Export seletivo do núcleo SDD — sem skills de produto específico.
Detalhes: [`docs/reference/MANIFEST.md`](./docs/reference/MANIFEST.md).
