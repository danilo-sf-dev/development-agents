# Reference: `/sdd.fix --batch`

**Used by**: `/sdd.fix --batch`, or when Step -1 (Multi-Issue Detection) finds N > 1 issues.

## Flow

1. Split the input into individual issues (one per line, per `/sdd.fix` call, or per numbered list item).
2. For each issue, sequentially spawn a subagent — never process issues inline in this session.
   This is `DELEGATE_OFFLOAD` (context-saving delegation, no isolation requirement; see
   `framework/_shared/harness-capabilities.md`):

```
for each issue in issues (sequentially, one at a time):
  Task(
    subagent_type="general-purpose",
    description="Fix: [short name]",
    prompt="Working dir: {DIR}\nFollow the /sdd.fix command workflow (commands/sdd.fix.md) for this single issue — this is a command, not a skill:\n{ISSUE_DESCRIPTION}\nReport: classification, root cause, layers, fix record path, status."
  )
  → wait for Task result before spawning next
```

3. After all Tasks complete, show a consolidated batch summary:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🛠️ BATCH FIX SUMMARY — N issues
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Fixed: [issue] → [fix record path]
✅ Fixed: [issue] → [fix record path]
⚠️ Escalated: [issue] → [reason]
```

**Never**: use `TodoWrite` to list issues and process them one-by-one inline — this is the exact anti-pattern `--batch` exists to prevent (see Step -1 in the main command).
