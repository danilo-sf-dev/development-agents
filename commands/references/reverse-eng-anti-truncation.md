# Reference: Reverse-Eng Anti-Truncation Protocol

**Used by**: `/sdd.reverse-eng` under context pressure.

## Anti-Truncation Protocol (CRITICAL)

> **NEVER TRUNCATE entity fields, enum values, or endpoint lists.**

```
┌─────────────────────────────────────────────────────────────────────┐
│  ANTI-TRUNCATION RULE                                               │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  If an entity has 48 fields → Document ALL 48 fields                │
│  If an enum has 15 values → List ALL 15 values                      │
│  If there are 44 endpoints → Document ALL 44 endpoints              │
│                                                                     │
│  DO NOT:                                                            │
│  - Use "..." to truncate                                            │
│  - Say "and X more"                                                 │
│  - Summarize instead of listing                                     │
│                                                                     │
│  WHY: Truncated specs cause integration failures                    │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

---
