# Reference: PR Pre-checks

**Used by**: `/sdd.pr` Step 2.

## Branch

```bash
git branch --show-current
git status --short
```

- Head must be a **feature branch**, not `main`/`master`/`develop` unless user explicitly chose that via Outros.
- If dirty working tree with non-gitignored changes → list files; AskUserQuestion (commit first | stash | Outros).

## Commits vs base

```bash
git log --oneline origin/master..HEAD 2>/dev/null || git log --oneline master..HEAD
```

If no commits → STOP: nothing to PR.

## Remote / push

```bash
git rev-parse --abbrev-ref @{upstream} 2>/dev/null
```

If no upstream → before `gh pr create`, run `git push -u origin HEAD` **after user confirms** (push is sensitive).

## GitHub CLI

```bash
gh auth status
gh repo view --json nameWithOwner -q .nameWithOwner
```

| Result | Action |
|--------|--------|
| `gh` not found | STOP — suggest install or Outros (copy draft to GitHub UI) |
| Not logged in | STOP — `gh auth login`; do not open PR |
| OK | Continue |

## Feature path

Resolve WIP folder:

- `sdd/wip/[feature]/meta.md` preferred
- If archived only: `sdd/features/[feature]/` — draft still written there or copy to wip notes

## Secrets scan (light)

Quick scan staged diff for `.env`, `credentials`, `token=` patterns — WARN before PR.
