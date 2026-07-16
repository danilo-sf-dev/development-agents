# Reference: Infrastructure Creation (`/sdd.build` Step 3.3)

**Used by**: `/sdd.build` Step 3.3, when `tasks.json` contains `INFRA-TASK-*` entries (from services marked `(NEW)` in the technical spec).

**Skip if**: No `INFRA-TASK-*` entries in `tasks.json`.

**Runs before**: Step 3.5 (Database Migration Branch).

## Generic infra protocol

Provision project services / platform services using what the **target project** declares — never assume a vendor CLI or marketplace skill.

```
FOR EACH pending INFRA-TASK in tasks.json:
  1. Read service type, name, and parameters from the task AND the technical spec
     (Infrastructure / Services sections) and sdd/PROJECT.md.
  2. Prefer automation already used in the repo (IaC, Terraform, Pulumi, CloudFormation,
     platform CLI named in PROJECT.md, or existing scripts under infra/).
  3. If PROJECT.md names an infra skill/plugin, invoke that skill; otherwise follow
     the create/verify steps written in the INFRA-TASK description.
  4. Verify the resource exists (list/describe via the same tooling).
  5. If automation is unavailable → AskUserQuestion: Retry / Mark manual / Abort.
     NEVER mark skipped without explicit user approval.
  6. "Already exists" → mark completed (idempotent).
```

**Cite in the layer commit**:
```
infra: provision <service-name> per technical spec / PROJECT.md
```
