# Reference: Start Platform Detection

**Used by**: `/sdd.start` Step 2.

### Step 2: Platform Detection

> **Run this bash command:**

```bash
stack_result=$(bash development-agents/framework/tools/detection/detect-stack.sh . --json 2>/dev/null)
platform=$(echo "$stack_result" | grep -o '"platform":[^,}]*' | grep -o '"[^"]*"$' | tr -d '"')
([ "$platform" = "android" ] || [ "$platform" = "ios" ]) && IS_MOBILE=true || IS_MOBILE=false
echo "platform=$platform IS_MOBILE=$IS_MOBILE"
```

---
