## Resumo

<!-- Objetivo do PR em 2–4 linhas. Preencher a partir da functional-spec / card Jira. -->

## Contexto SDD

| Campo | Valor |
|-------|-------|
| Feature | <!-- ex: 20260716-user-auth --> |
| Card / ticket | <!-- JIRA-1234 ou link --> |
| Branch | <!-- feature/JIRA-1234-user-auth --> |
| Base | <!-- master / main / develop --> |

## O que foi alterado

<!-- Lista objetiva — derivada de tasks.json + diff -->

-
-
-

## Testes (tests-first)

<!-- De test-plan.md / tests-manifest.json -->

- [ ] Testes aprovados no gate `/sdd.test` (fase red verificada)
- [ ] Implementação faz os testes aprovados passarem (green)
- [ ] Testes relevantes executados nesta sessão

### Cobertura / escopo de teste

<!-- Quais AC/US/tasks os testes cobrem -->

## Validação

- [ ] Build executado com sucesso (comando do projeto — ver `sdd/PROJECT.md`)
- [ ] Lint / typecheck conforme projeto
- [ ] Sem secrets ou credenciais no diff

### Evidências (opcional)

<!-- Saídas curtas de comando, links CI, prints -->

## Commits

<!-- Preencher com `git log` da branch vs base -->

- `hash` mensagem
- `hash` mensagem

## Checklist

- [ ] Escopo do PR está claro e alinhado à spec
- [ ] Não inclui mudanças não relacionadas
- [ ] Documentação atualizada (quando aplicável)
- [ ] Sem quebra de compatibilidade não documentada
- [ ] `development-agents/`, `.cursor/`, `.claude/`, `sdd/` **não** incluídos no commit (gitignored)

## Observações

<!-- Riscos, limitações, follow-ups, pontos para review -->
