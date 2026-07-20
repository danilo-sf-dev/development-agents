---
name: sdd.reverse-eng
description: Reverse engineer existing codebase to generate SDD specifications. Use when user wants to create specs from existing code.
model: opus
argument-hint: "[scope]"
---

> **Shared agent instructions**: Read `development-agents/framework/_shared/agent-instructions.md` before executing this command.

# Command: /sdd.reverse-eng

**Version**: 2.6.2
**Last Updated**: 2026-01-21
**Description**: Reverse engineer an existing codebase to generate specs for spec-driven evolution.

**Usage**:
- `/sdd.reverse-eng` → Analyze current directory
- `/sdd.reverse-eng [path]` → Analyze specific path
- `/sdd.reverse-eng --focus api,database` → Focus on specific areas
- `/sdd.reverse-eng --focus --audio` → Record component focus via microphone

---

## Quick Help

> `/sdd.reverse-eng help` → Shows this summary

**Syntax**: `/sdd.reverse-eng [path] [flags]`

| Flag | Description |
|------|-------------|
| (none) | Analyze current directory |
| `[path]` | Analyze specific path |
| `--focus <component>` | Deep-dive into specific component, enriching existing specs |
| `--focus --audio` | Record component focus description via microphone |

**Note on `--focus`**: This flag enriches existing specs with more detail about a specific component.
It does NOT create separate spec files - it updates `functional-spec.md` and `technical-spec.md` directly.

Use cases:
- General extraction first, then `--focus PaymentService` for more detail
- Re-extract specific component that was too shallow
- Add detail to existing brownfield specs

**See also**: `/sdd.help reverse-eng` · `--focus` / `--audio` lazy-loaded at bottom.

**Model advisory (entry)**: Read `references/model-suggestion-advisory.md` — compact line for `phase_key`: `entry:reverse-eng`.

---

## ⚡ First Step: Mode Selection (MANDATORY)

> **🚨 CRITICAL**: Before ANY extraction work, ALWAYS present mode selection to user.

AskUserQuestion first: **FULL** | **UPDATE** | **VIEW STATUS** | (if specs without extracted) **ENHANCE**.

**⛔ INVOKE TOOL (do not print this, CALL the tool):**

```
AskUserQuestion(
  questions=[{
    "question": "Select the reverse-engineering mode for this codebase.",
    "header": "Mode Selection",
    "options": [
      {"label": "FULL EXTRACTION", "description": "Complete analysis from scratch"},
      {"label": "UPDATE MODE", "description": "Re-analyze and merge with existing specs"},
      {"label": "VIEW STATUS", "description": "Show current extraction summary"},
      {"label": "ENHANCE SPECS", "description": "Add missing details to existing specs (only if sdd/specs/ exists but sdd/extracted/ doesn't)"}
    ],
    "multiSelect": false
  }]
)
```

### Mode Behavior

| Mode | Condition | Behavior |
|------|-----------|----------|
| **FULL EXTRACTION** | Any state | Delete existing `sdd/extracted/`, create fresh, run Phase 0-7 |
| **UPDATE MODE** | `sdd/extracted/` exists | Re-run extraction, compare diffs, update ALL files |
| **UPDATE MODE + --focus** | `sdd/extracted/` exists + `--focus` flag | **Enrich** existing specs with focused component detail |
| **VIEW STATUS** | `sdd/extracted/` exists | Show summary of current extraction, no changes |
| **ENHANCE SPECS** | `sdd/specs/` exists, `sdd/extracted/` missing | Analyze code to add missing details to existing specs |

> **Lazy-loaded**: When `--focus` is present, Read `references/reverse-eng-focus.md` (includes anti-pattern rules for `-UPDATED` suffixes).

---

## Subagent Delegation (MANDATORY)

> **⚠️ MANDATORY**: See [warning-hierarchy.md](../framework/standards/warning-hierarchy.md#subagent-delegation-central-principle) for the central principle.
> This command MUST delegate exploration work to the `sdd-explorer` subagent.

```
┌─────────────────────────────────────────────────────────────────────┐
│  MANDATORY SUBAGENT: sdd-explorer                                   │
│                                                                      │
│  Use Task(subagent_type="sdd-explorer") for: Phase 0-3             │
│                                                                      │
│  WHY: Reduces tokens 30-40%, isolates read-only operations,          │
│       preserves main context for synthesis.                          │
│                                                                      │
│  WORKFLOW:                                                           │
│  1. Main agent coordinates phases and writes final specs             │
│  2. sdd-explorer subagent performs all read-only exploration        │
│  3. Results returned to main agent for synthesis (Phase 4)           │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Purpose

Performs comprehensive reverse engineering in **eight phases** (0-7):

| Phase | Name | Purpose |
|-------|------|---------|
| **0** | Repository State Detection | Identify existing specs/frameworks before extraction |
| **1** | Parallel Extraction | Extract data from existing docs/specs AND code (both mandatory) |
| **2** | Basic Cross-Validation | Compare sources, calculate coverage |
| **3** | Deep Cross-Validation | Field-by-field comparison, detect phantom endpoints |
| **4** | Synthesis | Generate specs with 6-level confidence indicators |
| **5** | Generate PATTERNS.md | Extract established patterns from codebase |
| **6** | Consistency Check | Validate functional ↔ technical alignment |
| **7** | Spec Promotion | **Copy specs to `sdd/specs/`** for brownfield mode |

**Use Cases**:
1. **Onboarding**: Document existing system for new team members
2. **Evolution**: Prepare system for spec-driven feature development
3. **Migration**: Create specs before technology migration
4. **Compliance**: Generate architecture documentation for audits

---

## Output Structure (CANONICAL)

> Working: `sdd/extracted/` · Final: `sdd/specs/` (+ root `sdd/PATTERNS.md`). Never invent ad-hoc files at `sdd/` root.
> **ONLY IF** needing full tree / KEY POINTS:
> Read `references/reverse-eng-output-structure.md`.

## Directory Creation Rules (MANDATORY)

> **🚨 CRITICAL**: Before writing ANY file, ensure parent directories exist.

**Phase 0 Pre-step** - Create complete structure:

```bash
# ALWAYS execute at start of extraction
mkdir -p sdd/extracted/raw/existing-specs/
mkdir -p sdd/extracted/raw/mcp-platform/
mkdir -p sdd/extracted/raw/code-analysis/architecture/
mkdir -p sdd/extracted/raw/code-analysis/api-specs/
mkdir -p sdd/extracted/raw/code-analysis/platform-services/
mkdir -p sdd/extracted/raw/code-analysis/database/
mkdir -p sdd/extracted/raw/code-analysis/deployment/
mkdir -p sdd/specs/
mkdir -p sdd/wip/
```

**Validation Rule**: If any directory creation fails, STOP and report error.

---

## Forbidden File Names (short)

Never write `FOCUSED_ANALYSIS_*`, `*_DEEP_DIVE.md`, standalone use-case files, or anything in `sdd/` root except `PATTERNS.md`.
> **ONLY IF** validating filenames / remapping content:
> Read `references/reverse-eng-forbidden.md`.

## Eight-Phase Workflow

### Phase 0 Pre-step: Ensure Standard Structure (MANDATORY)

> **PURPOSE**: Create the sdd/ directory structure if it doesn't exist.

**ALWAYS execute BEFORE Phase 0 detection**:

```bash
# Check if sdd/ exists
if [ ! -d "sdd" ]; then
    # Create standard structure
    mkdir -p sdd/specs
    mkdir -p sdd/extracted/raw/code-analysis
    mkdir -p sdd/wip

    echo "✅ Created sdd/ directory structure. This repo is now ready for SDD workflow."
fi
```

**Structure Created**:
```
sdd/
├── specs/           # For promoted global specs
├── extracted/
│   └── raw/
│       └── code-analysis/
└── wip/             # For feature work-in-progress
```

**Why This Matters**: Users reported confusion when `sdd/` didn't exist. This ensures a consistent starting point regardless of repo state.

---

### Phase 0 Pre-step 2: Project Configuration (lazy-loaded)

> Ensure `PROJECT.md` (+ optional CLAUDE.md bootstrap). Resolve `$spec_lang`.
> **ONLY IF** PROJECT.md/CLAUDE.md missing or language unresolved:
> Read `references/reverse-eng-project-config.md`.

### Phase 0: Repository State Detection

> **PURPOSE**: Identify if the repository already has specifications or follows an established spec framework.

**Detection Matrix** (execute in order):

| Framework | Detection Patterns | Confidence |
|-----------|-------------------|------------|
| **SDD Kit** | `sdd/specs/*.md`, `sdd/wip/*/spec.md` | 🟢 High |
| **OpenSpec** | `openspec/specs/`, `openspec/project.md` | 🟢 High |
| **GitHub Spec-Kit** | `memory/`, `.markdownlint-cli2.jsonc` | 🟢 High |
| **Kiro** | `.kiro/` folder OR triplet with Kiro markers | 🟡 Medium |
| **Tessl** | `.tessl/framework/`, `@generate`/`@test` tags | 🟢 High |
| **Cursor Rules** | `.cursor/rules/*.md`, `.cursorrules` | 🟡 Medium |
| **Claude Code** | `CLAUDE.md`, `.claude/settings.json` | 🟡 Medium |
| **Codex** | `.codex/instructions.md`, `.codex/AGENTS.md` | 🟡 Medium |
| **SpecStory** | SpecFlow methodology, captured conversation specs | 🟡 Medium |
| **OpenAPI/Swagger** | `openapi.yaml`, `swagger.json` | 🟢 High |
| **ADR/RFC** | `docs/adr/`, `docs/rfc/` | 🟡 Medium |
| **Plain Docs** | `ARCHITECTURE.md`, `DESIGN.md` | 🟡 Medium |

> **Reference**: See `sdd-explorer` agent for complete detection commands.

**Optimization Strategies** (based on detected frameworks):

| Strategy | When to Use | Expected Speedup |
|----------|-------------|------------------|
| **INCREMENTAL** | SDD Kit detected | 60-80% faster |
| **AUGMENTED** | OpenSpec, Spec-Kit, Kiro detected | 40-60% faster |
| **API_ANCHORED** | OpenAPI/Tessl detected | 30-50% faster |
| **ASSISTED** | Cursor Rules, ADR, Plain Docs | 10-20% faster |
| **FULL** | No frameworks detected | Baseline |

**Output**: `DETECTION_REPORT.md` with findings + selected `optimization_strategy`

**DETECTION_REPORT.md Template**:
```markdown
# Detection Report

**Generated**: [ISO-8601 timestamp]
**Repository**: [repo name]

## Extraction Scope

**Mode**: [FULL | UPDATE | ENHANCE]
**Focus Component**: [component name if --focus used, "Full Repository" otherwise]

## Detected Frameworks

| Framework | Confidence | Files Found |
|-----------|------------|-------------|
| [name] | 🟢 High / 🟡 Medium | [file list] |

## Selected Strategy

**Strategy**: [INCREMENTAL | AUGMENTED | API_ANCHORED | ASSISTED | FULL]
**Rationale**: [why this strategy was chosen]

## Detected Specs Summary

| Spec Type | Location | Last Modified |
|-----------|----------|---------------|
| [type] | [path] | [date] |

## Extraction History

| Date | Mode | Focus | Summary |
|------|------|-------|---------|
| [ISO-8601] | [mode] | [component or "-"] | [brief description] |

## Recommendations

- [Action items based on findings]
```

---

### Phase 1: Parallel Extraction (lazy-loaded)

> Extract from existing docs/specs **and** code (both mandatory). Prefer Task()-delegated subagents.
> **ONLY IF** running Phase 1 (full/update/enhance modes that extract):
> Read `references/reverse-eng-phase1.md`.

### Phase 2: Cross-Validation (lazy-loaded)

> Compare sources, coverage gaps → `DOCUMENTATION_GAPS.md`.
> Read `references/reverse-eng-phase2.md` when executing Phase 2.

### Phase 3: Deep Cross-Validation (lazy-loaded)

> Field-by-field + phantom endpoints → `DISCREPANCIES_REPORT.md`.
> Read `references/reverse-eng-phase3.md` when executing Phase 3.

### Phase 4: Synthesis (lazy-loaded)

> Write `functional-spec.md` + `technical-spec.md` with confidence indicators.
> Read `references/reverse-eng-phase4.md` when synthesizing.

### Phase 4.5: Code Ownership Mapping

> **Lazy-loaded**: When mode is FULL or ENHANCE (not UPDATE), Read `references/code-ownership.md` for code ownership analysis guidelines.

---

### Phase 5: Generate PATTERNS.md (lazy-loaded)

> Extract established patterns → `sdd/extracted/PATTERNS.md`.
> Read `references/reverse-eng-phase5.md` when generating patterns.

### Phase 6: Functional ↔ Technical Consistency (lazy-loaded)

> Validate functional ↔ technical alignment before promotion.
> Read `references/reverse-eng-phase6.md` when executing Phase 6.

### Phase 7: Spec Promotion (lazy-loaded)

> Promote `extracted/` → `sdd/specs/` (+ PATTERNS.md) with merge confirmation when specs already exist.
> Read `references/reverse-eng-phase7.md` before writing to `sdd/specs/`.

## Anti-Truncation (CRITICAL — short)

Never stop mid-phase; write partial artifacts to disk; resume from last completed phase.
> **ONLY IF** context pressure or long extraction:
> Read `references/reverse-eng-anti-truncation.md`.

## AI Agent Instructions


### Help Flag Detection

**WHEN** the user runs `/sdd.reverse-eng help`:
1. Output ONLY the "Quick Help" section (not full documentation)
2. Do NOT execute reverse-eng logic
3. Keep response concise (~15 lines)

## Optional flags (lazy-loaded)

Read **ONLY IF** flag/condition present:

| Flag / condition | Reference |
|------------------|-----------|
| `--focus` | `references/reverse-eng-focus.md` |
| `--audio` | `references/audio-capture-flow.md` |
| `platform = android \| ios` | `references/start-mobile-claude.md` |
| Full output tree | `references/reverse-eng-output-structure.md` |
| Forbidden filenames | `references/reverse-eng-forbidden.md` |
| PROJECT.md / CLAUDE.md bootstrap | `references/reverse-eng-project-config.md` |
| Phase 1 extraction | `references/reverse-eng-phase1.md` |
| Phase 2–3 validation | `references/reverse-eng-phase2.md`, `phase3.md` |
| Phase 4–7 | `references/reverse-eng-phase4.md` … `phase7.md` |
| Anti-truncation | `references/reverse-eng-anti-truncation.md` |
| Detailed phase rules | `references/reverse-eng-phase-rules.md` |

## Telemetry

Telemetry is captured **automatically by hooks** during reverse-engineering. No manual tracking required.

**Supported Tools**:
| Tool | Support |
|------|---------|
| Claude Code | ✅ |
| Cursor | ✅ |
| optional Agent CLI | ✅ |

---

## Related Commands

- `/sdd.start` - Start new feature after reverse engineering
- `/sdd.import` - Import specific specs

---

## References

- **Detection commands**: `sdd-explorer` agent
- **Spec templates**: `templates/reverse-eng/`
- **Anti-Invention Protocol**: Never invent APIs, endpoints, or config
- **Consistency validation**: `standards/spec-consistency.md`
