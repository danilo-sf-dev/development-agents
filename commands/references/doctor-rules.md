# Reference: Rule Catalog (`rule → axis / kit_reference / recipe`)

**Used by**: `/sdd.doctor` Step 1 (Heuristic Scan), to resolve each raw phrase-hit into a full issue with axis, kit reference, and fix recipe.

> **Implementation note**: This catalog assumes a `phrases.json` data file (pattern → rule id mapping) and a `scan-config.sh`/`detect-duplication.sh` pair of scripts under `framework/tools/doctor/`. As of this writing those scripts don't exist yet in this repo — this file documents the intended rule catalog so the scripts (when written) and this doc stay in sync. Treat `/sdd.doctor` as **not yet functional** until that tooling is implemented.

---

## Axes

| Axis | Meaning |
|------|---------|
| `contradicts` | The user's config directly conflicts with a kit standard (e.g. "always be exhaustive" vs. elegance-principle's brevity target) |
| `duplicates` | The user's config repeats something the kit already enforces, adding noise without adding value |
| `steals_context` | The user's config consumes always-on token budget for something rarely relevant (candidate for lazy-loading, ironically the same problem this cleanup pass addressed in `commands/`) |

## Rule Catalog

| Rule ID | Axis | Kit Reference | Typical Evidence | Recipe | Fixable |
|---------|------|----------------|-------------------|--------|---------|
| `O1` | duplicates | N/A (structural) | Custom command file shadows a kit command name (e.g. `.claude/commands/spec.md`) | Rename the custom command to avoid collision | Yes |
| `O2` | steals_context | N/A (structural) | Custom agent shadows a kit agent name | Rename the custom agent | Yes |
| `K1` | contradicts | `elegance-principle.md` | Directive telling the agent to "always be exhaustive" / "never summarize" | Remove or scope the directive to specific file types | No |
| `K2` | duplicates | `coding-standards.md` | Config repeats a standard the kit already documents (e.g. restating "no hardcoded secrets") | Remove the duplicate; reference the kit standard instead | Yes |
| `D1` | duplicates | N/A (cross-file) | Two always-on files have high content overlap (shingle similarity above threshold) | Consolidate into one canonical file, reference from the other | No |
| `D2` | duplicates | N/A (cross-file) | Same as D1 but overlap is partial (specific sections, not whole files) | Extract the shared section to a common file | No |
| `X1` | contradicts | varies (semantic) | LLM-detected conflict between user config and a kit standard, no exact phrase match | Follow the specific recipe generated for that finding | No |

## Severity Assignment

- `contradicts` → default **ERROR** (breaks kit behavior)
- `duplicates` → default **WARN** (wastes tokens/maintenance, doesn't break correctness)
- `steals_context` → default **WARN**, escalate to **ERROR** if footprint exceeds threshold by 2x+

If a semantic finding (`SEM-*` / `X*`) has no `kit_reference` resolvable from the loaded comparator docs, severity automatically drops to **INFO** regardless of axis (see `semantic-prompt.md`).
