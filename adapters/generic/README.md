# Adapter: Generic / Other

**Declared support level: Fallback only.** This adapter makes no assumption about tool APIs, subagent mechanisms, or structured UI. It exists so a harness the pack doesn't explicitly know about still gets an honest, literal description of what to do — never a false sense of automated compatibility. If this adapter isn't earning its keep for a given install (i.e. the operator would get more value from picking the closest real adapter and adjusting by hand), say so and don't install it.

## What this adapter installs

| Destination                             | Source                                                                                                                    |
| --------------------------------------- | ------------------------------------------------------------------------------------------------------------------------- |
| _(nothing beyond the pack copy itself)_ | `development-agents/` is already synced to the target in Passo 2 of the installer — no adapter-specific folder is created |
| Printed instructions (not a file)       | See below                                                                                                                 |

There is no `.generic/` folder, no frontmatter overlay, and no attempt to guess an unknown harness's tool syntax.

## What the installer tells the operator instead

```
Nenhum adapter automatizado existe para o harness selecionado. O pack development-agents/
foi copiado para o projeto, mas a instalacao para de ser automatica a partir daqui:

1. Instrucoes de sessao: cole o conteudo de development-agents/AGENTS.md nas instrucoes
   de projeto do seu harness (se ele tiver esse conceito).
2. Comandos: os arquivos em development-agents/commands/*.md sao a definicao de cada
   /sdd.* comando — abra o arquivo do comando que quiser rodar e siga as instrucoes nele.
3. Skills: os arquivos em development-agents/skills/*/SKILL.md sao procedimentos
   reutilizaveis — leia o arquivo quando o fluxo indicar "invoque a skill X".
4. Delegacao isolada (validacao, revisao): abra uma nova sessao/conversa contendo so os
   arquivos relevantes (sem o raciocinio de quem implementou), rode o procedimento descrito
   em skills/sdd-validator/SKILL.md manualmente, e traga o veredito de volta.
5. Perguntas ao usuario: os gates do pipeline (aprovar spec, aprovar plano, aprovar testes,
   etc.) sao pontos onde o agente deve parar e perguntar em texto simples, sempre com uma
   opcao livre alem das sugeridas.
```

## Known gaps

Everything not explicitly automated above. This adapter deliberately does not simulate `DELEGATE_ISOLATED`, `ASK_USER`, or `ISOLATED_WORKSPACE` — see `framework/_shared/harness-capabilities.md` for what each conceptual capability means and why faking it here would be worse than not having it.
