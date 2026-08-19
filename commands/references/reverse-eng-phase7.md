# Reference: Reverse-Eng Phase 7 — Spec Promotion

**Used by**: `/sdd.reverse-eng` Phase 7.

### Phase 7: Spec Promotion with Merge Confirmation (MANDATORY)

> **PURPOSE**: Copy synthesized specs to `sdd/specs/` - the canonical location for global specs.

**CRITICAL**: This phase ensures specs are in the **correct location** for the SDD workflow.

**Main agent only.** When Phase 0-3 was delegated to the `sdd-explorer` subagent (FULL
EXTRACTION / ENHANCE SPECS — see `sdd.reverse-eng.md` § "Subagent Delegation"), that subagent's
job ends when it returns exploration results. It never reaches Phase 7, never sees this dialog,
and never writes to `sdd/specs/`. Phase 4 (synthesis) through this gate always run in the main
agent, after the subagent's results are back.

#### Step 1: Present Promotion Dialog (ALWAYS)

After Phase 6 completes, **ALWAYS** ask user before promoting — this is the one and only
promotion gate for `/sdd.reverse-eng`; do not introduce a second one elsewhere:

```
┌─────────────────────────────────────────────────────────────────┐
│  📋 EXTRACTION COMPLETE - Ready to Promote                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  Generated specs in sdd/extracted/:                             │
│  • functional-spec.md (X lines, Y use cases detected)            │
│  • technical-spec.md (X lines, Y endpoints documented)           │
│  • PATTERNS.md (X patterns discovered)                           │
│                                                                  │
│  [If sdd/specs/ already exists]:                                │
│  ⚠️  Current specs will be REPLACED.                             │
│                                                                  │
│  Options:                                                        │
│  1. PROMOTE NOW - Copy to sdd/specs/ (Recommended)              │
│  2. REVIEW FIRST - Let me review extracted/ manually             │
│  3. SHOW DIFF - Show what changed vs existing specs              │
│  4. SKIP PROMOTION - Keep only in extracted/                     │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

**⛔ INVOKE TOOL (do not print this, CALL the tool):**

```
AskUserQuestion(
  questions=[{
    "question": "How would you like to proceed with the extracted specs?",
    "header": "Spec Promotion",
    "options": [
      {"label": "PROMOTE NOW", "description": "Copy to sdd/specs/ (Recommended)"},
      {"label": "REVIEW FIRST", "description": "Let me review extracted/ manually"},
      {"label": "SHOW DIFF", "description": "Show what changed vs existing specs"},
      {"label": "SKIP PROMOTION", "description": "Keep only in extracted/"}
    ],
    "multiSelect": false
  }]
)
```

#### Step 2: Execute Promotion

```
┌─────────────────────────────────────────────────────────────────────┐
│  SPEC PROMOTION                                                      │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  FROM: sdd/extracted/                                               │
│    functional-spec.md                                                │
│    technical-spec.md                                                 │
│    PATTERNS.md                                                       │
│                                                                      │
│  TO: sdd/specs/                                                     │
│    functional-spec.md    ← Global functional spec                    │
│    technical-spec.md     ← Global technical spec                     │
│                                                                      │
│  TO: sdd/ (root)                                                    │
│    PATTERNS.md           ← Reference doc (not a spec)                │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

**Promotion Steps** (same for standard and focused extractions):

1. **Create directory** if not exists:
   ```bash
   mkdir -p sdd/specs
   ```

2. **Copy/Replace specs** (ALWAYS the base files):
   ```bash
   cp sdd/extracted/functional-spec.md sdd/specs/functional-spec.md
   cp sdd/extracted/technical-spec.md sdd/specs/technical-spec.md
   ```

   > **Note**: Even with `--focus`, these are the only spec files.
   > Focused detail is merged INTO these files, not stored separately.

3. **Copy PATTERNS.md** to project root (reference doc, not a spec):
   ```bash
   cp sdd/extracted/PATTERNS.md sdd/PATTERNS.md
   ```

4. **Confirm to user**:
   ```
   ✅ Specs promoted:
      - sdd/specs/functional-spec.md
      - sdd/specs/technical-spec.md
      - sdd/PATTERNS.md

   Next steps:
   - Review specs with: /sdd.check
   - Start feature work with: /sdd.start
   ```

**Model Routing (automatic, informational only)** (before next-step AskUserQuestion if shown): `/sdd.start` next runs at `model_role: EXECUTION` — resolved and dispatched automatically, no confirmation needed. Optionally print the one-line observability format from `references/model-suggestion-advisory.md`.

#### Update Mode Behavior

When `sdd/specs/` already exists (re-extraction):
- **REPLACE** existing files directly (no `-UPDATED` suffix)
- Show diff summary before replacing
- Ask for confirmation if >20% changes detected

---
