# Reference: Build Improvement Capture & Iterative Flow

**Used by**: `/sdd.build` after tasks / for flow diagrams.

## Improvement Capture

During implementation, if you detect improvements outside scope:

| Option | Action |
|--------|--------|
| Fix now | Implement if trivial (low effort) and low risk |
| Add TODO | Track in `sdd/backlog.md` |
| Add DEBT | Document as technical debt |
| Skip | Ignore if not relevant |

---

## Iterative Flow

Can return to specs if discoveries require changes:

| Size | Action |
|------|--------|
| Small | Update spec inline, continue |
| Medium | `/sdd.spec --iterate` |
| Large | `/sdd.rollback --phase 2` |

---

## Command Flow

```
/sdd.plan --approve
        │
        ▼
   /sdd.test --approve
        │
        ▼
   /sdd.build
        │
   ┌────┴────┐
   │         │
   ▼         ▼
 Layer 1     Layer 2       Layer 3
 (Local)   (CI Pipeline)  (Quality)
   │         │         │
   └────┬────┴────┬────┘
        ▼         ▼
   Final Validation
        │
        ▼
   /sdd.finish
```

---
