---
name: commit-workflow
description: >-
  Fluxo agnóstico para preparar commits com formatação, testes, validação,
  Conventional Commits e uma opção de fluxo personalizado. Use quando o
  usuário pedir commit, git commit ou concluir uma tarefa que exige commit.
---

# Commit Workflow

Esta skill funciona em qualquer linguagem ou stack. Nunca assuma Node.js,
Prettier, npm, Maven, Gradle, pytest ou outra ferramenta sem confirmar que ela
existe no projeto alvo.

## Trigger

Use quando:

- o usuário pedir um commit;
- o usuário pedir `git commit`;
- uma tarefa SDD chegar ao ponto em que um commit é necessário;
- o usuário pedir apenas preparação ou formatação antes do commit.

## Regra principal

Antes de executar comandos de formatação, testes ou commit:

1. detectar a linguagem, framework e ferramentas do projeto;
2. ler `sdd/PROJECT.md`, se existir;
3. verificar scripts e configurações do repositório;
4. não inventar comandos;
5. mostrar bloqueios ou ambiguidades ao usuário.

Use a ferramenta de detecção do pack quando disponível:

```text
development-agents/framework/tools/detect-language.sh
development-agents/framework/tools/detect-stack.sh
```

## Passo 1 — Escolha do fluxo

Faça uma pergunta obrigatória com exatamente estas quatro opções:

| Opção | Comportamento |
|---|---|
| **Fluxo completo** | Formatação + testes + validações disponíveis + commit |
| **Formatar e commit** | Formatação + validações leves configuradas + commit, sem suíte completa de testes |
| **Commit direto** | Não formatar nem testar; revisar status/diff e criar commit |
| **Outros** | Usuário descreve um fluxo personalizado |

Pergunta sugerida:

> Qual fluxo de commit deseja executar?

### Fluxo completo

1. detectar o formatador configurado;
2. executar a formatação nos arquivos relevantes;
3. adicionar ao stage somente arquivos pretendidos;
4. executar a suíte de testes configurada;
5. executar lint, typecheck, build ou validações exigidas pelo projeto;
6. se qualquer validação bloqueante falhar, abortar o commit;
7. revisar `git status`, `git diff` e arquivos staged;
8. gerar uma mensagem Conventional Commit;
9. pedir confirmação final antes de `git commit`.

### Formatar e commit

1. detectar e executar o formatador configurado;
2. não executar a suíte completa de testes;
3. executar apenas validações leves se o projeto as definir explicitamente;
4. revisar status, diff e arquivos staged;
5. gerar uma mensagem Conventional Commit;
6. pedir confirmação final antes de `git commit`.

### Commit direto

1. não executar formatador;
2. não executar testes;
3. revisar status, diff e arquivos staged;
4. verificar arquivos proibidos ou sensíveis;
5. gerar uma mensagem Conventional Commit;
6. pedir confirmação final antes de `git commit`.

### Outros

Solicite ao usuário a descrição do fluxo personalizado. Antes de executar:

1. interpretar a solicitação em passos concretos;
2. listar os comandos que serão executados;
3. informar quais passos serão pulados;
4. pedir confirmação;
5. interromper se a solicitação for ambígua ou potencialmente destrutiva.

Exemplos válidos:

- “Rodar somente os testes de autenticação.”
- “Formatar apenas os arquivos TypeScript.”
- “Executar `mvn spotless:apply` e depois `mvn test`.”
- “Rodar lint, mas não executar os testes.”
- “Somente preparar o stage; não criar o commit.”

Não execute `reset --hard`, `clean -f`, remoções em massa ou comandos
equivalentes sem confirmação explícita.

## Descoberta de ferramentas

Priorize, nesta ordem:

1. comandos definidos em `sdd/PROJECT.md`;
2. scripts do projeto (`package.json`, `Makefile`, `pom.xml`,
   `build.gradle`, `pyproject.toml`, `go.mod`, `Cargo.toml` ou equivalentes);
3. configurações de ferramentas existentes;
4. convenções detectadas no projeto;
5. pergunta ao usuário quando não houver uma escolha segura.

Exemplos de ferramentas possíveis:

| Ecossistema | Formatação | Testes |
|---|---|---|
| JavaScript/TypeScript | Prettier, Biome | Jest, Vitest, script do projeto |
| Java/Kotlin | Spotless, formatter do projeto | Maven ou Gradle |
| Python | Ruff, Black | pytest |
| Go | gofmt, goimports | `go test` |
| Rust | `cargo fmt` | `cargo test` |

Esses exemplos não autorizam o agent a executar o comando sem detectá-lo no
projeto.

## Conventional Commits

Use:

```text
<type>(<scope>): <description>
```

Tipos permitidos:

`feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `chore`, `ci`

A mensagem deve ser escrita em **português** e explicar a intenção da
mudança. O `type` e o `scope` permanecem nos identificadores padronizados;
somente a descrição deve ser em português.

Exemplos:

```text
feat(auth): adicionar validação de sessão expirada
fix(fatura): corrigir cálculo do valor total
test(parser): adicionar casos de borda para arquivo vazio
refactor(api): extrair validação para serviço dedicado
docs(sdd): documentar fluxo de testes
```

Nunca use mensagens vagas como `update`, `fix`, `WIP` ou `changes`.

## Segurança e escopo

> Regras canônicas: `framework/standards/boundaries.md` — B-04, B-17, section **`commit-workflow`**.

Antes do commit, confirme: branch atual, arquivos staged, diff staged, ausência de secrets, mensagem final.

## Graphify — integração opcional de contexto

Graphify não faz parte do commit e nunca deve ser adicionado ao stage.
`graphify-out/` é um contexto auxiliar do projeto, não um artefato da
funcionalidade.

### Detecção

Se o projeto tiver `graphify-out/graph.json`, configuração Graphify ou o
comando `graphify` disponível, considere a integração detectada.

Se não houver evidência de Graphify, não faça pergunta sobre Graphify e siga
o fluxo normalmente.

### Quando detectado

Após alterações de código, o agent pode atualizar o contexto com:

```bash
graphify update .
```

Essa atualização deve ser não bloqueante e não deve alterar o escopo do
commit. Não execute `graphify update` quando a mudança for apenas documentação,
spec ou Markdown sem alteração estrutural de código.

Se o projeto já possuir hooks `post-commit` ou `post-checkout`, respeite-os.
Não execute uma segunda atualização sem necessidade.

### Restrições

- não perguntar se `graphify-out/` deve entrar no commit;
- não executar `graphify extract` automaticamente;
- não exigir API key;
- não bloquear o commit se a atualização falhar;
- não executar Graphify quando ele não estiver presente;
- nunca fazer `git add graphify-out/` automaticamente.

## Resultado

Ao concluir, informe:

- fluxo escolhido;
- ferramentas detectadas e executadas;
- validações executadas e resultado;
- arquivos incluídos no commit;
- mensagem do commit;
- se Graphify foi detectado e atualizado separadamente;
- qualquer validação que foi pulada e o motivo.
