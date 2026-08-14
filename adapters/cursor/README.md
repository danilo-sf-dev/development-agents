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
   substantiva via CLI headless — **escolhendo `--force` conforme o tipo de trabalho, nunca por
   padrao**:
   - Sem escrita de arquivo (sdd-explorer, sdd-validator, sdd-layer-analysis, sdd-system-design,
     sdd-debugger, qualquer leitura/analise): `agent -p --model "<modelo resolvido>"
     --output-format json "<tarefa>"` — sem `--force`. Sem essa flag, o `agent -p` só propõe
     mudanças, não as aplica; é exatamente o comportamento certo para uma Skill que não deve tocar
     arquivos.
   - Com escrita de arquivo (sdd-implementation, sdd-test-writing, `/sdd.build`, `/sdd.plan` quando
     grava tasks.json, qualquer fase que precisa criar/editar arquivo real): `agent -p --force
     --model "<modelo resolvido>" --output-format json "<tarefa>"` — sem `--force`, o processo
     filho terminaria sem gravar nada e a fase pareceria concluída sem ter feito o trabalho.
   NAO execute o conteudo do comando inline nesta sessao interativa sob o modelo ambiente dela — a
   sessao interativa so resolve o role, decide read vs write, dispara o processo filho, e repassa o
   resultado. Se o processo filho retornar `NEEDS_USER_INPUT` (ver "Interactive handoff" abaixo),
   a sessao interativa apresenta a pergunta via AskUserQuestion, grava a resposta no estado
   (`sdd/wip/<feature>/`), e re-dispara com `--resume <thread-id>` — Gates (1/2/2.5/3, AskUserQuestion)
   NUNCA sao respondidos pelo processo filho sozinho. Ver "Model Routing" abaixo para o mecanismo
   completo.
```

## Model Routing — `RESOLVED`

Canonical policy: `development-agents/framework/_shared/model-routing.md`. Concrete values:
`config/model-routing.yaml`, resolved via `framework/tools/resolve-model.sh cursor <STRONG|EXECUTION>`
— this adapter does **not** keep its own copy of the mapping.

**Command name, confirmed**: the official CLI is invoked as `agent` — the installer
(`curl https://cursor.com/install -fsS | bash`) places a binary literally named `agent` (not
`cursor-agent`) on `PATH`; `cursor.com/docs/cli/overview`, `cursor.com/docs/cli/using`, and
`cursor.com/docs/cli/reference/parameters` all use `agent` as the command in every example. "cursor-agent"
is the colloquial name people use for the tool in conversation/blog posts, and there are unrelated
third-party npm packages that happen to share that string — neither is the real binary. This adapter
uses `agent`, which is the confirmed-official name, not merely an "alias."

**Real mechanism (child CLI invocation, confirmed via current Cursor CLI documentation)**: Cursor CLI
supports non-interactive, scriptable execution — `agent -p "<prompt>" --model "<model>"
--output-format json` — documented as the form meant for "CI jobs, git hooks and shell scripts where
nothing is sitting at a keyboard to approve steps." This is a real `--model` flag, not an interactive
picker, and it is exactly the "child execution" mechanism this pack's architecture allows an adapter
to use when the harness can't switch its own running session's model. The rule file above (`sdd-workflow.mdc`,
regra 6) instructs the interactive agent to resolve the role, then shell out to `agent -p --model ...`
for the actual work, rather than running the command's content itself under whatever model the
interactive tab happens to be on.

**`--force` — read vs. write dispatch, confirmed via current docs, corrected this round**: without
`--force` (or `--yolo`), `agent -p` only **proposes** file changes — it does not write them. An
earlier version of this adapter dispatched every Skill through the same `agent -p --model ...` call
with no `--force`, which silently made every "write" dispatch (implementation, test-writing) a no-op
that reported success without ever touching a file. That was wrong and is fixed: this adapter now
grants `--force` only to dispatches whose Skill/phase actually writes files, and withholds it from
everything else:

| Dispatch is...                                                                                    | Flag                        | Why                                                                 |
| -------------------------------------------------------------------------------------------------- | ---------------------------- | -------------------------------------------------------------------- |
| Read-only / analysis (`sdd-explorer`, `sdd-layer-analysis`, `sdd-system-design`, `sdd-debugger`, `sdd-validator` isolated mode) | `agent -p --model "<resolved>" --output-format json "<task>"` (no `--force`) | Nothing here should mutate the working tree — `sdd-validator` in particular must not, per `VALIDATOR_ISOLATED` property 3. |
| Write-capable (`sdd-implementation`, `sdd-test-writing`, `/sdd.build`, `/sdd.plan` writing `tasks.json`, any phase that creates/edits files) | `agent -p --force --model "<resolved>" --output-format json "<task>"`         | Without `--force` the call would silently do nothing to the filesystem while still reporting a result. |

`--force` is granted per-dispatch based on what that specific Skill/phase does, never blanket-applied
to every call — see `sdd-workflow.mdc` regra 6 above for the exact routing.

**Interactive handoff (`NEEDS_USER_INPUT` / `--resume`)**: `agent -p` is headless — it cannot pause
mid-run to ask a human anything, so a dispatched command that reaches a Gate (1/2/2.5/3) or any other
`AskUserQuestion` point cannot answer it itself and must not guess. The child process stops at that
point instead and returns a structured JSON result (its final `--output-format json` line) of the
shape:

```json
{"status": "NEEDS_USER_INPUT", "resume_token": "<thread-id from this call>", "gate": "<gate name>", "questions": [...]}
```

The **interactive parent session** (never the child) then: presents `questions` via `AskUserQuestion`
(degraded to plain text per `ASK_USER` in `harness-capabilities.md`), writes the human's answer to the
state the phase expects (`sdd/wip/<feature>/meta.md` or wherever that gate normally persists its
result), and resumes the **same** child thread with the answer and the **same** resolved model/`--force`
choice: `agent -p --resume "<resume_token>" --model "<same resolved model>" [--force if this was a
write dispatch] "<human's answer, verbatim>" --output-format json`. This repeats until the child
returns a terminal status (not `NEEDS_USER_INPUT`). `--resume <thread-id>` is a real, documented Cursor
CLI mechanism (`cursor.com/docs/cli/using`: "continue from an existing thread with `--resume [thread
id]` to load prior context") — this is not a new capability invented for this pack, it's the existing
session-continuation primitive repurposed as the gate-answer channel. See "Known gaps" below for what
is and isn't confirmed about this specific usage.

**Evidence and its limits**: `agent -p --model`, `--force`/`--yolo`, `--output-format json`, and
`--resume <thread-id>` are all corroborated from current official Cursor CLI documentation
(`cursor.com/docs/cli/headless`, `cursor.com/docs/cli/using`, `cursor.com/docs/cli/reference/parameters`)
cross-checked across multiple independent sources in this session. It was **not** live-round-trip-tested
against a running Cursor session — this sandbox has no `agent` binary installed and this session's
`WebFetch` tool is fully blocked by network egress policy (confirmed by testing it against several
unrelated hosts, not just Cursor's), so the primary docs pages could not be fetched directly, only
corroborated via independent search-result excerpts that quote the same flag and example syntax.
Treat the mechanism as **designed and documented as real automation**, not as a claim of a completed
live test — before relying on this in production, run the exact commands below once against a real
`agent` install and confirm the outputs match:

```bash
# READ dispatch (no --force) — should report a proposed change, no file written
agent -p --model "$(bash development-agents/framework/tools/resolve-model.sh cursor EXECUTION | sed -n 's/model=\([^ ]*\).*/\1/p')" --output-format json "List the files in the current directory and suggest one naming improvement, but do not change anything."

# WRITE dispatch (--force) — should report a change AND the file should actually be modified
agent -p --force --model "$(bash development-agents/framework/tools/resolve-model.sh cursor EXECUTION | sed -n 's/model=\([^ ]*\).*/\1/p')" --output-format json "Append a comment line to README.md confirming this test ran."

# Catalog discovery — the actual source of truth for the two UNCONFIRMED strings in
# config/model-routing.yaml (see that file's header comment)
agent models
```

**Reasoning effort**: no confirmed CLI flag for effort/reasoning-level in headless mode (only an
interactive slash-menu control was found in current docs). This adapter folds effort into the model
identifier itself (`config/model-routing.yaml`'s `cursor.STRONG.model: grok-4.6-high` already encodes
"high" in the string) rather than passing a second flag — if Cursor CLI ships a dedicated effort flag
later, add it to `resolve-model.sh`'s cursor branch, not to this file.

**Model catalog strings are account/plan-dependent — not guessable, not guessed**: Cursor's exact
`--model` ID strings (e.g. whether "Composer 2.5" is passed as `composer-2.5`, `composer-2`, or
something else) vary by account entitlement and change as the catalog evolves, and could not be
independently confirmed against a live install in this environment (no binary, `WebFetch` blocked).
`config/model-routing.yaml` marks its two Cursor values `UNCONFIRMED` for exactly this reason, and
points at the real source of truth: `agent models` (or `--list-models`, or the `/models` slash command
in an interactive session) is a documented, real CLI command that lists the exact strings this
account's `--model` flag accepts — run it once and correct the YAML if the values differ. This is not
a gap in the automation mechanism (the child-dispatch design is unaffected either way); it is an
account-specific data value that has to come from that account, not from documentation.

**What "the operator does nothing" actually requires here, precisely**: `CURSOR_API_KEY` (or
equivalent headless auth) must be set in the environment for `agent -p` to run non-interactively —
this is a one-time environment setup, not a per-command action, and is the same requirement Cursor's
own CI/GitHub Actions integration has. It is not "manual model selection"; it's the auth precondition
every headless CLI call needs regardless of role/model.

## Known gaps (do not silently degrade past these — tell the user)

- **No commands/ folder.** Cursor's slash-command mechanism is not repo-shareable the way `.claude/commands/` is. The rule file above tells the agent to read `development-agents/commands/*.md` directly instead of relying on a `/sdd.*` slash-command registration.
- **`DELEGATE_ISOLATED` is degraded**, not equivalent to Claude Code's synchronous in-session subagent — it is now satisfied via the headless `agent -p --model ...` child-CLI mechanism above (real isolation: separate process, fresh context) rather than "open a new conversation tab by hand" (the pre-Model-Routing version of this gap note). The Validator Independence Protocol (`sdd-validator`) runs as that headless child call, **without** `--force` (read-only), with a scrubbed prompt; flag to the user when a `CANNOT_PROCEED` verdict comes back, same as before.
- **`ASK_USER` is degraded** to plain conversational text with listed options (always including a free-text "Outros"/"Other" choice) — Cursor's structured clarifying-questions UI is scoped to Plan Mode only, not a general-purpose tool this adapter can call at arbitrary gate points. This happens in the **interactive parent session**, after a headless child dispatch returns `NEEDS_USER_INPUT` or completes — never inside the headless call itself (see regra 6 and "Interactive handoff" above).
- **`--force` must never be granted blanket-wide.** A dispatch's read/write status comes from the Skill's/phase's own nature (see the table under "Model Routing" above), not from a shortcut of "always pass `--force` to be safe" — that would let a read-only Skill like `sdd-validator` or `sdd-explorer` mutate files it has no business touching.
- **Model Routing mechanism is documented `RESOLVED` automation, not yet live-verified in this environment.** The `--model`/`--force`/`--resume` flags and headless behavior are corroborated from current official-documentation excerpts (see "Model Routing" above for exactly what was and wasn't confirmed, and the exact commands to run to verify), not from a live round-trip in this sandbox. This is a verification gap, not a "falls back to manual" gap — do not reintroduce a manual-picker instruction as a substitute; if a flag turns out to be wrong, fix the flag, not the architecture.
- **Cursor's exact `--model` catalog strings are unconfirmed** (account/plan-dependent, see "Model catalog strings" above) — run `agent models` once and correct `config/model-routing.yaml` if `grok-4.6-high`/`composer-2.5-fast` don't match this account's real catalog. This is a data-value gap, not a mechanism gap.
