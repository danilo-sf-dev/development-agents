# Execution Modes Guide

> Guide to choosing the right execution mode and template for your feature.

---

## Mode Selection

SDD Kit has **2 execution modes** and **2 template modes**.

### Execution Modes

| Mode | Flag | Interaction | Control | Best For |
|------|------|-------------|---------|----------|
| **Express** | `--express` or `/sdd.go` | Minimal | Low | Quick MVPs, solo dev |
| **Standard** | (default) | Balanced | Medium | Most features |

### Template Modes

| Template | Flag | Size | Best For |
|----------|------|------|---------|
| **Full** | (default) | ~1,100 lines | Production, compliance, multi-team |
| **Lite** | `--lite` | ~80 lines | MVPs, prototypes, internal tools |

---

## Execution Mode Details

### Express Mode

```bash
/sdd.go "add dark mode toggle"
# OR
/sdd.start "dark-mode" --express
```

**Characteristics**:
- Asks 3-5 critical questions
- Auto-generates specs
- Auto-approves specs and tasks
- Auto-selects Batched strategy
- Implements without pauses
- Auto-fixes common errors
- Archives automatically

**Token Budget**: ~80K-100K tokens

**Best for**:
- ✅ Solo developers
- ✅ Simple features (< 10 tasks)
- ✅ Quick prototypes
- ✅ Internal tools
- ✅ When you trust Platform AI docs decisions

**NOT recommended for**:
- ❌ Production features requiring review
- ❌ Compliance-heavy features (payments, PII)
- ❌ Multi-team coordination
- ❌ Complex architecture decisions

**Workflow**:
```
/sdd.go → Questions → Specs → Tasks → Build → Finish → Done
           ↑        ↑      ↑      ↑       ↑
           5-10min  auto   auto   30min   auto
```

---

### Standard Mode (Default)

```bash
/sdd.start "payment-gateway"
```

**Characteristics**:
- Interactive interview for specs
- Asks for confirmation before approving
- User chooses execution strategy
- Progress reports during build
- Pauses on errors for user input
- Shows validation results

**Token Budget**: ~100K-200K tokens (depending on feature complexity)

**Best for**:
- ✅ Production features
- ✅ Team environments
- ✅ Features requiring review
- ✅ Moderate complexity (10-30 tasks)
- ✅ Learning the framework

**NOT recommended for**:
- ❌ Very simple features (use Express)
- ❌ Very complex features where you need per-phase iteration (consider sub-commands)

**Workflow**:
```
/sdd.start → /sdd.spec → /sdd.plan → /sdd.build → /sdd.finish
              ↑           ↑            ↑              ↑
              30-60min    10-20min     1-2h           5min
              (interactive) (review)   (progress)     (summary)
```

---

## Template Mode Details

### Full Template (Default)

```bash
/sdd.start "payment-gateway"
```

**Structure**:
- `1-functional/spec.md` (378 lines)
- `2-technical/spec.md` (715 lines)
- **Total**: ~1,100 lines

**Sections included**:
- Comprehensive problem analysis
- Detailed user stories with acceptance criteria
- Success metrics and KPIs
- Dependencies and risks
- Architecture diagrams
- Complete API specifications
- Data models with relationships
-  service configurations
- Security and compliance
- E2E test scenarios
- ADRs (Architecture Decision Records)

**Best for**:
- ✅ Production features
- ✅ Compliance requirements (SOX, PCI, GDPR)
- ✅ Multi-team projects
- ✅ Complex integrations
- ✅ E2E testing with E2E
- ✅ Features requiring audits

---

### Lite Template

```bash
/sdd.start "internal-tool" --lite
```

**Structure**:
- `1-functional/spec.md` (80 lines - combines functional + technical)
- `2-technical/` (not created)
- **Total**: ~80 lines

**Sections included**:
- Problem statement (3-5 lines)
- User stories with acceptance criteria
- Scope (in/out)
- Architecture overview (simple diagram)
- API endpoints table
- Data model (basic schema)
- Technology stack
- project services
- Security essentials
- Open questions

**Best for**:
- ✅ MVPs and prototypes
- ✅ Internal tools (not customer-facing)
- ✅ Solo developer projects
- ✅ Quick iterations (< 1 week)
- ✅ Learning/experimentation

**NOT recommended for**:
- ❌ Production customer-facing features
- ❌ Compliance requirements
- ❌ Multi-team coordination
- ❌ Complex integrations

**Behavior in /sdd.spec**:
- `/sdd.spec` → Works on single combined spec
- `/sdd.spec technical` → Shows message "Lite mode: technical in functional spec"

---

## Project Mode Detection

### Greenfield Mode

**Auto-detected when**:
- Repository is empty (no meaningful content)
- OR `sdd/specs/` doesn't exist

**Behavior**:
- Offers to create PROJECT.md
- Offers .gitignore generation
- No reverse engineering needed
- Clean slate for architecture

**Commands optimized**:
- `/sdd.start` → Full setup wizard
- `/sdd.spec` → Ask all questions

---

### Brownfield Mode

**Auto-detected when**:
- Repository has existing code
- OR `sdd/specs/` exists

**Behavior**:
- Suggests `/sdd.reverse-eng` first
- References existing patterns
- Integrates with existing architecture

**Commands optimized**:
- `/sdd.reverse-eng` → Analyze first
- `/sdd.spec` → Reference existing code
- `/sdd.build` → Match existing patterns

---

## Decision Matrix

| I'm working on... | Execution Mode | Template Mode |
|-------------------|----------------|---------------|
| Quick internal tool | Express | Lite |
| MVP to validate idea | Standard | Lite |
| Production API | Standard | Full |
| Payment/PII feature | Standard | Full |
| Solo dev, simple feature | Express | Lite |
| Team feature, moderate complexity | Standard | Full |
| Complex integration, many teams | Standard | Full |
| Prototype for demo | Express | Lite |
| Brownfield refactoring | Standard | Full |

---

## Mode Combinations

### Valid Combinations

```bash
/sdd.start "feature" --express --lite    # Fast + Simple
/sdd.start "feature" --lite              # Standard + Simple
/sdd.start "feature"                     # Standard + Full (default)
```

### Invalid Combinations

```bash
/sdd.go --lite                # ❌ /sdd.go doesn't support --lite (use /sdd.start --express --lite)
```

---

## Switching Modes

**Can I change mode mid-feature?**

No. Mode is set at `/sdd.start` and persists in `meta.md`.

**To change mode**:
1. `/sdd.cancel` - Cancel current feature
2. `/sdd.start "same-feature" --[new-mode]` - Restart with new mode

**Exception**: Template mode (`--lite`) can only be set at start, cannot be changed.

---

## Recommendations by Team Size

| Team Size | Recommended Mode | Reasoning |
|-----------|------------------|-----------|
| **Solo dev** | Express or Standard + Lite | Speed, simplicity |
| **2-3 devs** | Standard + Full | Balance, team review |
| **4+ devs** | Standard + Full | Coordination, approvals |

---

## Recommendations by Feature Type

| Feature Type | Mode | Template |
|--------------|------|----------|
| CRUD API | Express | Lite |
| Payment integration | Standard | Full |
| Internal admin tool | Standard | Lite |
| Customer-facing feature | Standard | Full |
| Data migration | Standard | Full |
| Prototype/POC | Express | Lite |
| Compliance feature (SOX, PCI) | Standard | Full |
| Refactoring | Standard | Full |

---

## FAQ

**Q: Can I use --lite with production features?**
A: Not recommended. Lite template lacks compliance sections required for production.

**Q: What's the difference between Express mode and /sdd.go?**
A: `/sdd.go` is Express mode in a single command. `/sdd.start --express` is Express mode step-by-step.

**Q: Can I switch from Lite to Full mid-feature?**
A: No. Template mode is set at `/sdd.start`. To switch, cancel and restart.

**Q: Which mode should I use for learning the framework?**
A: Standard mode - shows all steps with confirmations, good for understanding the workflow.

---

For more details, see:
- [COMMANDS.md](./COMMANDS.md) - Command reference
- [AGENTS.md](./AGENTS.md) - Agent reference
- [WORKFLOW.md](./WORKFLOW.md) - Complete workflow guide
