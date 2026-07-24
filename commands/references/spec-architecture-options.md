# Reference: Architecture Options Presentation

**Used by**: `/sdd.spec` Step 5 when multiple architecture approaches are viable.

#### Architecture Options (Standard Mode + Technical Profile)

> **SKIP for mobile projects** — Mobile architecture is handled by `mobile-android-expert` / `mobile-ios-expert` skill, not `sdd-system-designer`.

> When sdd-system-designer identifies genuinely different architecture
> approaches, present them to the user before writing the spec.

**Trigger**: sdd-system-designer returns 2-3 options (not a single recommendation)
  AND profile == `technical` AND mode == Standard

**Skip when** (auto-select recommended, no user interaction):
- `non-technical` profile — agent selects best option silently (same as current behavior)
- Express mode — auto-select recommended
- User pre-selected approach in functional spec
- `platform = android` or `platform = ios` — always skip, use mobile skill instead

⛔ INVOKE TOOL (do not print this, CALL the tool):

```
AskUserQuestion(
  questions=[{
    "question": "Multiple architecture approaches are viable. Which do you prefer?",
    "header": "Architecture",
    "options": [
      {
        "label": "[Option A name] (Recommended)",
        "description": "[1-line summary]. Services: [list]. Complexity: [level]",
        "markdown": "[ASCII diagram]\n\nPros:\n- [pro1]\n- [pro2]\n\nCons:\n- [con1]\n- [con2]"
      },
      {
        "label": "[Option B name]",
        "description": "[1-line summary]. Services: [list]. Complexity: [level]",
        "markdown": "[ASCII diagram]\n\nPros:\n- [pro1]\n- [pro2]\n\nCons:\n- [con1]\n- [con2]"
      }
    ],
    "multiSelect": false
  }]
)
```

On selection:
  - Use selected approach for technical spec generation
  - Record ALL options in spec "Design Decisions" section as ADR:

```markdown
## Design Decisions
### DD-1: Architecture Approach
**Selected**: [chosen option]
**Options Considered**:
- Option A: [description] — [pros/cons]
- Option B: [description] — [pros/cons]
- Option C (selected): [description] — [pros/cons]
**Trade-offs Accepted**: [what we give up with the selected option and why it's acceptable]
**Rationale**: [why selected option fits best given the trade-offs]
```

> **⚠️ MANDATORY**: Every DD must include `Options Considered` and `Trade-offs Accepted`. Missing either section fails `validate-technical.sh` with an error (not a warning).

**Sections** (delegate heavy lifting to `sdd-system-designer`):

1. Executive Summary
2. Architecture (Mermaid diagrams - see `standards/diagram-standard.md`)
3.  Platform compliance (conditional - see below)
4.  Services

⛔ INVOKE TOOL (do not print this, CALL the tool — backend projects only):
Skill("sdd-system-designer")

   After the plugin responds, run `project-cli-expert` for live instance discovery (existing vs new).
5. Dependencies (MUST verify from docs - NEVER invent)
6. Design Decisions (with rationale)
7. Data Model
8. REST API Contracts
9. Testing Strategy (unit + integration only; E2E is external)
10. Security (MUST include Secrets Management)
11. Performance
12. Deployment
