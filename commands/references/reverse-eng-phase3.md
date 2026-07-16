# Reference: Reverse-Eng Phase 3

**Used by**: `/sdd.reverse-eng` Phase 3.

### Phase 3: Deep Cross-Validation (Field-by-Field)

> **CRITICAL**: This phase catches the most dangerous errors - phantom endpoints, missing enum values.

**Validation Checks**:

| Check Type | What to Compare | Output |
|------------|-----------------|--------|
| **Entity Fields** |  schema vs code struct/class | Field diff table |
| **Endpoint Existence** |  routes vs code annotations | Missing routes list |
| **Enum Values** |  enum vs code enum/constants | Value diff |
| ** Services** | Mentioned services vs actual dependencies | Services diff |

**Output**: `DISCREPANCIES_REPORT.md` with prioritized action items.

---
