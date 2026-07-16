# Reference: Fix Anti-Shortcut Protocol

**Used by**: `/sdd.fix` Step 3.5.

### Step 3.5: Anti-Shortcut Protocol (MANDATORY)

> **CRITICAL**: Before declaring "No Change" for ANY layer, you MUST complete this verification.

#### The "No Change" Trap

**PROBLEM OBSERVED**: Agents declare "No Change" without verifying, leading to:
- Code has features not documented in specs
- Tasks don't reflect actual work done
- Accumulated inconsistencies across multiple fixes

#### Mandatory Verification Before "No Change"

For EACH layer where you plan to declare "No Change", you MUST:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🛡️ ANTI-SHORTCUT VERIFICATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

For each "No Change" declaration, verify:

📋 FUNCTIONAL SPEC - Declaring "No Change"?
   □ I READ the relevant section of functional spec
   □ The fix does NOT add new user-facing behavior
   □ The fix does NOT change acceptance criteria
   □ Quote from spec that covers this: "[quote]"

🔧 TECHNICAL SPEC - Declaring "No Change"?
   □ I READ the relevant section of technical spec
   □ The fix does NOT change API contracts
   □ The fix does NOT add new data models
   □ The fix does NOT change external tool integration
   □ Quote from spec that covers this: "[quote]"

📝 TASKS - Declaring "No Change"?
   □ I READ the relevant tasks
   □ The fix does NOT add new acceptance criteria
   □ The task description already covers this fix
   □ Quote from task that covers this: "[quote]"
```

#### Evidence Requirement

**You MUST provide a quote** from each spec/task when declaring "No Change":

```markdown
### 📋 Functional Spec
**Status**: No Change
**Evidence**: Section "Error Handling" already states:
> "System displays user-friendly error messages for all validation failures"
This covers the email validation error we're fixing.

### 📝 Tasks
**Status**: No Change
**Evidence**: TASK-005 acceptance criteria already includes:
> "Validate all user input fields before submission"
This covers email validation.
```

#### Red Flags That Indicate Spec Update Needed

| If the fix involves... | Then you MUST update... |
|------------------------|-------------------------|
| Adding a new command/trigger | Functional Spec |
| Adding new output/display | Functional Spec |
| Changing user-visible behavior | Functional Spec |
| Adding API parameters | Technical Spec |
| Adding new models/entities | Technical Spec |
| Adding external tool calls | Technical Spec |
| Adding new acceptance criteria | Tasks |
| Changing task scope | Tasks |

---
