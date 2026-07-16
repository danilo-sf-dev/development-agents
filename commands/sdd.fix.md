---
name: sdd.fix
description: Fix validation errors and horizontal consistency issues across spec layers. Use when /sdd.check reports errors, specs are misaligned, or tasks don't match the technical spec.
model: opus
argument-hint: "[feature-name]"
---

> **Shared agent instructions**: Read `development-agents/framework/_shared/agent-instructions.md` before executing this command.

# Command: /sdd.fix

**Purpose**: Fix errors by analyzing output and propagating changes across ALL artifacts (specs, tasks, code) to maintain consistency.

---

## Usage

```bash
/sdd.fix                           # Interactive: paste error output
/sdd.fix "error message or output" # Direct: pass error inline
/sdd.fix --file ./error.log        # From file: read error from file
/sdd.fix --audio                   # Record error description via microphone
/sdd.fix --batch                   # Batch: one subagent per fix (prevents context exhaustion)
```

---

## Quick Help

> `/sdd.fix help` → Shows this summary

**Syntax**: `/sdd.fix [input] [flags]`

| Flag | Description |
|------|-------------|
| (none) | Interactive: paste error output |
| `"error message"` | Direct: pass error inline |
| `--file <path>` | Read error from file |
| `--audio` | Record error description via microphone |
| `--batch` | Batch mode: one subagent per fix (prevents context exhaustion) |
| `--layer <N>` | Target specific layer only |
| `--auto` | Auto-apply recommended fixes |

**See also**: `/sdd.help fix` · flags lazy-loaded at bottom.

---


## Context Safety Protocol ⭐ v1.7.0

> **ROOT CAUSE OF SHALLOW FIXES**: When multiple `/sdd.fix` calls accumulate in one session, context fills to 100%. An agent with full context loses depth — it stops generating hypotheses, skips evidence gathering, and resolves superficially. This section prevents that.

### Rule: Check Context Before EVERY Fix

**BEFORE Step 0**, invoke the context guard:

```
Skill("context-guardian")
```

Then act on the result:

| Context Level | Action |
|---------------|--------|
| 0–50% | ✅ Proceed normally |
| 51–70% | ⚠️ Warn user: "Context is at X%. Investigation may be limited. Consider `/sdd.fix` in a fresh session for complex bugs." Proceed. |
| 71–89% | 🔴 Warn user: "Context at X% — deep investigation WILL be compromised. Strongly recommend fresh session." Ask to continue or abort. |
| 90–100% | ⛔ BLOCK: "Context exhausted. Fix quality cannot be guaranteed. Start a new Claude session." Do NOT proceed. |

### Rule: --batch MUST Use Subagents

The `--batch` flag MUST spawn one subagent per fix. Processing multiple fixes inline in the same session is PROHIBITED because:
- Each fix reads many files → context accumulates fast
- By fix #3, context is typically >70% → depth drops
- Fixes #4+ are often resolved superficially or incorrectly

See `references/fix-batch.md` for the subagent implementation.

---

## When to Use (short)

`/sdd.fix` = errors that reveal **spec gaps** (propagate across layers). Typos/simple bugs → fix code directly. Drift after reopen → prefer `/sdd.check --sync` when that fits.
> **ONLY IF** decision tree / comparisons:
> Read `references/fix-when-to-use.md`.

## Core Principle: Horizontal Consistency

Fix the **cause across layers** (functional ↔ technical ↔ tasks ↔ code). Never leave specs lying after a code-only patch.
Phase-aware: only edit layers that exist/are active for current stage.
> **ONLY IF** terminology / phase-aware matrix:
> Read `references/fix-horizontal-principle.md`.

## Subagent Delegation (short)

Complex/multi-file investigation → Task() subagents. `--batch` → one subagent per fix (`references/fix-batch.md`).
> **ONLY IF** full decision tree / invocation templates:
> Read `references/fix-subagent.md`.

## Workflow (outline)

1. Context guard (`context-guardian`) before Step 0
2. Detect phase → classify problem → investigate → impact all layers
3. Propose horizontal fix → plan → (spec tests if needed) → apply → re-test → code review
4. Bidirectional consistency → finalize fix record
Details: Execution Flow stubs below + lazy refs.

## Execution Flow

### Step -1: Multi-Issue Detection (lazy-loaded)

> **ONLY IF** input suggests multiple independent errors:
> Read `references/fix-multi-issue.md`. Else treat as single issue → Step 0.

### Step 0: Detect Current Phase (BLOCKING)

Determine current SDD phase from meta.md / detect-phase. Phase constrains which layers you may edit.
> **ONLY IF** needing phase matrix / bash:
> Read `references/fix-phase-detect.md`.

### Step 1: Receive Error Input

```
AI: 🔧 Fix Mode
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Current Phase: [detected phase]
Available Layers: [list of layers that exist]

Paste the error output or describe the issue:

> [User pastes error]
```

---

### Step 1.5: Problem Classification (lazy-loaded)

> Classify: CODE_BUG | SPEC_GAP | TASK_DRIFT | ENV/TEST | UNKNOWN. Drives which layers change.
> Read `references/fix-classification.md` (and `classification-guide.md` if present).

## Plan Mode (lazy-loaded)

> Opt-in. **ONLY IF** plan_mode enabled + complex bug triggers:
> Read `references/fix-plan-mode.md`. Otherwise skip.

### Step 2: Deep Investigation (lazy-loaded)

Hypotheses → evidence → eliminate → root-cause statement. No shallow “just change the code”.
> Read `references/fix-investigation.md` when investigating.

### Step 3: Assess Impact (all layers)

Functional / technical / tasks / code — list what must change. No layer left implicit.
> **ONLY IF** needing impact templates:
> Read `references/fix-impact.md`.

### Step 3.5: Anti-Shortcut (CRITICAL — short)

Forbidden: fix only code when spec is wrong; weaken tests to pass; skip a layer that impact listed; “temporary” without recording.
Must: update every impacted layer in one fix cycle; keep acceptance criteria honest.
> **ONLY IF** full protocol / examples:
> Read `references/fix-anti-shortcut.md`.

### Step 4: Propose Horizontal Fix (lazy-loaded)

Present option(s) covering all impacted layers; get user approval (Standard) before applying.
> Read `references/fix-propose.md`.

### Step 4.5: Implementation Plan (lazy-loaded)

> Ordered steps across layers. Read `references/fix-impl-plan.md`.

### Step 4.6: Fix Record Draft (lazy-loaded)

> Draft FIX-NNN record under feature fixes/. Read `references/fix-record-draft.md` (templates: `fix-templates.md`).

### Step 4.7: Specification Tests (lazy-loaded)

> **ONLY IF** classification requires new/changed behavior tests (red→green, no gaming):
> Read `references/fix-spec-tests.md`.

### Step 5: Apply Fix Horizontally

Edit every impacted layer in order (specs → tasks → code/tests as planned). No partial apply.

### Step 6: Re-run Tests

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🧪 RUNNING TESTS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Running test suite...

✅ All tests passing (47 passed, 0 failed)
✅ New tests for email validation: 3 passed
✅ Coverage: 87%
```

---

### Step 6.5: Code Review (short)

Run `sdd-code-reviewer` / validator on changed code; fix findings before Step 7.

### Step 7: Bidirectional Consistency (BLOCKING)

Re-check specs ↔ tasks ↔ code still align. On failure → do not close fix; loop to Step 3/5.
> **ONLY IF** failure handling / checklists:
> Read `references/fix-consistency.md`.

## Impact Categories (short)

SPEC | TASKS | CODE | TESTS | DOCS — tag each change; record in FIX-NNN.

## Behavior by Mode

| Mode | Behavior |
|------|----------|
| Express | Auto-apply recommended horizontal fix after investigation |
| Standard | Propose → approve → apply |

## Examples (lazy-loaded)

> Read `references/fix-examples.md` ONLY IF user asks for a full walkthrough.

## Flags (short)

`--file`, `--audio`, `--batch`, `--layer N`, `--auto` — see optional table; dangerous flags → `references/fix-dangerous-flags.md`.

## Output Format (lazy-loaded)

> Read `references/fix-output-format.md` when presenting the final summary to the user.

## AI Agent Instructions (short)

1. Context guard first; block at ≥90%.
2. Horizontal: every impacted layer; anti-shortcut.
3. `--batch` → subagents only. Never game tests.
4. Phase-aware edits only. Finalize FIX record (Step 8) when applicable.
> Extended rules: `references/fix-agent-instructions.md` ONLY IF needed.

## Failure / Exit Criteria (lazy-loaded)

> Read `references/fix-recovery.md` if fix fails or exit criteria unclear.

## Step 8: Finalize Fix Record (lazy-loaded)

> Write/update FIX-NNN + append `fixes-log.md`. Templates: `references/fix-templates.md`.
> Read `references/fix-finalize.md`. Skip if trivial one-line code-only and no WIP feature (see ref).

## Backlog Integration (lazy-loaded)

> **ONLY IF** fix reveals follow-up work: Read `references/fix-backlog.md`.

## Related Commands

`/sdd.check`, `/sdd.test --refine`, `/sdd.build`, `/sdd.backlog`.

## Optional flags (lazy-loaded)

| Flag / condition | Reference |
|------------------|-----------|
| `--audio` | `references/audio-capture-flow.md` |
| `--batch` | `references/fix-batch.md` |
| Dangerous / `--auto` nuance | `references/fix-dangerous-flags.md` |
| Multi-issue | `references/fix-multi-issue.md` |
| Classification | `references/fix-classification.md` |
| Investigation | `references/fix-investigation.md` |
| Anti-shortcut detail | `references/fix-anti-shortcut.md` |
| Spec tests (4.7) | `references/fix-spec-tests.md` |
| Finalize FIX record | `references/fix-finalize.md` / `fix-templates.md` |
| Plan mode | `references/fix-plan-mode.md` |
