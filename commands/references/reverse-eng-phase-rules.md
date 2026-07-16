# Reference: Reverse-Eng Phase Rules

**Used by**: `/sdd.reverse-eng` AI agent instructions for detailed phase rules.

### Phase 0: Repository State Detection Rules

1. **Execute Detection FIRST** - Before any extraction
2. **Delegate to sdd-explorer** for scanning
3. **Copy detected specs** to `sdd/extracted/raw/existing-specs/[framework]/`
4. **Generate DETECTION_REPORT.md** with findings
5. **Select optimization strategy** based on detected frameworks
6. **Communicate strategy to user** before proceeding to Phase 1

### Phase 1: Parallel Extraction Rules

1. Read `optimization_strategy` from DETECTION_REPORT.md
2. Apply strategy-specific behavior
3. Execute ProjectSystemMCP queries, if configured (ALL primary queries)
4. Delegate code analysis to sdd-explorer
5. Store results in `sdd/extracted/raw/`

### Phase 2: Cross-Validation Rules

1. Compare THREE sources: existing-specs vs ProjectSystemMCP vs Code
2. Calculate coverage percentage per source
3. If coverage < 70%, execute conditional ProjectSystemMCP queries
4. **Source Priority**: CODE > existing-specs > ProjectSystemMCP

### Phase 3: Deep Cross-Validation Rules

1. For EACH entity/model: Compare fields across ALL THREE sources
2. For EACH endpoint: Verify existence in ALL THREE sources
3. For EACH enum: Compare ALL values across ALL THREE sources
4. Generate `DISCREPANCIES_REPORT.md`

### Phase 4: Synthesis Rules

1. Mark EVERY item with 6-level confidence indicator
2. **NEVER invent data** - if unknown, mark as ❓ UNKNOWN
3. Transform implementation details to capabilities
4. Use technology-agnostic language
5. Follow framework template structure
6. Follow Anti-Invention Protocol: never invent APIs, endpoints, or config that doesn't exist in the codebase

### Phase 5: PATTERNS.md Generation Rules

1. Extract patterns ONLY from actual code (not from documentation)
2. Include code evidence (file path + line reference) for each pattern
3. Categorize by: HTTP/API, Database, Messaging, Error Handling, Testing,  Services, Security
4. Only document patterns that are:
   - ✅ Actually used in the codebase (evidence in code)
   - ✅ Non-obvious (not just standard framework usage)
   - ✅ Reusable for future features
5. Output to `sdd/extracted/PATTERNS.md`

### Phase 6: Consistency Check Rules

1. After generating BOTH specs, run consistency validation
2. Check all items in `standards/spec-consistency.md`:
   - Every use case in functional → has implementation path in technical
   - Every endpoint in technical → traces to a user story
   - Data models match between specs
3. If inconsistencies found:
   - List each with severity (CRITICAL, WARNING, INFO)
   - CRITICAL blocks completion
   - WARNING requires user acknowledgment
4. Generate consistency report in synthesis output

### Phase 7: Spec Promotion Rules

1. **ALWAYS execute** - This phase is mandatory, not optional
2. **Create `sdd/specs/`** if it doesn't exist
3. **Copy specs** from `sdd/extracted/` to `sdd/specs/`:
   - `functional-spec.md`
   - `technical-spec.md`
4. **Copy PATTERNS.md** to `sdd/` root
5. **On Update Mode**:
   - **REPLACE files directly** - no `-UPDATED` suffix
   - Show diff summary before replacing
   - If >20% changes, ask confirmation
6. **Confirm to user** with final file locations

### Framework Conflict Resolution (Multi-Framework Repos)

When Phase 0 detects MULTIPLE spec frameworks:

```
┌─────────────────────────────────────────────────────────────────────┐
│  MULTI-FRAMEWORK RESOLUTION                                          │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  1. IDENTIFY all detected frameworks and their coverage areas        │
│                                                                      │
│  2. DETERMINE precedence:                                            │
│     - SDD Kit > OpenSpec > Other frameworks                     │
│     - More specific > More general                                   │
│     - Newer timestamp > Older (check file dates)                     │
│                                                                      │
│  3. ASK USER which framework is authoritative:                       │
│     "Multiple spec frameworks detected. Which should be primary?"    │
│                                                                      │
│  4. MERGE non-conflicting content from secondary frameworks          │
│                                                                      │
│  5. FLAG conflicts in DETECTION_REPORT.md for manual resolution      │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

---
