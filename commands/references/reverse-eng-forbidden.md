# Reference: Forbidden Reverse-Eng Filenames

**Used by**: `/sdd.reverse-eng` when checking output paths.

## Forbidden File Names

> **🚨 NEVER generate these files** - they indicate unstructured output.

| Forbidden Pattern | Why It's Wrong |
|-------------------|----------------|
| `FOCUSED_ANALYSIS_*.md` | Analysis should go into standard phase outputs |
| `*_DEEP_DIVE.md` | Deep dives belong in PATTERNS.md or specs |
| `*_USE_CASE_*.md` (standalone) | Use cases go IN functional-spec.md |
| `*_FLOW_DIAGRAMS.md` | Diagrams go IN the relevant spec file |
| `*_RESERVE.md` | No ad-hoc reserve files |
| Files in `sdd/` root | Only `PATTERNS.md` allowed at root |

**If analysis is needed**: It MUST go into the appropriate phase output file:
- Use case analysis → `functional-spec.md`
- Technical deep dive → `technical-spec.md`
- Pattern analysis → `PATTERNS.md`
- Gaps/issues → `DOCUMENTATION_GAPS.md` or `DISCREPANCIES_REPORT.md`

---
