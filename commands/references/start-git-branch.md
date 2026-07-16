# Reference: Start Git Branch Management

**Used by**: `/sdd.start` Step 9.

### Step 9: Git Branch Management

```bash
current_branch=$(git rev-parse --abbrev-ref HEAD)

case "$current_branch" in
    main|master)
        # On main/master → Create feature branch
        git checkout -b "feature/$feature_name"
        ;;
    feature/*)
        # Already on feature branch → Ask user
        # Option 1: Switch to new branch
        # Option 2: Stay on current branch

        # ⚠️ SAFETY CHECK: Before switching branches
        if ! git diff --quiet || ! git diff --cached --quiet; then
            echo "⚠️ You have uncommitted changes."
            echo "Please commit or stash them before switching branches."
            # BLOCK - do not switch
        else
            git checkout -b "feature/$feature_name"
        fi
        ;;
    *)
        # Other branch → Ask what to do
        # Same safety check before switching
        ;;
esac
```

**Safety Rules**:
- NEVER switch branches with uncommitted changes
- Always verify clean working tree before `git checkout -b`
