# Sugestão: quando usar modelo mais forte ou mais barato (Claude Code)

Documento **informativo**, com sabor **Claude Code**, para quem está aprendendo a rodar o time de
agents SDD. Não é a política canônica — essa é [`framework/_shared/model-routing.md`](./framework/_shared/model-routing.md)
(harness-agnostic, `STRONG`/`EXECUTION`, sem nomes concretos de modelo). Este doc só traduz essa
política para nomes reais de modelo Claude Code, com dicas de effort e janela de contexto.

---

## Em uma frase

Use `STRONG` enquanto a feature ainda está sendo **definida** (e sempre para testes e validação —
são gates de qualidade, não execução mecânica). Use `EXECUTION` quando for **implementar** o que já
foi aprovado nos passos anteriores.

O build consome muitos tokens. Se o "o quê" e o "como testar" já estão claros em `sdd/wip/`, não
precisa pagar inteligência de ponta para seguir tasks e fazer o código passar nos testes.

---

## Por que isso faz sentido

O pipeline SDD separa propositalmente:

1. **Decidir** — problema, escopo, arquitetura, plano, contrato de testes (com você aprovando)
2. **Executar** — escrever código a partir desses artefatos

Erro na decisão (spec/plan/test) propaga para tudo. Erro na execução, com specs boas, costuma ser
mais barato de corrigir. Por isso: investir em `STRONG` no começo (e em testes/validação sempre);
economizar com `EXECUTION` na implementação mecânica.

---

## Papéis → Claude Code (mapeamento deste harness)

| Model Role (canônico) | Modelo Claude Code | Onde |
|---|---|---|
| `EXECUTION` | **Haiku 4.5** | `/sdd.start`, `/sdd.plan`, `/sdd.build`, `/sdd.check`, `/sdd.pr`, `/sdd.mcp`, `/sdd.backlog`, `/sdd.install`, `/sdd.project`, `/sdd.doctor`, `/sdd.import`, `/sdd.rollback` |
| `STRONG` | **Sonnet 5** (effort `high` por padrão) | `/sdd.spec`, `/sdd.test`, `/sdd.finish`, `/sdd.reverse-eng`, `/sdd.fix` + Skill `sdd-debugger` |
| `inherit` | Segue o modelo do comando pai | `/sdd.go`, `/sdd.hub` (delegam para Skills que resolvem seu próprio role) |

Skills de execução/descoberta (`sdd-implementation`, `sdd-explorer`) usam `model_role: EXECUTION` por
padrão; `sdd-test-writing`, `sdd-system-design`, `sdd-validator` usam `model_role: STRONG` sempre —
ver a tabela completa e as regras de escalation/de-escalation em `model-routing.md`.

> **Sem tier "Opus/Extremo" automático.** A política canônica define só dois roles (`STRONG`,
> `EXECUTION`) — nenhum comando resolve Opus por padrão, nem `/sdd.fix`. Se um caso realmente exigir
> Opus (arquitetura/legado excepcionalmente difícil), isso é uma **troca manual do operador** no
> Claude Code (`/model opus`), fora do routing automático — não é mais um passo pinado pelo pack.

**Garantia de não pagar mais do que o esperado:** no Claude Code, o `model_role:` do frontmatter do
`/sdd.*` é traduzido pelo instalador em um `model:` concreto (Haiku/Sonnet) no `.claude/commands/`
gerado, sobrescrevendo o modelo da sessão **naquele turno**. Esquecer de trocar manualmente não faz
o build rodar caro — o comando instalado já está pinado em Haiku.

**Garantia de pausa:** no fluxo **Standard** (comando a comando), cada fase termina com
`AskUserQuestion`; nas trocas críticas `test→build` e `build→finish` há confirmação explícita de
role. No **Express** (`/sdd.go`) há menos pausas — o custo continua limitado pelo `model_role` de
cada comando/Skill delegado, mas o ritmo educativo some. Prefira Standard se quiser as pausas.

### Effort e custo

Effort **não muda o preço por token** — muda **quantos tokens** (thinking + tools) o modelo gasta.

| Effort | Custo relativo | Uso típico |
|--------|----------------|------------|
| `low` | Mais barato | Ops simples / alto volume |
| `medium` | Economia vs default | Bom equilíbrio (plan, test) |
| `high` | Default do Sonnet 5 | Spec functional, finish |
| `xhigh` | Bem mais caro | Diagnóstico difícil / coding agentic longo |
| `max` | Sem teto | Evitar no dia a dia |

**Haiku 4.5:** na prática trate effort como **N/A** (não usa o dial moderno de effort como Sonnet).

**Armadilha:** Sonnet 5 default = `high`. Se não setar `/effort medium` em plan/test, você paga o
default mais caro sem precisar — nem toda tarefa `STRONG` precisa do `high`.

### Contexto (janela)

| Modelo | Contexto | Max output |
|--------|----------|------------|
| Haiku 4.5 | **200k** | 64k |
| Sonnet 5 | **1M** | 128k |

No build com Haiku, sessão/repo muito grande enche a janela mais rápido → `/compact` ou escale para
`STRONG` naquela fase (ver Escalation em `model-routing.md`).

### Fluxo Standard — planilha por pausa

| # | Pausou em… | Próximo comando | Role (frontmatter) | Modelo Claude Code | Effort |
|---|------------|-----------------|---------------------|---------------------|--------|
| 1 | Início | `/sdd.start` | EXECUTION | Haiku 4.5 | N/A |
| 2 | Pós-start | `/sdd.spec` functional | STRONG | Sonnet 5 | `high` |
| 3 | Approve functional | `/sdd.spec` technical | STRONG | Sonnet 5 | `medium` *( `high` se arch nova)* |
| 4 | Approve technical | `/sdd.plan` | EXECUTION | Haiku 4.5 | N/A |
| 5 | Approve plan | `/sdd.test` | STRONG | Sonnet 5 | `medium` *( `high` se regra ambígua)* |
| 6 | Approve testes | `/sdd.build` | EXECUTION | Haiku 4.5 | N/A |
| 7 | Build ok | `/sdd.check` (opcional) | EXECUTION | Haiku 4.5 | N/A |
| 8 | Pré-arquivar | `/sdd.finish` | STRONG | Sonnet 5 | `high` |
| 9 | Feature arquivada | `/sdd.pr` | EXECUTION | Haiku 4.5 | N/A |

> As pausas 6 e 8 pedem confirmação explícita de role (`AskUserQuestion`). O frontmatter já aplica
> Haiku/Sonnet mesmo se você só clicar "Seguir".

### Caso extremo (fora do routing automático)

| Situação | O que fazer |
|----------|-------------|
| Spec / arquitetura muito difícil | Sonnet (`STRONG`) + `effort high` no `/sdd.spec`; se ainda insuficiente → troca manual para Opus fora do routing, ou `/sdd.fix` |
| Bug / repo profundo | `/sdd.fix` → `sdd-debugger` (`STRONG` = Sonnet); troca manual para Opus só se Sonnet insistir sem resolver |
| Security crítico no finish | Sonnet (`STRONG`) no `/sdd.finish`; escalar manualmente se crítico demais |

Se no **build** (`EXECUTION`) o modelo reinventar produto ou alterar teste aprovado, ou bater em um
dos gatilhos de escalation (`model-routing.md`): pause, `/sdd.test --refine` ou `/sdd.fix` em vez de
insistir no barato.

### Evite `/sdd.go` se pausas importam

Express auto-avança com poucas pausas → menos confirmações de role (o custo ainda é limitado pelo
`model_role` de cada comando/Skill delegado). Prefira o fluxo Standard comando a comando para o ritmo
com AskUserQuestion.

---

## Ordem de contexto (também ajuda no custo)

Independente do role, passar o card cedo na spec reduz perguntas repetidas:

```text
/sdd.start "PAY-42 pix refund — seu ângulo / fora de escopo"

/sdd.spec --include "https://…/browse/PAY-42"
também: o que o card não deixa explícito
```

O Jira (ou texto colado) alimenta o contexto; a conversa cobre só os gaps. Detalhe do fluxo do dia a
dia: `framework/PLAYBOOK.md`.

---

## O que este doc não é

- Não é a política canônica de routing — isso é `framework/_shared/model-routing.md` (harness-agnostic)
- Não configura o IDE fora do que o instalador já traduz em `model:` no `.claude/commands/` gerado
- Não substitui o playbook nem o `PIPELINE.md`
- Detalhe operacional do advisory/gates: `commands/references/model-suggestion-advisory.md`
- Mapeamento de role para outros harnesses (Cursor, Codex, Generic): `adapters/<harness>/README.md`

É leitura para quem quer gastar menos sem perder qualidade onde importa — no Claude Code o pack **já
resolve** Haiku/Sonnet a partir do `model_role:` de cada comando.
