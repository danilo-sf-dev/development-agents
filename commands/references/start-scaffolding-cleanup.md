# Reference: Scaffolding Cleanup

**Used by**: `/sdd.start` Step 2.6 when freshly scaffolded.

### Step 2.6: Cleanup Scaffolding Samples (CONDITIONAL)

> **WHEN TO RUN**: Only if `freshly_scaffolded=true`. Adjust the globs below to match your own template/starter conventions — these are just common examples.

```bash
if [ "$freshly_scaffolded" = true ]; then
    echo "🧹 Running scaffolding cleanup..."
    case "$technology" in
        java*)   rm -rf src/main/java/com/example/*/beans/ src/main/java/com/example/*/dtos/ src/test/java/com/example/*/unit/beans/ 2>/dev/null ;;
        kotlin*) rm -rf src/main/kotlin/com/example/*/beans/ src/main/kotlin/com/example/*/dtos/ src/test/kotlin/com/example/*/unit/beans/ 2>/dev/null ;;
        go*)     rm -f telemetry/example_test.go 2>/dev/null ;;
        python*) rm -rf app/dummy/ 2>/dev/null ;;
        node*|typescript*) rm -rf src/routes/example*.ts src/controllers/example*.ts 2>/dev/null ;;
    esac
    git add -A && git commit -m "chore: cleanup scaffolding samples" 2>/dev/null
    echo "✅ Cleanup complete (sample/example files removed if present)"
else
    echo "ℹ️  Skipping cleanup (existing app with code)"
fi
```

#### 2.6.1 Verify Essential Files (best-effort, adjust per stack)

```bash
if [ "$IS_MOBILE" = true ]; then
    case "$platform" in
        android) required_files=("app/src/main/AndroidManifest.xml" "build.gradle.kts") ;;
        ios)     ls -d *.xcodeproj *.xcworkspace 2>/dev/null | head -1 | grep -q . || echo "⚠️ Missing Xcode project/workspace" ;;
    esac
else
    case "$technology" in
        java*)   required_files=("pom.xml" "Dockerfile") ;;
        go*)     required_files=("go.mod" "Dockerfile") ;;
        python*) required_files=("pyproject.toml" "Dockerfile") ;;
        node*)   required_files=("package.json" "Dockerfile") ;;
    esac
fi
for file in "${required_files[@]}"; do
    [ ! -e "$file" ] && echo "⚠️ Missing: $file"
done
```
