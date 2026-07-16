# Reference: Infrastructure Task Templates

**Used by**: `/sdd.plan`, when the technical spec's Service Selection section has `(NEW)` markers (new project services/infrastructure needed, not just reuse of existing ones).

---

## General Template

```json
{
  "id": "INFRA-TASK-NNN",
  "title": "Provision <service-name> (<service-type>)",
  "description": "Create/configure <service-type> per technical spec Infrastructure section and sdd/PROJECT.md conventions. Prefer existing IaC/automation in this repo over manual provisioning.",
  "acceptance_criteria": [
    "AC-1: <service-name> exists and is reachable from the app environment",
    "AC-2: Configuration matches technical spec (size/tier, region, access policy)",
    "AC-3: Secrets/connection strings are stored via the project's secrets mechanism, never hardcoded",
    "GATE: Resource verified via list/describe command before marking task complete"
  ],
  "depends_on": [],
  "layer": 2
}
```

## Common Service Types and What to Check

| Service type | Acceptance criteria to include |
|---|---|
| **Relational DB** | Schema/migration tool matches project convention; connection pooling configured; backup policy noted if production |
| **Cache (Redis/Memcached)** | TTL strategy documented; eviction policy matches expected usage; no cache used as source of truth |
| **Message queue/topic** | Consumer group naming convention; dead-letter handling; idempotency of consumers |
| **Object storage (S3-like)** | Bucket/container access policy (private by default); lifecycle rules if temporary data |
| **Secrets manager** | Rotation policy noted; access scoped to the specific service, not broad org-wide access |
| **Feature flag service** | Flag naming convention matches project standard; default/fallback value documented |

## Ordering Rules

- Infrastructure tasks are **Layer 2** (see `sdd.plan.md` layer definitions) — they must complete before Layer 2 business-logic tasks that depend on the new service, but can run in parallel with Layer 1 (local-only) tasks.
- If task B's acceptance criteria reference a resource created in task A, set `depends_on: ["INFRA-TASK-A"]` explicitly — don't rely on ordering in the file alone.

## Anti-Patterns to Avoid

- ❌ Don't generate a single mega-task for "set up all infrastructure" — split by resource so each is independently verifiable and revertible.
- ❌ Don't skip the "GATE" verification criterion — a task that creates a resource but never confirms it exists is not actually done.
- ❌ Don't assume a specific vendor CLI/console — always check `PROJECT.md` and existing `infra/` scripts first.
