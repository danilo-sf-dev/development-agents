# Reference: Frontend Task Templates

**Used by**: `/sdd.plan`, when `PROJECT.md -> platform.type == "frontend-web"`.

---

## General Template

```json
{
  "id": "TASK-NNN",
  "title": "Build <ComponentName> for <feature>",
  "description": "Implement <ComponentName> per technical spec's Frontend Architecture section. Reuse existing design-system components where possible.",
  "acceptance_criteria": [
    "AC-1: Renders the states defined in the spec (loading/empty/error/success)",
    "AC-2: Keyboard-navigable and passes basic accessibility checks (labels, roles, focus order)",
    "AC-3: Responsive at the breakpoints declared in the spec",
    "AC-4: Matches the design-system's existing visual language (spacing, typography, color tokens) — no one-off styles unless the spec explicitly calls for a new pattern"
  ],
  "layer": 1
}
```

## Typical Task Breakdown for a Frontend Feature

1. **Static UI task** — build the component tree with mock/static data, no wiring yet (fastest to review visually)
2. **Data wiring task** — connect to the real API contract, implement loading/error/empty states
3. **Interaction task** — forms, validation, optimistic updates, any state machine beyond simple display
4. **Routing task** (if new pages/routes) — add route definitions, guards, deep-link handling
5. **Test task** — component tests for the above (written in `/sdd.test`, not here — this task list just needs to make the components testable: clear props, no hidden global state)

## Acceptance Criteria Checklist (apply per component task)

- [ ] All states from the spec's "Data Fetching & API Contracts" section are handled (not just the happy path)
- [ ] No hardcoded strings that should be i18n keys, if the project uses i18n
- [ ] No new state-management library introduced without an explicit spec decision
- [ ] Component props are typed (TypeScript/PropTypes/whatever the project uses) — no implicit `any`

## Cross-Reference

For the architectural decisions behind these tasks (rendering strategy, state management, routing), see the technical spec's Frontend Architecture section — generated using `references/frontend-web-architecture.md` during `/sdd.spec`.
