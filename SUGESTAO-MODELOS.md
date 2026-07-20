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

## Sugestão por passo

| Passo | Sugestão | Por quê |
|-------|----------|---------|
| `/sdd.start` | Barato | Só cria a pasta da feature e metadados |
| `/sdd.spec` | **Forte** | Entende o pedido (chat + Jira), entrevista, AC, arquitetura |
| `/sdd.plan` | **Forte** | Quebra em tasks e dependências sem inventar escopo |
| `/sdd.test` | **Forte** | Define o que será testado e por quê (você revisa o contrato) |
| `/sdd.build` | **Barato** | Implementa o que já foi muito bem definido |
| `/sdd.finish` | **Forte** | Code review final, security e validação antes de arquivar |
| `/sdd.pr` | Barato | Descreve o PR do que já existe |
| Debug difícil / `/sdd.fix` | **Forte** (só no diagnóstico) | Volte ao barato quando o caminho estiver claro |

### Momento típico de trocar

```text
modelo forte  →  spec → plan → test → finish  (e suas aprovações)
modelo barato →  build → pr
```

Antes do `/sdd.finish`, troque para o **forte** — é onde roda o code review final.

Se no build o agente começar a reinventar produto ou mudar teste aprovado, pause e volte ao modelo forte (ou refine spec/test) em vez de insistir no barato.

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
