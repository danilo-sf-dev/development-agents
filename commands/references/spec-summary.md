# Reference: `/sdd.spec --summary`

**Used by**: `/sdd.spec --summary` and `/sdd.spec --summary <feature-name>`.

## Purpose

Provide a quick status overview without loading complete specification files.
Target approximately 100 tokens of rendered output.

## Agent instructions

1. Read only `meta.md`.
2. Scan section headers and list markers in the functional spec.
3. Scan section headers and list markers in the technical spec.
4. Count stories, acceptance criteria, endpoints, services, entities, and
   decisions where present.
5. Do not execute spec creation or load full spec contents.

## Output format

```text
┌─────────────────────────────────────────────────────────────────┐
│ SPEC SUMMARY: [feature-name]                                    │
├─────────────────────────────────────────────────────────────────┤
│ Functional Spec: [APPROVED/DRAFT/PENDING]                       │
│   • User Stories: [N]                                           │
│   • Acceptance Criteria: [M]                                    │
│   • E2E Scenarios: [K]                                          │
│                                                                 │
│ Technical Spec: [APPROVED/DRAFT/PENDING]                        │
│   • Endpoints: [N]                                              │
│   • Services: [list]                                            │
│   • Data Entities: [N]                                          │
│   • Key Decisions: [N]                                          │
│                                                                 │
│ Load full: /sdd.spec functional OR /sdd.spec technical          │
└─────────────────────────────────────────────────────────────────┘
```

Use `PENDING` when the file is absent, and omit metrics that cannot be
determined safely from headers or list markers.
