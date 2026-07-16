# Reference: `/sdd.doctor --explain <id>`

**Used by**: `/sdd.doctor --explain X2` (or any semantic issue id).

## Flow

1. Re-read the file and the cited `kit_reference`.
2. Print:
   - The exact quote from the user file (with surrounding 2-3 lines of context)
   - The exact quote from the kit reference
   - The axis (`contradicts` / `duplicates` / `steals_context`)
   - The reasoning chain — why these two pieces of text conflict
   - The recipe with concrete alternatives

This makes every semantic finding falsifiable. If the user disagrees, they can ignore it.

**Agent routing**: Skip Steps 1-3; jump directly to this explain flow. Use cached run if available, or run heuristic again and locate the issue.

See also `references/doctor-output-examples.md` for `--explain` output layout.
