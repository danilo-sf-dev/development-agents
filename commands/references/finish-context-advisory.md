# Reference: Finish Context Advisory

**Used by**: `/sdd.finish` under high context.

## Context Advisory

> **Before finalizing**: Finish phase should require minimal context if build was completed properly.

```
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃                    📊 CONTEXT CHECK FOR /sdd.finish                      ┃
┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┫
┃                                                                          ┃
┃  Threshold: 60% before starting /sdd.finish                             ┃
┃                                                                          ┃
┃  /sdd.finish is lightweight:                                            ┃
┃    • Validation already done in /sdd.build                              ┃
┃    • Just runs final double-check                                        ┃
┃    • Generates summary and archives                                      ┃
┃                                                                          ┃
┃  IF context > 60%:                                                       ┃
┃    → Still OK to proceed (finish is lightweight)                         ┃
┃    → Use sdd-layer-analyzer subagent for consistency check              ┃
┃                                                                          ┃
┃  IF context > 80%:                                                       ┃
┃    → Consider compacting first (optional)                                ┃
┃    → Or proceed if confident validation passed in build                  ┃
┃                                                                          ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
```

### Context Note

`/sdd.finish` should typically be run with plenty of context remaining because:
- If `/sdd.build` completed all tasks, you likely have fresh context
- If resuming after break, `/sdd.build --resume` should have clean context

If arriving at `/sdd.finish` with high context, the workflow may have skipped compaction checkpoints. Consider this a learning for next feature.

---
