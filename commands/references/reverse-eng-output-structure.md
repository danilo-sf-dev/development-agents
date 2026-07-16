# Reference: Reverse-Eng Output Structure

**Used by**: `/sdd.reverse-eng` when creating/validating extraction paths.

## Output Structure (CANONICAL)

> **⚠️ CRITICAL**: This is the ONLY valid output structure. Any file outside these locations is an error.

```
sdd/
├── extracted/                        # WORKING directory (Phases 0-5)
│   ├── raw/                          # Phase 0-1: Source data
│   │   ├── existing-specs/           # MUST CREATE if any specs detected
│   │   │   └── DETECTION_REPORT.md   # What frameworks/specs were found
│   │   ├── mcp-platform/                  # MUST CREATE
│   │   │   ├── functional-docs.md
│   │   │   ├── technical-docs.md
│   │   │   └── openapi.yaml
│   │   ├── code-analysis/            # MUST CREATE always
│   │   │   ├── architecture/
│   │   │   ├── api-specs/
│   │   │   ├── platform-services/
│   │   │   ├── database/
│   │   │   └── deployment/
│   │   └── README.md                 # Extraction metadata
│   │
│   ├── DOCUMENTATION_GAPS.md         # Phase 2: Cross-validation report
│   ├── DISCREPANCIES_REPORT.md       # Phase 3: Field-level validation
│   ├── functional-spec.md            # Phase 4: Synthesized spec
│   ├── technical-spec.md             # Phase 4: Synthesized spec
│   ├── PATTERNS.md                   # Phase 5: Discovered project patterns
│   └── README.md                     # Index and metadata
│
├── specs/                            # FINAL location (Phase 7)
│   ├── functional-spec.md            # ← PROMOTED from extracted/
│   └── technical-spec.md             # ← PROMOTED from extracted/
│
└── PATTERNS.md                       # ← PROMOTED from extracted/ (root level)
```

**KEY POINTS**:
- `sdd/extracted/` = Working directory with all extraction artifacts
- `sdd/specs/` = **Final location** for global specs (created in Phase 7)
- Phase 7 **PROMOTES** specs from `extracted/` to `specs/`
- Both  AND code analysis are **mandatory**
- **NEVER write files to `sdd/` root except `PATTERNS.md`**

---
