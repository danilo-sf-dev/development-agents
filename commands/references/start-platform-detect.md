# Reference: Start Platform Detection

**Used by**: `/sdd.start` Step 2.

### Step 2: Platform Detection + Frontend Skills Check

> **Run these two bash commands sequentially. Check the output of each before continuing.**

**Step 2a** — detect platform:
```bash
stack_result=$(bash development-agents/framework/tools/detection/detect-stack.sh . --json 2>/dev/null)
platform=$(echo "$stack_result" | grep -o '"platform":[^,}]*' | grep -o '"[^"]*"$' | tr -d '"')
([ "$platform" = "android" ] || [ "$platform" = "ios" ]) && IS_MOBILE=true || IS_MOBILE=false
echo "platform=$platform IS_MOBILE=$IS_MOBILE"
```

**Step 2b** — validate frontend skill (run this independently):
```bash
bash development-agents/framework/tools/shared/check-frontend-skill.sh "$(pwd)" "$stack_result"
```
> If `$stack_result` is not available in this shell, run: `bash development-agents/framework/tools/shared/check-frontend-skill.sh "$(pwd)"` instead (the script will re-run detect-stack internally).

> **If Step 2b output contains `❌`, STOP. Do not proceed.**

---
