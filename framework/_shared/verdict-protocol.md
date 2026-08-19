# Verdict Output Protocol — Shared by Quality-Gate Skills

**Used by**: `skills/sdd-code-reviewer/SKILL.md`, `skills/sdd-performance-expert/SKILL.md`, and any future quality-gate skill that must produce a machine-readable pass/fail result for `/sdd.build` Layer 3. This file is the **single source of truth** for the verdict file's location convention, JSON envelope, and enforcement rule — consuming skills should reference this file by name instead of repeating it.

**Read this file when**: you are writing or maintaining a quality-gate skill and need the verdict-file contract, or you are the orchestrating command / `sdd-validator` and need to know how to read and enforce a verdict.

---

## Why this file exists

`sdd-code-reviewer` and `sdd-performance-expert` (and any similar quality-gate skill) each run their own domain-specific checks, but they all report their result the same way: a JSON verdict file, in the same directory convention, with the same three-value verdict enum, enforced the same way by the orchestrator. Duplicating that plumbing per skill made it easy for the schema to drift between copies. This file holds the shared plumbing; each skill's own `SKILL.md` keeps only what's genuinely specific to it — its own findings taxonomy, its own verdict-condition thresholds, and its own extension fields.

---

## Verdict File Location

```
sdd/wip/<feature>/verdicts/<check-name>.json
```

`<check-name>` is skill-specific (e.g. `code_review.json` for `sdd-code-reviewer`, `performance.json` for `sdd-performance-expert`) — see each skill's `SKILL.md` for its exact filename.

### Verdict Writing Instructions

1. **Create the verdicts directory** if it doesn't exist:

   ```bash
   mkdir -p sdd/wip/<feature>/verdicts
   ```

2. **Write the verdict file** with current findings, using the JSON envelope below.

3. **Verdict determines if the Layer 3 task can be completed**:
   - `APPROVED` / `CAN_PROCEED_WITH_WARNINGS` → Task can be marked complete
   - `CANNOT_PROCEED` → Must fix issues and re-run this skill

---

## JSON Schema (base envelope)

Every quality-gate verdict file MUST contain at least these fields:

```json
{
  "skill": "<skill-name>",
  "verdict": "APPROVED | CAN_PROCEED_WITH_WARNINGS | CANNOT_PROCEED",
  "findings": { "...": "skill-specific severity breakdown — see that skill's SKILL.md" },
  "timestamp": "2026-01-19T12:00:00Z"
}
```

| Field       | Type              | Meaning                                                                                                                                                                                                                                           |
| ----------- | ----------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `skill`     | string            | Name of the skill that produced the verdict (e.g. `sdd-code-reviewer`)                                                                                                                                                                            |
| `verdict`   | enum              | One of the three canonical values below                                                                                                                                                                                                           |
| `findings`  | object            | Severity-bucketed counts; the **bucket names are skill-specific** (e.g. code-reviewer uses `critical`/`major`/`minor`, performance-expert uses `critical`/`warnings`/`recommendations`) — defined in the consuming skill's own SKILL.md, not here |
| `timestamp` | string (ISO-8601) | When the verdict was produced                                                                                                                                                                                                                     |

### Canonical Verdict Values

| Verdict                     | Meaning                                                                | Task Completion |
| --------------------------- | ---------------------------------------------------------------------- | --------------- |
| `APPROVED`                  | No blocking findings of any kind                                       | Allowed         |
| `CAN_PROCEED_WITH_WARNINGS` | Only non-blocking findings, within the skill's own tolerance threshold | Allowed         |
| `CANNOT_PROCEED`            | At least one blocking finding                                          | BLOCKED         |

The exact **condition** that maps a skill's findings onto one of these three values (e.g. "any critical OR major finding" vs "any critical finding") is domain-specific and is defined in each consuming skill's own SKILL.md, not here — only the three-value enum and its meaning are shared.

### Known Per-Consumer Extension Fields

Consuming skills may add extra fields beyond the base envelope. These are **not** part of the shared contract — they're documented here only so readers know they exist and where to find their definition:

| Field              | Consumer                 | Purpose                                                                        |
| ------------------ | ------------------------ | ------------------------------------------------------------------------------ |
| `files_reviewed`   | `sdd-code-reviewer`      | Count of files covered by the review                                           |
| `patterns_checked` | `sdd-performance-expert` | List of anti-pattern categories scanned (e.g. `n+1`, `regex`, `string_concat`) |

---

## Enforcement (MANDATORY)

> **v2.0.0**: After completing its checks, a quality-gate skill MUST write a verdict file per the location convention above.

> **CRITICAL**: Enforcement is **agent-based**, not an OS/git hook (see `framework/HARD_GATES.md`).
> The orchestrating command and `sdd-validator` **must** read this verdict and stop (AskUserQuestion, always including **Outros**) when the result is `CANNOT_PROCEED`.
