# Test Plan — [feature-name]

**Status**: pending | in-progress | approved  
**Gate**: tests-first (antes de `/sdd.build`) — obrigatório para toda feature

---

## Coverage Map

| AC / US | Task | Test ID | Case IDs | Description |
|---------|------|---------|----------|-------------|
| AC-1 | TASK-002 | TEST-001 | EC-HP, EC-001 | |

---

## Cases contract (mandatory)

Every case lives in `tests-manifest.json` → `tests[].cases[]` with:

| Field | Required |
|-------|----------|
| `id` | yes (`EC-…`) |
| `title` | yes |
| `expect` | yes — observable outcome |
| `assert_kind` | yes — `exception` \| `status` \| `state` |
| `qa_surrogate` | yes — `true` if protects QA/E2E risk |
| `risk_if_missed` | yes — one-line risk |

> Full rules: `commands/references/test-manifest-contract.md`

### Case checklist (examples — adapt to feature)

- [ ] Happy path per AC/rule
- [ ] Empty / null / blank inputs
- [ ] Invalid identifiers / malformed payloads
- [ ] Authorization / permission denied (when auth applies)
- [ ] Not found / conflict errors
- [ ] Boundary values (min/max)

Prefer `qa_surrogate: true` over combinatorial noise.

---

## QA risk bridge

| QA / E2E risk | Case ID | Test ID | qa_surrogate |
|---------------|---------|---------|--------------|
| | EC-001 | TEST-001 | true |

Every high-visibility QA risk for this feature should map to at least one `qa_surrogate: true` case.

---

## Out of Scope (this gate)

| Item | Why deferred |
|------|----------------|
| E2E browser flows | Only if `testing.e2e.enabled` |
| Combinatorial variants of the same rule | Covered by representative `cases[]` |
| Performance load tests | Layer 3 quality tasks |

---

## Red Phase Verification

| Run at | Command | Expected | Actual |
|--------|---------|----------|--------|
| | | New tests FAIL for the right reason (missing behavior / expect) | |

---

## Approval

- **Contract validated**: cases[] complete (no free-text `edge_cases`)
- **Approved by**:
- **Approved at**:
