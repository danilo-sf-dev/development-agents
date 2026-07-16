# Reference: Layer-Based Execution

**Used by**: `/sdd.build` Step 3.

### Step 3: Layer-Based Execution

Execute tasks by LAYER first, then by dependency level:

```
LAYER 1 (Local) - Parallel Execution
├─ Skill(skill="sdd-code-reviewer") → Build mode (load security rules + SDKs) [MANDATORY]
├─ Analyze task dependencies → identify independent tasks
├─ For each independent task group:
│   ├─ IF platform == "android" → Spawn sdd-implementer (isolation: "worktree")
│   ├─ IF platform == "ios"     → Spawn sdd-implementer     (isolation: "worktree")
│   ├─ ELSE                     → Spawn sdd-implementer          (isolation: "worktree")
│   └─ Each instance works on its own worktree
├─ After all complete:
│   ├─ Merge worktree changes to main branch
│   └─ Resolve any conflicts
├─ Validate gates pass (build, local tests)
├─ git commit "feat: layer 1 complete"
└─ /sdd.check --compact (if context > 50%)

LAYER 2 (Integration)
├─ Execute all Layer 2 tasks
├─ Validate CI Pipeline passes
├─ git commit "feat: layer 2 complete"
└─ /sdd.check --compact (if context > 50%)

LAYER 3 (Quality)
├─ Skill(skill="sdd-code-reviewer") → Audit mode (vulnerability review) [MANDATORY]
├─ Execute all quality tasks
├─ All experts pass (0 findings)
└─ git commit "feat: layer 3 complete"

<signal>ALL_TASKS_COMPLETE</signal>
```

#### Layer Completion Protocol

After completing all tasks in a layer:

1. **Validate layer**: All tasks pass gates
2. **Commit**: Natural checkpoint for the layer
3. **Compact context** (if needed): `/sdd.check --compact`
4. **Proceed to next layer**

**Why compact between layers**:
- Layer 1 code details not needed for Layer 2  integration
- Layer 2 service configs not needed for Layer 3 quality reviews
- Prevents context exhaustion on large features

**When to optimize context**:
- Context > 50% after completing a layer → Recommend `/clear` or compaction (show advisory below)
- Context > 70% → Strongly recommend `/clear` before next layer
- Large feature (10+ tasks per layer) → Always optimize context

**Context advisory** (when context > 50% at layer boundary):
```
╔═══════════════════════════════════════════════════════╗
║  CONTEXT ADVISORY (optional)                          ║
╠═══════════════════════════════════════════════════════╣
║                                                       ║
║  Context usage: ~[XX]%                                ║
║  Layer completed: [N]                                 ║
║                                                       ║
║  All progress is saved in specs and tasks.json.       ║
║  Options:                                             ║
║    1. /clear — fresh context (recommended if > 50%)   ║
║    2. /sdd.check --compact — compress current context║
║    3. Continue as-is                                  ║
║                                                       ║
╚═══════════════════════════════════════════════════════╝
```

#### Layer 1 Parallel Execution Strategy

When Layer 1 has multiple independent tasks, use worktree-isolated agents for parallel execution:

1. **Dependency analysis**: Identify tasks with no inter-dependencies (no shared files, no data flow between them)
2. **Parallel dispatch**: Spawn the platform-correct implementer (with `isolation: "worktree"`) for each independent task or task group:
   - `platform == "android"` → `sdd-implementer` — optional mobile docs/skills from PROJECT.md
   - `platform == "ios"` → `sdd-implementer` — optional mobile docs/skills from PROJECT.md
   - backend/web → `sdd-implementer`
3. **Merge**: After all instances complete, merge worktree changes back to the main branch and resolve conflicts
4. **Validate**: Run build + local tests on the merged result

**When NOT to parallelize**:
- Tasks that modify the same files
- Tasks with data dependencies (task B needs output from task A)
- Less than 3 independent tasks (overhead not worth it)
- Layer 2 tasks ( services have side effects — always sequential)
- Layer 3 tasks (quality reviews need full codebase context)

#### After Layer Completion - Interactive Next Steps

> **MANDATORY (Standard mode only)**: Check context, then offer interactive selection after each layer.
> **EXPRESS MODE**: Check context, show advisory only if > 70%, then auto-continue to next layer.

**Context check**: Estimate context usage. If > 50%, show advisory before presenting options (tasks.json is already up-to-date on disk from Step 5, and layer commit includes it):

```
╔═══════════════════════════════════════════════════════╗
║  CONTEXT ADVISORY                                     ║
╠═══════════════════════════════════════════════════════╣
║                                                       ║
║  Context usage: ~[XX]%                                ║
║  Layer completed: [N]                                 ║
║                                                       ║
║  All progress is saved in tasks.json (committed).     ║
║  Primary recommendation:                              ║
║    /clear then /sdd.build --resume                   ║
║  Fresh context (~187K tokens) outperforms              ║
║  compaction (~140K degraded tokens).                   ║
║                                                       ║
╚═══════════════════════════════════════════════════════╝
```

**⛔ INVOKE TOOL (do not print this, CALL the tool)** (only in Standard mode):

```
AskUserQuestion(
  questions=[{
    "question": "Layer [N] complete. What next?",
    "header": "Next",
    "options": [
      {"label": "/clear + /sdd.build --resume (Recommended)", "description": "Fresh context, resume from next layer"},
      {"label": "/sdd.build", "description": "Continue in current context"},
      {"label": "/sdd.check --compact", "description": "Compact context if /clear not possible"},
      {"label": "/sdd.check --sync", "description": "Verify spec-code consistency"}
    ],
    "multiSelect": false
  }]
)
```

> **Note**: Replace `[N]` with the actual layer number in the question.

**On user selection**:

| Selection | Action |
|-----------|--------|
| /clear + /sdd.build --resume (Recommended) | Inform user to run `/clear`, then `/sdd.build --resume` |
| /sdd.build | `Skill(skill="sdd.build")` |
| /sdd.check --compact | `Skill(skill="sdd.check", args="--compact")` |
| /sdd.check --sync | `Skill(skill="sdd.check", args="--sync")` |
| Other | User types custom input |

> **MODE BEHAVIOR**: In Express mode, check context and show advisory only if > 70%, then automatically continue to next layer.
