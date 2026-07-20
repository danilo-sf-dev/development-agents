# Pre-Execution Checks — Canonical Source

**Version**: 1.0.0  
**Purpose**: Validation agents must run **before** executing `/sdd.*` commands or writing specs/code.  
**Used by**: `/sdd.start`, `/sdd.check`, `/sdd.spec`, `/sdd.build`, and referenced from `AI_AGENT_GUIDELINES.md`.

> Operational boundaries (destructive ops, git, database): **`boundaries.md`** — not duplicated here.

---

## When to run

| Command | Minimum checks |
|---------|----------------|
| **Any** `/sdd.*` | Working directory + feature context |
| `/sdd.start` | All checks below |
| `/sdd.spec`, `/sdd.plan` | Stack, PROJECT.md, anti-invention |
| `/sdd.build`, `/sdd.finish` | Stack + build commands from PROJECT.md |

---

## Checklist

| Check | Rule | On failure |
|-------|------|------------|
| **Working directory** | cwd is the **target project root**, not inside `.development-agents/` or pack-only hub | STOP — change directory |
| **Feature context** | Active feature folder exists in `sdd/wip/` when phase requires it | Route to `/sdd.start` or `/sdd.check` |
| **PROJECT.md** | Read `sdd/PROJECT.md` for stack, platform, conventions, forbidden libs | Ask user if missing on brownfield |
| **Tech stack** | Never suggest a different language/framework than detected + PROJECT.md | See `core-principles.md` |
| **Internal services** | Check PROJECT.md / org services before designing new infra | Invoke architecture skill when configured |
| **Dependencies** | Never invent versions or coordinates — verify manifest or registry | Mark UNKNOWN if unverified |
| **SDK / APIs** | Never invent method signatures — verify library docs or code | Mark UNKNOWN if unverified |
| **Docker base image** | Use prefix declared in PROJECT.md when org mandates one | Flag mismatch to user |
| **Dockerfiles** | Follow org convention (e.g. FROM-only) when declared in PROJECT.md | Do not improvise |
| **LLM gateway** | If PROJECT.md mandates proxy/gateway for AI calls, use it | No direct provider bypass |
| **User profile** | `/sdd.start` Step 0 — technical vs non-technical profile | AskUserQuestion (never skip) |
| **Brownfield** | If `sdd/specs/` exists, do not treat as greenfield cleanup | Skip sample deletion |

---

## Anti-invention (summary)

If information is missing:

1. Say **UNKNOWN** — do not guess entity fields, enums, or endpoints  
2. Offer options or ask — see `core-principles.md`  
3. Verify in code before documenting — see `mandatory-standards.md` Anti-Invention Protocol

---

## Related

| Document | Content |
|----------|---------|
| `boundaries.md` | 🚫 Never / ⚠️ Ask First operational rules |
| `core-principles.md` | Smart questioning, stack fidelity |
| `mandatory-standards.md` | Build validation, coverage, anti-truncation |
