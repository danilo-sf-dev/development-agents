# Reference: Create PR via GitHub CLI

**Used by**: `/sdd.pr` Step 7.

## Prerequisites

- User approved draft (Step 5)
- Base branch confirmed (Step 6)
- `gh auth status` OK

## Extract title

From top of `pr-draft.md` if present:

```
<!-- suggested-title: feat(scope): descrição -->
```

Else derive from first line of Resumo or `meta.md` title (max ~72 chars).

## Push (if needed)

Ask before push unless user already said to publish:

```bash
git push -u origin HEAD
```

PowerShell and Bash use the same command.

## Create PR

**Body file** (avoid escaping issues):

```bash
gh pr create --base master --title "feat(auth): adicionar validação de sessão" --body-file "sdd/wip/20260716-user-auth/pr-draft.md"
```

**Draft PR**:

```bash
gh pr create --draft --base master --title "..." --body-file "..."
```

**With assignee / reviewer** (only if user asked via Outros):

```bash
gh pr create --base master --title "..." --body-file "..." --reviewer user1,user2
```

## PowerShell note

Use forward slashes or quoted paths for `--body-file`. If path has spaces, quote fully.

Alternative when `body-file` fails:

```powershell
$body = Get-Content -Raw -LiteralPath "sdd/wip/feature/pr-draft.md"
gh pr create --base master --title "..." --body $body
```

## Success output

Parse URL from gh output (typically prints `https://github.com/.../pull/N`).

Show:

- PR URL
- Base ← Head
- Reminder: merge is manual; CI may still run on GitHub

## Failure handling

| Error | Action |
|-------|--------|
| PR already exists for branch | `gh pr view --web` or show existing URL |
| No commits between base and head | STOP — explain |
| Base not found | Re-ask base branch |
| Auth / permission | STOP — Outros (manual UI) |

Never use `--fill` blindly — body must match approved SDD draft.
