# Reference: Reverse-Eng Phase 5 — PATTERNS.md

**Used by**: `/sdd.reverse-eng` Phase 5.

### Phase 5: Generate PATTERNS.md

> **PURPOSE**: Extract established patterns from the codebase to accelerate future development.

#### PATTERNS.md Content Guidelines (CRITICAL)

**What IS a Pattern (INCLUDE)**:
| Criteria | Example |
|----------|---------|
| Reusable code structure used **3+ times** in codebase | Error handling wrapper |
| Established convention with clear evidence | Naming conventions |
| Configuration pattern (env vars, feature flags) | Config loading strategy |
| Error handling strategy | Custom error types |
| Testing approach | Mock patterns |

**What is NOT a Pattern (EXCLUDE)**:
| Anti-Pattern | Where It Should Go |
|--------------|-------------------|
| One-time implementation details | `technical-spec.md` |
| Business logic specific to one use case | `functional-spec.md` |
| "Deep dive" analysis of a single flow | `technical-spec.md` |
| Architectural decisions | `technical-spec.md` |
| Use case descriptions | `functional-spec.md` |

#### Pattern Format Requirements

Each pattern MUST have:

```markdown
### [Pattern Name]

**Category**: [HTTP/API | Database | Messaging | Error Handling | Testing |  Services | Security]

**Evidence**: Used in:
- `path/to/file1.go:42`
- `path/to/file2.go:87`
- `path/to/file3.go:123`

**Example**:
```[language]
// Max 20 lines of code showing the pattern
```

**When to use**: [1-2 sentences explaining when to apply this pattern]
```

#### Max Patterns by Repository Size

| Repo Size | Max Patterns | Rationale |
|-----------|--------------|-----------|
| Small (<10k LOC) | **Max 10 patterns** | Small repos have limited patterns |
| Medium (10-50k LOC) | **Max 20 patterns** | Balanced coverage |
| Large (>50k LOC) | **Max 30 patterns** | Focus on most important |

> **⚠️ NEVER create "deep dive" documents** - all analysis goes into standard output files.

#### Extract from code analysis

| Category | What to Extract |
|----------|-----------------|
| **HTTP/API** | Client library, retry patterns, timeout configs |
| **Database** | Query patterns, ORM usage, migration style |
| **Messaging** | MessageQueue/Streams patterns, ACK mode, idempotency |
| **Error Handling** | Custom error types, error wrapping, logging |
| **Testing** | Test framework, mocking strategy, coverage |
| ** Services** | KeyValueStore key patterns, TTL defaults, segment usage |
| **Security** | Auth patterns, input validation, secrets access |

**IMPORTANT**: Only document patterns that are:
- ✅ Actually used in the codebase (evidence in code)
- ✅ Non-obvious (not just standard framework usage)
- ✅ Reusable for future features
- ✅ Have **minimum 2 evidence locations** in code

---
