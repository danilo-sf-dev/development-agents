# Reference: Functional Spec Interview

**Used by**: `/sdd.spec` Step 2 during the consolidated / simplified interview.

### Step 2: Functional Spec (WHAT to build)

<!-- PROFILE: TECHNICAL_ONLY -->
**Consolidated Interview (4-6 questions max)**:

| Question | Fills Sections | Condition |
|----------|----------------|-----------|
| Q1: Problem + expected outcome + business value | Problem Statement, Objectives, Success Metrics | Always |
| Q2: Explicit exclusions? | Scope (Out of Scope) | Skip if "nothing special" |
| Q3: Main user actions + outcomes | User Stories, User Experience, Acceptance Criteria | Always |
| Q3b: Data input example? | Data Model, Business Rules, Validations | **IF data processing detected** |
| Q4: External dependencies/risks + edge cases | Dependencies, Risks, Edge Cases | Skip if internal feature |
| Q4b: Business rules example? | Business Rules, Acceptance Criteria | **IF calculations detected** |
| Q5: E2E scenarios? | E2E Scenarios | Only if user/PROJECT enables E2E |

**Gap-Driven Questions** (from `genai-detect-gaps.sh` or inline fallback):

> If gaps need architecture (`delegate_to: sdd-system-designer` or async/storage/concurrent keywords):
> invoke `Skill("sdd-system-designer")` **before** asking the user. Ask in **product terms only** (no service names).
> Candidates stay tentative until technical spec.

| Feature Type | Ask (product terms) |
|--------------|---------------------|
| Async/Event | duplicate handling + payload example |
| Storage | pre-existing data + retention |
| Calculations | concrete numeric example |
| External API | failure/retry policy |
| Concurrent | conflict resolution |

Q3b/Q4b are conditional — only when relevant.
<!-- END PROFILE -->

<!-- PROFILE: NON_TECHNICAL_ONLY -->
**Simplified Interview (3-5 questions)**:

| Question | Purpose |
|----------|---------|
| Q1: What problem does this solve and what outcome do you expect? | Defines the objective |
| Q2: Is there anything that should NOT be included? | Limits scope |
| Q3: What does the user do and what do they get? | Defines actions |
| Q4: Does it need data from other systems? | Identifies dependencies |

> The agent asks questions in simple language and internally translates to technical requirements.
<!-- END PROFILE -->

**Anti-Redundancy**: NEVER ask the same thing twice. Derive from answers.

#### E2E Decision (Q5)

| Condition | E2E Question? | Default |
|-----------|---------------|---------|
| `testing.e2e.enabled` already true in PROJECT.md | Confirm / refine scenarios | keep enabled |
| E2E tooling not configured | Skip question | `e2e_enabled: false` |
| User asks for E2E / tooling present | Ask user | user choice |
