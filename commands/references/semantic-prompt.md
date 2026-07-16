# Reference: Semantic Analysis Prompt Template

**Used by**: `/sdd.doctor` Step 2 (Semantic Analysis), one call per in-scope file.

---

## Prompt Template

```
You are comparing ONE user configuration file against a fixed set of kit standards.
Your only job is to find genuine conflicts, duplication, or context-wasting content —
not to review the file for general quality.

## Kit Standards (loaded once, reused across all files in this run)
<comparator docs: elegance-principle.md, coding-standards.md, testing-strategy.md,
security*.md, skill frontmatter purpose lines, template files>

## User File Under Review
Path: <file path>
Content:
<full file content>

## Task
For each genuine conflict/duplication/context-waste you find:
1. Quote the EXACT line(s) from the user file (verbatim, with line numbers).
2. Quote or name the EXACT kit document/section it conflicts with.
3. Classify the axis: contradicts | duplicates | steals_context
4. Assign severity: ERROR (contradicts a mandatory standard) | WARN (duplicates/wastes context) | INFO (stylistic, low confidence)
5. Write a one-sentence recipe for how to fix it.

## Output Format (strict JSON, no prose outside the JSON)
{
  "issues": [
    {
      "id": "SEM-1",
      "axis": "contradicts | duplicates | steals_context",
      "severity": "error | warn | info",
      "file": "<path>",
      "line": <int>,
      "evidence": "<exact quote>",
      "kit_reference": "<doc#section, or null if none applies>",
      "recipe": "<one sentence>"
    }
  ]
}

## Hard Rules
- If you cannot point to a specific kit_reference, set severity to "info" — never claim
  a contradiction against a standard you can't cite.
- Bias toward FALSE NEGATIVES. If you're not confident, don't report it. A missed issue
  costs nothing; a false accusation erodes trust in every future run.
- Do not comment on code quality, typos, or anything outside the contradicts/duplicates/
  steals_context axes — that's out of scope for this analysis.
```

## Key Invariants (enforced by the caller, not just the prompt)

- **Evidence required**: any issue missing a verbatim quote is discarded by the caller before merging into the report.
- **Severity floor**: caller re-checks `kit_reference` — if null/empty, force severity to `info` even if the model returned something higher.
- **Rule ID namespace**: semantic issues always use the `SEM-*` prefix so they're visually distinguishable from heuristic rule IDs (`O1`, `K2`, `D1`, etc.) in the merged report.
