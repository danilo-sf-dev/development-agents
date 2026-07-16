# Reference: Start Step 0 Profile Check

**Used by**: `/sdd.start` Step 0 (see also start-user-profile.md).

### Step 0: User Profile Check (BLOCKING - NEVER SKIP)

> **⛔ This step runs BEFORE anything else. No profile = must ask.**

```bash
profile_file="$HOMEdevelopment-agents/framework/user-profile.yaml"
if [ -f "$profile_file" ]; then
    profile=$(grep "^profile:" "$profile_file" | cut -d: -f2 | tr -d ' ')
    echo "✓ Using saved profile: $profile"
else
    # ⛔ MANDATORY: Ask user for profile. Do NOT continue without it.
    # → Go to "First-time Profile Selection" in Step 5.5 below
    # → Save result to $profile_file BEFORE proceeding
fi
```

If no profile file exists, you MUST:
1. Display the profile options (Business/Product vs Technical) using AskUserQuestion
2. If Technical: ask Plan Mode preferences
3. Save `development-agents/framework/user-profile.yaml`
4. Only then continue to Step 1
