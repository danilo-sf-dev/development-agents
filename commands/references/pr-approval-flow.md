# Reference: PR Approval Flow

**Used by**: `/sdd.pr` Step 5–6.

## Gate rules

- **Never** run `gh pr create` without explicit "Aprovar" (or Outros that clearly means proceed).
- **Always** include **Outros** — see `ask-user-question-outros.md`.
- Express mode does **not** skip this gate.

## Approve path

1. User selects "Aprovar e abrir PR"
2. → Mandatory base-branch question (Step 6 in main command)
3. → Push if needed → `gh pr create`

## Deny path

1. User selects "Negar / cancelar"
2. Keep `pr-draft.md` on disk
3. Tell user they can edit manually or re-run `/sdd.pr`
4. Do not push or create PR

## Outros — common intents

| User says | Agent action |
|-----------|--------------|
| "Muda o resumo para…" | Edit Resumo section → re-approve |
| "Remove seção Commits" | Edit draft → re-approve |
| "Título deve ser X" | Update suggested-title → re-approve |
| "Abro manual no GitHub" | STOP after saving draft; show path |
| "Só quero o markdown" | Show/copy draft; no gh |
| "Usa template do repo sem SDD" | Regenerate from `.github/` only → re-approve |

If ambiguous → one clarifying question, then re-approve loop.

## Base branch Outros

User may type: `release/2026-Q3`, `homolog`, etc.

Verify branch exists:

```bash
git fetch origin
git branch -r | findstr /i "origin/release"
# or: git ls-remote --heads origin release/2026-Q3
```

If not found → WARN + AskUserQuestion (proceed anyway | pick another | Outros).

## After successful create

Optional note in feature metadata:

```yaml
# meta.md notes (append)
pr_url: https://github.com/org/repo/pull/123
pr_base: master
pr_created_at: 2026-07-16
```

Do not rewrite entire meta.md structure — append to notes section if present.
