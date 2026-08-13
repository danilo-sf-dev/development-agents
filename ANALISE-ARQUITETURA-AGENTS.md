# Análise da camada de papéis (Agents) — development-agents

> Investigação arquitetural em 3 rodadas. Nenhum arquivo de `agents/`, `skills/` ou `commands/` foi alterado — isto é só análise + experimentos controlados e reversíveis. Data: 2026-08-13.

## Como ler este documento

- **Rodada 1**: classificação inicial dos 12 agentes (Agent / Skill / Fundir / Investigar).
- **Rodada 2**: desafio da premissa "precisa de offload ⇒ precisa de Agent dedicado", com achados de mecanismo (o que é overridable por chamada vs. só por arquivo de identidade).
- **Rodada 3**: validação **experimental real** nesta sessão — 8 chamadas reais ao mecanismo de subagente, não inferência.

Cada afirmação técnica é marcada como:

- 🟢 **Testado nesta sessão** — executei e observei o resultado.
- 🔵 **Suportado por documentação** — confirmado lendo o pack (`framework/_shared/harness-capabilities.md`, `commands/*.md`).
- ⚪ **Inferência** — raciocínio meu, não testado nem documentado explicitamente.
- 🔴 **Não suportado** — testado e confirmado que NÃO funciona.
- ⬛ **Não foi possível testar** — depende de infraestrutura fora do meu acesso.

---

## Rodada 1 — Classificação inicial dos 12 agentes

| Agente | Classificação | Motivo principal |
|---|---|---|
| `development-agents-installer` | Pode virar Skill | Checklist mecânico, sem viés a proteger |
| `sdd-backlog-manager` | Pode virar Skill | O próprio arquivo já se descreve como offload opcional |
| `sdd-debugger` | Agent | Deep reasoning, modelo opus, exploração iterativa |
| `sdd-explorer` | Agent | Maior volume de offload do pack (grep/leitura pesada) |
| `sdd-implementer` | Agent | Write/Edit + worktree, trabalho de dev real |
| `sdd-large-test-writer` | Fundir em `sdd-small-test-writer` | Sobreposição de responsabilidade, condicional |
| `sdd-layer-analyzer` | Agent | Offload de leitura cross-layer |
| `sdd-mcp-setup` | Agent | Wizard multi-turn embutido em outros fluxos |
| `sdd-project-wizard` | Agent | Caso documentado: ~15k→~200 tokens |
| `sdd-small-test-writer` | Agent | Write/Edit + worktree, gate obrigatório |
| `sdd-system-designer` | Agent | Deep reasoning pré-Gate 1, WebSearch/WebFetch |
| `sdd-validator-runner` | Agent (não-negociável) | `DELEGATE_ISOLATED` — isolamento de viés é requisito de correção, não otimização |

**Resultado**: 12 → 8 Agents, 3 Skills novas, 1 fusão.

---

## Rodada 2 — Desafiando "offload" como sinônimo de "Agent"

Três fatos de mecanismo, relidos direto do schema real da ferramenta de subagente disponível nesta sessão:

- 🔵 **Fato 1**: `model` e `isolation` (`worktree`/`remote`) são parâmetros de **chamada**, não exigem arquivo de identidade — na época, isso era leitura de schema, não teste.
- 🔵 **Fato 2**: não há parâmetro `tools`/`allowed_tools`/`disallowed_tools` documentado no schema da ferramenta de subagente.
- 🔵 **Fato 3**: o installer já roda hoje via *direct-file-follow* (a própria sessão principal lê e segue `agents/development-agents-installer.md`) — nunca existiu `Task(subagent_type="development-agents-installer", ...)` em lugar nenhum do pack. Confirmado por grep em `commands/`.

Com isso, reclassifiquei (ainda sem testar em runtime):

| Agente | Rodada 1 | Rodada 2 (revisado) | Motivo da mudança |
|---|---|---|---|
| `sdd-explorer` | Agent | Skill + worker read-only | Read-only genérico já cobre a garantia de tools; Cursor já degrada offload pra inline hoje mesmo sendo Agent |
| `sdd-layer-analyzer` | Agent | Skill + worker read-only | Mesma lógica — não é `DELEGATE_ISOLATED`, é puro volume |
| `sdd-project-wizard` | Agent | Skill + worker genérico + `model` override | Ganho de contexto vem do offload, não da identidade |
| `sdd-mcp-setup` | Agent | Skill | O próprio `commands/sdd.mcp.md` já diz "inline fallback is a complete substitute, not a degraded one" |
| `sdd-debugger` | Agent | Shell fino (Read/Glob/Grep/Bash, **sem Write/Edit**) + Skill | Modelo overridable por chamada; só a ausência de Write é uma fronteira real |
| `sdd-system-designer` | Agent | Shell fino (+ WebSearch/WebFetch, sem Write) + Skill | Fronteira real: não pode tocar código antes do Gate 1 |
| `sdd-implementer` | Agent | Shell fino (Write/Edit/worktree, sem Web) + Skill | Fronteira real: não deve "re-pesquisar" depois do Gate 2 |
| `sdd-validator-runner` | Agent | Mantido, sem mudança | Isolamento de viés é o requisito, não o offload |

**Resultado da Rodada 2**: 8 → 5 Agents ("shells finos" definidos só por fronteira de tools), 6 Skills.

**Limitação explícita da Rodada 2**: tudo isso vinha de ler o schema, não de testar. O usuário pediu, corretamente, para não aceitar isso sem prova em runtime — daí a Rodada 3.

---

## Rodada 3 — Validação experimental (rodada nesta sessão, agora)

Todos os experimentos abaixo foram **executados de verdade** nesta sessão via o mecanismo real de subagente (equivalente a `Task(subagent_type=...)`), não simulados. Artefatos temporários (arquivo de teste de escrita, `PROJECT.md.experiment`, worktree de teste) foram criados e removidos ao final; nenhum arquivo do pack real foi tocado.

### Experimento 1 — `sdd-explorer` como Skill + worker read-only nativo

**Setup**: worker `Explore` (tipo genérico read-only já embutido no harness) recebeu `agents/sdd-explorer.md` como conteúdo ad-hoc de Skill e aplicou o protocolo de "Technology Stack Detection" + "Quick Scan Protocol" ao próprio repo `development-agents`.

**Resultado**:
- 🟢 Produziu um "Discovery Summary" no formato exato definido pelo arquivo original (Technology Stack / Architecture Pattern / Key Components), corretamente identificando o repo como um pack markdown sem stack de build.
- 🟢 Retornou **só o resumo compacto** (~200 palavras) — nenhuma saída bruta de grep/find/ls voltou para minha sessão principal. Isolamento de contexto confirmado, não inferido: eu literalmente não vi as chamadas intermediárias, só o relatório final.
- 🟢 **Teste de escrita**: instruí o worker a tentar gravar um arquivo. Ele reportou: *"Confirmed: no local Write tool exists in my toolset at all (checked both the active tool list and the deferred-tool registry via ToolSearch)"* — bloqueio **rígido**, no nível de ferramenta disponível, não uma regra de prompt que ele escolheu obedecer.

**Conclusão**: equivalente funcional ao Agent dedicado, com garantia read-only real e mais forte do que eu esperava (nem sequer aparece no registro de tools, não é "tool presente mas negada por policy").

---

### Experimento 2 — `sdd-layer-analyzer` como Skill + worker read-only

**Setup**: mesmo worker `Explore`, carregando `agents/sdd-layer-analyzer.md` como Skill, aplicado a uma checagem cross-layer real (comparar `framework/PIPELINE.md` contra os 8 arquivos de `commands/` que ele referencia).

**Resultado**:
- 🟢 Produziu uma Coverage Matrix + Drift Details no formato exato do arquivo original, cobrindo os 8 comandos citados no pipeline, e corretamente notou que `/sdd.check --sync` já delega para `sdd-layer-analyzer` (referência cruzada correta, mostrando que entendeu o conteúdo carregado, não só copiou template).
- 🟢 Achou 0 drifts reais (pipeline e comandos estão de fato consistentes) — resultado plausível e verificável.
- 🟢 Retorno compacto (~250 palavras), sem dump de arquivo.

**Conclusão**: mesma equivalência do Experimento 1. Não há nada em `sdd-layer-analyzer` que dependa de identidade — é puro offload de volume, como eu já suspeitava, agora comprovado.

---

### Experimento 3 — `sdd-project-wizard` como Skill + worker genérico + `model` override

**Setup**: worker `general-purpose` com `model="haiku"` (override explícito por chamada), carregando `agents/sdd-project-wizard.md`, em modo dry-run (proibido tocar `sdd/` do repo real; devia escrever no scratchpad).

**Resultado**:
- 🟢 `model="haiku"` foi aceito e aplicado com sucesso na chamada — não precisou de frontmatter de agente dedicado.
- 🟢 Verifiquei via `ls`/`git status` **depois** da execução: `sdd/` **não existe** no repo real, e o arquivo apareceu corretamente em `scratchpad/PROJECT.md.experiment`. O dry-run foi respeitado de fato, não só na intenção.
- ⚠️ **Achado colateral importante**: o texto de resumo retornado pelo worker disse `"Path": "sdd/PROJECT.md"` — um rótulo copiado literalmente do template do arquivo original, mesmo tendo escrito no lugar certo (scratchpad). Ou seja: **o relatório final de um worker pode ficar cosmeticamente impreciso mesmo quando a ação real foi correta** — reforça que "trust but verify" vale tanto para Agent quanto para Skill+worker; não é uma vulnerabilidade nova introduzida pela mudança de arquitetura, mas vale documentar como cuidado operacional.

**Conclusão**: o ganho de contexto (diálogo do wizard fora da sessão principal, retorno resumido) não depende da identidade `sdd-project-wizard` — é obtido pela combinação fresh-context + `model` override, ambos disponíveis num worker genérico.

---

### Experimento 4 — Restrição de `tools` por chamada (o mais importante)

Este foi o único experimento onde a hipótese da Rodada 2 **não se sustentou** ao ser testada.

**Teste A** — chamada com `tools`, `allowed_tools`, `disallowed_tools` extras, sem tarefa real:
- 🟢 O harness **não rejeitou** a chamada por causa dos campos desconhecidos (diferente do que o schema `additionalProperties: false` sugeria que aconteceria). A chamada foi despachada normalmente.
- O worker resultante reportou corretamente que não tem visibilidade sobre se alguma restrição foi de fato aplicada por trás — só poderia saber tentando usar a ferramenta.

**Teste B (decisivo)** — mesma chamada, mas com uma tarefa real exigindo `Write`, e `disallowed_tools: ["Write", "Edit", "Bash"]` explicitamente:
- 🔴 **`Write` funcionou normalmente.** O worker escreveu o arquivo de teste sem erro, sem prompt de permissão, apesar de `Write` estar explicitamente na lista de bloqueio.

**Conclusão testada, não inferida**: **não existe, nesta sessão/mecanismo, uma forma de restringir `tools` dinamicamente por chamada.** Os parâmetros `tools`/`allowed_tools`/`disallowed_tools` são aceitos sintaticamente mas **não têm efeito real**. A única forma comprovada de obter um perfil de ferramentas restrito é usar um **tipo de subagente nomeado** cuja restrição já vem embutida na definição do tipo (como `Explore`, que comprovadamente não tem `Write` — Experimento 1) — ou seja, um arquivo de definição de Agent (mesmo que fino).

**Isso muda a conclusão da Rodada 2 para `sdd-debugger`, `sdd-system-designer` e `sdd-implementer`**: a ideia de "shell fino sem arquivo, restrição via parâmetro de chamada" **não é viável neste mecanismo**. Para essas fronteiras de permissão (sem Write no debugger, sem Write no system-designer, sem Web no implementer), **precisa mesmo de um arquivo de Agent dedicado com `tools:` fixo no frontmatter** — não existe atalho por parâmetro.

---

### Experimento 5 — Isolamento por viés (estilo `sdd-validator-runner`) com prompt scrubbed

**Setup**: worker `Explore` recebeu **apenas** um caminho de arquivo + uma regra de verificação, explicitamente instruído a não perguntar o motivo ("this is intentional for this experiment").

**Resultado**:
- 🟢 O worker não pediu contexto adicional, não tentou racionalizar, e devolveu exatamente o formato de veredito estruturado solicitado (`checks_run`/`issues`/`verdict`), com uma verificação real e verificável (cross-reference de IDs de regra `B-NN` entre `agents/`+`commands/` e `boundaries.md`, resultado: `APPROVED`, 0 pendências).
- 🟢 Fresh context: garantido estruturalmente por construção — cada chamada de subagente começa sem memória da conversa principal (comprovado pela ausência de qualquer referência a contexto anterior na resposta).
- 🔴 **Mas o mesmo Experimento 4 se aplica aqui**: se a tarefa real do validator-runner precisasse bloquear `Write`/`Edit` para garantir que o worker "não pode corrigir silenciosamente o que encontrou", isso **não é possível via parâmetro de chamada** — só via tipo de subagente com tools fixas (`Explore` já serve, coincidentemente, porque não tem Write).

**Conclusão**: a parte de **isolamento de viés** (prompt scrubbed + fresh context) **não depende de identidade** — um worker genérico (`Explore`) consegue. Mas a parte de **"não pode ter tools de escrita"** depende de usar um tipo com tools fixas — que `Explore` já satisfaz por coincidência de perfil, mas que não seria garantido se o validator precisasse, por exemplo, rodar builds com `Bash` de forma mais ampla que `Explore` permite (Explore já inclui Bash, então isso não chega a ser um problema real aqui — mas seria se o perfil precisasse ser mais estrito que qualquer tipo nomeado existente).

**Resposta à pergunta central do Experimento 5**: a integridade do gate **não depende do nome `sdd-validator-runner`**, depende de duas garantias que juntas hoje só se obtêm assim: (1) fresh context + prompt scrubbed (worker genérico resolve), e (2) tools sem Write/Edit (só um tipo nomeado com essa restrição resolve — `Explore` já é esse tipo, coincidentemente).

---

### Experimento 6 — `sdd-implementer` × `sdd-small-test-writer`

Não precisou de execução nova — é comparação estrutural dos dois arquivos já lidos integralmente nas rodadas anteriores:

| | `sdd-implementer` | `sdd-small-test-writer` |
|---|---|---|
| Tools | Read, Glob, Grep, Edit, Write, Bash | Read, Glob, Grep, Edit, Write, Bash |
| Worktree | `isolation: worktree` | `isolation: worktree` |
| Model | `inherit` | `inherit` |
| WebSearch/WebFetch | Não | Não |

⚪ **Achado (inferência a partir dos arquivos, não testado em runtime porque não há dependência técnica a testar)**: os dois têm o **perfil de tools idêntico**. A diferença entre eles não é de fronteira de permissão — é puramente de **conteúdo/Skill** (o que fazer com as mesmas ferramentas). Sob o critério "Agent = fronteira de tools" que a Rodada 2 estabeleceu e o Experimento 4 confirmou como o único critério que realmente exige arquivo dedicado, `sdd-implementer` e `sdd-small-test-writer` são o **mesmo perfil de execução** com duas Skills diferentes carregadas — mais parecidos entre si do que qualquer um deles é com `sdd-debugger` ou `sdd-system-designer`.

**Risco perguntado pelo usuário** ("Test Writer receber contexto de implementação que não deveria"): não se aplica ao perfil de tools — aplica-se à ORDEM de invocação. Como testes são escritos no Gate 2.5 (antes de existir implementação) e cada chamada de subagente começa em fresh context (confirmado estruturalmente em todos os experimentos acima), esse risco já é neutralizado pela ordem do pipeline, não pela separação de identidade. Mesmo perfil único, chamado duas vezes com Skills diferentes, preservaria essa proteção.

---

## Tabela consolidada — Rodada 3

| Papel | Skill possível? | Generic worker possível? | Precisa Agent/profile próprio? | Motivo técnico real |
|---|---|---|---|---|
| `sdd-explorer` | 🟢 Sim (testado) | 🟢 Sim, `Explore` (testado) | **Não** | Read-only já é preset nativo; offload puro de volume |
| `sdd-layer-analyzer` | 🟢 Sim (testado) | 🟢 Sim, `Explore` (testado) | **Não** | Mesma lógica; não é `DELEGATE_ISOLATED` |
| `sdd-project-wizard` | 🟢 Sim (testado) | 🟢 Sim, `general-purpose` + `model` override (testado) | **Não** | Ganho vem de fresh-context + model override, ambos por parâmetro |
| `sdd-mcp-setup` | 🔵 Sim (pack já declara "complete substitute") | 🔵 Sim, mesmo raciocínio do wizard | **Não** | Sem restrição de tools por segurança |
| `sdd-backlog-manager` | 🔵 Sim (pack já trata como opcional) | 🔵 Sim | **Não** | CRUD determinístico, sem viés, sem restrição |
| `development-agents-installer` | 🟢 Sim (já roda via direct-file-follow hoje) | N/A (roda inline por design) | **Não** | Nunca foi despachado via subagente — sempre foi Skill de fato |
| `sdd-debugger` | 🔵 Conteúdo sim | 🔴 Não plenamente — falta bloquear Write/Edit por chamada (testado e confirmado que falha) | **Sim, arquivo fino** (`tools:` sem Write/Edit) | Único jeito comprovado de restringir tools é tipo nomeado com frontmatter fixo |
| `sdd-system-designer` | 🔵 Conteúdo sim | 🔴 Não plenamente — mesma limitação (Write bloqueado só via frontmatter) | **Sim, arquivo fino** (`tools:` com Web, sem Write) | Idem — fronteira pré-Gate-1 |
| `sdd-implementer` | 🔵 Conteúdo sim | ⚪ Tecnicamente sim (não precisa bloquear nada que `general-purpose` não já tenha) — mas ver nota abaixo | **Sim, mas pode ser o MESMO arquivo que test-writer** | Sem fronteira de tools a proteger; só precisa de Write+worktree, que `general-purpose`+`isolation` já dá |
| `sdd-small-test-writer` | 🔵 Conteúdo sim | ⚪ Idem `sdd-implementer` | **Sim, mas pode ser o MESMO arquivo que implementer** | Perfil de tools idêntico ao implementer (Experimento 6) |
| `sdd-validator-runner` | 🔵 Conteúdo sim | 🟡 Parcial — fresh-context+scrubbed-prompt testados e funcionam (Exp. 5); bloqueio de Write só via tipo nomeado (`Explore` cobre por coincidência) | **Sim** | Isolamento de viés é a parte não-negociável; a parte de tools tem solução via `Explore`, mas não é "sem Agent nenhum" — é "sem Agent CUSTOM", já que usa um tipo pronto |

Nota sobre `sdd-implementer`/`sdd-small-test-writer`: marquei "sim, mas pode ser o mesmo arquivo" porque, diferente de debugger/system-designer, `general-purpose` + `isolation: worktree` já dá exatamente o perfil que os dois precisam (Write/Edit/Bash + worktree, sem nada a bloquear) — então tecnicamente nem precisariam de arquivo dedicado. Mantive como "sim" mais conservador porque não testei explicitamente `general-purpose` fazendo escrita de código real dentro de um worktree isolado (só testei worktree isoladamente no Experimento do meio, e Write isoladamente no Experimento 4) — a combinação das duas coisas juntas não foi validada ponta a ponta.

---

## Três cenários

### Cenário A — Conservador
Manter os 5 Agents da Rodada 2 como shells finos: `sdd-debugger`, `sdd-system-designer`, `sdd-implementer`, `sdd-small-test-writer`, `sdd-validator-runner`. 6 Skills para o resto.
**Por quê**: não exige nenhuma mudança em relação à Rodada 2 — só formaliza o que já foi comprovado (explorer/layer-analyzer/wizard/mcp/backlog/installer viram Skill) sem forçar a fusão implementer↔test-writer, que não foi testada ponta a ponta.

### Cenário B — Mínimo comprovado
Aplicar também o achado do Experimento 6: fundir `sdd-implementer` + `sdd-small-test-writer` num único arquivo de Agent (`tools: Read, Glob, Grep, Edit, Write, Bash` + `isolation: worktree`) carregando duas Skills diferentes (`implementation` vs `test-writing`), selecionadas pelo comando que invoca. Resultado: **4 Agents** (`sdd-debugger`, `sdd-system-designer`, `sdd-implementer-executor`, `sdd-validator-runner`) + 7 Skills.
**Risco a testar antes de aceitar**: validar em runtime que um worktree isolado + Write real de código funcionam juntos (não testado nesta rodada — só testei os dois separadamente).

### Cenário C — Futuro (se o harness ganhar restrição de tools por chamada)
Se uma versão futura do mecanismo aceitar `tools`/`allowed_tools`/`disallowed_tools` **de verdade** (o Experimento 4 provou que hoje não aceita), a arquitetura mínima real colapsaria para:
- **1 único Agent**: `sdd-validator-runner` — o único papel cuja necessidade não é dissolvida por nenhum parâmetro de chamada (é isolamento de viés, uma propriedade de PROMPT, não de tooling — já resolvida hoje via `Explore`+prompt scrubbed, mas mantida como Agent nomeado para não depender de todo chamador lembrar de fazer o scrub corretamente toda vez).
- Todos os outros 11 papéis: Skills, cada um invocado com `model`/`isolation`/`tools` ajustados por chamada, sem nenhum arquivo em `agents/` além do validator.

---

## Recomendação

Não implementar ainda — como pedido. Duas decisões pendentes para fechar antes de mexer em arquivos:

1. **Cenário A vs B**: B economiza 1 arquivo a mais, mas depende de um teste ponta-a-ponta (worktree + Write de código real) que não rodei nesta sessão — recomendo rodar esse teste específico antes de escolher B.
2. Mesmo no Cenário A, o Experimento 4 já é evidência suficiente para não tentar "shells sem arquivo nenhum" para debugger/system-designer — eles precisam permanecer como arquivos de Agent (ainda que muito mais finos que hoje, com o grosso do conteúdo movido para Skills que eles carregam).

Nenhum arquivo de `agents/`, `skills/` ou `commands/` foi alterado nesta análise.
