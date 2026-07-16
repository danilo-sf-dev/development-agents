# Reference: Reverse-Eng Phase 4 — Synthesis

**Used by**: `/sdd.reverse-eng` Phase 4.

### Phase 4: Synthesis with Confidence Indicators

Transform data into specs, marking the **origin** of each piece of information.

#### Six-Level Confidence System (CRITICAL)

| Level | Icon | Meaning | Action |
|-------|------|---------|--------|
| **THREE_WAY** | ✅✅✅ | Found in code + existing-specs + , ALL MATCH | Highest confidence |
| **VERIFIED** | ✅✅ | Found in code + one other source, fields MATCH | High confidence |
| **PARTIAL** | ✅⚠️ | Found in multiple sources, but fields DIFFER | Review diff first |
| **CODE_ONLY** | 🔸 | Found only in code (reliable, undocumented) | Consider documenting |
| **DOCS_ONLY** | ⚠️ | Found only in specs/ (NOT in code) | VERIFY before using |
| **UNKNOWN** | ❓ | Insufficient information | DO NOT USE without verification |

**Source Priority for Conflicts**:
1. **CODE** - Always the source of truth
2. **existing-specs** - Pre-validated, higher trust than 
3. **Plain Docs (Wiki/Confluence)** - May be stale, lowest priority
4. **Plain Docs (README)** - HINTS ONLY, never trust without verification

#### Override Rules for Plain Docs

> **CRITICAL**: When discrepancies are found between Plain Docs (README) and CODE,
> the generated specs MUST reflect CODE reality, NOT README claims.

**Never Trust README For**:
- Storage technology choices (verify against service imports)
- project service integrations (verify against pom.xml/package.json)
- Processing architectures (verify against actual implementations)
- API versions (verify against controller annotations)

**Generates**:
- `functional-spec.md` - From use cases, capabilities (with confidence)
- `technical-spec.md` - From architecture, APIs (with confidence)
- `DISCREPANCIES_REPORT.md` - Field-level validation results
- `PATTERNS.md` - Discovered project patterns

#### Focused Extraction Merge Strategy (v2.6.2)

When `--focus <component>` is used with existing specs:

**Step 1**: Load existing specs
```bash
if [ -f "sdd/extracted/functional-spec.md" ]; then
    EXISTING_FUNCTIONAL=$(cat sdd/extracted/functional-spec.md)
fi
```

**Step 2**: Extract focused component detail
- Deep analysis of specified component
- More detailed use cases, edge cases, error flows
- Implementation specifics

**Step 3**: Merge strategy

| Spec Section | Merge Behavior |
|--------------|----------------|
| **System Context** | Preserve existing, add focused component relationships |
| **Actors** | Preserve existing, add actors relevant to focused component |
| **Use Cases** | **ADD** detailed use cases for focused component with marker |
| **Data Models** | Preserve existing, expand models used by focused component |
| **API Endpoints** | Preserve existing, add detail for focused component endpoints |
| **Patterns** | Add patterns specific to focused component |

**Step 4**: Mark focused sections for traceability

```markdown
### UC-005: Extract Products from Page
<!-- Focused: ExtractPageProductsUseCase -->

[Detailed use case from focused extraction...]

<!-- End Focus -->
```

**Step 5**: Update DETECTION_REPORT.md

```markdown
## Extraction History

| Date | Mode | Focus | Changes |
|------|------|-------|---------|
| 2026-01-24 | FULL | - | Initial extraction |
| 2026-01-25 | UPDATE | ExtractPageProductsUseCase | Added UC-005, UC-006, expanded DM-003 |
```

---
