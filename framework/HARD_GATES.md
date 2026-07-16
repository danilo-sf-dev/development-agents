# Hard Gates — Deterministic enforcement (SDD)

> **Problem**: Most SDD gates are *soft* — markdown instructions the LLM is expected to follow.
> A confused or miscalibrated model can skip them with no second layer catching the violation.
>
> **Solution**: *Hard* gates — shell scripts, git hooks, and CI steps that **exit non-zero**
> independently of the agent. The agent can still *try* to cheat; the repo refuses the commit/PR.

## Layer model

| Layer | Mechanism | Enforces | Bypass |
|-------|-----------|----------|--------|
| **Soft** | Command/skill markdown | Agent behavior | Human review, luck |
| **Hard** | `framework/tools/*.sh`, git hooks, CI | Repo state | `SDD_GUARD_SKIP=1` (local only — never in CI) |

Gate 2.5 (tests-first) is the first gate with a **hard** layer:

```
/sdd.test --approve
    │
    ├─ soft: meta.md stages.tests.status = approved
    └─ hard: guard-approved-tests.sh snapshot → sha256 per test file in tests-manifest.json

/sdd.build (implementation)
    │
    ├─ soft: "Approved Tests Are Immutable" in sdd.build.md + sdd-implementer
    └─ hard: guard-approved-tests.sh check
              ├─ pre-commit (--staged-only)
              └─ CI (full working tree vs snapshot)
```

## Script: `guard-approved-tests.sh`

Location: `framework/tools/guard-approved-tests.sh` (in target projects: `development-agents/framework/tools/`).

### Snapshot (on approval)

Run when `/sdd.test --approve` completes — **before** setting `status: approved`:

```bash
bash development-agents/framework/tools/guard-approved-tests.sh snapshot \
  --root . \
  --feature sdd/wip/my-feature
```

Writes `sha256` + `snapshotted_at` per entry in `tests-manifest.json`.

### Check (pre-commit / CI / manual)

```bash
# Pre-commit (staged files only)
bash development-agents/framework/tools/guard-approved-tests.sh check --root . --staged-only

# CI or manual audit (staged + unstaged vs snapshot hash)
bash development-agents/framework/tools/guard-approved-tests.sh check --root . --json
```

**Blocks when**:
- `tests-manifest.json → status: approved`, AND
- An approved test file appears in git diff, OR
- On-disk content hash ≠ stored `sha256`

**Does not block when**:
- No WIP feature with approved tests
- Manifest `status` is `pending`, `in-progress`, etc. (e.g. during `/sdd.test --refine`)
- `SDD_GUARD_SKIP=1` (local emergency only — logged warning)

## Installation

### Pre-commit hook

Installed automatically by `install.sh` / `install.ps1` into `.git/hooks/pre-commit` (chains with existing hooks).

Template source: `framework/templates/git-hooks/pre-commit-sdd`

### CI

Copy snippet from `framework/templates/ci/sdd-guard-approved-tests.yml` into your pipeline.

## Refine path (legitimate test edits)

1. `/sdd.test --refine` sets `tests-manifest.json → status: in-progress` (unlocks edits)
2. Human adjusts tests + re-approves
3. Snapshot runs again → new sha256 values → `status: approved`

Escalation from `/sdd.build` uses the same path — never edit approved tests silently.

## Future hard gates (not yet implemented)

| Gate | Soft today | Hard candidate |
|------|------------|----------------|
| Spec approval | meta.md flags | Validate required sections exist before plan |
| Task approval | tasks.json status | Schema + AC coverage linter |
| Build quality | sdd-validator-runner | Existing `validate-code.sh` in CI (partial) |
| Finish archive | sdd.finish checks | Script verifying meta stage + artifact completeness |

## See also

- `framework/PIPELINE.md` — gate table (soft + hard columns)
- `commands/sdd.test.md` — snapshot on approve
- `commands/sdd.build.md` — anti-gaming (soft + hard reference)
