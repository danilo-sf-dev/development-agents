# Reference: Start Repository Readiness

**Used by**: `/sdd.start` Step 2.5.

### Step 2.5: Repository Readiness Check

> **Assumption**: `/sdd.start` runs *inside* an already-existing git repository — cloned, scaffolded by your org's own tooling, or freshly `git init`'d. This command never creates/registers applications in an external system; that step (if your org has one) happens **before** `/sdd.start`.

```bash
freshly_scaffolded=false
commit_count=$(git log --oneline 2>/dev/null | wc -l)
if [ "$commit_count" -le 1 ] && ! [ -d "sdd/specs" ] && ! [ -d "sdd/features" ]; then
    freshly_scaffolded=true
fi
echo "freshly_scaffolded=$freshly_scaffolded (commits=$commit_count)"
```

| Scenario | Action |
|----------|--------|
| No `.git` folder at all | Ask user (AskUserQuestion): initialize a repo here, or point to the correct existing one |
| Fresh repo (0-1 commits), no `sdd/specs`/`sdd/features` | Likely brand-new project. If your org has its own app-creation/scaffolding tool, that should already have run — see `references/new-app-scaffolding.md` for a generic checklist if you need to improvise one |
| Fresh repo but scaffold/sample files still present | Optional cleanup — Step 2.6 below |
| Repo has real history / existing code / existing SDD specs | Standard case — skip straight to Step 3 (stack detection) |
