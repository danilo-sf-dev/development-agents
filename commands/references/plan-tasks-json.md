# Reference: tasks.json Structure

**Used by**: `/sdd.plan` when emitting tasks.json.

## tasks.json Structure

**Single source of truth** - Do NOT create `tasks.md`.

```json
{
  "feature": "feature-name",
  "local_config": {
    "mysql": "container|testcontainers|existing|null",
    "keyvaluestore": "mock|null",
    "messagequeue": "mock|null"
  },
  "stats": { "total": 15, "done": 0, "by_layer": { "1": 8, "2": 5, "3": 2 } },
  "tasks": [
    {
      "id": "TASK-001",
      "title": "Short title",
      "description": "2-3 sentences max.",
      "status": "pending",
      "layer": 1,
      "depends_on": [],
      "files": ["path/to/file.go"],
      "acceptance_criteria": ["AC-1: ...", "GATE: go build passes"],
      "references": ["US-1"],
      "design_decisions": ["DD-1", "DD-3"]
    }
  ],
  "dependency_graph": {
    "by_layer": {
      "1": { "level_0": ["TASK-001"], "level_1": ["TASK-002"] }
    }
  }
}
```

---
