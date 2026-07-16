# Reference: Start Validations & References

**Used by**: `/sdd.start` extended validation lists.

## Validations

Pre: valid description/flag path; no duplicate WIP name; repo ready (or user chooses init).
Post: WIP dir + meta.md exist; stack/mode recorded; branch created if required.

### Pre-execution (BLOCKING)

| Validation | Blocking | Recovery |
|------------|----------|----------|
| Not inside `development-agents/framework/` | YES | Ask user to change directory |
| Input is valid name (not prompt) | YES | Convert → suggest → confirm |
| Valid name format (kebab-case) | YES | Ask for valid name |
| Feature doesn't exist in `wip/` | YES | Ask for different name |
| Repo is git-initialized | AUTO-RETRY | Prompt to `git init` or point to correct folder |

### Post-execution

- [ ] Folder `sdd/wip/[YYYYMMDD-feature-name]/` created
- [ ] File `meta.md` exists with mode set
- [ ] Execution mode recorded

---

## References

- **Meta.md template**: `development-agents/framework/templates/meta.md`
- **Lite spec template**: `development-agents/framework/templates/lite/spec.md`
- **Gitignore templates**: `development-agents/framework/templates/gitignore/`
- **PROJECT.md wizard**: `sdd-project-wizard` subagent
- **Mandatory standards**: `standards/mandatory-standards.md`

---
