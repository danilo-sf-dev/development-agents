---
name: sdd.go
description: Express mode - orchestrates start, spec, plan, build, and finish in one command. Use for rapid feature development when you want the full workflow automated end-to-end with minimal interaction.
model_role: inherit
argument-hint: "[feature-description]"
---

> **Shared agent instructions**: Read `development-agents/framework/_shared/agent-instructions.md` before executing this command.

# Command: /sdd.go

**Description**: Express mode - orchestrates the complete workflow using standard commands

**Usage**:

- `/sdd.go "feature-name"` → Full automatic workflow with explicit name
- `/sdd.go "feature description"` → Auto-derives name from description
- `/sdd.go --audio` → Record feature description via microphone
- `/sdd.go --resume` → Resume interrupted express workflow

---

## Quick Help

> `/sdd.go help` → Shows this summary

**Syntax**: `/sdd.go "feature-name" [flags]`

| Flag             | Description                                |
| ---------------- | ------------------------------------------ |
| `"feature-name"` | Full automatic workflow with explicit name |
| `"description"`  | Auto-derives name from description         |
| `--audio`        | Record feature description via microphone  |
| `--resume`       | Resume interrupted express workflow        |

**Flow**: start → spec → plan → test → build → check → finish (3-5 questions total)

**Examples**:

```bash
/sdd.go "payment-gateway"    # Full express workflow
/sdd.go --audio              # Voice-driven express workflow
```

**See also**: `/sdd.help go` for detailed documentation

---

## Architecture: Orchestrator Pattern

> **CRITICAL**: `/sdd.go` is an **orchestrator**, NOT a standalone implementation.
> It invokes standard commands with express mode rules. **DO NOT duplicate logic here.**

**Flow**: `/sdd.start --express` → `/sdd.spec` → `/sdd.plan` → `/sdd.test` → `/sdd.build` → `/sdd.check` → `/sdd.finish`

## Model Routing — automatic per-phase dispatch (mandatory mechanism, not documentation-only)

`/sdd.go` declares `model_role: inherit` because it does not pin a single model for the whole
express run — each phase below has its own `model_role` (from that phase's own command frontmatter)
and must actually execute under that phase's resolved Model Role, automatically, with no operator
switching anything. Each phase is dispatched as its own isolated execution, resolved to that phase's
`model_role` at the moment of dispatch — see `adapters/<harness>/README.md` § Model Routing for the
concrete mechanism on the installed harness (it differs per harness — a call-time parameter on some,
a child-process invocation on others — but the dispatch-per-phase principle is the same everywhere).
This works cleanly because pipeline phases already pass state through disk (`sdd/wip/<feature>/*.md`,
`meta.md`) rather than through shared conversation context — the same file-based handoff
`ISOLATED_WORKSPACE` and `VALIDATOR_ISOLATED` already rely on.

**Gates inside a dispatched phase — `NEEDS_USER_INPUT`, not silent pass-through.** A dispatched phase
cannot itself ask the human a question — verified directly on Claude Code (an immediate tool error,
not a pause), and true by design on every harness's headless/isolated dispatch mechanism. This applies
to every phase below that can reach a Gate (1/2/2.5/3, the tests-immutability check in `/sdd.build`,
next-steps prompts), which in practice is most of them. So a dispatched phase does not "surface its
own gates" — it **stops at the gate and returns** `{"status": "NEEDS_USER_INPUT", "gate": "<name>",
"questions": [...]}` instead of attempting to ask. The orchestrator (the session actually running
`/sdd.go`, which does have the real `ASK_USER` mechanism) then asks the question itself, persists the
answer to `sdd/wip/<feature>/meta.md` (or wherever that Gate already persists its result), and
re-dispatches that phase — resolving its `model_role` fresh again — to continue from the state file
now that the answer is recorded. A phase may therefore take more than one dispatch (one per Gate it
contains, plus one final call) — this is expected, not an error. See
`framework/_shared/model-routing.md` § "Interactive dispatch" for the full, harness-general statement
of this rule, and `adapters/claude-code/README.md` for a live-tested account of exactly this sequence.

**Phase-by-phase Model Role** (the harness's resolver — see `adapters/<harness>/README.md` — is the
one and only lookup; no concrete model name is repeated here on purpose, so this table never goes
stale when `config/model-routing.yaml` changes):

| Phase | `model_role` (from that command's frontmatter) |
| --- | --- |
| `/sdd.start --express` | `EXECUTION` |
| `/sdd.spec` | `STRONG` |
| `/sdd.plan` | `EXECUTION` |
| `/sdd.test` | `STRONG` |
| `/sdd.build` (implementation) | `EXECUTION` |
| `/sdd.build` → validator sub-step | `STRONG` (always — `VALIDATOR_ISOLATED`) |
| `/sdd.check` | `EXECUTION` |
| `/sdd.finish` | `STRONG` |

Gates that need a human answer (the 3-5 consolidated Express questions, any `AskUserQuestion`) are
**never** answered by the phase-dispatch call itself — a dispatched phase cannot ask the human a
question at all (verified: the attempt errors immediately). The orchestrator session running
`/sdd.go` asks them, after the current phase-dispatch call returns `NEEDS_USER_INPUT` instead of a
final result — see "Model Routing" above for the full mechanism.
Nothing about model routing changes *which* gates fire or *what* they ask; it changes which model
executes each phase and which execution context (always the orchestrator) answers a gate along the way.

**Express Rules**:

- 3-5 critical questions only
- Auto-advance between steps
- Predefined defaults
- Same E2E rules as standard

---

## Purpose

One-command feature development for simple, well-understood features.

**Good for**: Simple features with clear requirements (still full pipeline: spec → plan → test → build → finish)
**Not for**: Complex integrations, extensive design decisions, unclear requirements

---

## Express Rules

### 1. Consolidated Questions (3-5 only)

| #   | Question                 | Purpose                | Triggers                      |
| --- | ------------------------ | ---------------------- | ----------------------------- |
| 1   | What's the main feature? | Problem statement      | Always                        |
| 2   | Who uses it?             | User context           | Always                        |
| 3   | Technical constraints?   | Architecture decisions | Always                        |
| 4   | External integrations?   | Dependencies           | If mentioned → auto-discovery |
| 5   | Security requirements?   | Security design        | If sensitive data             |
| 6   | E2E E2E Testing? [Y/N]   | E2E test generation    | Always (user chooses)         |

### 2. Predefined Defaults

| Decision             | Express Default   |
| -------------------- | ----------------- |
| Execution strategy   | Batched           |
| Test coverage target | 80%               |
| Template             | Full (not Lite)   |
| JVM language         | Java (not Kotlin) |
|                      | Always enforced   |

### 3. Auto-Advance Behavior

- No confirmation prompts between steps
- No "proceed?" questions - just continue
- Pause only on: errors, missing env vars, security decisions, consolidated questions

### 4. E2E E2E Question

Same rules as standard mode. Reference: `spec.md` → "E2E E2E Testing Decision"

---

## Execution Flow

Each step (except Step 0, local input parsing) is a separate model-pinned dispatch — see "Model
Routing" above, not an inline continuation of this same turn.

| Step | Command                         | Reference                    | Override                     | `model_role` |
| ---- | -------------------------------- | ----------------------------- | ----------------------------- | --- |
| 0    | Input validation                | -                            | Derive name if description   | (local, no dispatch) |
| 1    | `/sdd.start "<name>" --express` | `start.md` → "Express Mode"  | -                            | `EXECUTION` |
| 2    | `/sdd.spec`                     | `spec.md` → "Express Mode"   | Consolidated questions       | `STRONG` |
| 3    | `/sdd.plan`                     | `plan.md` → "Express Mode"   | Auto-select Batched          | `EXECUTION` |
| 4    | `/sdd.test`                     | `test.md` → "Express Mode"   | Auto-approve if red verified | `STRONG` |
| 5    | `/sdd.build`                    | `build.md` → "Express Mode"  | Auto-retry 2x max            | `EXECUTION` (+ validator: `STRONG`) |
| 6    | `/sdd.check`                    | `check.md` → "Express Mode"  | Auto-advance if status clean | `EXECUTION` |
| 7    | `/sdd.finish`                   | `finish.md` → "Express Mode" | All validations mandatory    | `STRONG` |

---

## AI Agent Instructions

### Help Flag Detection

**WHEN** the user runs `/sdd.go help`:

1. Output ONLY the "Quick Help" section (not full documentation)
2. Do NOT execute go logic
3. Keep response concise (~15 lines)

### Hub Guard

**WHEN** `/sdd.go` is invoked, **BEFORE** any other step:

1. Run `detect-stack.sh --level` in the current directory
2. If result is `hub`:
   - Output: "`/sdd.go` does not support hubs. Use `/sdd.hub go \"description\"` for express mode, or `/sdd.hub start|spec|plan|build|finish` for standard mode."
   - **STOP** — do NOT proceed with the express workflow
3. If result is `app` or `unknown`: continue normally

### CRITICAL: Orchestrator Implementation

When `/sdd.go` is invoked:

1. **DO NOT implement each step from scratch**
2. **DO dispatch each standard command as its own model-pinned call** (see "Model Routing" above — never execute a phase's content inline in this turn)
3. **DO apply express rules as overrides**

### Phase Transition Logging (mandatory, never pause)

Before dispatching each step, print one line:

```
▶ [N/7] /sdd.<phase> (Pipeline: START → ... → [PHASE] → ... → FINISH)
```

Full example sequence per `commands/references/phase-transition-observability.md` § `/sdd.go`.

After the pipeline completes:

```
✓ concluído: /sdd.finish
Pipeline: START → SPEC → PLAN → TEST → BUILD → CHECK → FINISH ✓
```

Never pause or gate on these lines — output only.

### Step 0: Input Validation

If input is valid kebab-case name → use directly
If input is description → derive name (extract key nouns, kebab-case), DO NOT ask confirmation

### Step 1: Initialize

Dispatch `/sdd.start "<feature-name>" --express` per "Model Routing" above (`model_role: EXECUTION`)
→ Reference: `start.md` → "Express Mode (`--express`)" section

Includes: app verification, creation if needed, scaffolding cleanup, git branch, meta.md with `execution_mode: express`

### Step 2: Specifications

Dispatch `/sdd.spec` per "Model Routing" above (`model_role: STRONG`; reads `execution_mode: express` from meta.md)
→ Reference: `spec.md` → "Express Mode" section

**Override**: Use consolidated questions instead of full interview.

### Step 3: Task Planning

Dispatch `/sdd.plan` per "Model Routing" above (`model_role: EXECUTION`; reads mode from meta.md)
→ Reference: `plan.md` → "Express Mode" section

**Override**: Auto-select "Batched" strategy, no confirmation.

### Step 4: Tests-First

Dispatch `/sdd.test` per "Model Routing" above (`model_role: STRONG`; reads mode from meta.md)
→ Reference: `test.md` → "Express Mode" section

**Override**: Auto-approve if red phase verified. Never skip writing/running the tests-first gate.

### Step 5: Implementation

Dispatch `/sdd.build` per "Model Routing" above (`model_role: EXECUTION`; validator sub-step always `STRONG`; reads mode from meta.md)
→ Reference: `build.md` → "Express Mode" section

**Override**: Auto-retry failures (max 2x), then pause.

### Step 6: Status/Validation Check

Dispatch `/sdd.check` per "Model Routing" above (`model_role: EXECUTION`; reads mode from meta.md)
→ Reference: `check.md` → "Express Mode" section

**Override**: Auto-advance if status clean (all tasks completed, no blockers).

### Step 7: Finalization

Dispatch `/sdd.finish` per "Model Routing" above (`model_role: STRONG`; reads mode from meta.md)
→ Reference: `finish.md` → "Express Mode" section

All validations mandatory (, tests, code review, security, performance).

---

## Error Handling

If any step fails, show error details and options:

- (a) Fix and retry with appropriate command
- (b) Continue in standard mode: `/sdd.check`
- (c) Abort: `/sdd.cancel`

---

## Resume

`/sdd.go --resume` checks meta.md progress and continues from last incomplete step.

---

## Comparison with Standard

| Aspect        | /sdd.go            | Standard        |
| ------------- | ------------------ | --------------- |
| Commands      | 1 (orchestrates 5) | 5 separate      |
| Questions     | 3-5 critical       | Full interviews |
| Confirmations | None               | At each phase   |
| Time          | ~10-20 min         | ~1-2 hours      |

---

## Stack from target project

Inherited from standard commands - see `spec.md`. Map external tech to project services.

---

## Key Principle

> **Standard commands are the single source of truth.**
> `/sdd.go` only defines: express rules, orchestration flow, error handling.
> For implementation details, read the corresponding command file.

## Code Graph — inherited, not duplicated

`/sdd.go` never implements Graphify bootstrap/query/refresh/cleanup itself. Because it
dispatches `start.md`/`spec.md`/`plan.md`/`build.md`/`check.md`/`finish.md` unchanged (see
"Architecture: Orchestrator Pattern" above), each phase's own optional Graphify behavior —
bootstrap in `/sdd.start` (after branch creation), query-first in `/sdd.spec`/`/sdd.plan`/
`/sdd.check`, refresh in `/sdd.build`, cleanup in `/sdd.finish` — applies automatically,
express mode or not. See `framework/_shared/graphify-context.md` for the full mechanism.

## Optional flags (lazy-loaded)

| Flag      | Reference                          |
| --------- | ---------------------------------- |
| `--audio` | `references/audio-capture-flow.md` |
