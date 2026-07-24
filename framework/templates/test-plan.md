# Test Plan — [feature-name]

**Status**: pending | in-progress | approved  
**Gate**: tests-first (antes de `/sdd.build`) — obrigatório para toda feature

---

## Coverage Map

| AC / US | Task | Test ID | Description | Edge cases |
|---------|------|---------|-------------|------------|
| AC-1 | TASK-002 | TEST-001 | | |

---

## Edge Cases (mandatory)

Every acceptance criterion / domain rule needs a happy path plus relevant edge cases
(with observable `expect` in `tests-manifest.json`). Prefer cases that protect QA/E2E risk
(`qa_surrogate: true`) over combinatorial noise.

- [ ] Empty / null inputs
- [ ] Invalid identifiers / malformed payloads
- [ ] Authorization / permission denied
- [ ] Not found / conflict errors
- [ ] Boundary values (min/max)

---

## Out of Scope (this gate)

| Item | Handled in |
|------|------------|
| E2E browser flows | Only if `testing.e2e.enabled` (PROJECT.md / meta) |
| Performance load tests | Layer 3 quality tasks |

---

## Red Phase Verification

| Run at | Command | Expected | Actual |
|--------|---------|----------|--------|
| | | New tests FAIL for the right reason (missing behavior) | |

---

## Approval

- **Approved by**:
- **Approved at**:
