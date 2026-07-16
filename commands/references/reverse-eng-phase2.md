# Reference: Reverse-Eng Phase 2

**Used by**: `/sdd.reverse-eng` Phase 2.

### Phase 2: Cross-Validation (Basic Coverage)

Compare **THREE sources** and generate initial coverage report.

```
┌─────────────────────────────────────────────────────────────────┐
│                 THREE-WAY CROSS-VALIDATION                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  existing-specs/ ───┐                                           │
│                     │                                           │
│  mcp-platform/ ──────────┼──► Compare EXISTENCE ──► Coverage %       │
│                     │                                           │
│  code-analysis/ ────┘                                           │
│                                                                 │
│  Source Priority (for conflicts):                               │
│    1. CODE (source of truth)                                    │
│    2. existing-specs (pre-validated)                            │
│    3.  (may be stale)                                    │
└─────────────────────────────────────────────────────────────────┘
```

**Output**: `DOCUMENTATION_GAPS.md` with coverage percentages per category.

---
