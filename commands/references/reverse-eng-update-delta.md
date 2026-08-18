# Reference: `/sdd.reverse-eng` UPDATE MODE — Delta-First Protocol

**Used by**: `/sdd.reverse-eng` when Mode = UPDATE (without `--focus` — see
`references/reverse-eng-focus.md` for the `--focus` variant, which already has its own
targeted-merge behavior and is unaffected by this file). Read this **before** Phase 1's
"Parallel Extraction" protocol (`references/reverse-eng-phase1.md`) — for UPDATE MODE, this file
decides whether Phase 1 runs at all, and if so, with what scope.

## Why this exists

Before this protocol, UPDATE MODE and FULL EXTRACTION ran the **same** Phase 1-3 exploration —
UPDATE only "diffed" against the previous specs *after* re-exploring everything. A real cost
audit of `/sdd.reverse-eng` traced an observed $1.82 / ~2.4M cache-read-token UPDATE run to
exactly this: no delta detection existed, so UPDATE re-scanned the repository broadly (often via
a generic delegated subagent) to discover that little or nothing had actually changed. This file
makes UPDATE MODE genuinely incremental: **detect the delta first, cheaply, before any
exploration**, and only look at what the delta says needs looking at.

**FULL EXTRACTION is unaffected by this file** — it keeps exploring the whole repository via
`sdd-explorer` exactly as before (§ "FULL EXTRACTION" in `sdd.reverse-eng.md`, `references/
reverse-eng-phase1.md`). Do not weaken FULL to "save cost" — the separation is deliberate:
**FULL = broad discovery, UPDATE = delta-first incremental.**

---

## Step 0: Delta Detection (mandatory, runs before Phase 1)

Run the delta detector — a real script, not a narrated re-scan:

```bash
bash framework/tools/reverse-eng-delta.sh \
  --detection-report sdd/extracted/DETECTION_REPORT.md \
  --repo-root .
```

Output is one JSON object:

```json
{"baseline_source":"sha|mtime|none","baseline_sha":"...","current_sha":"...",
 "changed_files":[...],"relevant_changed_files":[...],"delta_empty":true|false,"fallback":"full|none"}
```

- `baseline_source: "sha"` — the previous extraction's own recorded Git SHA (Tier 1, exact).
- `baseline_source: "mtime"` — no recorded SHA (an extraction predating this feature); nearest
  commit at-or-before `DETECTION_REPORT.md`'s own mtime was used instead (Tier 2, approximate
  but still real git history — not a guess).
- `baseline_source: "none"`, `fallback: "full"` — no reliable baseline could be determined at
  all (fresh report, non-git edge case, or an unreadable Extraction History table). **This is
  the one case where UPDATE MODE degrades to FULL EXTRACTION's protocol for this run only** —
  say so explicitly to the user (one line: "no reliable baseline found — running full extraction
  this once; a baseline will be recorded for future updates"), never silently. The next run will
  have a real baseline because Step 3 below always records one.
- `relevant_changed_files` already excludes this pipeline's own output (`sdd/`) — never treat a
  previous extraction's own artifacts as "the repo changed."

## Step 1: Zero-Delta Protocol (`delta_empty: true`)

```
UPDATE
→ delta detection (Step 0) → delta_empty: true
→ minimal consistency check:
    - sdd/extracted/ files exist and are non-empty
    - functional-spec.md / technical-spec.md still present in sdd/specs/ (if promoted)
→ report: "No relevant changes since <baseline_sha> — extraction is already up to date."
→ record new baseline (Step 3) — current_sha may equal baseline_sha (nothing to advance) or be
  ahead of it (unrelated commits happened but touched nothing this pipeline cares about) —
  record it either way so the next run's Tier 1 stays exact.
→ proceed directly to whatever the mode's normal next step is (VIEW STATUS / promotion gate,
  unchanged behavior — § "6. VIEW STATUS / PROMOTION" is explicitly out of scope for this file)
```

**Do NOT, on a zero-delta run**: spawn `sdd-explorer` or any subagent, re-read source files,
regenerate `PATTERNS.md`, rewrite `functional-spec.md`/`technical-spec.md`, or touch any
`sdd/extracted/raw/` file. A zero-delta UPDATE is idempotent — its only side effect is recording
the new baseline SHA (Step 3), which is bookkeeping, not a spec change.

## Step 2: Non-Zero-Delta Protocol (`delta_empty: false`)

### 2.1 Build the target set

```
relevant_changed_files (from Step 0)
        ↓
Graphify ACTIVE + READY?  (read GRAPHIFY_MODE/GRAPHIFY_GRAPH exactly as already resolved by
                            this run's own preflight — § "Code Graph" in sdd.reverse-eng.md;
                            never re-ask, never re-run the preflight here)
   ├─ YES → git guard (graphify-context.md § 2) → for each relevant changed file, query/path/
   │        explain to find directly dependent files (callers/callees, same-module neighbors)
   │        → target set = relevant_changed_files ∪ (Graphify-found direct dependents)
   │        → this is the ONLY place Graphify is used in this protocol: to size the *existing*
   │          delta's blast radius, never to re-discover the delta itself (Step 0 already did
   │          that, cheaply, via git — do not query Graphify for "what changed").
   └─ NO  → target set = relevant_changed_files, unchanged. Do NOT widen it with a manual
            repo-wide Glob/Grep pass "just in case" — an under-scoped target set is itself one
            of the delegation triggers below, not a reason to pre-emptively over-scan.
```

Never do: `graph query` → then still fall back to sweeping the repo with `Read`/`Grep`/`find`
over everything anyway. If Graphify is used, it must actually shrink or bound the reading you do
next — if it doesn't, that is itself grounds for delegation (§ 2.3), not for ignoring it and
re-scanning by hand.

### 2.2 Read the target set locally (default path — no subagent)

Read only the target-set files directly (main session `Read`/`Grep`, no delegation). For most
UPDATE runs — a handful of changed files — this is the entire "exploration" step. Update only
the spec sections that reference the affected files/components, using the same per-section merge
philosophy already established for `--focus` (`references/reverse-eng-phase4.md` § "Focused
Extraction Merge Strategy" — reuse that table and the `<!-- Focused: X -->` marker convention
directly; this file does not redefine a second merge mechanism). Sections/files with no
connection to the target set are left untouched — no rewrite, no cosmetic refresh, no metadata
touch beyond the Extraction History row (Step 3).

### 2.3 Delegate only on genuine ambiguity

UPDATE MODE does **not** delegate by default. Delegate to `sdd-explorer` (never a generic
`general-purpose` agent — same rule as FULL EXTRACTION's own mandatory-subagent block, § "Subagent
Delegation" in `sdd.reverse-eng.md`) only when one of these concretely applies:

- The delta is structurally large (many files, or files spanning many components).
- Cross-module impact of the change can't be resolved from the target set alone (e.g. a shared
  interface changed and its full blast radius is unclear even after Graphify expansion).
- Evidence conflicts between sources (existing spec says one thing, changed code says another,
  and it's not obvious which is now correct).
- Specs and code diverge in a way that's ambiguous, not a clean one-directional update.
- The target set is still large even after Graphify expansion (or Graphify wasn't available to
  bound it at all).

**If delegating**: give `sdd-explorer` the target set explicitly — "analyze exactly these N
files/components for their impact on the existing spec" — never "explore the codebase" or any
open-ended prompt. Read-only scope, per `sdd-explorer`'s own existing contract
(`skills/sdd-explorer/SKILL.md`) — unchanged by this file.

## Step 3: Record the new baseline (every UPDATE run, zero-delta or not)

Append one row to `sdd/extracted/DETECTION_REPORT.md`'s Extraction History table (template in
`sdd.reverse-eng.md` — now has a `Git SHA` column) using `current_sha` from Step 0's JSON:

```markdown
| 2026-08-18 | UPDATE | - | <one-line summary of what changed, or "no relevant changes"> | <current_sha> |
```

This is what makes the **next** UPDATE run's Step 0 land on Tier 1 (`baseline_source: "sha"`)
instead of falling back to Tier 2/3.

---

## Interaction with existing conventions (unchanged, cross-referenced not duplicated)

- **Graphify** — this file only adds a new *use* of the existing, unmodified mechanism
  (`framework/_shared/graphify-context.md`) for target-set expansion. Opt-in, no auto-install,
  no auto-update, git guard, ownership/lifecycle: all identical to every other command that uses
  Graphify. No Graphify tool is modified by this file.
- **`--focus`** — orthogonal. `--focus` targets one named component regardless of what changed;
  this file targets whatever the git delta says changed. `references/reverse-eng-focus.md` and
  its merge table are reused here (§ 2.2), not replaced.
- **VIEW STATUS / PROMOVER AGORA / REVISAR PRIMEIRO / PULAR PROMOÇÃO** — explicitly out of scope;
  this file governs Phase 0-1 scoping only, not the promotion gate (Phase 7).
