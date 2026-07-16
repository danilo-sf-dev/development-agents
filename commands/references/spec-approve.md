# Reference: `/sdd.spec --approve`

**Used by**: `/sdd.spec functional --approve` or `/sdd.spec technical --approve`.

**WHEN** the user runs `/sdd.spec functional --approve` or `/sdd.spec technical --approve`:

> **CRITICAL**: Do NOT call `EnterPlanMode()`. Skip Steps 2, 4, 4.5 entirely. This flag is used to resume approval after plan mode was already completed.

1. Detect the target phase from the command: `functional` or `technical`
2. **Locate the spec file**: `sdd/wip/[feature]/1-functional/spec.md` or `sdd/wip/[feature]/2-technical/spec.md`
3. **Validate spec exists**: If the file does not exist, show error and suggest running `/sdd.spec <phase>` first
4. **Check meta.md status**: Read `meta.md` and verify the phase status is `draft` (not already `approved`)
   - If already approved: Show message "Spec already approved" and offer next steps
5. **Run validation** (same as Step 3a/6a depending on phase):
   - Functional: `bash development-agents/framework/tools/validation/validate-functional.sh sdd/wip/[feature]`
   - Technical: `bash development-agents/framework/tools/validation/validate-technical.sh sdd/wip/[feature]`
   - If validation fails: Show errors, do NOT proceed
6. **Show concise summary** (same as Step 3b/6b depending on phase)
7. **Ask for approval** via AskUserQuestion (same as Step 3c/6c depending on phase)
8. **On approval**: Update `meta.md` with `status: approved`, `approved_by: <git config user.name>`, `approved_at: <ISO-8601>`
9. **Context advisory** (optional): Estimate context usage. If > 50%, show:
   ```
   ╔═══════════════════════════════════════════════════════╗
   ║  CONTEXT ADVISORY (optional)                          ║
   ╠═══════════════════════════════════════════════════════╣
   ║                                                       ║
   ║  Context usage: ~[XX]%                                ║
   ║  Phase completed: [spec phase]                        ║
   ║                                                       ║
   ║  All decisions are saved in your spec artifacts.      ║
   ║  Consider /clear before starting next phase           ║
   ║  for maximum available context.                       ║
   ║                                                       ║
   ║  This is optional — you can continue as-is.           ║
   ║                                                       ║
   ╚═══════════════════════════════════════════════════════╝
   ```

**PROHIBITED**:
- ❌ Calling `EnterPlanMode()` — the user already exited plan mode
- ❌ Re-running the interview or spec generation steps
- ❌ Re-entering the full workflow (Steps 1-6)
