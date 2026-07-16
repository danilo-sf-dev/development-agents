# Reference: Technical Design Anti-Patterns

**Used by**: `/sdd.spec` Step 5 when drafting or reviewing technical design decisions.

### Technical Design Anti-Patterns ⚠️ CRITICAL

> **PRINCIPLE**: Be conservative. The simplest solution that works is the best solution.

**NO Over-Engineering**:
```
❌ WRONG: "Let's add a message queue for future scalability"
✅ RIGHT: Direct call. Add queue only when load requires it.

❌ WRONG: "Let's create an abstraction layer for flexibility"
✅ RIGHT: Direct implementation. Abstract when you have 3+ concrete implementations.

❌ WRONG: "Let's use microservices for separation of concerns"
✅ RIGHT: Monolith first. Split only when team/scale demands it.

❌ WRONG: "Let's add caching for performance"
✅ RIGHT: No cache. Add only when measured latency requires it.
```

**NO Data Duplication**:
```
❌ WRONG: Store same data in Object Storage AND MySQL
   → Will get out of sync!

✅ RIGHT: Store data in ONE place, use REFERENCES elsewhere
   Object Storage: { id: "abc", text: "Hello" }
   MySQL: { id: 1, storage_ref: "abc", result: "..." }
```

**Conservative Design Checklist**:
- [ ] Is this the simplest solution that meets requirements?
- [ ] Am I adding complexity for hypothetical future needs?
- [ ] Can I remove any component and still meet requirements?
