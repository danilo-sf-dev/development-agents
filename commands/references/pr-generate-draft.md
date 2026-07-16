# Reference: Generate PR Draft from SDD Artifacts

**Used by**: `/sdd.pr` Step 3–4.

## Template resolution

```
IF exists(".github/pull_request_template.md"):
  use as structural base
ELSE:
  use "development-agents/framework/templates/pull-request-template.md"
```

Always ensure these sections exist (append if missing):

- **Contexto SDD** (feature, card, branch, base placeholder)
- **Testes (tests-first)** from `4-tests/`
- **Checklist** gitignore pack (`development-agents/`, `sdd/`, etc.)

## Data sources

| Section | Source |
|---------|--------|
| Resumo | `1-functional/functional-spec.md` → outcome / user stories |
| Card / ticket | `meta.md` → `jira`, `ticket`, title, or user-provided link |
| Feature name | WIP folder name |
| Branch | `git branch --show-current` |
| O que foi alterado | `3-tasks/tasks.json` completed tasks + `git diff --stat origin/<base>...HEAD` |
| Testes | `4-tests/test-plan.md`, `tests-manifest.json` → files, AC coverage |
| Validação checkboxes | Last green validation from build/finish session; `sdd/PROJECT.md` test commands |
| Commits | `git log --oneline <base>..HEAD` |
| Observações | Open tasks, known limits from technical-spec, validator warnings |

## Output file

Path: `sdd/wip/[feature]/pr-draft.md`

Also suggest PR title (separate line at top of file or in chat):

```
<!-- suggested-title: feat(auth): adicionar validação de sessão -->
```

Title rules from `sdd/PROJECT.md` if present; else Conventional Commits in Portuguese for description.

## Quality rules

1. Replace every placeholder when data exists — no empty "TODO" if artifact has content.
2. Keep evidence section optional but mention CI link if `gh run list` available.
3. If tests gate was `skipped` (prototype) → state explicitly in Testes section.
4. Do not invent Jira keys — use `meta.md` or AskUserQuestion once if missing.

## Regeneration (after Outros)

1. Read user's free-text adjustments
2. Patch `pr-draft.md` surgically — do not wipe approved sections unless asked
3. Re-show diff summary in chat
4. Return to approval AskUserQuestion
