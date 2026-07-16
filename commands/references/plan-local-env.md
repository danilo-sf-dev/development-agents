# Reference: Plan Local Environment

**Used by**: `/sdd.plan` Step 4.

### Step 4: Detect Services & Local Environment

> **SKIP for mobile** (`
Scan technical spec for project services (KeyValueStore, MessageQueue, MySQL, etc.) — **backend/web only**.

**Profile-aware behavior**:

| Profile | Database Question | Auto-Decision |
|---------|-------------------|---------------|
| `technical` | Ask: Container / Existing / Testcontainers | User chooses |
| `non-technical` | **DO NOT ASK** | Auto-select Container |

**For technical profile** - If relational DB detected (MySQL/PostgreSQL), use AskUserQuestion:
- "Spin up container (Recommended)"
- "Use existing database"
- "Testcontainers"

**For non-technical profile** - Auto-select with message:
```
✓ Base de datos local configurada automáticamente
```

Store choice in `tasks.json → local_config`.
