---
name: sdd.spec
description: Create and approve functional and technical specifications. Use when user needs to define requirements (functional) or design architecture (technical). Supports --approve, --iterate, --summary, and --audio flags.
model: opus
argument-hint: "[functional|technical] [--approve]"
---

> **Shared agent instructions**: Read `development-agents/framework/_shared/agent-instructions.md` before executing this command.

# Command: /sdd.spec

**Description**: Create and manage functional and technical specifications

**Usage**: `/sdd.spec [functional|technical] ["description"] [--approve|--iterate|--summary|--audio|--include|--resume]`

---

## Quick Help

`/sdd.spec help` → this summary. Flags: see table at bottom (lazy-loaded refs). Phases: `functional` | `technical` | auto.

---


## Subagent Delegation

| Need | Use |
|------|-----|
| Gaps after description | `genai-detect-gaps.sh` (inline fallback: async/persist/calc/API/concurrent) |
| Architecture / services | `sdd-system-designer` then `sdd-implementer` |
| Service discovery | `sdd-explorer` |
| Conflicts after technical | `genai-resolve-conflicts.sh` → `validate-spec-conflicts.sh` |

Context before technical: >50% → `/clear`; >80% → `context-guardian`.

**Model advisory (entry)**: Read `references/model-suggestion-advisory.md` — compact line for `phase_key`: `entry:spec`.

---

## Profile-Aware Spec Creation (lazy-loaded)

> **ONLY IF** adapting interview/output by `technical` vs `non-technical` profile:
> Read `references/spec-profile-aware.md`.

> Frontend Web stack: Read `references/spec-frontend-web-agents.md` (already flagged below).

## Stack from target project (CRITICAL)

> Resolve language, frameworks, and infra from **detect-language.sh / detect-stack.sh**, **sdd/PROJECT.md**, and the existing codebase.
> Do **not** force a corporate service catalog. Prefer technologies already used in the repo and declared in PROJECT.md / technical spec.

**Mobile** (`platform.type` = android | ios): follow mobile constraints in PROJECT.md if present; otherwise use standard Android/iOS libraries already in the repo.

When the user mentions a technology unfamiliar to the repo, ask which option fits PROJECT.md — do not silently rewrite to a vendor platform.

---

## Behavior by Mode

| Mode | Behavior |
|------|----------|
| **Express** | 3-5 critical questions, auto-generates both specs, auto-approves |
| **Standard** | Interactive interview, section review, confirmation before approval |

---

## Skill Hooks (lazy-loaded)

> **ONLY IF** `.claude/skill-hooks.json` or `development-agents/framework/skill-hooks.json` exists,
> or installed skills declare `sdd-kit-*` metadata:
> Read `references/spec-skill-hooks.md` before each extension point in the workflow.

## Workflow (Steps in Order)

> Extension points (`before-start` / `after-implementation` / `before-approval` × functional|technical): only if skill hooks configured — see `references/spec-skill-hooks.md`.


### Step 1: Detect Phase

Run `detect-phase.sh sdd/wip/[feature] --json`. Phase 1→functional, 2→technical, 3+→redirect to `/sdd.plan` or `/sdd.build`.
`template_mode: lite` → single combined spec; `full` → separate (default).

### Step 1.1: Spec Language

Resolve: `meta.md` `spec_language` → `PROJECT.md` `language.specs` → `en`.
Write entire spec in that language; headers/identifiers/tech terms in English.

### Step 1.5: Project Vision (lazy-loaded)

> Before functional interview: if `sdd/PROJECT.md` has `vision:`, use it to guide scope/anti-goals.
> **ONLY IF** vision is missing and not yet prompted for this feature: Read `references/spec-vision.md`.

### Step 2: Functional Spec (WHAT to build)

> Consolidated interview (tech: 4–6 Q; non-tech: 3–5 Q). Anti-redundancy: never ask twice.
> Gap-driven + architect-first for async/storage/concurrent — ask in product terms only.
> E2E: auto-skip prototype/mvp; ask on production.
> **ONLY IF** you need the full question tables / gap protocol matrix: Read `references/spec-interview.md`.

### Step 2.5: Completeness Check

> After interview, before generating spec: assume safe standards; **never** leave data origins or business-logic examples unclear.
> Scan for missing origins, unnamed integrations, vague sources. Profile-specific wording: `references/spec-profile-aware.md`.

### Completeness Checklist (lazy-loaded)

> **ONLY IF** gap detection or Step 2.5 found unresolved critical gaps:
> Read `references/spec-completeness-checklist.md` and keep asking until exit condition.

### Step 3: Functional Approval Gate

> **BLOCKING**: (1) No architecture leak in functional spec — Dependencies = capabilities only, not concrete service products.
> (2) Run `validate-functional.sh` — fail → fix, do not ask approval.
> (3) Show short summary → AskUserQuestion Approve / View full / Request changes.
> (4) On approve: `meta.md` stages.functional `approved` with `approved_by` = `git config user.name` (NEVER "AI Agent").
> (5) Offer next: `/sdd.spec technical` (recommended) | `--iterate` | `/sdd.check`.
> **ONLY IF** you need AskUserQuestion payloads / summary template: Read `references/spec-functional-approval.md`.

### Step 4: External API Auto-Discovery

After functional approval, before technical:
1. Scan functional spec for integration phrases
2. Query project docs / service directory (per PROJECT.md) for each detected API
3. Display findings with status (Found/Partial/Not Found)
4. Ask: "Include discovered APIs in Dependencies?"

> **Deep Analysis Fallback**: If platform docs are insufficient for external API
> integration, Ask To Repo can query the actual source code. This is slow (30s-5min)
> and should only be used with user consent as a last resort.

### Step 4.5: Plan Mode for Brownfield (lazy-loaded)

> **ONLY IF** `mode == brownfield` AND profile is `technical` AND feature needs architecture decisions:
> Read `references/spec-plan-mode-brownfield.md` before Step 5.
> Otherwise skip (non-technical / greenfield / pure CRUD → go to Step 5).

### Step 5: Technical Spec (HOW to build)

> **IMPORTANT**: This step generates a **MARKDOWN SPECIFICATION FILE** (`spec.md`), NOT implementation code.
> If you just exited Plan Mode, your approved plan informs the CONTENT of the spec — the spec document is the output, not code files.

> **FIRST**: Read `platform` from `meta.md`. This determines which sections and subagents to use.

```bash
platform=$(grep "^\*\*Platform\*\*:" sdd/wip/[feature]/meta.md | awk '{print $2}')
```

> **Lazy-loaded**: When `platform = android` or `platform = ios`, Read `references/spec-mobile-technical.md` for the complete mobile technical spec workflow.

#### Backend/Web Technical Spec (platform = backend | web | "")

> **BLOCKING — Architect-First**: before ANY DD / service / dependency / diagram, invoke
> `Skill("sdd-system-designer")` with functional summary + capabilities. Do not invent services from pre-training.
> Single recommendation → use it. 2–3 options → Architecture Options ref below.
> Then for each selected service: `Skill("sdd-implementer")` for live SDK details.

#### Architecture Options (lazy-loaded)

> **ONLY IF** `sdd-system-designer` returns 2–3 viable approaches AND profile is `technical` AND Standard mode:
> Read `references/spec-architecture-options.md`.
> Otherwise auto-select the recommended approach and continue.

**Sections to produce** (after architect skill): Executive Summary, Architecture, Platform compliance (conditional), Project Services, Dependencies, Design Decisions (Options Considered + Trade-offs Accepted mandatory), Data Model, REST API Contracts, Testing Strategy (unit+integration; E2E external), Security (Secrets mandatory), Performance, Deployment.

### Brownfield Infrastructure Sections (lazy-loaded)

> **ONLY IF** `mode == brownfield` (from meta.md):
> Read `references/spec-brownfield-infra.md` to include/exclude Dockerfile, health, compliance sections.
> Greenfield: include full infrastructure sections from the technical template.

### Frontend Architecture Section ⭐ v2.6.0

> **Lazy-loaded**: When `should_include_frontend_architecture()` is true (Frontend framework/design system detected AND UI keywords in spec), Read `references/frontend-web-architecture.md` for frontend architecture patterns and component guidelines.

### Project Services & Instance Selection (lazy-loaded)

> **ONLY IF** the technical spec documents project services (KeyValueStore, MessageQueue, DB, etc.):
> Read `references/spec-project-services.md` for snippet format, live discovery, and `(EXISTING)`/`(NEW)` markers.
> Non-technical profile: summary table only, no code snippets.

### Technical Design Anti-Patterns (CRITICAL — short)

> Be conservative: simplest solution that works. No speculative queues/caches/microservices/abstraction layers.
> No duplicate storage of the same data in two systems.
> **ONLY IF** writing Design Decisions or reviewing over-engineering risk:
> Read `references/spec-anti-patterns.md` for full checklist and examples.

### Step 5.5: Database Migration Detection (lazy-loaded)

> **ONLY IF** the generated technical spec mentions migrations, CREATE/ALTER TABLE, or a relational DB service:
> Read `references/spec-migration-detection.md` and annotate `meta.md` before Step 6.
> Otherwise set `migration.detected: false` and continue.

### Step 6: Technical Approval Gate

> **BLOCKING**: (1) Architect self-check (`sdd-system-designer` before DD/Services; `sdd-implementer` per service).
> (2) `validate-technical.sh` then `validate-security.sh` (skip security if prototype).
> (3) Short summary + ASCII diagram (shapes: `references/spec-architecture-diagram.md`).
> (4) AskUserQuestion Approve / View full / Request changes.
> (5) On approve: `meta.md` stages.technical with human `approved_by`.
> **ONLY IF** you need AskUserQuestion payloads / summary template: Read `references/spec-technical-approval.md`.

### Step 7: Conflict Detection

After technical approval: `genai-resolve-conflicts.sh` (fallback `validate-spec-conflicts.sh`).
Present conflicts; user confirms resolve action; annotate spec.

### Step 8: Post-Approval Context Compaction

After technical approval + conflicts: run `/sdd.check --compact` if context >40% (optional for tiny specs).

### Step 9: Next Steps (both specs approved)

**Model advisory**: Read `references/model-suggestion-advisory.md` — full box for `phase_key`: `spec→plan`.

AskUserQuestion: `/sdd.plan` (recommended — sugere modelo forte) | `/sdd.spec --iterate` | `/sdd.check`.

## Key Rules

- Stack from detection + `sdd/PROJECT.md` — never invent corporate defaults/services.
- Architect-first for technical; capabilities-only in functional Dependencies.
- Validate scripts before approval; human `approved_by`; Secrets mandatory in technical Security.
- E2E: document scenarios only (no test files here). IDs via `generate-ids.sh`.
- Anti-redundancy; show summary before every approval gate.

---

## Output Files

| Phase | Path |
|-------|------|
| Functional | `sdd/wip/[feature]/1-functional/spec.md` |
| Technical | `sdd/wip/[feature]/2-technical/spec.md` |
| Architecture | `sdd/wip/[feature]/2-technical/architecture.md` |

Validation is owned by `validate-functional.sh` / `validate-technical.sh` / `validate-security.sh` at approval gates.

---

## External Context (--include) (lazy-loaded)

> **ONLY IF** user passed `--include <context>`:
> Read `references/spec-include-context.md`.

## Command Flow

`detect phase → functional (interview → approve) → API discovery → technical (architect → approve) → conflicts → /sdd.plan`

Canonical pipeline: `framework/PIPELINE.md`.

---

## References

Templates: `framework/templates/functional-spec.md`, `technical-spec.md`, `lite/spec.md`.
Pipeline: `framework/PIPELINE.md`. Shared instructions: `framework/_shared/agent-instructions.md`.

## Optional flags & conditions (lazy-loaded)

Read the matching reference **ONLY IF** the flag/condition is present. Never load all refs.

| Flag / condition | Reference |
|------------------|-----------|
| `--iterate` | `references/spec-iterate.md` |
| `--summary` | `references/spec-summary.md` |
| `--audio` | `references/spec-audio.md` |
| `--include` | `references/spec-include-context.md` |
| `functional --approve` or `technical --approve` | `references/spec-approve.md` |
| `platform = android \| ios` (technical) | `references/spec-mobile-technical.md` |
| Frontend Web stack | `references/spec-frontend-web-agents.md` |
| Profile adapt (tech vs non-tech) | `references/spec-profile-aware.md` |
| Skill hooks configured | `references/spec-skill-hooks.md` |
| Critical gaps in Step 2.5 | `references/spec-completeness-checklist.md` |
| Full interview tables needed | `references/spec-interview.md` |
| Functional approval UX payloads | `references/spec-functional-approval.md` |
| Technical approval UX payloads | `references/spec-technical-approval.md` |
| Vision missing / alignment | `references/spec-vision.md` |
| Brownfield + technical (Step 4.5) | `references/spec-plan-mode-brownfield.md` |
| Multiple architecture options | `references/spec-architecture-options.md` |
| Brownfield infra sections | `references/spec-brownfield-infra.md` |
| Project services in tech spec | `references/spec-project-services.md` |
| Over-engineering review | `references/spec-anti-patterns.md` |
| Migration signals in tech spec | `references/spec-migration-detection.md` |
| ASCII diagram shapes/examples | `references/spec-architecture-diagram.md` |
| Frontend architecture section | `references/frontend-web-architecture.md` |

---

## AI Agent Instructions

- `help` → Quick Help only, do not run workflow.
- Inline `"description"` → store as `initial_context`, seed interview (do not skip it).
- Flag-first: if an optional flag/condition matches the table above, Read that reference first and follow it; otherwise run the happy-path workflow above.
