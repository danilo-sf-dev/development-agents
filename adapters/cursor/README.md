# Adapter: Cursor

**Declared support level: Supported (adapter, with documented capability gaps).** `INVOKE_PROCEDURE` and `WRITE_PROJECT_INSTRUCTIONS` are Full (Cursor's native `SKILL.md` format and rules files match the pack directly). `DELEGATE_ISOLATED`/`DELEGATE_OFFLOAD` and `ASK_USER` degrade — see `framework/_shared/harness-capabilities.md` for exact translations. Never claim parity with Claude Code for those two.

## What this adapter installs

| Destination                                     | Source                                                                                                             |
| ----------------------------------------------- | ------------------------------------------------------------------------------------------------------------------ |
| `.cursor/agents/`                               | `development-agents/agents/*.md` (verbatim copy)                                                                   |
| `.cursor/skills/<name>/`                        | `development-agents/skills/<name>/` (verbatim copy — same `SKILL.md` format as Claude Code, no translation needed) |
| `.cursor/rules/sdd-workflow.mdc`                | Fixed content, see below                                                                                           |
| _(no `.cursor/commands/` populated by default)_ | See gap note below                                                                                                 |

### `.cursor/rules/sdd-workflow.mdc` content

```markdown
---
description: Workflow SDD via development-agents - specs antes de codigo
alwaysApply: true
---

# SDD Workflow (development-agents)

Este projeto usa o pack development-agents/.

## Pipeline

Fonte canonica (unica, nao redefinir): development-agents/framework/PIPELINE.md

Bootstrap minimo: /sdd.start -> /sdd.spec -> /sdd.plan -> /sdd.test -> /sdd.build -> /sdd.check -> /sdd.finish (atalho: /sdd.go, express). Prefira o fluxo padrao no primeiro contato com um card.

## Como os comandos funcionam neste harness

Cursor nao tem uma pasta de slash-commands compartilhavel via repo equivalente a .claude/commands/.
Os comandos /sdd.* sao arquivos Markdown normais em development-agents/commands/ — leia o arquivo
correspondente (ex: development-agents/commands/sdd.spec.md) e siga as instrucoes nele quando o
usuario disser "/sdd.spec" ou equivalente.

## Referencias

- Pack: development-agents/AGENTS.md
- Commands (leia diretamente, nao ha pasta .cursor/commands/): development-agents/commands/
- Skills: .cursor/skills/
- Agents: .cursor/agents/
- Framework: development-agents/framework/
- Traducao de capacidades (Task/AskUserQuestion -> equivalente Cursor): development-agents/framework/_shared/harness-capabilities.md

## Regras

1. Nao pular fases do pipeline canonico (ver secao Pipeline acima ou development-agents/framework/PIPELINE.md — fonte unica; nao redefinir aqui)
2. Stack vem do projeto (sdd/PROJECT.md + detection), nao de defaults do pack
3. Commits: skill commit-workflow (4 opcoes; mensagens em portugues)
4. Graphify, se existir, atualiza contexto e NAO entra no commit
5. Quando um comando pedir Task(subagent_type=...) ou AskUserQuestion(...), traduza pela tabela em
   harness-capabilities.md (delegacao isolada degrada para nova conversa; pergunta estruturada
   degrada para texto simples com opcoes)
```

## Known gaps (do not silently degrade past these — tell the user)

- **No commands/ folder.** Cursor's slash-command mechanism is not repo-shareable the way `.claude/commands/` is. The rule file above tells the agent to read `development-agents/commands/*.md` directly instead of relying on a `/sdd.*` slash-command registration.
- **`DELEGATE_ISOLATED` is degraded**, not equivalent. Cursor has no synchronous "spawn isolated subagent, get structured result back into this session" primitive — only asynchronous Background/Cloud Agents that run out-of-session. The Validator Independence Protocol (`sdd-validator-runner`) must run as a fresh conversation with a scrubbed prompt when using this adapter; the isolation guarantee is weaker than Claude Code's and must be flagged to the user when it matters (e.g. a `CANNOT_PROCEED` gate).
- **`ASK_USER` is degraded** to plain conversational text with listed options (always including a free-text "Outros"/"Other" choice) — Cursor's structured clarifying-questions UI is scoped to Plan Mode only, not a general-purpose tool this adapter can call at arbitrary gate points.
