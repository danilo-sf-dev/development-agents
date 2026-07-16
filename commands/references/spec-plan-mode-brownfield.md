# Reference: Plan Mode for Brownfield Architecture

**Used by**: `/sdd.spec` Step 4.5 when brownfield + technical profile.

### Step 4.5: Plan Mode for Brownfield Architecture

> **ENABLED BY DEFAULT FOR TECHNICAL USERS IN BROWNFIELD**: Explore existing code and specs
> before making architecture decisions. Prevents regeneration cycles.

### Platform Availability

| Platform | Plan Mode Available |
|----------|---------------------|
| Claude Code (CLI) | ✅ Yes (`EnterPlanMode`/`ExitPlanMode`) |
| Cursor | ❌ No (use fallback) |

### Configuration

```yaml
# In PROJECT.md or development-agents/framework/config.yaml
plan_mode:
  spec_technical_brownfield: true  # Default: true (enabled)
```

### Trigger Conditions

Enter Plan Mode when **ALL** of these are true:
- Project mode is `brownfield` (from meta.md)
- User profile is `technical` (non-technical users skip Plan Mode entirely)
- Feature requires architecture decisions (not pure CRUD)
- Plan Mode not explicitly disabled

### Non-Technical Users

For `non-technical` profile:
- **NO Plan Mode** - Agent assumes everything automatically
- Agent explores code and specs internally (without showing details)
- Generates technical spec based on functional spec
- User only sees final result for approval

### Plan Mode Flow (Technical Users)

```
BEFORE engaging sdd-system-designer:

  IF brownfield AND technical_user AND config.plan_mode.spec_technical_brownfield:

    IF EnterPlanMode available (Claude Code):
      1. EnterPlanMode()

      2. EXPLORE CODE:
         - Detect existing project services in codebase
         - Map current API endpoints
         - Analyze data models and patterns
         - Check infrastructure status

      3. EXPLORE EXISTING SPECS (sdd/features/, sdd/wip/):
         - Read existing functional specs → extract data models, business rules
         - Read existing technical specs → extract services, endpoints, entities
         - Identify potential conflicts (endpoints, tables, topics)
         - Identify extension opportunities (existing entities to extend)

      4. VALIDATE FUNCTIONAL SPEC SYNC:
         - Read meta.md `auto_generated.functional` flag
         - IF `auto_generated.functional == true`:
           → Lighter validation: only check that stories exist and scope is defined
           → Skip gap/extras analysis (auto-generated is intentionally minimal)
         - ELSE (standard flow):
           - Read current feature's functional spec (1-functional/spec.md)
           - Extract: user stories, acceptance criteria, data requirements
           - Verify proposed architecture COVERS all functional requirements
           - Flag gaps: "Functional spec mentions X but architecture doesn't address it"
           - Flag extras: "Architecture includes Y but functional spec doesn't require it"

      5. DESIGN (present to user):
         - Architecture pattern (matches existing vs new)
         - project services to use (existing reuse vs new)
         - API endpoint structure (check conflicts with code AND specs)
         - Data model approach (extend existing entities vs new)
         - Spec consistency (references to existing specs if relevant)
         - **Functional coverage check**: "All N user stories covered by architecture"
         - **Gaps/extras identified** (if any)

      6. ExitPlanMode() (user approves approach)

      ⚠️ POST-PLAN-MODE CRITICAL INSTRUCTION:
      After the user approves the plan, you MUST:
      - Generate the TECHNICAL SPEC MARKDOWN (spec.md), NOT implementation code
      - The plan captured architecture decisions — the OUTPUT is a spec document
      - Do NOT write .go, .java, .ts, .py or any source code files
      - Do NOT create directories outside of sdd/wip/
      - CONTINUE with Step 5 below to generate the spec markdown

    ELSE (Fallback for non-Claude Code):
      1. EXPLORE: Same codebase and spec exploration
      2. DESIGN: Same architecture planning
      3. Display plan inline in chat
      4. AskUserQuestion: "Approve this architecture approach?"
         - Options: "Approve", "Modify", "Skip exploration"

    7. Generate full technical spec with approved approach
```

### Value: Scenarios Prevented

| Scenario | Without Plan Mode | With Plan Mode |
|----------|-------------------|----------------|
| Pattern mismatch | Hexagonal vs layered conflict | Detect and match existing pattern |
|  over-engineering | Add unnecessary services | Identify reusable existing services |
| Endpoint conflicts | Duplicate routes | Detect conflicts before generating |
| Data model conflicts | Duplicate tables | Extend existing entities |
| Spec inconsistency | New spec contradicts existing | Cross-reference before design |
| Missed reuse | Create new when extend is better | Identify extension opportunities |

---
