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
Na pausa entre comandos `/sdd.*`, o kit **já aplica** o modelo certo via frontmatter do command (você não precisa lembrar de `/model` para não pagar caro).

> **Informativo** — não é gate de processo SDD. Nomes/versões e preços mudam; confira a doc Anthropic se algo parecer desatualizado.

### Política fechada (custo × qualidade)

| Tier | Alias | Onde |
|------|-------|------|
| Barato | **haiku** | `/sdd.start`, `/sdd.build`, `/sdd.check`, `/sdd.pr`, `/sdd.mcp` |
| Forte | **sonnet** | `/sdd.spec`, `/sdd.plan`, `/sdd.test`, `/sdd.finish`, `/sdd.reverse-eng` |
| Extremo | **opus** | **Só** `/sdd.fix` + agent `sdd-debugger` |

Subagents de execução/descoberta (`sdd-implementer`, `sdd-small-test-writer`, `sdd-explorer`, `sdd-system-designer`) usam `model: inherit` → seguem o modelo do comando pai.

**Garantia de não pagar Opus sem querer:** no Claude Code, o `model:` do frontmatter do `/sdd.*` sobrescreve o modelo da sessão **naquele turno**. Esquecer `/model` **não** faz o build rodar em Opus — o comando já está pinado em Haiku.

**Garantia de pausa:** no fluxo **Standard** (comando a comando), cada fase termina com `AskUserQuestion`; nas trocas críticas `test→build` e `build→finish` há confirmação explícita de modelo. No **Express** (`/sdd.go`) há menos pausas — o custo continua limitado pelo frontmatter de cada skill delegada, mas o ritmo educativo some. Prefira Standard se quiser as pausas.

**Extremo de verdade:** arquitetura/legado monstruoso → use `/sdd.fix` (Opus) ou descreva em **Outros** no gate; não deixe Opus no caminho feliz do spec/build.

### Faixas recomendadas

| Faixa | Modelo | Papel |
|-------|--------|-------|
| Barato / executor | **Haiku 4.5** | Rodar o que já está aprovado (start, build, pr, ops) |
| Pensar / intermediário | **Sonnet 5** | Spec, plan, test, finish — default de qualidade |
| Extremo | **Opus 5** | **Só** `/sdd.fix` + `sdd-debugger` (não usar no caminho feliz) |

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

| # | Pausou em… | Próximo comando | Modelo (frontmatter) | Effort |
|---|------------|-----------------|----------------------|--------|
| 1 | Início | `/sdd.start` | Haiku 4.5 | N/A |
| 2 | Pós-start | `/sdd.spec` functional | Sonnet 5 | `high` |
| 3 | Approve functional | `/sdd.spec` technical | Sonnet 5 | `medium` *( `high` se arch nova)* |
| 4 | Approve technical | `/sdd.plan` | Sonnet 5 | `medium` |
| 5 | Approve plan | `/sdd.test` | Sonnet 5 | `medium` *( `high` se regra ambígua)* |
| 6 | Approve testes | `/sdd.build` | Haiku 4.5 | N/A |
| 7 | Build ok | `/sdd.check` (opcional) | Haiku 4.5 | N/A |
| 8 | Pré-arquivar | `/sdd.finish` | Sonnet 5 | `high` |
| 9 | Feature arquivada | `/sdd.pr` | Haiku 4.5 | N/A |

> As pausas 6 e 8 pedem confirmação explícita de modelo (`AskUserQuestion`). O frontmatter já aplica Haiku/Sonnet mesmo se você só clicar “Seguir”.

### Em uma linha

```text
Haiku 4.5              → start, build, check, pr, mcp
Sonnet 5 + medium/high → spec, plan, test, finish, reverse-eng
Opus                   → só /sdd.fix (+ sdd-debugger)
```

### Na pausa (Claude Code)

Você **não precisa** trocar `/model` para o caminho feliz — o command já pina Haiku/Sonnet.

Opcional (hosts sem frontmatter, ou effort):

```text
/effort medium   # ou high / xhigh — só onde o modelo aceitar
```

### Caso extremo

| Situação | O que fazer |
|----------|-------------|
| Spec / arquitetura muito difícil | Sonnet + `effort high` no `/sdd.spec`; se ainda fraco → `/sdd.fix` (Opus) ou Outros no gate |
| Bug / repo profundo | `/sdd.fix` → `sdd-debugger` (Opus) |
| Security crítico no finish | Sonnet no `/sdd.finish`; se crítico demais → `/sdd.fix` |
| Evitar | Opus no caminho feliz (spec/plan/test/build) ou Opus 5 + `max` |

Se no **build** o Haiku reinventar produto ou alterar teste aprovado → pause, `/sdd.test --refine` ou `/sdd.fix`.

### Evite `/sdd.go` se pausas importam

Express auto-avança com poucas pausas → menos confirmações de modelo (o custo ainda é limitado pelo frontmatter de cada skill). Prefira o fluxo Standard comando a comando para o ritmo com AskUserQuestion.

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

- Não configura o IDE fora do que os commands já pinam em `model:`
- Não substitui o playbook nem o `PIPELINE.md`
- Detalhe operacional do advisory/gates: `commands/references/model-suggestion-advisory.md`

É leitura para quem quer gastar menos sem perder qualidade onde importa — e no Claude Code o pack **já aplica** Haiku/Sonnet/Opus via frontmatter.
