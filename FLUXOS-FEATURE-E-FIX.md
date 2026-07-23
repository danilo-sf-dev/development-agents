# Fluxos: Feature nova e Bug (Fix)

Documento **informativo** — o mapa rápido de **quais comandos rodar** no dia a dia.  
Não substitui o pipeline canônico (`framework/PIPELINE.md`); só deixa claro o caminho **Feature** versus o caminho **Fix**.

---

## Em uma frase

- **Feature / implementação nova** → fluxo longo: `start → spec → plan → test → build → finish → pr`
- **Bug / correção** → fluxo curto: `start → fix → finish → pr`  
  (se o bug for **no meio** de uma feature já aberta → só `/sdd.fix`)

---

## Antes do primeiro card (uma vez por serviço)

Bootstrap do projeto alvo — **não** é o ciclo do card:

```
/sdd.install          → coloca o pack no projeto
/sdd.project          → stack, convenções, forbidden (modelo forte)
/sdd.reverse-eng      → specs/padrões do código existente (modelo forte)
/sdd.mcp              → opcional (Jira/Confluence só leitura)
```

Depois disso o serviço está ancorado. Cada card novo abre **um** `/sdd.start` (de preferência em chat novo).

---

## Fluxo 1 — Feature (implementação nova)

Use quando o card é **nova capacidade**, mudança de comportamento planejada, ou bug tão grande que precisa de spec/plano/testes como feature.

```
/sdd.start "JIRA-123 resumo do pedido"
    ↓
/sdd.spec            (+ --include link do Jira, se tiver)
    ↓
/sdd.plan
    ↓
/sdd.test            ← testes aprovados (fase red)
    ↓
/sdd.build           ← só implementa; não inventa teste novo
    ↓
/sdd.finish
    ↓
/sdd.pr              ← opcional
```

Atalho express (mesmo caminho, menos pausas): `/sdd.go "…"`.

Sugestão de modelo: ver `SUGESTAO-MODELOS.md`.

---

## Fluxo 2 — Fix (bug / correção)

Use quando o card é **corrigir um defeito** e você tem (ou consegue descrever) o erro: stacktrace, log, comportamento errado vs esperado.

### 2A — Card novo = bug (caso mais comum no dia a dia)

```
/sdd.start "JIRA-456 — descrição do bug"
    ↓
/sdd.fix             ← cola o erro, log, ou descreve o problema
    ↓                  (o comando investiga, propõe, aplica, re-testa)
/sdd.finish
    ↓
/sdd.pr              ← opcional
```

**Neste caminho você NÃO roda** `/sdd.spec`, `/sdd.plan`, `/sdd.test`, `/sdd.build`.  
O miolo é o `/sdd.fix`.

Variantes do fix:

```
/sdd.fix
/sdd.fix "NullPointerException em PaymentService linha 88"
/sdd.fix --file ./error.log
```

### 2B — Bug no meio de uma feature já em `sdd/wip/`

Já existe WIP (você estava no fluxo Feature e o build/teste quebrou):

```
/sdd.fix            ← com a saída do erro
    ↓
continuar de onde parou (/sdd.build ou /sdd.finish)
```

**Não** abra outro `/sdd.start`.

---

## Qual fluxo escolher?

```
É card novo?
  │
  ├─ Sim → /sdd.start
  │         │
  │         ├─ Implementação / regra nova / bug que precisa de contrato claro
  │         │     → Fluxo 1 (Feature): spec → plan → test → build → finish
  │         │
  │         └─ Bug com erro/log/comportamento quebrado
  │               → Fluxo 2A (Fix): fix → finish
  │
  └─ Não (já estou no meio do Fluxo 1 e quebrou)
        → Fluxo 2B: só /sdd.fix
```

| Situação | Fluxo |
|----------|--------|
| Nova feature no Jira | **1 — Feature** |
| Bug no Jira (primeiro trabalho do card) | **2A — Fix** |
| Teste/build falhou no meio da feature | **2B — Fix** |
| Typo / NPE óbvio / config local | Corrigir no código (SDD completo é overkill) |

---

## O que o `/sdd.fix` faz (por dentro)

Você roda **um** comando; o agent, dentro dele:

1. Checa contexto (`context-guardian`)
2. Classifica o problema
3. Investiga causa raiz
4. Propõe correção nas camadas impactadas (spec/tasks/código — só o que existir)
5. Você aprova → aplica → re-roda testes
6. Code review / validator
7. Grava registro `FIX-NNN`

---

## Lembretes

- **Um card ≈ um chat ≈ um `/sdd.start`** (feature ou bug).
- Bootstrap (`project` + `reverse-eng`) é **por serviço**, não por card.
- Detalhe canônico do pipeline Feature: `framework/PIPELINE.md` e `framework/PLAYBOOK.md`.
- Modelo forte/barato por passo: `SUGESTAO-MODELOS.md`.
