# Sugestão: quando usar modelo mais forte ou mais barato

Documento **informativo** para quem está aprendendo a rodar o time de agents SDD.  
Não é regra do pack, não é gate e não obriga nenhum fornecedor ou nome de modelo — só uma dica de custo × qualidade.

---

## Em uma frase

Use um modelo **mais forte/caro** enquanto a feature ainda está sendo **definida**.  
Use um modelo **mais fraco/barato** quando for **implementar** o que já foi aprovado nos passos anteriores.

O build consome muitos tokens. Se o “o quê” e o “como testar” já estão claros em `sdd/wip/`, não precisa pagar inteligência de ponta para seguir tasks e fazer o código passar nos testes.

---

## Por que isso faz sentido

O pipeline SDD separa propositalmente:

1. **Decidir** — problema, escopo, arquitetura, plano, contrato de testes (com você aprovando)
2. **Executar** — escrever código a partir desses artefatos

Erro na decisão (spec/plan/test) propaga para tudo.  
Erro na execução, com specs boas, costuma ser mais barato de corrigir.

Por isso a sugestão: investir no modelo forte no começo; economizar no meio/fim.

---

## Sugestão por passo (agnóstica de host)

| Passo | Sugestão | Por quê |
|-------|----------|---------|
| `/sdd.start` | Barato | Só cria a pasta da feature e metadados |
| `/sdd.spec` | **Forte** | Entende o pedido (chat + Jira), entrevista, AC, arquitetura |
| `/sdd.plan` | **Forte** / intermediário | Quebra em tasks; com spec boa pode ser o intermediário |
| `/sdd.test` | **Forte** / intermediário | Contrato de testes; suba se a regra for ambígua |
| `/sdd.build` | **Barato** | Implementa o que já foi muito bem definido |
| `/sdd.finish` | **Forte** | Code review final, security e validação antes de arquivar |
| `/sdd.pr` | Barato | Descreve o PR do que já existe |
| Debug difícil / `/sdd.fix` | **Forte** (só no diagnóstico) | Volte ao barato quando o caminho estiver claro |

### Momento típico de trocar

```text
modelo forte / intermediário → spec → plan → test → finish
modelo barato                → start → build → pr
```

Antes do `/sdd.finish`, troque para o **forte** — é onde roda o code review final.

Se no build o agente começar a reinventar produto ou mudar teste aprovado, pause e volte ao modelo forte (ou refine spec/test) em vez de insistir no barato.

---

## Se você estiver no Claude Code

No Claude Code (CLI ou extensão VS Code) o custo tem **dois eixos**: modelo **e** effort.  
Na pausa entre comandos `/sdd.*`, ajuste com `/model` e `/effort` (quando o modelo aceitar effort).

> **Informativo** — não é gate. Nomes/versões e preços mudam; confira a doc Anthropic se algo parecer desatualizado.

### Faixas recomendadas

| Faixa | Modelo | Papel |
|-------|--------|-------|
| Barato / executor | **Haiku 4.5** | Rodar o que já está aprovado (start, build, pr, ops) |
| Pensar / intermediário | **Sonnet 5** | Spec, plan, test, finish — default de qualidade |
| Extremo | **Opus 5** | Só quando Sonnet/Haiku falharem (mesmo $/token que Opus 4.8) |

### Effort e custo

Effort **não muda o preço por token** — muda **quantos tokens** (thinking + tools) o modelo gasta.

| Effort | Custo relativo | Uso típico |
|--------|----------------|------------|
| `low` | Mais barato | Ops simples / alto volume |
| `medium` | Economia vs default | Bom equilíbrio (plan, test, technical) |
| `high` | Default do Sonnet 5 | Spec functional, finish |
| `xhigh` | Bem mais caro | Extremo / coding agentic longo |
| `max` | Sem teto | Evitar no dia a dia |

**Haiku 4.5:** na prática trate effort como **N/A** (não usa o dial moderno de effort como Sonnet/Opus).

**Armadilha:** Sonnet 5 default = `high`. Se não setar `/effort medium` em plan/test/technical, você paga o default mais caro sem precisar.

### Contexto (janela)

| Modelo | Contexto | Max output |
|--------|----------|------------|
| Haiku 4.5 | **200k** | 64k |
| Sonnet 5 | **1M** | 128k |
| Opus 5 | **1M** | 128k |

No build com Haiku, sessão/repo muito grande enche a janela mais rápido → `/compact` ou suba para Sonnet 5 naquela fase.

### Setup (uma vez no projeto)

| # | Passo | Modelo | Versão | Effort |
|---|--------|--------|--------|--------|
| 0a | Install / `/sdd.install` | Haiku | 4.5 | N/A |
| 0b | `/sdd.project` (se ainda não existir) | Sonnet | 5 | `medium` |
| 0c | `/sdd.mcp` (opcional) | Haiku | 4.5 | N/A |

### Fluxo Standard — planilha por pausa

| # | Pausou em… | Próximo comando | Modelo | Versão | Effort |
|---|------------|-----------------|--------|--------|--------|
| 1 | Início | `/sdd.start` | Haiku | 4.5 | N/A |
| 2 | Pós-start | `/sdd.spec` functional | Sonnet | 5 | `high` |
| 3 | Approve functional | `/sdd.spec` technical | Sonnet | 5 | `medium` *( `high` se arch nova)* |
| 4 | Approve technical | `/sdd.plan` | Sonnet | 5 | `medium` |
| 5 | Approve plan | `/sdd.test` | Sonnet | 5 | `medium` *( `high` se regra ambígua)* |
| 6 | Approve testes | `/sdd.build` | Haiku | 4.5 | N/A |
| 7 | Build ok | `/sdd.check` (opcional) | Haiku | 4.5 | N/A |
| 8 | Pré-arquivar | `/sdd.finish` | Sonnet | 5 | `high` |
| 9 | Feature arquivada | `/sdd.pr` | Haiku | 4.5 | N/A |

### Em uma linha

```text
Haiku 4.5              → start, build, check, pr, mcp
Sonnet 5 + medium      → technical*, plan, test*
Sonnet 5 + high        → spec functional, finish
Opus 5 + high/xhigh    → só extremo
```

### Na pausa (Claude Code)

```text
/model sonnet    # ou haiku / opus
/effort medium   # ou high / xhigh
```

### Caso extremo

| Situação | Modelo | Versão | Effort |
|----------|--------|--------|--------|
| Spec / arquitetura muito difícil | Opus | 5 | `high` → `xhigh` se ainda fraco |
| Bug / repo profundo | Opus | 5 | `xhigh` |
| Security crítico no finish | Opus | 5 | `high` |
| Evitar | Opus 5 + `max` / `ultracode` | — | Estoura custo sem necessidade |

Prefira **Opus 5** (não 4.8): mesmo preço por token, benches mais fortes no lançamento.

Se no **build** o Haiku reinventar produto ou alterar teste aprovado → pause, `/model sonnet` + `/effort high` (ou `/sdd.test --refine`).

### Evite `/sdd.go` se custo importa

Express auto-avança com poucas pausas → menos janelas para trocar modelo/effort. Prefira o fluxo Standard comando a comando.

---

## Ordem de contexto (também ajuda no custo)

Independente do modelo, passar o card cedo na spec reduz perguntas repetidas:

```text
/sdd.start "PAY-42 pix refund — seu ângulo / fora de escopo"

/sdd.spec --include "https://…/browse/PAY-42"
também: o que o card não deixa explícito
```

O Jira (ou texto colado) alimenta o contexto; a conversa cobre só os gaps. Detalhe do fluxo do dia a dia: `framework/PLAYBOOK.md`.

---

## O que este doc não é

- Não configura o IDE
- Não escolhe modelo por você
- Não altera commands, agents ou gates
- Não substitui o playbook nem o `PIPELINE.md`

É só leitura opcional para quem quer gastar menos sem perder qualidade onde importa.
