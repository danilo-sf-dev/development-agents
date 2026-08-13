# Reference: Model Suggestion Advisory

**Used by**: Phase-boundary gates (next-steps, approvals) and optional command entry.

> Aligns with `SUGESTAO-MODELOS.md` at repo root.
>
> **Cost guarantee (Claude Code)**: each `/sdd.*` command pins `model:` in its frontmatter
> (Haiku / Sonnet / Opus only on `/sdd.fix`). That override applies for the command turn, so
> forgetting `/model` **cannot** silently charge Opus on build/start/pr. Pauses below are for
> awareness + extremo escalation — not the primary cost lock.

---

## Policy (closed)

| Tier | Claude Code alias | Where |
|------|-------------------|--------|
| **BARATO** | `haiku` | `/sdd.start`, `/sdd.build`, `/sdd.check`, `/sdd.pr`, `/sdd.mcp` |
| **FORTE** | `sonnet` | `/sdd.spec`, `/sdd.plan`, `/sdd.test`, `/sdd.finish`, `/sdd.reverse-eng` |
| **EXTREMO** | `opus` | **Only** `/sdd.fix` + Skill `sdd-debugger` |
| **Express** | `inherit` on `/sdd.go` | Prefer Standard if you want every phase pause; when go delegates a skill, that skill’s own `model:` applies |

Executor / discovery subagents (`sdd-implementation`, `sdd-test-writing`, `sdd-explorer`, `sdd-system-design`) use `model: inherit` so they follow the parent command’s pinned model.

---

## When to show

| Trigger | Action |
|---------|--------|
| Before every **Interactive Next Steps** `AskUserQuestion` at a phase boundary | Show **full box** (mandatory) |
| On **command entry** for `/sdd.start`, `/sdd.spec`, `/sdd.plan`, `/sdd.test`, `/sdd.build`, `/sdd.finish`, `/sdd.reverse-eng`, `/sdd.fix` | Show **compact line** (recommended, once per invocation) |
| **Critical switches** `test→build` and `build→finish` (Standard mode) | Full box **+** dedicated model-confirm `AskUserQuestion` (see below) — **BLOCKING** |
| **`/sdd.start` entry** (`entry:start`) | Full box **+** entry model-confirm **before Step 1** — **BLOCKING** (do not trust session default Sonnet) |
| **`/sdd.start` exit** (`start→spec`) | Full box **+** model-confirm before next-steps — **BLOCKING** |
| **Express mode** (`/sdd.go`) between auto-advanced steps | Skip most pauses — **except** before `/sdd.build` and before `/sdd.finish`: full box + model-confirm |
| `/sdd.help`, `/sdd.check`, `/sdd.install`, mid-task build layers | Skip unless transitioning to next phase |

Show the box **before** any optional CONTEXT ADVISORY (prefer **model advisory first**, then context).

### Pause guarantee

- **Standard** (`/sdd.start` → … → `/sdd.finish` comando a comando): phase-boundary `AskUserQuestion` always runs → you get a pause before the next command. **`/sdd.start` entry** and critical switches (`start→spec`, `test→build`, `build→finish`) add explicit model confirm — **BLOCKING**.
- **Express** (`/sdd.go`): fewer pauses by design. Cost is still capped by each delegated command’s frontmatter; you will **not** get every educational pause. Prefer Standard when learning the cost rhythm.

---

## Phase catalog

Use the `phase_key` when invoking this reference from command files.

| `phase_key` | Próximo passo | Modelo (frontmatter) | Motivo (PT) |
|-------------|---------------|----------------------|-------------|
| `start→spec` | `/sdd.spec` | **sonnet** | Entender pedido, entrevista, AC |
| `functional→technical` | `/sdd.spec technical` | **sonnet** | Arquitetura e decisões técnicas |
| `technical→plan` | `/sdd.plan` | **sonnet** | Quebrar escopo em tasks |
| `spec→plan` | `/sdd.plan` | **sonnet** | Plano a partir de specs aprovadas |
| `plan→test` | `/sdd.test` | **sonnet** | Contrato de testes e casos de borda |
| `test→build` | `/sdd.build` | **haiku** | Executar o que já foi aprovado |
| `build→finish` | `/sdd.finish` | **sonnet** | Code review final + validação antes de arquivar |
| `finish→pr` | `/sdd.pr` | **haiku** | Descrever PR do que já existe |
| `finish→start` | `/sdd.start` | **haiku** | Só metadados; sonnet de novo no spec |
| `reverse-eng→start` | `/sdd.start` | **haiku** | Extração já concluída |
| `reverse-eng→promote` | PROMOTE / `/sdd.start` | **haiku** após promote | |
| `project→reverse-eng` | `/sdd.reverse-eng` | **sonnet** | Mapear legado do código |
| `project→start` | `/sdd.start` | **haiku** | |
| `mcp→next` | `/sdd.spec` ou `/sdd.start` | **sonnet** se spec; **haiku** se start | |
| `entry:spec` | (fase atual) | **sonnet** | Definir o quê e como |
| `entry:plan` | (fase atual) | **sonnet** | Decompor sem inventar escopo |
| `entry:test` | (fase atual) | **sonnet** | O que testar e por quê |
| `entry:build` | (fase atual) | **haiku** | Seguir tasks + testes aprovados |
| `entry:finish` | (fase atual) | **sonnet** | Code review + security + validação final |
| `entry:reverse-eng` | (fase atual) | **sonnet** | Síntese a partir do código |
| `entry:fix` | (fase atual) | **opus** | Diagnóstico profundo (único passo Opus do fluxo) |
| `entry:start` | (fase atual) | **haiku** | Só metadados; sonnet no `/sdd.spec` (Step 12) |
| `express:overview` | fluxo `/sdd.go` | **sonnet** → **haiku** | Mapa compacto no início do express |

**Troca crítica**: após aprovar testes → **haiku** no build (já pinado no frontmatter). Se o build reinventar produto ou alterar teste aprovado → `/sdd.test --refine` ou `/sdd.fix` (Opus).

---

## Display templates

### Full box (gate boundaries)

Replace placeholders from the phase catalog row for the given `phase_key`:

```
╔═══════════════════════════════════════════════════════╗
║  MODEL ADVISORY                                       ║
╠═══════════════════════════════════════════════════════╣
║  Próximo: [NEXT_COMMAND]                              ║
║  Frontmatter: [haiku|sonnet|opus] — [MOTIVO]          ║
║  Custo: o comando já força esse modelo no turno       ║
║  [EXTRA_LINE if any]                                  ║
╚═══════════════════════════════════════════════════════╝
```

**Extra lines by phase**:

| `phase_key` | `EXTRA_LINE` |
|-------------|--------------|
| `test→build` | Troca crítica → haiku. Extremo: Outros / `/sdd.fix` se precisar de Opus |
| `build→finish` | Volta para sonnet — code review + validação final |
| `start→spec` | Passe o Jira cedo: `/sdd.spec --include "<url>"` |
| `project→reverse-eng` | Brownfield: 1× por microserviço, não por card |
| `express:overview` | (use compact map instead of single next) |
| `entry:fix` | Opus só aqui (+ `sdd-debugger`). Depois volte ao fluxo normal |

### Compact line (command entry)

```
💡 Este comando roda em **sonnet** (frontmatter) — [motivo curto].
```

or

```
💡 Este comando roda em **haiku** (frontmatter) — [motivo curto].
```

or

```
💡 Este comando roda em **opus** (frontmatter) — diagnóstico extremo.
```

### Express compact map (show once at `/sdd.go` start)

```
💡 Modelo (frontmatter): sonnet → spec/plan/test/finish  |  haiku → build/pr  |  opus → só /sdd.fix
   Express pula pausas intermediárias; use Standard se quiser confirmar cada troca.
```

---

## Command entry — model confirm (BLOCKING)

For **`entry:start`** (and the same moment at the beginning of `/sdd.go` when it delegates to `/sdd.start --express`), **before Step 1 / any file creation / profile AskUserQuestion**:

1. Show the **full box** for `phase_key`: `entry:start`.
2. Run **entry model-confirm** AskUserQuestion (always include **Outros**):

```
AskUserQuestion(
  questions=[{
    "question": "Este /sdd.start deve rodar em haiku (só metadados + pasta WIP). Confirme antes de continuar — não confie só no cabeçalho Sonnet da sessão.",
    "header": "Modelo /start",
    "options": [
      {"label": "Haiku — seguir (Recomendado)", "description": "Frontmatter model: haiku. Após o start, confira /usage: tokens de haiku devem dominar este passo."},
      {"label": "Não estou em haiku — parar", "description": "STOP: rode /model haiku e reinvocar /sdd.start, ou Outros com o caminho"},
      {"label": "Outros", "description": "Descreva o que você vai fazer ou sugira outro caminho (texto livre)"}
    ],
    "multiSelect": false
  }]
)
```

| Selection | Action |
|-----------|--------|
| Haiku — seguir | Continue to Step 0 (profile) and the rest of `/sdd.start` |
| Não estou em haiku — parar | **STOP** — do not create WIP, meta.md, or branch until user fixes model and re-runs `/sdd.start` |
| Outros | Follow free text; default to STOP if model path is unclear |

> **Why**: Claude Code may keep the session on Sonnet while `/sdd.start` runs. The frontmatter pin is not always visible to the user; this gate makes cost explicit.

---

## Critical switch — model confirm (BLOCKING)

For `phase_key` **`start→spec`**, **`test→build`**, and **`build→finish`** (and the same points inside `/sdd.go`), **after** the full box and **before or as part of** next-steps, call AskUserQuestion with a dedicated model question (always include **Outros**):

```
AskUserQuestion(
  questions=[{
    "question": "Confirmar modelo do próximo passo? (o frontmatter já aplica o recomendado — isto é só o gate de pausa)",
    "header": "Modelo",
    "options": [
      {"label": "Seguir com o modelo do comando (Recomendado)", "description": "Usa o model: do próximo /sdd.* — sem surpresa de custo"},
      {"label": "Preciso de modelo mais forte neste passo", "description": "Pare; use /sdd.fix ou descreva em Outros o extremo"},
      {"label": "Outros", "description": "Descreva o que você vai fazer ou sugira outro caminho (texto livre)"}
    ],
    "multiSelect": false
  }]
)
```

| Selection | Action |
|-----------|--------|
| Seguir com o modelo do comando | Continue to the next-steps AskUserQuestion (or invoke recommended command) |
| Preciso de modelo mais forte | STOP — do not auto-invoke build/finish; wait for user path |
| Outros | Follow free text; do not invent a path |

You may combine this with the next-steps question as a **two-question** AskUserQuestion (`questions: [modelConfirm, nextSteps]`) when the host supports it; otherwise run model-confirm first, then next-steps.

---

## AskUserQuestion enhancement (non-critical boundaries)

For the **Recommended** option in next-steps gates, append to `description`:

- FORTE next phase: `" — comando em sonnet"`
- BARATO next phase: `" — comando em haiku"`
- EXTREMO: `" — comando em opus"`

Example:

```json
{"label": "/sdd.build (Recomendado)", "description": "Contexto limpo para implementar — comando em haiku"}
```

---

## Agent instructions

1. Look up `phase_key` in the catalog table.
2. Print the **full box** to the user (not inside AskUserQuestion JSON).
3. If `entry:start` → run **entry model-confirm** before any other start work (BLOCKING).
4. If critical switch (`start→spec` / `test→build` / `build→finish`) → run **model-confirm** AskUserQuestion (BLOCKING).
5. Then invoke next-steps `AskUserQuestion` with enhanced descriptions on the recommended option.
6. For `/sdd.start`: mention `/usage` after finish if Sonnet dominated — user may need `/model haiku` + re-run on hosts that ignore frontmatter.
7. Do not link or modify `SUGESTAO-MODELOS.md` from gates — this reference is self-contained for agents.
