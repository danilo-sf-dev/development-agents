# Reference: Architecture Options Presentation

**Used by**: `/sdd.spec` Step 5 when multiple architecture approaches are viable.

#### Architecture Options (Standard Mode + Technical Profile)

> **SKIP for mobile projects** — Mobile architecture is handled by `mobile-android-expert` / `mobile-ios-expert` skill, not `sdd-system-design`. These are a **project-provided extension point, not bundled with this pack or created by `/sdd.install`** — see the status note in `spec-mobile-technical.md`.

> When sdd-system-design identifies genuinely different architecture
> approaches, present them to the user before writing the spec.

**Trigger**: sdd-system-design returns 2-3 options (not a single recommendation)
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

**Sections** (delegate heavy lifting to `sdd-system-design`):

1. Executive Summary
2. Architecture (Mermaid diagrams - see `standards/diagram-standard.md`)
3. Platform compliance (conditional - see below)
4. Services

⛔ DELEGATE (backend projects only) — `sdd-system-design` is a **Skill**, `model_role: STRONG`, delegate via `DELEGATE_OFFLOAD` (see `framework/_shared/harness-capabilities.md` for the capability and `adapters/<harness>/README.md` for the concrete dispatch on the installed harness).

After the agent responds, if a project-provided CLI-discovery skill (commonly `project-cli-expert`) is available, run it for live instance discovery (existing vs new) — **this skill is not bundled with the pack or created by `/sdd.install`; see the status note in `spec-project-services.md`. If absent, skip live discovery and rely on the technical spec / PROJECT.md for service inventory instead.** 5. Dependencies (MUST verify from docs - NEVER invent) 6. Design Decisions (with rationale) 7. Data Model 8. REST API Contracts 9. Testing Strategy (unit + integration only; E2E is external) 10. Security (MUST include Secrets Management) 11. Performance 12. Deployment
