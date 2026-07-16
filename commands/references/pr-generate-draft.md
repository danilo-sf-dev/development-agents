# Reference: Generate PR Draft from SDD Artifacts

**Used by**: `/sdd.pr` Step 3–4.

## Template resolution (project first — any platform)

> **Regra canônica:** se o **projeto alvo** já tem template de PR/MR, **use o dele**. Template do pack só quando o projeto **não** tiver nenhum.

### Discovery order (first match wins)

```
1. sdd/PROJECT.md → pr_template / merge_request_template path (if declared)
2. GitHub:
     .github/pull_request_template.md
     .github/PULL_REQUEST_TEMPLATE.md
     .github/PULL_REQUEST_TEMPLATE/*.md  → Default.md or single file; if multiple → AskUserQuestion
3. GitLab:
     .gitlab/merge_request_templates/Default.md
     .gitlab/merge_request_templates/*.md  → if multiple, prefer Default.md or ask
4. Generic (any host / Azure / Bitbucket / custom):
     pull_request_template.md
     PULL_REQUEST_TEMPLATE.md
     docs/pull_request_template.md
     .azuredevops/pull_request_template.md  (if present)
5. FALLBACK (pack only when 1–4 find nothing):
     development-agents/framework/templates/pull-request-template.md
```

Use Glob / Read to probe paths — do not assume GitHub only.

### When project template exists

- Use **its** headings, checklist, and language — fill sections from SDD artifacts where they map naturally.
- Do **not** replace with pack template structure.
- Do **not** append pack-only sections (Contexto SDD, Testes tests-first) unless user asks via **Outros** or template has no place for test/scope info and user approves an addendum.

### When pack template is used (fallback)

Ensure these sections exist (native in pack template):

- **Contexto SDD** (feature, card, branch, base)
- **Testes (tests-first)** from `4-tests/`
- **Checklist** gitignore pack (`development-agents/`, `sdd/`, etc.)

## Data sources

| Section | Source |
|---------|--------|
| Resumo / Summary | `1-functional/functional-spec.md` → outcome / user stories |
| Card / ticket | `meta.md` → `jira`, `ticket`, title, or user-provided link |
| Feature name | WIP folder name |
| Branch | `git branch --show-current` |
| O que foi alterado / Changes | `3-tasks/tasks.json` completed tasks + `git diff --stat origin/<base>...HEAD` |
| Testes | `4-tests/test-plan.md`, `tests-manifest.json` → files, AC coverage |
| Validação checkboxes | Last green validation from build/finish session; `sdd/PROJECT.md` test commands |
| Commits | `git log --oneline <base>..HEAD` |
| Observações | Open tasks, known limits from technical-spec, validator warnings |

Map SDD fields into **whatever sections the chosen template already has** (e.g. project "Validação" ← build/test evidence).

## Output file

Path: `sdd/wip/[feature]/pr-draft.md`

Also suggest PR title (separate line at top of file or in chat):

```
<!-- suggested-title: feat(auth): adicionar validação de sessão -->
<!-- template-source: project:.github/pull_request_template.md | pack:fallback -->
```

Title rules from `sdd/PROJECT.md` if present; else Conventional Commits in Portuguese for description.

## Quality rules

1. Replace every placeholder when data exists — no empty "TODO" if artifact has content.
2. Keep evidence section optional but mention CI link if `gh run list` available.
3. If tests gate was `skipped` (prototype) → state explicitly in Testes section (or equivalent project section).
4. Do not invent Jira keys — use `meta.md` or AskUserQuestion once if missing.
5. Log which template was chosen (`template-source` comment) so user can verify project vs pack.

## Regeneration (after Outros)

1. Read user's free-text adjustments
2. Patch `pr-draft.md` surgically — do not wipe approved sections unless asked
3. If user says "use só template do repo" → re-resolve project template, no pack sections
4. Re-show diff summary in chat
5. Return to approval AskUserQuestion
