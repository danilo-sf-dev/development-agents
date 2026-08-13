# Reference: Model Suggestion Advisory

**Used by**: Phase-boundary gates (next-steps, approvals) and optional command entry.

> Canonical policy: [`framework/_shared/model-routing.md`](../../framework/_shared/model-routing.md)
> (Model Roles, defaults per Skill, escalation/de-escalation, anti-patterns). Concrete model names for
> the currently-installed harness live in that harness's `adapters/<harness>/README.md` — never here.
>
> **Cost guarantee (harness-agnostic)**: each `/sdd.*` command declares `model_role:` in its
> frontmatter (`STRONG` or `EXECUTION`; `inherit` for orchestrators `/sdd.go` and `/sdd.hub`, which
> resolve role per delegated Skill instead of pinning one). On a harness that can apply this
> programmatically, that role's resolved model applies for the command's turn, so forgetting to
> switch models manually **cannot** silently run an expensive role on a mechanical step. Pauses below
> are for awareness + escalation, not the primary cost lock.

---

## Policy (closed)

| Role | Where (commands) |
|------|-------------------|
| **EXECUTION** | `/sdd.start`, `/sdd.plan`, `/sdd.build`, `/sdd.check`, `/sdd.pr`, `/sdd.mcp`, `/sdd.backlog`, `/sdd.install`, `/sdd.project`, `/sdd.doctor`, `/sdd.import`, `/sdd.rollback`, `/sdd.cancel`, `/sdd.list`, `/sdd.help` |
| **STRONG** | `/sdd.spec`, `/sdd.test`, `/sdd.finish`, `/sdd.reverse-eng`, `/sdd.fix` (+ Skill `sdd-debugger`) |
| **Express** | `model_role: inherit` on `/sdd.go` and `/sdd.hub` — prefer Standard if you want every phase pause; when an orchestrator delegates a Skill, that Skill's own `model_role` applies |

Executor/discovery Skills (`sdd-implementation`, `sdd-explorer`) default to `EXECUTION`; `sdd-test-writing`,
`sdd-system-design`, and `sdd-validator` default to `STRONG` — see the full table and rationale in
`framework/_shared/model-routing.md`. `sdd-implementation` may escalate to `STRONG` mid-task per that
file's Escalation rules; this does not change the command's own frontmatter role.

---

## When to show

| Trigger | Action |
|---------|--------|
| Before every **Interactive Next Steps** `AskUserQuestion` at a phase boundary | Show **full box** (mandatory) |
| On **command entry** for `/sdd.start`, `/sdd.spec`, `/sdd.plan`, `/sdd.test`, `/sdd.build`, `/sdd.finish`, `/sdd.reverse-eng`, `/sdd.fix` | Show **compact line** (recommended, once per invocation) |
| **Critical switches** `test→build` and `build→finish` (Standard mode) | Full box **+** dedicated model-confirm `AskUserQuestion` (see below) — **BLOCKING** |
| **`/sdd.start` entry** (`entry:start`) | Full box **+** entry model-confirm **before Step 1** — **BLOCKING** (do not assume the session's active model matches the command's role) |
| **`/sdd.start` exit** (`start→spec`) | Full box **+** model-confirm before next-steps — **BLOCKING** |
| **Express mode** (`/sdd.go`) between auto-advanced steps | Skip most pauses — **except** before `/sdd.build` and before `/sdd.finish`: full box + model-confirm |
| `/sdd.help`, `/sdd.check`, `/sdd.install`, mid-task build layers | Skip unless transitioning to next phase |

Show the box **before** any optional CONTEXT ADVISORY (prefer **model advisory first**, then context).

### Pause guarantee

- **Standard** (`/sdd.start` → … → `/sdd.finish` comando a comando): phase-boundary `AskUserQuestion` always runs → you get a pause before the next command. **`/sdd.start` entry** and critical switches (`start→spec`, `test→build`, `build→finish`) add explicit model confirm — **BLOCKING**.
- **Express** (`/sdd.go`): fewer pauses by design. Role is still resolved per delegated command's frontmatter; you will **not** get every educational pause. Prefer Standard when learning the routing rhythm.

---

## Phase catalog

Use the `phase_key` when invoking this reference from command files.

| `phase_key` | Próximo passo | `model_role` (frontmatter) | Motivo (PT) |
|-------------|---------------|----------------------|-------------|
| `start→spec` | `/sdd.spec` | **STRONG** | Entender pedido, entrevista, AC |
| `functional→technical` | `/sdd.spec technical` | **STRONG** | Arquitetura e decisões técnicas |
| `technical→plan` | `/sdd.plan` | **EXECUTION** | Quebrar escopo em tasks a partir de spec aprovada |
| `spec→plan` | `/sdd.plan` | **EXECUTION** | Plano a partir de specs aprovadas |
| `plan→test` | `/sdd.test` | **STRONG** | Contrato de testes e casos de borda (gate de qualidade) |
| `test→build` | `/sdd.build` | **EXECUTION** | Executar o que já foi aprovado |
| `build→finish` | `/sdd.finish` | **STRONG** | Code review final + validação antes de arquivar |
| `finish→pr` | `/sdd.pr` | **EXECUTION** | Descrever PR do que já existe |
| `finish→start` | `/sdd.start` | **EXECUTION** | Só metadados; STRONG de novo no spec |
| `reverse-eng→start` | `/sdd.start` | **EXECUTION** | Extração já concluída |
| `reverse-eng→promote` | PROMOTE / `/sdd.start` | **EXECUTION** após promote | |
| `project→reverse-eng` | `/sdd.reverse-eng` | **STRONG** | Mapear legado do código |
| `project→start` | `/sdd.start` | **EXECUTION** | |
| `mcp→next` | `/sdd.spec` ou `/sdd.start` | **STRONG** se spec; **EXECUTION** se start | |
| `entry:spec` | (fase atual) | **STRONG** | Definir o quê e como |
| `entry:plan` | (fase atual) | **EXECUTION** | Decompor sem inventar escopo |
| `entry:test` | (fase atual) | **STRONG** | O que testar e por quê |
| `entry:build` | (fase atual) | **EXECUTION** | Seguir tasks + testes aprovados |
| `entry:finish` | (fase atual) | **STRONG** | Code review + security + validação final |
| `entry:reverse-eng` | (fase atual) | **STRONG** | Síntese a partir do código |
| `entry:fix` | (fase atual) | **STRONG** | Diagnóstico profundo (`sdd-debugger`) |
| `entry:start` | (fase atual) | **EXECUTION** | Só metadados; STRONG no `/sdd.spec` (Step 12) |
| `express:overview` | fluxo `/sdd.go` | **STRONG** → **EXECUTION** | Mapa compacto no início do express |

**Troca crítica**: após aprovar testes → **EXECUTION** no build (já pinado no frontmatter). Se o build
reinventar produto ou alterar teste aprovado, ou encontrar um dos gatilhos de escalation em
`model-routing.md` (ambiguidade, falha repetida, blast radius alto, decisão de segurança) → `/sdd.test --refine`
ou `/sdd.fix` (que já roda em `STRONG`).

---

## Display templates

### Full box (gate boundaries)

Replace placeholders from the phase catalog row for the given `phase_key`:

```
╔═══════════════════════════════════════════════════════╗
║  MODEL ADVISORY                                       ║
╠═══════════════════════════════════════════════════════╣
║  Próximo: [NEXT_COMMAND]                              ║
║  Role (frontmatter): [STRONG|EXECUTION] — [MOTIVO]     ║
║  Custo: o comando já resolve o role para esse turno    ║
║  [EXTRA_LINE if any]                                  ║
╚═══════════════════════════════════════════════════════╝
```

**Extra lines by phase**:

| `phase_key` | `EXTRA_LINE` |
|-------------|--------------|
| `test→build` | Troca crítica → EXECUTION. Se precisar de raciocínio forte: Outros / `/sdd.fix` (escalation para STRONG) |
| `build→finish` | Volta para STRONG — code review + validação final |
| `start→spec` | Passe o Jira cedo: `/sdd.spec --include "<url>"` |
| `project→reverse-eng` | Brownfield: 1× por microserviço, não por card |
| `express:overview` | (use compact map instead of single next) |
| `entry:fix` | STRONG só aqui (+ `sdd-debugger`). Depois volte ao fluxo normal |

### Compact line (command entry)

```
💡 Este comando roda em **STRONG** (frontmatter) — [motivo curto].
```

or

```
💡 Este comando roda em **EXECUTION** (frontmatter) — [motivo curto].
```

The concrete model behind each role is whatever the currently-installed harness's adapter maps it
to — do not hardcode a model name in this line; if the harness surfaces it (e.g. a session header),
that's incidental, not something this template should assume or repeat.

### Express compact map (show once at `/sdd.go` start)

```
💡 Role (frontmatter): STRONG → spec/test/finish/reverse-eng/fix  |  EXECUTION → start/plan/build/check/pr/mcp/...
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
    "question": "Este /sdd.start deve rodar em EXECUTION (só metadados + pasta WIP). Confirme antes de continuar — não confie apenas no que a sessão mostra como modelo ativo.",
    "header": "Role /start",
    "options": [
      {"label": "EXECUTION — seguir (Recomendado)", "description": "Frontmatter model_role: EXECUTION. Após o start, confira o custo real do passo pelo mecanismo de uso do seu harness."},
      {"label": "Não estou em EXECUTION — parar", "description": "STOP: ajuste o modelo pelo mecanismo do seu harness (ver adapters/<harness>/README.md) e reinvoque /sdd.start, ou Outros com o caminho"},
      {"label": "Outros", "description": "Descreva o que você vai fazer ou sugira outro caminho (texto livre)"}
    ],
    "multiSelect": false
  }]
)
```

| Selection | Action |
|-----------|--------|
| EXECUTION — seguir | Continue to Step 0 (profile) and the rest of `/sdd.start` |
| Não estou em EXECUTION — parar | **STOP** — do not create WIP, meta.md, or branch until user fixes model and re-runs `/sdd.start` |
| Outros | Follow free text; default to STOP if model path is unclear |

> **Why**: some harnesses keep a session on its default model regardless of a command's declared
> `model_role`, and the resolved model is not always visible to the user. This gate makes the cost
> tradeoff explicit instead of assuming the frontmatter silently won.

---

## Critical switch — model confirm (BLOCKING)

For `phase_key` **`start→spec`**, **`test→build`**, and **`build→finish`** (and the same points inside `/sdd.go`), **after** the full box and **before or as part of** next-steps, call AskUserQuestion with a dedicated model question (always include **Outros**):

```
AskUserQuestion(
  questions=[{
    "question": "Confirmar o role do próximo passo? (o frontmatter já aplica o recomendado — isto é só o gate de pausa)",
    "header": "Model Role",
    "options": [
      {"label": "Seguir com o role do comando (Recomendado)", "description": "Usa o model_role: do próximo /sdd.* — sem surpresa de custo"},
      {"label": "Preciso de raciocínio mais forte neste passo", "description": "Pare; use /sdd.fix ou descreva em Outros o cenário de escalation"},
      {"label": "Outros", "description": "Descreva o que você vai fazer ou sugira outro caminho (texto livre)"}
    ],
    "multiSelect": false
  }]
)
```

| Selection | Action |
|-----------|--------|
| Seguir com o role do comando | Continue to the next-steps AskUserQuestion (or invoke recommended command) |
| Preciso de raciocínio mais forte | STOP — do not auto-invoke build/finish; wait for user path (escalation, per `model-routing.md`) |
| Outros | Follow free text; do not invent a path |

You may combine this with the next-steps question as a **two-question** AskUserQuestion (`questions: [modelConfirm, nextSteps]`) when the host supports it; otherwise run model-confirm first, then next-steps.

---

## AskUserQuestion enhancement (non-critical boundaries)

For the **Recommended** option in next-steps gates, append to `description`:

- `STRONG` next phase: `" — comando em STRONG"`
- `EXECUTION` next phase: `" — comando em EXECUTION"`

Example:

```json
{"label": "/sdd.build (Recomendado)", "description": "Contexto limpo para implementar — comando em EXECUTION"}
```

---

## Agent instructions

1. Look up `phase_key` in the catalog table.
2. Print the **full box** to the user (not inside AskUserQuestion JSON).
3. If `entry:start` → run **entry model-confirm** before any other start work (BLOCKING).
4. If critical switch (`start→spec` / `test→build` / `build→finish`) → run **model-confirm** AskUserQuestion (BLOCKING).
5. Then invoke next-steps `AskUserQuestion` with enhanced descriptions on the recommended option.
6. For `/sdd.start`: if the resolved model doesn't look right for the declared role, point the user at `adapters/<harness>/README.md` for how to fix it on their harness — never assume a Claude-Code-specific fix like a `/model` command applies universally.
7. Do not link or modify `SUGESTAO-MODELOS.md` from gates — this reference is self-contained for agents. `SUGESTAO-MODELOS.md` is a Claude-Code-flavored companion doc, not the canonical policy (`framework/_shared/model-routing.md` is).
