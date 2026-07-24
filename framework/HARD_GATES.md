# Process gates — LLM validator (no OS hard deps)

> **Decision (2026)**: Machine-level hard gates (`bash` + `jq` + git hooks + CI scripts) were
> removed. Corporate Windows fleets often lack a reliable shell/`jq` path; blocking the pipeline
> on those tools made the pack less portable.
>
> Enforcement of SDD process rules is now **agent-based**: `sdd-validator-runner` runs a
> **Process Compliance** check (isolated context), and the orchestrating command **must** pause
> with AskUserQuestion (always including **Outros**) when a process rule fails or is ambiguous.

## Layer model

| Layer | Mechanism | Enforces | Bypass |
|-------|-----------|----------|--------|
| **Soft convention** | Command/skill markdown | Agent behavior | Human review |
| **Process validator** | `agents/sdd-validator-runner.md` → Check: Process Compliance | Pipeline integrity | User authorizes via AskUserQuestion (incl. Outros) |
| **Optional local tooling** | Project’s own CI / hooks | Whatever the team installs | Outside this pack |

This pack does **not** install pre-commit hooks or require `jq`/`bash` for gate enforcement.

## What the validator checks (process)

See `agents/sdd-validator-runner.md` → **Check 6: Process Compliance**:

1. Approved artifact immutability (tests / specs / tasks while `status: approved`)
2. Phase order (e.g. build only after tests approved)
3. Anti-shortcut (no production feature code during `/sdd.test`; no new unit tests during `/sdd.build`)
4. Manifest consistency (`tests-manifest.json` ↔ files ↔ `meta.md`)
5. Manifest case contract (`tests[].cases[]` with `expect` / `assert_kind` / `qa_surrogate` / … — no hollow labels)

Quality/security/build/test execution remain separate checks (same agent).

## Human authorization

When process compliance fails or is unclear:

1. STOP — do not continue the task cycle silently
2. Call AskUserQuestion with closed options **and always** an **Outros** free-text option
3. User may keep the current model, switch to a stronger one for the validator pass, skip with risk accepted, or describe another path via Outros

Template: `commands/references/ask-user-question-outros.md`

## Refine path (legitimate test edits)

1. `/sdd.test --refine` sets `tests-manifest.json → status: in-progress`
2. Human adjusts tests + re-approves
3. Return to `/sdd.build`

## See also

- `framework/PIPELINE.md` — gate table
- `commands/sdd.build.md` — anti-gaming (soft + validator)
- `commands/sdd.test.md` — approval gate
- `agents/sdd-validator-runner.md` — process + quality checks
