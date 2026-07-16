# Reference: Auto-Generated Functional Spec Template

**Used by**: `/sdd.backlog`, modes 2 (`technical-only`) and 3 (`tasks-only`) — see `references/workflow-modes.md`. This is the template used to auto-draft the functional spec from a backlog item's existing context.

---

## Template

```markdown
# Functional Spec: <feature-name>

> ⚠️ **Auto-generated from backlog item <TODO/DEBT-ID>**. Review and edit before approving — this draft was inferred from the backlog description, it has not been validated with a real user/stakeholder conversation.

## Problem Statement
<Pulled verbatim from the backlog item's description field>

## Origin
- Backlog ID: <TODO-001 / DEBT-003>
- Originally logged: <date from backlog.md>
- Affected files (known at logging time): <affected_files from backlog item>

## User Story (best-effort inference)
As a <infer role from context — default to "developer" or "user" if unclear>,
I want <infer from problem statement>,
So that <infer from problem statement — mark "NEEDS REVIEW" if not inferable>.

## Acceptance Criteria (best-effort inference)
- AC-1: <infer from problem statement — mark low-confidence items explicitly>
- AC-2: <...>

> **NEEDS REVIEW**: Acceptance criteria above are inferred, not confirmed. Add/correct before moving to technical spec.

## Out of Scope
<Leave as "TBD — confirm during review" unless the backlog item explicitly excluded something>

## Success Metrics
<Leave as "TBD — confirm during review" — rarely inferable from a backlog one-liner>
```

## Rules for Filling the Template

1. **Never invent acceptance criteria the backlog description doesn't support** — if the description is thin, write fewer, more honest AC items rather than padding with generic ones.
2. **Always keep the "Auto-generated" warning banner** at the top until the human explicitly approves the spec (approval removes the banner).
3. **Low-confidence inferences must be marked inline** (`NEEDS REVIEW`) rather than presented as settled facts.
4. **If the backlog item links to related code** (`affected_files`), read those files before drafting — even a quick skim usually improves the inferred acceptance criteria significantly over description text alone.
