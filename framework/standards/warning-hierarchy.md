# Warning Hierarchy & Subagent Delegation

**Purpose**: Central severity model for findings raised anywhere in the pipeline (`/sdd.fix`, `/sdd.check`, `/sdd.reverse-eng`, `/sdd.build` validation), plus the rule for when analysis should be delegated to a specialized subagent instead of handled inline.

**Loaded by**: `/sdd.fix`, `/sdd.check`, `/sdd.reverse-eng`

---

## Severity Levels

| Level | Meaning | Blocks progress? |
|-------|---------|-------------------|
| **INFO** | Observation, no action required | No |
| **WARNING** | Should be addressed, but not this cycle if out of scope | No — surfaced in reports, not blocking |
| **BLOCKER** | Must be fixed before the current gate can pass | Yes — command stops and reports until resolved |

Rules of thumb:
- A finding is a **BLOCKER** if leaving it in place would violate a mandatory standard (see `mandatory-standards.md`), break a build/test, or introduce a security/data-integrity risk.
- A finding is a **WARNING** if it's a real quality issue but doesn't violate a hard rule (e.g. a slightly long function, a missing edge-case test for a non-critical path).
- A finding is **INFO** if it's purely observational (e.g. "this pattern differs from the rest of the codebase but isn't wrong").

Never silently downgrade a BLOCKER to a WARNING to avoid stopping — if a check feels too strict for the situation, surface it to the human via `AskUserQuestion` rather than reclassifying it unilaterally.

## Subagent Delegation — Central Principle

> **Delegate when the analysis needs isolated context, not when the fix is easy.**

Delegate to a specialized subagent (not just "run more steps inline") when:
- The investigation would pollute the current context with a large amount of exploratory reading that isn't needed once the root cause is found (e.g. reading 15 files to rule out 14 of them)
- The task benefits from a **fresh, unbiased perspective** — e.g. a code reviewer subagent shouldn't inherit the implementer's assumptions about why the code is "obviously correct"
- The task is naturally parallel and independent from the current flow (e.g. running a full validator suite while the main flow continues drafting a report)

Do **not** delegate when:
- The fix is a one-line, obvious correction (typo, missing import, off-by-one) — just fix it
- The subagent would need the exact same context you already have loaded, with no isolation benefit

## Cross-References

- Build/test/security standards → `mandatory-standards.md`
- Anti-pattern catalog → `anti-patterns.md`
- Task/commit formatting → `task-format.md`
