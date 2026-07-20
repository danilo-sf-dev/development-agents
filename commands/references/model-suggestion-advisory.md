# Reference: Model Suggestion Advisory

**Used by**: Phase-boundary gates (next-steps, approvals) and optional command entry.

> **INFORMATIVE ONLY** — not a gate, not a rule. Aligns with `SUGESTAO-MODELOS.md` at repo root (optional reading for humans).

---

## When to show

| Trigger | Action |
|---------|--------|
| Before every **Interactive Next Steps** `AskUserQuestion` at a phase boundary | Show **full box** (mandatory) |
| On **command entry** for `/sdd.start`, `/sdd.spec`, `/sdd.plan`, `/sdd.test`, `/sdd.build`, `/sdd.reverse-eng`, `/sdd.fix` | Show **compact line** (recommended, once per invocation) |
| **Express mode** (`/sdd.go`, `execution_mode: express`) between auto-advanced steps | Skip — **except** before `/sdd.build`: show full box for `test→build` (critical switch) |
| `/sdd.help`, `/sdd.check`, `/sdd.install`, mid-task build layers | Skip unless transitioning to next phase |

Show the box **before** any optional CONTEXT ADVISORY (context first is fine either order; prefer **model advisory first**, then context).

---

## Phase catalog

Use the `phase_key` when invoking this reference from command files.

| `phase_key` | Próximo passo | Modelo | Motivo (PT) |
|-------------|---------------|--------|-------------|
| `start→spec` | `/sdd.spec` | **FORTE** | Entender pedido, entrevista, AC |
| `functional→technical` | `/sdd.spec technical` | **FORTE** | Arquitetura e decisões técnicas |
| `technical→plan` | `/sdd.plan` | **FORTE** | Quebrar escopo em tasks |
| `spec→plan` | `/sdd.plan` | **FORTE** | Plano a partir de specs aprovadas |
| `plan→test` | `/sdd.test` | **FORTE** | Contrato de testes e casos de borda |
| `test→build` | `/sdd.build` | **BARATO** | Executar o que já foi aprovado |
| `build→finish` | `/sdd.finish` | **BARATO** | Fechar e arquivar |
| `finish→pr` | `/sdd.pr` | **BARATO** | Descrever PR do que existe |
| `finish→start` | `/sdd.start` | **BARATO** | Só metadados; forte de novo no spec |
| `reverse-eng→start` | `/sdd.start` | **BARATO** | Extração já concluída |
| `reverse-eng→promote` | PROMOTE / `/sdd.start` | **BARATO** após promote | |
| `project→reverse-eng` | `/sdd.reverse-eng` | **FORTE** | Mapear legado do código |
| `project→start` | `/sdd.start` | **BARATO** | |
| `mcp→next` | `/sdd.spec` ou `/sdd.start` | **FORTE** se spec; **BARATO** se start | |
| `entry:spec` | (fase atual) | **FORTE** | Definir o quê e como |
| `entry:plan` | (fase atual) | **FORTE** | Decompor sem inventar escopo |
| `entry:test` | (fase atual) | **FORTE** | O que testar e por quê |
| `entry:build` | (fase atual) | **BARATO** | Seguir tasks + testes aprovados |
| `entry:reverse-eng` | (fase atual) | **FORTE** | Síntese a partir do código |
| `entry:fix` | (fase atual) | **FORTE** | Diagnóstico; barato só após caminho claro |
| `entry:start` | (fase atual) | **BARATO** | Só metadados; FORTE no `/sdd.spec` (Step 12) |
| `express:overview` | fluxo `/sdd.go` | **FORTE** → **BARATO** | Mapa compacto no início do express |

**Troca crítica**: após aprovar testes → **BARATO** no build. Se o build reinventar produto ou alterar teste aprovado → volte ao **FORTE** (ou `/sdd.test --refine`).

---

## Display templates

### Full box (gate boundaries)

Replace placeholders from the phase catalog row for the given `phase_key`:

```
╔═══════════════════════════════════════════════════════╗
║  MODEL ADVISORY (sugestão — não é regra)              ║
╠═══════════════════════════════════════════════════════╣
║  Próximo: [NEXT_COMMAND]                              ║
║  Sugestão: modelo [FORTE|BARATO] — [MOTIVO]           ║
║  [EXTRA_LINE if any — e.g. troca crítica test→build]  ║
╚═══════════════════════════════════════════════════════╝
```

**Extra lines by phase**:

| `phase_key` | `EXTRA_LINE` |
|-------------|--------------|
| `test→build` | Se ambiguidade no build → pause e volte ao FORTE |
| `start→spec` | Passe o Jira cedo: `/sdd.spec --include "<url>"` |
| `project→reverse-eng` | Brownfield: 1× por microserviço, não por card |
| `express:overview` | (use compact map instead of single next) |

### Compact line (command entry)

```
💡 Modelo **FORTE** recomendado nesta fase — [motivo curto]. (Sugestão; troque se precisar.)
```

or

```
💡 Modelo **BARATO** recomendado nesta fase — [motivo curto]. (Sugestão; troque se precisar.)
```

### Express compact map (show once at `/sdd.go` start)

```
💡 Modelo (sugestão): FORTE → spec, plan, test  |  BARATO → build, finish, pr
```

---

## AskUserQuestion enhancement

For the **Recommended** option in next-steps gates, append to `description`:

- FORTE next phase: `" — sugere modelo forte"`
- BARATO next phase: `" — sugere modelo barato"`

Example:

```json
{"label": "/sdd.build (Recommended)", "description": "Contexto limpo para implementar — sugere modelo barato"}
```

---

## Agent instructions

1. Look up `phase_key` in the catalog table.
2. Print the **full box** to the user (not inside AskUserQuestion JSON).
3. Then invoke `AskUserQuestion` with enhanced descriptions on the recommended option.
4. Never block or require confirmation that the user switched models.
5. Do not link or modify `SUGESTAO-MODELOS.md` from gates — this reference is self-contained for agents.
