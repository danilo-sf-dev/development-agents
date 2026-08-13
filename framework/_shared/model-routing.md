# Model Routing (canonical, harness-agnostic)

**Read this file when**: a Skill or command needs to know which Model Role it should run under, or
when you're implementing/updating a harness adapter's model-mapping table.

> **No concrete model names live in this file.** `sonnet`, `haiku`, `opus`, `grok`, `sol`, `luna`,
> `compose`, and every other provider/model identifier belong **only** in `adapters/<harness>/README.md`.
> This file defines the roles and the rules; the adapter resolves a role to a real model.

## Where this fits in the architecture

```text
Skill                = o que fazer                     (behavior/procedure)
Execution Requirement = como executar                   (DELEGATE_ISOLATED, ISOLATED_WORKSPACE, ...)
Model Role             = quanta capacidade de modelo usar (STRONG, EXECUTION)
Adapter                 = traduz Model Role + Execution Requirement
                           para o mecanismo/modelo concreto daquele harness
```

Model Role is an **independent axis** from Execution Requirement. A Skill declares both:
`ISOLATED_WORKSPACE` says *where* it runs (a dedicated workspace); `model_role: EXECUTION` says
*how much reasoning capacity* it needs. Neither implies the other. `VALIDATOR_ISOLATED` is the one
case where a Model Role is pinned as part of the capability's own contract (see below) — everywhere
else, Model Role is a Skill-level or command-level declaration, resolved independently per harness.

## Model Roles

Two roles today. Do not add a third without a real, repeated case that doesn't fit either — see
Anti-Patterns.

### `STRONG`

Use when reasoning quality has high impact on correctness. Concretely:

- system design / architecture decisions
- complex debugging (root-cause analysis)
- test-writing (tests are a quality gate, not a mechanical output)
- validation (`sdd-validator`, always, independent of isolation — see below)
- security / performance decisions
- ambiguous or high-blast-radius implementation
- analysis requiring multiple competing hypotheses

### `EXECUTION`

Use for mechanical, deterministic, or already-well-specified execution. Concretely:

- installer, backlog ops, MCP setup, project wizard
- codebase exploration / layer analysis (read-and-report, not judgment)
- implementation from an already-approved spec/task
- repetitive or file-transform operations
- other operational tasks

`EXECUTION` is not "the weak model" — it's the *preferred* role for efficient execution when strong
reasoning isn't the bottleneck. Defaulting a mechanical Skill to `STRONG` is itself an anti-pattern
(see below): it does not buy correctness, it buys cost and latency for no return.

## Defaults by Skill

| Skill | Default `model_role` | Notes |
|---|---|---|
| `sdd-installer` | `EXECUTION` | Mechanical file operations |
| `sdd-backlog` | `EXECUTION` | Ops on `sdd/backlog.md` |
| `sdd-mcp-setup` | `EXECUTION` | Config/setup, read-only MCP |
| `sdd-project-wizard` | `EXECUTION` | Structured interview → `sdd/PROJECT.md` |
| `sdd-explorer` | `EXECUTION` | Read-and-report, no architectural judgment |
| `sdd-layer-analysis` | `EXECUTION` | Consistency checks against an existing spec |
| `sdd-system-design` | `STRONG` | Architecture / technical decisions |
| `sdd-debugger` | `STRONG` | Root-cause analysis on hard bugs |
| `sdd-test-writing` | `STRONG` | **Default is `STRONG`, not `EXECUTION`.** Tests are a Gate 2.5 quality artifact — "simple test = execution" is explicitly rejected as a default. Applies to both the unit/integration path and the lazy-loaded E2E branch. |
| `sdd-implementation` | `EXECUTION` | Default — implements an already-approved spec/task. See Escalation below for when this is insufficient. |
| `sdd-validator` | `STRONG` | **Always**, including inside `VALIDATOR_ISOLATED`. Isolation and Model Role are independent — see "Isolation is not a substitute" below. |
| `sdd-code-reviewer` | `STRONG` | Extension (not in the original 11-Skill list): blocking quality gate, same reasoning as `sdd-validator`. |
| `sdd-performance-expert` | `STRONG` | Extension: correctness-sensitive review, same class as security/performance criteria under `STRONG`. |
| `sdd-kit-expert` | `EXECUTION` | Extension: documentation/manual lookup, mechanical. |
| `context-guardian` | `EXECUTION` | Extension: token/context bookkeeping, operational. |
| `commit-workflow` | `EXECUTION` | Extension: formatting/commit mechanics. |

The five "Extension" rows were not enumerated in the original per-Skill mapping; they're classified
here using the same `STRONG`/`EXECUTION` criteria above, called out explicitly so the classification
is auditable rather than silently assumed.

## Escalation (`EXECUTION` → `STRONG`)

An `EXECUTION`-role Skill (in practice, `sdd-implementation` is the common case) may escalate to
`STRONG` mid-task when it detects:

- ambiguity in the approved spec/task that can't be resolved mechanically
- multiple plausible implementation approaches with materially different consequences
- repeated failure (the same fix attempt failing more than once)
- a significant cross-module change beyond the task's stated scope
- concurrency, distributed-systems, or transactional complexity
- a security-relevant decision
- performance-critical code paths
- high blast radius (change affects shared/critical infrastructure)
- the need to challenge a technical premise in the approved spec/task (not silently override it —
  escalate, surface the concern, do not redesign silently; see Anti-Patterns and `PROC-PHASE-ORDER`
  in `skills/sdd-validator/SKILL.md`)

Escalation is a **within-task** decision the Skill's own execution makes, not a pipeline/Gate change.
It does not bypass approval gates, does not let `STRONG` redesign an approved spec, and does not
change which Skill runs — only which Model Role that Skill's current step runs under.

**Rule**: escalate to the cheapest role that can resolve the responsibility with sufficient
reliability. Escalation is not a blanket upgrade for the rest of the task — see De-escalation.

**Escalation must actually execute in `STRONG`, not just be written down as a plan.** When an
`EXECUTION`-role Skill hits one of the triggers above, it does not keep reasoning about the hard part
itself under `EXECUTION` — it dispatches *that specific sub-decision*, at `model_role: STRONG`,
through the same `RESOLVED` mechanism `VALIDATOR_ISOLATED` and the other offload capabilities already
use on the installed harness (see `adapters/<harness>/README.md` for the concrete dispatch), gets the
decision/result back, and only then continues. This is a scoped delegation for one hard sub-problem,
not a mode switch for the rest of the task — which is exactly why De-escalation (below) is real and
automatic, not something the operator has to trigger.

## De-escalation (`STRONG` → `EXECUTION`)

If `STRONG` was invoked only to resolve one hard decision (an architectural question, a root cause,
an ambiguous case), the Skill returns to its default role for the remaining mechanical work once
that decision is resolved. Do not keep `STRONG` active for the rest of a workflow "just in case" —
that is the mirror anti-pattern of never escalating at all, and it defeats the purpose of having two
roles.

## Isolation is not a substitute for Model Role (and vice versa)

`VALIDATOR_ISOLATED` guarantees fresh context, a scrubbed prompt, and independent execution (see
`harness-capabilities.md`). `model_role: STRONG` guarantees reasoning capacity. **Never use one to
compensate for the other.** A `STRONG` model running inline in the implementer's own context is not
a substitute for isolation (self-validation bias survives model strength). An isolated worker running
`EXECUTION` is not a substitute for `STRONG` on a task that genuinely needs deep reasoning (isolation
survives model weakness, but validation quality doesn't). `sdd-validator`'s isolated mode always
declares both: `VALIDATOR_ISOLATED` **and** `model_role: STRONG`, independently.

## How a command/Skill declares its role

Both Skills (`skills/*/SKILL.md`) and commands (`commands/sdd.*.md`) declare `model_role` in their
frontmatter, alongside the existing `name:`/`description:` keys — the same shape the pack already
uses, no new file format:

```yaml
---
name: sdd-implementation
description: ...
model_role: EXECUTION
---
```

Orchestrator commands that delegate to multiple Skills with different roles in the same run
(`/sdd.go`, `/sdd.hub`) declare `model_role: inherit` — meaning "resolved per sub-step by whichever
Skill is delegated to at that point," not a single role for the whole command.

## Resolution — single authoritative source, resolved at runtime, no install step

There is exactly **one** place the Role→model mapping is written down:
[`config/model-routing.yaml`](../../config/model-routing.yaml). There is exactly **one** place that
reads it: [`framework/tools/resolve-model.sh <harness> <STRONG|EXECUTION> [--json]`](../tools/resolve-model.sh),
which prints `model=<value> effort=<value-or-empty>` (or JSON with `--json`). This is the concrete,
executable form of `resolve_model(harness, model_role)`. **Resolution happens at dispatch time, on
every harness, with no install-time step and no generated/cached copy anywhere.** Whatever mechanism
a harness adapter uses to turn a `model_role` into a running execution (see
`adapters/<harness>/README.md`) calls this script — or reads `config/model-routing.yaml` directly,
since it's two levels of flat YAML, cheap to parse without shelling out — at the moment it needs the
value, never ahead of time. **No adapter README, Skill, command file, or installer may contain a
second copy of the Role→model table, and none may cache a resolved value from a previous run.**
Changing a model means editing `config/model-routing.yaml` in exactly one place; every call site
picks up the change on its **very next dispatch** — no reinstall, no regeneration, no
installer involvement of any kind. The installer copies commands/Skills (including their
`model_role:` frontmatter) byte-for-byte, exactly like every other file it installs; it has no
Model Routing responsibility to begin with, so there is nothing for it to keep in sync.

## Interactive dispatch — a headless/isolated child cannot answer a Gate itself

Every `RESOLVED` mechanism on every harness dispatches the substantive work of a `model_role`-bearing
command/Skill as a **separate execution context** from the interactive session the human is talking
to (see each `adapters/<harness>/README.md` for what that context is concretely). **None of these
dispatched contexts, on any harness, can ask the human a question and wait for an answer from inside
that dispatch.** This was verified directly on Claude Code, not assumed: a dispatched worker
instructed to call the structured question tool receives an immediate error — it does not pause,
degrade, or forward the question; the call simply fails. Cursor's and Codex's headless child-process
mechanisms are non-interactive by design (no prompt loop) and have the same limitation for the same
structural reason. This is true **on all three harnesses**, not just the two that dispatch via an
external CLI — do not assume Claude Code is exempt because its dispatch mechanism looks more "native."

**The rule this forces**: any dispatched execution that reaches a point requiring human input — a
Gate (1, 2, 2.5, 3), the tests-immutability `AskUserQuestion` in `/sdd.build`, a next-steps prompt, or
any other `ASK_USER` point — must **stop there and return a structured request**, never fabricate an
answer, never silently auto-approve, and never attempt to call an interactive tool that isn't
available to it. The shape is the same on every harness (only the resume transport differs, and is an
adapter detail, not a core one):

```json
{"status": "NEEDS_USER_INPUT", "resume_token": "<mechanism-specific — see adapters/<harness>/README.md>", "gate": "<gate name>", "questions": [...]}
```

The **calling/interactive session** — which does have the real interactive tool (`ASK_USER`, per
`harness-capabilities.md`) — is the only place a Gate is ever actually answered. After it gets the
human's answer, it persists that answer to the state the phase already expects
(`sdd/wip/<feature>/meta.md` or wherever that Gate normally writes its result — no new state format),
then **resumes** the dispatched work under the *same resolved Model Role* it was already running
under, using whatever resume mechanism that harness's adapter documents (a fresh dispatch built from
the persisted state, on a harness with no session to reconnect to; a native session-resume primitive,
where the harness has one). Live-tested end-to-end on Claude Code: a fixture dispatch returned
`NEEDS_USER_INPUT`, the calling session asked the real question, persisted the real answer to a state
file, and a second, independent dispatch (no shared memory with the first) read that file and produced
a result reflecting the actual answer — confirming the state-file handoff is sufficient, not merely
theoretical.

**This does not change what a Gate is or when it fires** — Gate 1/2/2.5/3 and every methodological
`AskUserQuestion` still fire at exactly the same points in the pipeline they always did, asking
exactly the same questions. What changed is *which execution context answers them*: always the
interactive parent, never a dispatched worker — because on every harness tested, a dispatched worker
structurally cannot.

## Adapter contract

Every `adapters/<harness>/README.md` MUST document, instead of a duplicated mapping table:

1. **The dispatch mechanism**: exactly how a `model_role` gets turned into a real execution running
   under the resolved model — a call-time parameter, an install-time-generated frontmatter field, a
   child CLI process invoked with an explicit model flag, or (only for `generic`, and only as an
   explicitly labeled fallback) a documented gap.
2. **Whether that mechanism is `RESOLVED` or merely `RECOMMENDED`** (see below) — and if
   `RECOMMENDED`, why no `RESOLVED` mechanism exists yet, with the specific missing capability named,
   not just "not supported."
3. A pointer to `config/model-routing.yaml` / `resolve-model.sh` for the concrete values — never a
   restated table.

**`RESOLVED` vs `RECOMMENDED`** (this distinction is load-bearing, not decorative):

- **`RESOLVED`**: the framework itself executes the work under the correct model — via a real
  parameter, flag, or generated config the harness's own automation reads — with zero operator
  action. This is the required bar for Claude Code, Cursor, and Codex.
- **`RECOMMENDED`**: the framework tells the operator which model to use and waits for them to switch
  it by hand. This is **not** a completed Model Routing implementation for any harness that has a
  `RESOLVED` path available — it is only acceptable for `generic`, where no harness-specific
  automation exists by definition.

The core (`skills/`, `commands/`, `framework/`) never branches on harness name to resolve a role.
`if Claude / if Cursor / if Codex` logic for model resolution lives only in the adapter, and even
there it's confined to *which dispatch mechanism* to use — the mapping itself always comes from the
one YAML file via the one resolver script.

## Fallback

If a harness only exposes a single model (no role distinction possible): use that model for
everything and continue the pipeline unchanged. Model routing is a cost/quality optimization layer,
not a correctness dependency. Never weaken, as a consequence of routing being unavailable:

- Gates (1, 2, 2.5, 3)
- test-first discipline
- `sdd-validator` / `VALIDATOR_ISOLATED`
- workspace isolation (`ISOLATED_WORKSPACE`)
- traceability

A harness that can't route models still runs the full pipeline correctly — just without the
cost/quality tuning.

## Cost model (why this isn't just "cheap by default")

Do not optimize model routing for price-per-call alone. A cheap model that fails and needs 3 retries
— each retry re-reading files, re-running tools, producing a wrong diff that then needs
re-validation and rework — is frequently more expensive in aggregate (tokens, wall-clock latency,
context consumed re-establishing state, a second `VALIDATOR_ISOLATED` pass) than paying for `STRONG`
once and getting a correct result on the first attempt. Route on **expected total cost of the
responsibility**, not the sticker price of one call.

## Anti-Patterns

- `STRONG` on everything (defeats the purpose of having a cheap role at all).
- `EXECUTION` insisting after repeated failures instead of escalating (burns retries that individually
  look cheap but aggregate worse than one `STRONG` call — see Cost model above).
- Concrete model names anywhere in `skills/`, `commands/`, or `framework/` core — they belong in
  `adapters/<harness>/README.md` only.
- Using `STRONG` as a substitute for `VALIDATOR_ISOLATED` (or any isolation requirement) — they are
  independent axes; see "Isolation is not a substitute" above.
- Letting a `STRONG` escalation silently redesign an already-approved spec/task instead of surfacing
  the concern through the normal gate/`sdd-fix` path.
- Keeping `STRONG` active for the rest of a workflow after the hard part that required it is done.
- Duplicating the Role→model mapping in more than one place per harness (one table per adapter,
  referenced, not copied).
- `if Claude / if Cursor / if Codex` branching anywhere outside `adapters/`.
