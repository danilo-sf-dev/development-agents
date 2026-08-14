# Reference: `/sdd.fix --batch`

**Used by**: `/sdd.fix --batch`, or when Step -1 (Multi-Issue Detection) finds N > 1 issues.

## Flow

1. Split the input into individual issues (one per line, per `/sdd.fix` call, or per numbered list item).
2. For each issue, sequentially spawn a fresh-context dispatch — never process issues inline in this
   session. This is `DELEGATE_OFFLOAD` (context-saving delegation, no isolation requirement; see
   `framework/_shared/harness-capabilities.md` for the capability and `adapters/<harness>/README.md`
   for the concrete dispatch on the installed harness):

```
for each issue in issues (sequentially, one at a time):
  dispatch a fresh-context execution of the /sdd.fix command workflow (commands/sdd.fix.md) for
  this single issue only, with:
    - working dir: {DIR}
    - issue: {ISSUE_DESCRIPTION}
    - expected report: classification, root cause, layers, fix record path, status
  → wait for that dispatch to complete before starting the next
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
