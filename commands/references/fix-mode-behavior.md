# Reference: Fix Behavior by Mode

**Used by**: `/sdd.fix` Express vs Standard.

## Behavior by Mode

| Mode | Behavior |
|------|----------|
| **Express** | Auto-assess impact, auto-apply to all layers |
| **Standard** | Show impact assessment, confirm, apply all layers |
| **Expert** | Detailed analysis, choose which layers to update, manual control |

### Mode Impact on Steps

| Step | Express | Standard | Expert |
|------|---------|----------|--------|
| Step 0 (Phase Detection) | Auto | Auto | Auto |
| Step 1.5 (Classification) | Auto | Auto | User confirms |
| Step 2 (Deep Investigation) | 1 hypothesis | ≥2 hypotheses | ≥2 hypotheses, user reviews |
| Step 3 (Impact Assessment) | Auto | Shown, auto-proceed | User reviews each |
| Step 3.5 (Anti-shortcut) | Skipped | Auto-verify | User provides evidence |
| Step 4 (Propose Changes) | Skipped | Shown, confirm once | Review each layer |
| Step 4.5 (Implementation Plan) | Skipped | Auto | User reviews order |
| Step 4.6 (Fix Record Draft) | Auto | Auto | Auto |
| Step 4.7 (Spec Tests) | Skipped | Full red-green + mutation | User controls phases |
| Step 5 (Apply Fix) | Auto | After confirm | Per-layer control |
| Step 6 (Tests) | Auto | Auto | User triggers |
| Step 6.5 (Code Review) | Auto | Auto | User reviews findings |
| Step 7 (Consistency) | Auto | Auto | User verifies each |
| Step 8 (Fix Record) | Auto | Auto | Auto |

**Recommendation**: Use **Standard** mode for most fixes. Use **Expert** only when you need fine-grained control over which layers to update.

---
