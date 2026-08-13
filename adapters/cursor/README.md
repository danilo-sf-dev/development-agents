# Adapter: Cursor

**Declared support level: Supported (adapter, with documented capability gaps).** `INVOKE_PROCEDURE` and `WRITE_PROJECT_INSTRUCTIONS` are Full (Cursor's native `SKILL.md` format and rules files match the pack directly). `DELEGATE_ISOLATED`/`DELEGATE_OFFLOAD`/`VALIDATOR_ISOLATED`/`OFFLOAD_READ`/`OFFLOAD_REASONING`/`INTERACTIVE_OFFLOAD` and `ASK_USER` degrade — see `framework/_shared/harness-capabilities.md` for exact translations. Never claim parity with Claude Code for those.

**No `agents/` folder exists in this pack anymore** — all 12 former agent roles are Skills under `skills/`, installed the same way as any other Skill (row below).

## What this adapter installs

| Destination                                     | Source                                                                                                             |
| ----------------------------------------------- | ------------------------------------------------------------------------------------------------------------------ |
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
- Framework: development-agents/framework/
- Traducao de capacidades (Task/AskUserQuestion -> equivalente Cursor): development-agents/framework/_shared/harness-capabilities.md
- Model Routing (resolucao automatica de modelo): development-agents/framework/_shared/model-routing.md

## Regras

1. Nao pular fases do pipeline canonico (ver secao Pipeline acima ou development-agents/framework/PIPELINE.md — fonte unica; nao redefinir aqui)
2. Stack vem do projeto (sdd/PROJECT.md + detection), nao de defaults do pack
3. Commits: skill commit-workflow (4 opcoes; mensagens em portugues)
4. Graphify, se existir, atualiza contexto e NAO entra no commit
5. Quando um comando pedir Task(subagent_type=...) ou AskUserQuestion(...), traduza pela tabela em
   harness-capabilities.md (delegacao isolada degrada para nova conversa; pergunta estruturada
   degrada para texto simples com opcoes)
6. **Model Routing e automatico — o operador nunca troca modelo pelo picker.** Antes de executar o
   CONTEUDO de qualquer /sdd.* (ou de uma Skill offloaded), leia o `model_role:` do frontmatter do
   comando/Skill, resolva o modelo concreto rodando
   `bash development-agents/framework/tools/resolve-model.sh cursor <ROLE>`, e dispiche a execucao
   substantiva via CLI headless: `agent -p --model "<modelo resolvido>" --output-format json
   "<tarefa: siga development-agents/commands/sdd.<X>.md para a feature <nome>...>"`. NAO execute o
   conteudo do comando inline nesta sessao interativa sob o modelo ambiente dela — a sessao
   interativa so resolve o role, dispara o processo filho, e repassa o resultado. Gates que exigem
   aprovacao humana (Gate 1/2/2.5/3, AskUserQuestion) acontecem DEPOIS que o processo filho retorna
   (modo -p e headless: nao pausa no meio para perguntar) — a sessao interativa apresenta o resultado
   do filho e roda o gate normalmente antes do proximo dispatch. Ver "Model Routing" abaixo para o
   mecanismo completo.
```

## Model Routing — `RESOLVED`

Canonical policy: `development-agents/framework/_shared/model-routing.md`. Concrete values:
`config/model-routing.yaml`, resolved via `framework/tools/resolve-model.sh cursor <STRONG|EXECUTION>`
— this adapter does **not** keep its own copy of the mapping.

**Real mechanism (child CLI invocation, confirmed via current Cursor CLI documentation)**: Cursor CLI
supports non-interactive, scriptable execution — `agent -p "<prompt>" --model "<model>"
--output-format json` — documented as the form meant for "CI jobs, git hooks and shell scripts where
nothing is sitting at a keyboard to approve steps." This is a real `--model` flag, not an interactive
picker, and it is exactly the "child execution" mechanism this pack's architecture allows an adapter
to use when the harness can't switch its own running session's model. The rule file above (`sdd-workflow.mdc`,
regra 6) instructs the interactive agent to resolve the role, then shell out to `agent -p --model ...`
for the actual work, rather than running the command's content itself under whatever model the
interactive tab happens to be on.

**Evidence and its limits**: this mechanism is based on current official Cursor CLI documentation
(`agent -p "..." --model "<model>"`, confirmed example syntax, `--output-format json` for structured
output, `CURSOR_API_KEY` for headless auth) cross-checked across multiple independent sources in this
session. It was **not** live-round-trip-tested against a running Cursor session — this sandbox has no
`cursor-agent`/`agent` binary installed and this session's `WebFetch` tool is fully blocked by network
egress policy (confirmed by testing it against several unrelated hosts, not just Cursor's), so the
primary docs pages could not be fetched directly, only corroborated via independent search-result
excerpts that quote the same flag and example syntax. Treat the mechanism as **designed and
documented as real automation**, not as a claim of a completed live test — verify the exact flag
names against `cursor.com/docs/cli/reference/parameters` before relying on this in production, and
report back if the CLI's actual behavior differs from what's documented here.

**Reasoning effort**: no confirmed CLI flag for effort/reasoning-level in headless mode (only an
interactive slash-menu control was found in current docs). This adapter folds effort into the model
identifier itself (`config/model-routing.yaml`'s `cursor.STRONG.model: grok-4.6-high` already encodes
"high" in the string) rather than passing a second flag — if Cursor CLI ships a dedicated effort flag
later, add it to `resolve-model.sh`'s cursor branch, not to this file.

**What "the operator does nothing" actually requires here, precisely**: `CURSOR_API_KEY` (or
equivalent headless auth) must be set in the environment for `agent -p` to run non-interactively —
this is a one-time environment setup, not a per-command action, and is the same requirement Cursor's
own CI/GitHub Actions integration has. It is not "manual model selection"; it's the auth precondition
every headless CLI call needs regardless of role/model.

## Known gaps (do not silently degrade past these — tell the user)

- **No commands/ folder.** Cursor's slash-command mechanism is not repo-shareable the way `.claude/commands/` is. The rule file above tells the agent to read `development-agents/commands/*.md` directly instead of relying on a `/sdd.*` slash-command registration.
- **`DELEGATE_ISOLATED` is degraded**, not equivalent to Claude Code's synchronous in-session subagent — it is now satisfied via the headless `agent -p --model ...` child-CLI mechanism above (real isolation: separate process, fresh context) rather than "open a new conversation tab by hand" (the pre-Model-Routing version of this gap note). The Validator Independence Protocol (`sdd-validator`) runs as that headless child call with a scrubbed prompt; flag to the user when a `CANNOT_PROCEED` verdict comes back, same as before.
- **`ASK_USER` is degraded** to plain conversational text with listed options (always including a free-text "Outros"/"Other" choice) — Cursor's structured clarifying-questions UI is scoped to Plan Mode only, not a general-purpose tool this adapter can call at arbitrary gate points. This happens in the **interactive parent session**, after a headless child dispatch returns — never inside the headless call itself (see regra 6 above).
- **Model Routing mechanism is documented `RESOLVED` automation, not yet live-verified in this environment.** The `--model` flag and headless behavior are corroborated from current official-documentation excerpts (see "Model Routing" above for exactly what was and wasn't confirmed), not from a live round-trip in this sandbox. This is a verification gap, not a "falls back to manual" gap — do not reintroduce a manual-picker instruction as a substitute; if the flag turns out to be wrong, fix the flag, not the architecture.
