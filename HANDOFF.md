# HANDOFF — SDD Kit: Claude Code Adapter Telemetry

## Objetivo da tarefa

Adicionar telemetria por fase ao adapter Claude Code do SDD Kit. Cada dispatch `claude -p` já captura um envelope `stream-json` com `modelUsage` e `usage`; o objetivo é extrair esses dados, formatá-los para exibição ao usuário após cada fase SDD, e gerar um sumário consolidado ao final do `/sdd.finish` e `/sdd.go`.

---

## Problema identificado

A infraestrutura de telemetria foi criada e documentada, mas **não foi integrada** nos arquivos de comando SDD reais. Os arquivos `/sdd.*` ainda não chamam `parse-telemetry.sh` nem exibem o bloco de Usage após cada dispatch.

---

## Decisões tomadas e motivos

| Decisão | Motivo |
|---|---|
| `claude -p` subprocess como mecanismo primário de dispatch | Aceita model IDs versionados completos (`claude-sonnet-4-6`) e flag `--effort` — o `Agent()`/`Task()` só aceita aliases curtos e ignora effort |
| `--output-format stream-json --verbose` obrigatório em todos os dispatches | É a única fonte de `modelUsage` e `usage` — sem estimativa, sem re-tokenização |
| Parser sempre sai com exit 0 | Telemetria nunca deve abortar o pipeline SDD — falha de parse → `{"available":false}` → exibe "Usage: unavailable" e continua |
| Verbose mode via `sdd/PROJECT.md` | Reutiliza o mecanismo de configuração já existente; sem novo conceito |
| Model resolvido via `resolve-model.sh`, nunca hardcoded | Permite trocar model IDs editando `config/model-routing.yaml` sem alterar código de dispatch |

---

## Arquivos relevantes

### Criados neste trabalho (commit `4bf897a`)
| Arquivo | Descrição |
|---|---|
| `adapters/claude-code/tools/parse-telemetry.sh` | Parser: extrai model/input/output/cache/cost/duration do stream-json; sempre exit 0 |
| `adapters/claude-code/references/telemetry-display.md` | Spec de exibição: formato por fase, verbose mode, sumário final |
| `adapters/claude-code/tests/test-telemetry.sh` | 10 testes: 3 dispatches reais (STRONG, EXECUTION, VALIDATOR), agregação, resiliência, correção numérica, regras de cache |

### Modificados neste trabalho
| Arquivo | O que mudou |
|---|---|
| `framework/templates/project.md` | Adicionado bloco `telemetry.verbose: true` na seção de configuração |
| `adapters/claude-code/README.md` | Adicionada seção completa "Telemetry" documentando parser, display, verbose mode e regras de resiliência |

### Outros arquivos relevantes (não alterados)
| Arquivo | Descrição |
|---|---|
| `framework/tools/resolve-model.sh` | Resolve STRONG/EXECUTION → `{model, effort}` JSON; usado pelo parser e pelos testes |
| `config/model-routing.yaml` | Fonte de verdade dos model IDs — editar aqui para trocar modelos |
| `commands/*.md` | Arquivos de comando SDD — **ainda não integram telemetria** (próximo passo) |

---

## Classes / funções principais

### `parse-telemetry.sh`
```bash
bash adapters/claude-code/tools/parse-telemetry.sh \
    --model "$RESOLVED_MODEL" \
    --file  "$STREAM_JSONL_FILE"
# Saída: {"available":true,"model":"...","input":N,"output":N,
#          "cache_read":N,"cache_write":N,"cost_usd":N.NN,"duration_ms":N}
# Falha: {"available":false,"reason":"..."}
```

- `--model`: mesmo ID passado ao `claude -p --model`; é a chave direta em `modelUsage`
- `--file`: arquivo `.jsonl` capturado do subprocess; o parser encontra o objeto `"type":"result"` e extrai `modelUsage[RESOLVED_MODEL]`

### `resolve-model.sh` (pré-existente)
```bash
bash framework/tools/resolve-model.sh claude-code STRONG --json
# → {"model":"claude-sonnet-4-6","effort":"medium"}
```

---

## Alterações já realizadas

- [x] `parse-telemetry.sh` criado e documentado
- [x] `telemetry-display.md` criado (spec completa de UX)
- [x] `test-telemetry.sh` escrito (10 testes)
- [x] `framework/templates/project.md` atualizado com opção `telemetry.verbose`
- [x] `adapters/claude-code/README.md` atualizado com seção Telemetry completa
- [x] Commit `4bf897a` feito e push para `origin/update-agents` confirmado

---

## Alterações ainda pendentes

1. **Executar a suite de testes** — `test-telemetry.sh` foi escrito mas **não foi executado**. Testes 1–4 fazem dispatches reais (consomem tokens). Executar `--unit-only` primeiro.

2. **Integrar telemetria nos arquivos de comando SDD** — nenhum arquivo `/sdd.*` em `commands/` foi alterado para chamar `parse-telemetry.sh`. O padrão de integração esperado é:
   ```bash
   # Após cada claude -p dispatch que captura em $STREAM_FILE:
   RESOLVED_MODEL=$(bash framework/tools/resolve-model.sh claude-code STRONG --json | python3 -c '...')
   TELEMETRY=$(bash adapters/claude-code/tools/parse-telemetry.sh --model "$RESOLVED_MODEL" --file "$STREAM_FILE")
   # Exibir Usage block conforme telemetry-display.md
   ```

3. **Sumário final** — `/sdd.finish` e `/sdd.go` devem agregar telemetria por fase e exibir a tabela SDD USAGE SUMMARY conforme especificado em `telemetry-display.md` § "Final summary".

4. **PR update-agents → master** — verificar se existe PR aberta para o branch `update-agents` (muitos commits ahead of master); criar se não existir.

---

## Testes executados e resultados

| Teste | Status |
|---|---|
| `test-telemetry.sh --unit-only` | **NÃO EXECUTADO** |
| `test-telemetry.sh --real-only` | **NÃO EXECUTADO** (requer `claude` binary + API access) |
| Dispatch manual verificado na sessão anterior | STRONG (`claude-sonnet-4-6`) e EXECUTION (`claude-haiku-4-5`) confirmados via README live-verification |

---

## Comandos importantes

```bash
# Rodar testes unitários (sem API calls)
bash adapters/claude-code/tests/test-telemetry.sh --unit-only

# Rodar testes com dispatches reais (consome tokens)
bash adapters/claude-code/tests/test-telemetry.sh --real-only

# Rodar suite completa
bash adapters/claude-code/tests/test-telemetry.sh

# Resolver model para um papel
bash framework/tools/resolve-model.sh claude-code STRONG --json
bash framework/tools/resolve-model.sh claude-code EXECUTION --json

# Usar o parser manualmente
bash adapters/claude-code/tools/parse-telemetry.sh --model claude-sonnet-4-6 --file /tmp/stream.jsonl

# Estado do branch
git log --oneline master..update-agents
git status
```

---

## Restrições — o que NÃO alterar

- **Não fazer push para `master` diretamente** — todo trabalho vai para `update-agents`
- **Parser deve sempre sair com exit 0** — qualquer falha de parse deve retornar `{"available":false}`, nunca propagar erro
- **`--output-format stream-json --verbose` é obrigatório** em todos os dispatches — nunca omitir
- **Não hardcodar model IDs** nos arquivos de comando — sempre resolver via `resolve-model.sh`
- **Não alterar `config/model-routing.yaml`** sem entender que STRONG → `claude-sonnet-4-6` e EXECUTION → `claude-haiku-4-5` são os IDs canônicos atualmente mapeados
- **Telemetria nunca deve bloquear o pipeline SDD** — se indisponível, exibir "Usage: unavailable" e continuar

---

## Riscos e dúvidas abertas

1. **Testes 1–4 não validados** — os testes de dispatch real podem falhar se o `claude` binary não estiver no PATH ou se a API não responder dentro do timeout esperado. Verificar `which claude` antes de executar.

2. **Integração nos comandos SDD** — não está claro quais arquivos em `commands/` precisam de modificação. Alguns comandos (`/sdd.go`, `/sdd.hub`) são orquestradores que chamam outros; a telemetria deve ser agregada nesses pontos, não duplicada em cada subcomando. Ler `commands/sdd.go.md` e `commands/sdd.hub.md` antes de editar.

3. **Update-agents tem muitos commits ahead of master** — risco de conflito na hora de fazer PR. Verificar `git diff master...update-agents --name-only` para identificar arquivos em conflito potencial.

4. **Verbose mode detection** — a leitura de `sdd/PROJECT.md` usa `grep -qE '^\s+verbose:\s+true'`. Se o arquivo não existir (feature em setup), o grep falha silenciosamente e o modo padrão é usado — comportamento correto, mas vale confirmar que `PROJECT.md` está no path certo em projetos reais.

---

## Próximo passo recomendado

```
1. bash adapters/claude-code/tests/test-telemetry.sh --unit-only
   → Confirmar que os 6 testes unitários (5–10) passam sem API calls

2. Se unit OK:
   bash adapters/claude-code/tests/test-telemetry.sh --real-only
   → Confirmar que os 4 testes de dispatch real passam

3. Se todos os 10 testes OK:
   Identificar os arquivos de comando SDD que fazem dispatches claude -p
   e adicionar a chamada parse-telemetry.sh + exibição do Usage block
   seguindo o formato definido em adapters/claude-code/references/telemetry-display.md

4. Após integração nos comandos: commit + push para origin/update-agents
```

---

## Contexto do ambiente (sessão anterior)

- Sistema operacional: Linux (container remoto)
- Usuário: `root`
- Python disponível: 3.11.15 (`/usr/local/bin/python3`)
- `uv` disponível: 0.8.17
- `claude` binary: `/opt/node22/bin/claude` v2.1.233 (confirmado em sessão anterior)
- Branch de trabalho: `update-agents` (remotamente em `origin/update-agents`)
- **Graphify**: avaliação de diagnóstico concluída na sessão atual — nada foi instalado, nenhuma alteração no projeto. Diagnóstico: instalação viável via `uv tool install graphifyy` sem admin. Nenhuma ação pendente relacionada.
