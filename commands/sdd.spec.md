---
name: sdd.spec
description: Create and approve functional and technical specifications. Use when user needs to define requirements (functional) or design architecture (technical). Supports --approve, --iterate, --summary, and --audio flags.
model: opus
argument-hint: "[functional|technical] [--approve]"
---

> **Shared agent instructions**: Read `development-agents/framework/_shared/agent-instructions.md` before executing this command.

# Command: /sdd.spec

**Description**: Create and manage functional and technical specifications

**Usage**:
- `/sdd.spec` → Auto-detects phase, behavior based on mode
- `/sdd.spec "description"` → Start with initial context (seeds interview)
- `/sdd.spec --audio` → Record voice description via microphone
- `/sdd.spec functional` → Functional spec only
- `/sdd.spec functional "description"` → Functional with initial context
- `/sdd.spec technical` → Technical spec only
- `/sdd.spec functional --include <context>` → Include external context
- `/sdd.spec functional --approve` → Approve functional
- `/sdd.spec technical --approve` → Approve technical
- `/sdd.spec --resume` → Resume interrupted spec session
- `/sdd.spec --iterate "change"` → Refine spec (shows preview, asks confirmation)

---

## Quick Help

> `/sdd.spec help` → Shows this summary

**Syntax**: `/sdd.spec [phase] [flags]`

| Flag | Description |
|------|-------------|
| (none) | Auto-detect phase, behavior based on mode |
| `"description"` | Initial context for the spec (seeds interview) |
| `--audio` | Record voice description via microphone |
| `functional` | Create functional spec only |
| `technical` | Create technical spec only |
| `--include <ctx>` | Include external context in spec |
| `--approve` | Approve current spec |
| `--resume` | Resume interrupted session |
| `--iterate "desc"` | Refine spec (shows preview, asks confirmation) |
| `--summary` | Quick overview without loading full spec |

**Examples**:
```bash
/sdd.spec                              # Auto-detect and continue
/sdd.spec "payment with refunds"       # Start with initial context
/sdd.spec functional                   # Start functional spec
/sdd.spec functional "user auth"       # Functional with context
/sdd.spec technical --approve          # Approve technical spec
/sdd.spec --summary                    # Quick spec overview
```

**See also**: `/sdd.help spec` for detailed documentation

---


## Subagent Delegation

> **MANDATORY**: Use specialized subagents during spec creation (Backend Projects only).

| Decision Type | Subagent | Use For |
|---------------|----------|---------|
| Gap detection | `genai-detect-gaps.sh` → inline fallback | Identify missing info by feature type (see below) |
| Backend system architecture | `sdd-system-designer` | Architecture decisions, technology selection (only when `platform.type: backend` or no `platform.type`) |
| Frontend web architecture | `sdd-system-designer` | frontend web architecture, rendering strategy, component hierarchy (only when `platform.type: frontend-web`) |
| project services | `sdd-explorer` | KeyValueStore config, MessageQueue topics, service discovery |
| Service architecture | `sdd-system-designer` (platform-service plugin skill) | Service selection, segmentation strategy, trade-off analysis |
| Code snippets | `sdd-implementer` (platform-service plugin skill) | Live toolkit docs and code snippets per service + language |
| API design patterns | `sdd-system-designer` | REST vs GraphQL, pagination strategy |
| Conflict detection | `genai-resolve-conflicts.sh` → fallback `validate-spec-conflicts.sh` | Spec conflict scanning and resolution |

### Gap Detection (GenAI Offloaded)

> **MANDATORY**: Run gap detection AFTER receiving user's initial description.

**Workflow**:
```bash
# Try GenAI-powered gap detection first
gap_result=$(bash development-agents/framework/tools/genai/genai-detect-gaps.sh "$description" --answers "$previous_answers")
genai_exit=$?

if [ "$genai_exit" -eq 0 ]; then
    # Use pre-classified gaps: detected_needs, gap_questions, already_addressed
    # Ask ONLY the gap_questions returned (max 3-5, already prioritized)
    # Delegate technology decisions to experts listed in detected_needs[].delegate_to
else
    # Fallback: Agent manually identifies gaps using inline rules:
    # - "topic/queue/event" → ask idempotency, schema
    # - "save/store/persist" → ask TTL, access pattern
    # - "calculate/process" → ask concrete example
    # - "external API/integrate" → ask error handling, retry
    # - "concurrent/simultaneous" → ask conflict resolution
fi
```

**Example**:
```
User: "I need to process payments arriving from a topic and store them"
       ↓
genai-detect-gaps.sh returns:
  detected_needs: [FG-1 Async, FG-2 Storage]
  gap_questions:
    - "What happens if the same payment arrives twice?" (idempotency, high)
    - "Do you have an example of the message?" (schema, high)
    - "Is there pre-existing data to migrate?" (existing data, medium)
  delegate_to: sdd-system-designer
```

**Context Advisory**: Check context before starting technical phase.
- If >40%: Use `` for ALL  queries
- If >50%: Recommend `/clear` — functional spec is saved, fresh context produces better technical spec
- If >60%: Strongly recommend `/clear` or compacting context first
- If >80%: Invoke `context-guardian` skill

---

## 👤 Profile-Aware Spec Creation

> **RULE**: Adapt interview questions and output based on user profile.

### Check Profile First

```bash
# Read from meta.md or global config
profile=$(grep "type:" sdd/wip/*/meta.md | grep -o 'technical\|non-technical')
[ -z "$profile" ] && profile=$(cat development-agents/framework/user-profile.yaml | grep "^profile:" | cut -d: -f2 | tr -d ' ')
[ -z "$profile" ] && profile="non-technical"  # Default
```

### Functional Spec: Profile Differences

| Aspect | Technical | Non-Technical |
|--------|-----------|---------------|
| **Data source questions** | Ask about MessageQueue, Streams, scheduled jobs | Ask "Where does this data come from? (user input, other system, automatic)" |
| **Integration details** | Ask specific service names, API contracts | Ask "Does this need data from other systems?" |
| **Technical constraints** | Ask about performance, SLAs | Skip (agent infers from project type) |

### Technical Spec: Profile Differences

| Aspect | Technical | Non-Technical |
|--------|-----------|---------------|
| **Code snippets** | Show full implementation examples via `sdd-implementer` (platform-services plugin skill) | Hide code, show "Configuration ready ✓" |
| ** services** | Show service names, containers, TTLs | Show "Data storage configured" |
| **Architecture diagrams** | Show full Mermaid diagrams | Show simplified flow: "Input → Processing → Output" |
| **API contracts** | Show full REST contracts with schemas | Show "API structure: N endpoints" |

### Simplified Questions (Non-Technical)

**Instead of**:
```
Q: "Where does the data originate? (MessageQueue event, Streams CDC, REST API, scheduled job, user input)"
```

**Ask**:
```
Q: "Where does [X] come from?"
   1. User enters it (form, upload)
   2. Another system sends it
   3. It's calculated/generated automatically
```

### Frontend Web Skills (Frontend framework/design system Projects) ⭐ v1.2.0

> **CONDITIONAL**: Only invoke when project has Frontend framework/design system Web stack.
> **Detection**: Check `package.json` for `"frontend-framework"` or `"@design-system/*"` dependencies.

```
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃  🎨 AGENT FOR /sdd.spec technical (Frontend Web)                        ┃
┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┫
┃                                                                          ┃
┃  sdd-system-designer → All frontend architecture decisions       ┃
┃                                Uses Skill(frontend-web-expert) internally┃
┃                                                                          ┃
┃  WORKFLOW:                                                               ┃
┃     Agent("sdd-system-designer", ...)                            ┃
┃                                                                          ┃
┃  WHY: Single agent delegates to frontend-web-expert skill as source      ┃
┃       of truth for Frontend framework/design system patterns, rendering strategy, and        ┃
┃       component decisions. Replaces direct skill calls.                  ┃
┃                                                                          ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
```

**When to Use (Frontend Web Projects)**:
| Decision Type | Agent | Example |
|---------------|-------|---------|
| Architecture + rendering strategy | `sdd-system-designer` | "SSR vs Islands, page hierarchy" |
| Component selection + Frontend framework patterns | `sdd-system-designer` | "Which design system components? How to structure pages?" |

**Stack Detection Rules**:
- **Backend only** (`pom.xml`, `go.mod`, `requirements.txt`): Use backend subagents only
- **Frontend only** (`package.json` with `frontend-framework`/`@design-system/*`): Use frontend skills only
- **Fullstack**: Use both as appropriate

---

## Stack from target project (CRITICAL)

> Resolve language, frameworks, and infra from **detect-language.sh / detect-stack.sh**, **sdd/PROJECT.md**, and the existing codebase.
> Do **not** force a corporate service catalog. Prefer technologies already used in the repo and declared in PROJECT.md / technical spec.

**Mobile** (`platform.type` = android | ios): follow mobile constraints in PROJECT.md if present; otherwise use standard Android/iOS libraries already in the repo.

When the user mentions a technology unfamiliar to the repo, ask which option fits PROJECT.md — do not silently rewrite to a vendor platform.
---

## Behavior by Mode

| Mode | Behavior |
|------|----------|
| **Express** | 3-5 critical questions, auto-generates both specs, auto-approves |
| **Standard** | Interactive interview, section review, confirmation before approval |

---

## Skill Hooks (Extension Points)

This skill supports external skill hooks at 3 trigger points per sub-phase. Hooks can target `spec-functional` and/or `spec-technical` phases independently.

**Resolution steps** (at each extension point):
1. Read `.claude/skill-hooks.json` and `development-agents/framework/skill-hooks.json`
2. Scan installed skills in `~/.claude/skills/*/SKILL.md` for `metadata` with `sdd-kit-*` keys
3. Merge with precedence: user override > repo config > auto-declaration
4. For each enabled hook matching the current phase and trigger, ordered by priority:
   - If `hook.mode == "required"`: invoke `Skill("<hook.skill>")` with current feature context
   - If `hook.mode == "available"` (default): evaluate if the hook is relevant to the current feature. Only invoke if the feature context suggests it adds value. Skip silently if irrelevant.

| Trigger | When (functional) | When (technical) |
|---------|-------------------|-----------------|
| `before-start` | Before Step 2 (interview) | Before Step 5 (technical spec) |
| `after-implementation` | After spec draft generated | After technical spec generated |
| `before-approval` | Before Step 3 (approval) | Before Step 6 (approval) |

---

## Workflow (Steps in Order)

### Step 1: Detect Phase (Deterministic)

> **Use script for deterministic phase detection** - Saves ~500-1000 tokens vs manual parsing.

```bash
# Deterministic phase detection
phase_result=$(bash development-agents/framework/tools/detection/detect-phase.sh sdd/wip/[feature] --json)
# Returns: {"phase":N,"stage":"functional|technical|tasks|implementation","layers":"..."}

# Extract values
current_phase=$(echo "$phase_result" | grep -o '"phase":[0-9]*' | cut -d: -f2)
current_stage=$(echo "$phase_result" | grep -o '"stage":"[^"]*"' | cut -d'"' -f4)
```

**Phase mapping:**
- Phase 1 (`functional`) → Start/continue functional spec
- Phase 2 (`technical`) → Start/continue technical spec
- Phase 3+ → Specs already approved, redirect to `/sdd.plan` or `/sdd.build`

**Template mode** (read separately from meta.md):
- `template_mode: lite` → Single combined spec (~80 lines)
- `template_mode: full` → Separate specs (default)

### Step 1.1: Spec Language Resolution

> **MANDATORY**: Resolve spec language BEFORE writing any spec content.

**Resolution order** (highest to lowest priority):
1. `meta.md` → `spec_language` field (feature-level override)
2. `PROJECT.md` → `language.specs` field (project-level setting)
3. Fallback → `en` (English)

```bash
# 1. Try meta.md first (feature-level)
spec_lang=$(grep "^spec_language:" sdd/wip/*/meta.md 2>/dev/null | head -1 | awk '{print $2}')

# 2. Try PROJECT.md (project-level)
if [ -z "$spec_lang" ]; then spec_lang=$(grep "specs:" sdd/PROJECT.md 2>/dev/null | head -1 | awk '{print $2}'); fi

# 3. Fallback to English
if [ -z "$spec_lang" ]; then spec_lang="en"; fi
```

**Language name mapping**:

| Code | Language Name |
|------|--------------|
| `en` | English |
| `es` | Spanish (Español) |
| `pt` | Portuguese (Português) |

**Enforcement rule**:

```
┌─────────────────────────────────────────────────────────────────────┐
│  SPEC LANGUAGE ENFORCEMENT                                          │
│                                                                     │
│  • Write the ENTIRE spec in the resolved language ($spec_lang)      │
│  • NEVER mix languages within a spec document                       │
│  • Technical terms stay in English: API, REST, CRUD, endpoint,      │
│    MessageQueue, KeyValueStore, OAuth, JWT, UUID, SDK, MCP, etc.                  │
│  • Section headers follow spec template (always English)            │
│  • User stories, descriptions, acceptance criteria → resolved lang  │
│  • Code identifiers (function names, variables) → always English    │
│                                                                     │
│  This is INDEPENDENT of the agent's response language.              │
│  A user chatting in Spanish can have specs written in English.      │
└─────────────────────────────────────────────────────────────────────┘
```

### Step 1.5: Read Project Vision

> **MANDATORY**: Before starting functional spec, check for project vision.

```bash
# Check if PROJECT.md has a vision defined
vision=$(grep -A 50 "^vision:" sdd/PROJECT.md 2>/dev/null | head -50)
# Check if vision prompt was already shown
vision_prompted=$(grep "vision_prompt_shown: true" sdd/wip/*/meta.md 2>/dev/null)
```

**If vision is defined**:
- Extract: `summary`, `target_users`, `value_proposition`, `principles`, `anti_goals`
- Use to **guide** interview questions and spec content
- Validate that objectives align with value proposition
- Use `anti_goals` to inform Out of Scope decisions
- Use `principles` to guide acceptance criteria

**If vision is NOT defined AND NOT previously prompted**:

> First time only: Suggest defining vision before starting spec.

Use AskUserQuestion:
- Question: "PROJECT.md doesn't have a product vision defined. Vision helps ensure features align with your product goals. Would you like to define it now?"
- Header: "Vision"
- Options:
  1. "Define now" - Description: "Quick 3-question wizard"
  2. "Later (/sdd.project vision)" - Description: "Continue without, remind me later"
  3. "Don't need vision" - Description: "Skip permanently for this project"

**On user selection**:

| Selection | Action |
|-----------|--------|
| "Define now" | Execute inline vision mini-wizard (see below) |
| "Later" | Continue with spec, do NOT ask again for this feature |
| "Don't need vision" | Set `vision_prompt_shown: true` in meta.md, never ask again |

**Inline Vision Mini-Wizard** (if user selects "Define now"):

1. Ask: "What does your product do in one sentence?"
2. Ask: "What problem does it solve and why should users care?"
3. Ask: "Any guiding principles? (optional, can skip)"
4. Write vision to PROJECT.md
5. Continue with Step 2

**Vision Alignment Check** (during spec review):
- Before approval, verify spec aligns with vision
- If conflict detected, flag it: "This objective may conflict with project principle: [principle]"

### Extension point: before-start (spec-functional)

> Resolve and invoke hooks for phase=`spec-functional`, trigger=`before-start`.

### Step 2: Functional Spec (WHAT to build)

<!-- PROFILE: TECHNICAL_ONLY -->
**Consolidated Interview (4-6 questions max)**:

| Question | Fills Sections | Condition |
|----------|----------------|-----------|
| Q1: Problem + expected outcome + business value | Problem Statement, Objectives, Success Metrics | Always |
| Q2: Explicit exclusions? | Scope (Out of Scope) | Skip if "nothing special" |
| Q3: Main user actions + outcomes | User Stories, User Experience, Acceptance Criteria | Always |
| Q3b: Data input example? | Data Model, Business Rules, Validations | **IF data processing detected** |
| Q4: External dependencies/risks + edge cases | Dependencies, Risks, Edge Cases | Skip if internal feature |
| Q4b: Business rules example? | Business Rules, Acceptance Criteria | **IF calculations detected** |
| Q5: E2E E2E? | E2E Scenarios | Auto-skip for prototype/mvp |

**Gap-Driven Questions** (from `genai-detect-gaps.sh` or inline fallback):

> **MANDATORY — Architect-First Protocol (no skipping)**:
>
> If `genai-detect-gaps.sh` returns any `detected_need` with `delegate_to: project-services-architect`,
> **OR** the inline fallback matches `topic/queue/event`, `save/store/persist`, or `concurrent/simultaneous`,
> you **MUST** invoke `Skill("project-services-architect")` BEFORE asking the user any gap question on
> that need. The plugin is the only authority on project service candidates and trade-offs.
>
> ```
> Skill("project-services-architect")  # redirects to sdd-system-designer plugin skill
> # context: pass the feature description and the detected_need(s), e.g.:
> #   "User needs async/event processing AND key-value storage. Classify project services and
> #    return candidates with trade-offs."
> ```
>
> Use the plugin response to:
> 1. Identify candidate services (do NOT lock in a single service yet — these are tentative)
> 2. Formulate gap_questions in **product terms** (NEVER leak service names like
>    "MessageQueue at-least-once" or "TTL" into the user-facing question)
> 3. Reflect candidates in the functional spec output as "tentative — to be confirmed in
>    technical spec" rather than as fixed dependencies
>
> ❌ ANTI-PATTERN: asking "MessageQueue is at-least-once. What if the same event arrives twice?"
>    — this leaks the architectural decision into the functional phase before the user
>    confirmed MessageQueue, and bypasses the plugin.
> ✅ CORRECT: ask "If the same task creation request arrives twice, should the system
>    deduplicate, reject, or allow both?" — pure product semantics, no service name.

| Feature Type Detected | Architect-First Question (product terms) |
|----------------------|------------------------------------------|
| Async/Event processing | "If the same triggering event happens twice, should the action repeat or be deduplicated?" + "Do you have a payload example?" |
| Data storage | "Is there pre-existing data to migrate?" + "How long should the data be retained from the user's perspective?" |
| Calculations | "Can you give me an example with real numbers? If X=100, what result?" |
| External integration | "What do we do if the external API fails?" + "Should we retry?" |
| Concurrent access | "What happens if two users modify at the same time?" |

> **Key**: Questions marked 3b and 4b are CONDITIONAL - only asked when relevant to the feature type.
<!-- END PROFILE -->

<!-- PROFILE: NON_TECHNICAL_ONLY -->
**Simplified Interview (3-5 questions)**:

| Question | Purpose |
|----------|---------|
| Q1: What problem does this solve and what outcome do you expect? | Defines the objective |
| Q2: Is there anything that should NOT be included? | Limits scope |
| Q3: What does the user do and what do they get? | Defines actions |
| Q4: Does it need data from other systems? | Identifies dependencies |

> The agent asks questions in simple language and internally translates to technical requirements.
<!-- END PROFILE -->

**Anti-Redundancy**: NEVER ask the same thing twice. Derive from answers.

#### E2E E2E Decision Logic (Q5)

```
┌─────────────────────────────────────────────────────────────────────┐
│  FIRST: Check meta.md → project_type.type                           │
│                                                                     │
│  IF prototype OR mvp:                                               │
│    → AUTO-SKIP E2E (no question asked)                              │
│    → Set e2e_enabled: false in meta.md                              │
│    → Log: "⏭️ E2E skipped (prototype/mvp mode)"                      │
│                                                                     │
│  IF production:                                                     │
│    → ASK: "Do you want E2E to generate E2E tests? [Y/N]"            │
│    → If Y: e2e_enabled: true, ask for E2E scenarios                 │
│    → If N: e2e_enabled: false, continue                             │
└─────────────────────────────────────────────────────────────────────┘
```

| Project Type | E2E Question? | Default |
|--------------|---------------|---------|
| prototype | ❌ Auto-skip | false |
| mvp | ❌ Auto-skip | false |
| production | ✅ Ask user | user choice |

### Step 2.5: Completeness Check (Keep Asking)

> **AFTER answering all questions, BEFORE generating spec**
> **ENHANCED**: Now includes gap detection by feature type.

**Philosophy:**
- ✅ **ASSUME** what's safe to assume (standard patterns, obvious defaults)
- ❌ **NEVER** leave uncertainty about **DATA ORIGINS** (especially external systems)
- ❌ **NEVER** assume **BUSINESS LOGIC** without concrete examples
- 🎯 **PROACTIVELY** try to define the product as completely as possible

<!-- PROFILE: TECHNICAL_ONLY -->
**Critical to clarify - Data Sources:**

Data can come from many places - this MUST be explicit:
- User input (form, API request)
- External project service (which one?)
- External non- API (URL? contract?)
- Database (but WHO populates it initially?)
- MessageQueue message (from which producer?)
- Scheduled job (what triggers it?)
<!-- END PROFILE -->

<!-- PROFILE: NON_TECHNICAL_ONLY -->
**Data Origin - Clarify:**

Where does the data come from?
- From the user (form, manual action)
- From another system (automatic, receives data)
- Scheduled process (every X time)

> The agent asks in simple language: "Where does [X] come from?" and translates the response to the corresponding technical service.
<!-- END PROFILE -->

**Scan answers for gaps:**
- Missing data origins: "stored in DB" but WHERE does it come from originally?
- Unclear external systems: "calls an API" but WHICH one? What's the contract?
- Vague sources: "from the system", "it gets data" → need specifics

### Enhanced Completeness Checklist

> Validate based on feature type detected (from `genai-detect-gaps.sh` or inline fallback)

**1. Data Origin Clarity** (always required):
- ✓ Source identified (MessageQueue/API/User/Scheduled)
- ✓ Specific service/topic/endpoint named

**2. Data Structure** (if data processing detected):
- ✓ Example payload provided (JSON/XML)
- ⚠️ No example: Ask "Do you have an example of the input data?"

**3. Business Logic** (if calculations detected):
- ✓ Concrete example with numbers provided
- ⚠️ No example: Ask "If input=X, what output do we expect? Give me an example with numbers."

**4. Edge Cases** (if async/event processing detected):
- ✓ Duplicate handling specified
- ✓ Out-of-order handling specified (if relevant)
- ⚠️ Not specified: Ask "What should happen if the same event arrives twice?"

**5. Error Handling** (if external integration detected):
- ✓ Retry/fallback policy specified
- ⚠️ Not specified: Ask "What do we do if the external API fails? Should we retry?"

**6. Existing Data** (if storage detected):
- ✓ Pre-existing data addressed
- ⚠️ Not mentioned: Ask "Is there pre-existing data we should consider or migrate?"

**IF gaps detected:**

```
📋 I need a bit more detail to complete your spec.

**What I understood:**
[Brief summary of what's clear]

**What I need to clarify:**
1. You mentioned "[data X]" - where does this data originally come from?
2. You mentioned "[calculation Y]" - can you give me an example with real numbers?
3. You mentioned "[event processing]" - what happens if the same event arrives twice?

**How would you like to provide this info?**
```

Use AskUserQuestion with options:
1. "Type it here" (description: "I'll describe it in text")
2. "Record audio" (description: "Open mic - I'll explain verbally")
3. "Share a file" (description: "I have a doc, PPT, or image to share")
4. "Skip for now" (description: "I'll clarify later, continue with assumptions")

**If user chooses "Record audio":**
→ Trigger the `--audio` flow: `python3 development-agents/framework/tools/audio-capture/server.py`
→ Transcribe and incorporate into spec context

**If user chooses "Share a file":**
→ Ask: "Paste the file path or drag it here:"
→ Read and extract relevant info

**Safe assumptions (don't need to ask):**
- Standard REST patterns (JSON, HTTP methods)
- Standard containerization/health-check conventions (Dockerfile, `/ping` or `/health` endpoint) if this is a network service
- Standard auth patterns already established in the project (reuse the existing token/scope scheme rather than inventing a new one)
- Standard retry with exponential backoff for 5xx errors

**NEVER ask about these - they are industry standards:**
- ❌ "What to return for invalid parameters?" → Always 400 Bad Request
- ❌ "What to return if resource not found?" → Always 404 Not Found
- ❌ "What to return for internal errors?" → Always 500 Internal Server Error
- ❌ "Should we validate input types?" → Always yes
- ❌ "Should we log errors?" → Always yes
- ❌ "Should we return error messages?" → Always yes (with appropriate detail)
- ❌ "Should we handle null/empty values?" → Always yes
- ❌ "What HTTP method for create/read/update/delete?" → POST/GET/PUT|PATCH/DELETE

> **RULE**: If the answer can be derived from REST/HTTP standards,  conventions, or common sense - DO NOT ASK. Just apply the standard.

**MUST clarify before proceeding:**
- [ ] Origin of every data element (especially from external systems)
- [ ] Specific names of all integrations (apps, external APIs)
- [ ] Who/what triggers the feature initially
- [ ] At least one concrete example for calculations/transformations
- [ ] Duplicate/idempotency handling for event-driven features
- [ ] Error handling strategy for external dependencies

**Follow-up Question Examples by Gap Type:**

| Gap Type | Example Question |
|----------|------------------|
| Data source | "Where does [X] come from? User, external API, scheduled process?" |
| Integration | "Which app or external API provides [X]? I need the name." |
| Business logic | "Can you give me an example with numbers? If X=100, what result do we expect?" |
| Edge cases | "What happens if the same [event/request] arrives twice?" |
| Error handling | "If [external service] fails, what do we do? Retry? Fallback?" |
| Existing data | "Is there pre-existing data in [storage]? Do we need to migrate?" |

**Exit condition**: All critical gaps addressed → Continue to extension point, then Step 3

### Extension point: after-implementation (spec-functional)

> Resolve and invoke hooks for phase=`spec-functional`, trigger=`after-implementation`.

### Extension point: before-approval (spec-functional)

> Resolve and invoke hooks for phase=`spec-functional`, trigger=`before-approval`.

### Step 3: Show Summary + Approve (with Validation)

> **MANDATORY**: Run deterministic validation before approval - Saves ~3,000-5,000 tokens.

**Step 3a.0: No-Architecture-Leak Self-Check (BLOCKING)**

> **STOP before generating the summary**: Confirm the functional spec is free of premature
> architecture decisions.
>
> Verify in your own working memory:
>
> ```
> [ ] The Dependencies section does NOT name concrete project services
>     (no "MessageQueue", "KeyValueStore", "Audits", "Streams", etc.). It lists CAPABILITIES instead
>     (e.g. "async event processing", "key-value storage", "immutable audit trail").
> [ ] No gap question exposed implementation jargon to the user
>     (no "MessageQueue at-least-once", "TTL", "consumer", "producer", "topic", "container").
> [ ] If any architectural classification was needed (async vs sync, storage type, etc.),
>     I invoked Skill("project-services-architect") to inform candidate selection — and
>     surfaced the candidates as "tentative — to be confirmed in technical spec",
>     NOT as final dependencies.
> ```
>
> If ANY checkbox is unchecked: STOP. Reword the offending sections in product terms
> (or invoke the missing skill) before proceeding to Step 3a.
>
> ❌ ANTI-PATTERN: outputting "Dependencies:  MessageQueue · KeyValueStore · Audits" in the
>    functional summary. Service selection belongs to the technical spec.
> ✅ CORRECT: "Dependencies (capabilities): async event processing, key-value storage,
>    immutable audit trail. Concrete services to be selected in technical spec."

**Step 3a: Validate functional spec**

```bash
# Run deterministic validation BEFORE asking for approval
bash development-agents/framework/tools/validation/validate-functional.sh sdd/wip/[feature]

# If exit code != 0: Show errors, DO NOT proceed to approval
# If exit code == 0: Continue to summary
```

**Step 3b: Show concise summary** (if validation passed):
```markdown
## Functional Specification Summary
### Problem: [2-3 lines]
### User Stories (N): [list titles]
### Scope: In/Out
### Dependencies (capabilities): [list of capabilities, NOT project service names]
  e.g. "async event processing, key-value storage, immutable audit trail"
  Concrete services chosen in technical spec via project-services-architect plugin.
```

**Step 3c: Context Check Before Approval**

Before presenting the approval question, estimate context usage. If > 50%, prepend a context advisory:

```
╔═══════════════════════════════════════════════════════╗
║  CONTEXT ADVISORY                                     ║
╠═══════════════════════════════════════════════════════╣
║                                                       ║
║  Context usage: ~[XX]%                                ║
║                                                       ║
║  Tip: After approving, consider /clear before         ║
║  running /sdd.spec technical. Your spec is saved —   ║
║  a fresh context will give higher quality output.      ║
║                                                       ║
╚═══════════════════════════════════════════════════════╝
```

**Step 3d: Approve** (only if validation passed)

**⛔ INVOKE TOOL (do not print this, CALL the tool)**:

```
AskUserQuestion(
  questions=[{
    "question": "The functional spec is ready. What would you like to do?",
    "header": "Approval",
    "options": [
      {"label": "Approve", "description": "Approve and continue to technical spec"},
      {"label": "View full spec", "description": "Display the complete functional spec"},
      {"label": "Request changes", "description": "Iterate on the spec with /sdd.spec --iterate"}
    ],
    "multiSelect": false
  }]
)
```

**If user selects "View full spec"**:
- Read and display the entire file: `sdd/wip/[feature]/1-functional/spec.md`
- After displaying, loop back to the approval question (ask again)

**If user selects "Request changes"**:
- Ask what changes they want to make
- Apply changes using `--iterate` flow

**On approval - Update meta.md:**
```bash
# Get user identity and timestamp (single line to avoid multi-line permission prompts)
approver=$(git config user.name || echo "Unknown"); timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ"); echo "Approver: $approver | Timestamp: $timestamp"
```

Update `meta.md` stages.functional:
- `status: approved`
- `approved_by: <user from git config>` ← NEVER "AI Agent"
- `approved_at: <ISO-8601 timestamp>`

> **CRITICAL**: The `approved_by` field MUST be the human user who approved, obtained via `git config user.name`. The Platform AI docs agent facilitates the process but does NOT approve specs.

#### After Functional Spec Approval - Interactive Next Steps

> **MANDATORY**: Always offer interactive selection after approval.

**⛔ INVOKE TOOL (do not print this, CALL the tool)**:

```
AskUserQuestion(
  questions=[{
    "question": "Functional spec approved. What's next?",
    "header": "Next",
    "options": [
      {"label": "/sdd.spec technical (Recommended)", "description": "Create technical specification"},
      {"label": "/sdd.spec --iterate", "description": "Refine functional spec first"},
      {"label": "/sdd.check", "description": "View current status"}
    ],
    "multiSelect": false
  }]
)
```

**On user selection**:

| Selection | Action |
|-----------|--------|
| /sdd.spec technical (Recommended) | `Skill(skill="sdd.spec", args="technical")` |
| /sdd.spec --iterate | `Skill(skill="sdd.spec", args="--iterate")` |
| /sdd.check | `Skill(skill="sdd.check")` |
| Other | User types custom input |

### Step 4: External API Auto-Discovery

After functional approval, before technical:
1. Scan functional spec for integration phrases
2. Query `` for each detected API
3. Display findings with status (Found/Partial/Not Found)
4. Ask: "Include discovered APIs in Dependencies?"

> **Deep Analysis Fallback**: If platform docs are insufficient for external API
> integration, Ask To Repo can query the actual source code. This is slow (30s-5min)
> and should only be used with user consent as a last resort.

### Step 4.5: Plan Mode for Brownfield Architecture

> **ENABLED BY DEFAULT FOR TECHNICAL USERS IN BROWNFIELD**: Explore existing code and specs
> before making architecture decisions. Prevents regeneration cycles.

### Platform Availability

| Platform | Plan Mode Available |
|----------|---------------------|
| Claude Code (CLI) | ✅ Yes (`EnterPlanMode`/`ExitPlanMode`) |
| Cursor | ❌ No (use fallback) |

### Configuration

```yaml
# In PROJECT.md or development-agents/framework/config.yaml
plan_mode:
  spec_technical_brownfield: true  # Default: true (enabled)
```

### Trigger Conditions

Enter Plan Mode when **ALL** of these are true:
- Project mode is `brownfield` (from meta.md)
- User profile is `technical` (non-technical users skip Plan Mode entirely)
- Feature requires architecture decisions (not pure CRUD)
- Plan Mode not explicitly disabled

### Non-Technical Users

For `non-technical` profile:
- **NO Plan Mode** - Agent assumes everything automatically
- Agent explores code and specs internally (without showing details)
- Generates technical spec based on functional spec
- User only sees final result for approval

### Plan Mode Flow (Technical Users)

```
BEFORE engaging sdd-system-designer:

  IF brownfield AND technical_user AND config.plan_mode.spec_technical_brownfield:

    IF EnterPlanMode available (Claude Code):
      1. EnterPlanMode()

      2. EXPLORE CODE:
         - Detect existing project services in codebase
         - Map current API endpoints
         - Analyze data models and patterns
         - Check infrastructure status

      3. EXPLORE EXISTING SPECS (sdd/features/, sdd/wip/):
         - Read existing functional specs → extract data models, business rules
         - Read existing technical specs → extract services, endpoints, entities
         - Identify potential conflicts (endpoints, tables, topics)
         - Identify extension opportunities (existing entities to extend)

      4. VALIDATE FUNCTIONAL SPEC SYNC:
         - Read meta.md `auto_generated.functional` flag
         - IF `auto_generated.functional == true`:
           → Lighter validation: only check that stories exist and scope is defined
           → Skip gap/extras analysis (auto-generated is intentionally minimal)
         - ELSE (standard flow):
           - Read current feature's functional spec (1-functional/spec.md)
           - Extract: user stories, acceptance criteria, data requirements
           - Verify proposed architecture COVERS all functional requirements
           - Flag gaps: "Functional spec mentions X but architecture doesn't address it"
           - Flag extras: "Architecture includes Y but functional spec doesn't require it"

      5. DESIGN (present to user):
         - Architecture pattern (matches existing vs new)
         - project services to use (existing reuse vs new)
         - API endpoint structure (check conflicts with code AND specs)
         - Data model approach (extend existing entities vs new)
         - Spec consistency (references to existing specs if relevant)
         - **Functional coverage check**: "All N user stories covered by architecture"
         - **Gaps/extras identified** (if any)

      6. ExitPlanMode() (user approves approach)

      ⚠️ POST-PLAN-MODE CRITICAL INSTRUCTION:
      After the user approves the plan, you MUST:
      - Generate the TECHNICAL SPEC MARKDOWN (spec.md), NOT implementation code
      - The plan captured architecture decisions — the OUTPUT is a spec document
      - Do NOT write .go, .java, .ts, .py or any source code files
      - Do NOT create directories outside of sdd/wip/
      - CONTINUE with Step 5 below to generate the spec markdown

    ELSE (Fallback for non-Claude Code):
      1. EXPLORE: Same codebase and spec exploration
      2. DESIGN: Same architecture planning
      3. Display plan inline in chat
      4. AskUserQuestion: "Approve this architecture approach?"
         - Options: "Approve", "Modify", "Skip exploration"

    7. Generate full technical spec with approved approach
```

### Value: Scenarios Prevented

| Scenario | Without Plan Mode | With Plan Mode |
|----------|-------------------|----------------|
| Pattern mismatch | Hexagonal vs layered conflict | Detect and match existing pattern |
|  over-engineering | Add unnecessary services | Identify reusable existing services |
| Endpoint conflicts | Duplicate routes | Detect conflicts before generating |
| Data model conflicts | Duplicate tables | Extend existing entities |
| Spec inconsistency | New spec contradicts existing | Cross-reference before design |
| Missed reuse | Create new when extend is better | Identify extension opportunities |

---

### Extension point: before-start (spec-technical)

> Resolve and invoke hooks for phase=`spec-technical`, trigger=`before-start`.

### Step 5: Technical Spec (HOW to build)

> **IMPORTANT**: This step generates a **MARKDOWN SPECIFICATION FILE** (`spec.md`), NOT implementation code.
> If you just exited Plan Mode, your approved plan informs the CONTENT of the spec — the spec document is the output, not code files.

> **FIRST**: Read `platform` from `meta.md`. This determines which sections and subagents to use.

```bash
platform=$(grep "^\*\*Platform\*\*:" sdd/wip/[feature]/meta.md | awk '{print $2}')
```

#### Mobile Technical Spec (platform = android | ios)

> **PREREQUISITE**: Verify mobile skills are available before generating the spec.
>
> ```bash
> skill_dir="mobile-android-expert"
> plugin_name="mobile-android"
> [ "$platform" = "ios" ] && skill_dir="mobile-ios-expert"
> [ "$platform" = "ios" ] && plugin_name="mobile-ios"
> PLUGIN_PATH="$HOME/.claude/plugins/$plugin_name/skills/$skill_dir"
>
> if [ ! -d "$PLUGIN_PATH" ]; then
>     echo "❌ Mobile plugin not found: $plugin_name"
>     echo "   Re-run: sdd-kit install claude"
>     exit 1
> fi
> ```
>
> If skills are not found, **stop here** — do not generate the spec without documentation.

> **MANDATORY — 3-STEP SEQUENCE (all steps required, no skipping)**:
>
> **Step A — Invoke the mobile skill** (loads mobile SDK/design system documentation into context):
> ```
> Skill("mobile-android-expert")   # if platform = android
> Skill("mobile-ios-expert")       # if platform = ios
> ```
>
> **Step B — Read the skill documentation** (ALWAYS — before writing any section of the spec):
> ```bash
> # SKILL_PATH was resolved in the PREREQUISITE block above
> cat "$SKILL_PATH/SKILL.md"
> ```
> Read SKILL.md fully. Identify and follow the documentation navigation workflows it references
> for mobile SDK libraries and design system components.
> Use those workflows to map **every feature requirement** from the functional spec to its
> corresponding mobile SDK library or design system component. SKILL.md is the single source of truth — no assumptions.
>
> **Step C — Enforce ML-only library selection**:
> The index from Step B is the **only allowed source** for library decisions.
> For each feature requirement, the answer is one of exactly two outcomes:
>
> - **Found in index** → use that mobile SDK library. No alternatives, no substitutions.
> - **Not in index** → the capability does not exist in mobile SDK → document as
>   "no mobile SDK equivalent — use native [X]" in the spec.
>
> Generic Android/iOS ecosystem libraries (e.g. Retrofit, SharedPreferences, Coil,
> Hilt, Jetpack Navigation, UserDefaults, Alamofire, etc.) are **NEVER a valid answer**
> when an mobile SDK library exists for that need.
> The index tells you what exists — trust the index, not pre-training knowledge.

**Sections for mobile**:

1. Executive Summary
2. Architecture (MVVM layers: UI → ViewModel → Repository → DataSource)
3. mobile SDK Libraries — **derived from Step B index read**; list each library name + purpose; NO generic Android/iOS alternatives allowed
4. design system Components (list UI components needed — check design system component map via the skill)
5. Screen/Flow Design (screens, navigation deeplinks if applicable)
6. Data Model (local persistence schema — use the mobile SDK storage library identified in Step B's index read; NEVER SharedPreferences, DataStore, or UserDefaults)
7. Dependencies (mobile SDK lib versions — query via mobile skill index)
8. Testing Strategy (unit tests for ViewModel/Repository; UI tests via screenshot testing)
9. Accessibility (design system components handle this natively)
10. Performance (ANR analysis for Android; App Hangs for iOS)

**Subagents for mobile**:

| Decision type | Subagent | Notes |
|---|---|---|
| Architecture + mobile SDK libs | `Skill("mobile-android-expert")` or `Skill("mobile-ios-expert")` | **MANDATORY (Step A above)** |
| Conflict detection | `sdd-conflict-resolver` | Same as backend |

> ❌ Do NOT invoke `sdd-explorer` for mobile projects
> ❌ Do NOT include  Services, Dockerfile, /ping, or  Compliance sections
> ❌ Do NOT include specific import statements — your team library imports are ML-internal APIs that change across versions and are ONLY reliably known from the skill's official documentation. List libraries by name/purpose only; leave all imports to be resolved at build time.
>
> **IMAGE LOADING — MANDATORY RULE**:
> ❌ NEVER mention Coil, AsyncImage, Glide, Picasso, Fresco (Android) or Kingfisher, SDWebImage, Nuke, PinRemoteImage (iOS) in any spec
> ✅ ALWAYS use the image loading library provided by mobile SDK — the exact library name is in the skill's mobile SDK index (read in Step B above)
> This applies to the spec text, dependency tables, component lists, and code snippets

---

#### Backend/Web Technical Spec (platform = backend | web | "")

> **MANDATORY — Architect-First Protocol (no skipping, BLOCKING)**:
>
> Before producing ANY design decision (DD-1, DD-2, …), service selection, dependency list,
> code snippet, or architecture diagram, you **MUST** invoke the architect plugin skill.
>
> ```
> Skill("project-services-architect")  # redirects to sdd-system-designer plugin skill
> # context: pass the functional spec summary plus a list of capabilities derived from it:
> #   "Capabilities: [async event processing | key-value storage | object storage | audit
> #    trail | distributed lock | …]. Recommend project services with trade-offs and
> #    anti-patterns. Project language: [go|java|python|node]."
> ```
>
> The plugin is the **single source of truth** for:
> - Which project service to pick for each capability (KeyValueStore vs NoSQL vs MySQL, MessageQueue vs
>   Streams vs Workqueues, Object Storage vs Audits, etc.)
> - Trade-off rationale that feeds the Design Decisions section
> - Anti-patterns to call out
> - Segmentation strategy when relevant
>
> ❌ ANTI-PATTERN: writing DD-1, DD-2, … from pre-training knowledge or "what we already saw
>    in discovery" without invoking the plugin. This is the #1 regression mode — the agent
>    "knows" KeyValueStore+MessageQueue+Audits is the answer and skips the call. Don't.
> ✅ CORRECT: invoke `Skill("project-services-architect")` first; let the plugin response drive
>    the candidates; THEN present architecture options to the user (next subsection).
>
> If the plugin recommends 2-3 viable approaches with similar scores, surface those via the
> "Architecture Options" subsection below. If it returns a single recommendation, use it
> directly (skip Architecture Options) and document the rationale in the spec.
>
> After the architect, for each selected service, invoke `Skill("project-snippets-expert")`
> (which redirects to `sdd-implementer`) to fetch live SDK details before writing the
>  Services section of the spec.

#### Architecture Options (Standard Mode + Technical Profile)

> **SKIP for mobile projects** — Mobile architecture is handled by `mobile-android-expert` / `mobile-ios-expert` skill, not `sdd-system-designer`.

> When sdd-system-designer identifies genuinely different architecture
> approaches, present them to the user before writing the spec.

**Trigger**: sdd-system-designer returns 2-3 options (not a single recommendation)
  AND profile == `technical` AND mode == Standard

**Skip when** (auto-select recommended, no user interaction):
- `non-technical` profile — agent selects best option silently (same as current behavior)
- Express mode — auto-select recommended
- Prototype project type — auto-select simplest
- User pre-selected approach in functional spec
- `platform = android` or `platform = ios` — always skip, use mobile skill instead

⛔ INVOKE TOOL (do not print this, CALL the tool):

```
AskUserQuestion(
  questions=[{
    "question": "Multiple architecture approaches are viable. Which do you prefer?",
    "header": "Architecture",
    "options": [
      {
        "label": "[Option A name] (Recommended)",
        "description": "[1-line summary]. Services: [list]. Complexity: [level]",
        "markdown": "[ASCII diagram]\n\nPros:\n- [pro1]\n- [pro2]\n\nCons:\n- [con1]\n- [con2]"
      },
      {
        "label": "[Option B name]",
        "description": "[1-line summary]. Services: [list]. Complexity: [level]",
        "markdown": "[ASCII diagram]\n\nPros:\n- [pro1]\n- [pro2]\n\nCons:\n- [con1]\n- [con2]"
      }
    ],
    "multiSelect": false
  }]
)
```

On selection:
  - Use selected approach for technical spec generation
  - Record ALL options in spec "Design Decisions" section as ADR:

```markdown
## Design Decisions
### DD-1: Architecture Approach
**Selected**: [chosen option]
**Options Considered**:
- Option A: [description] — [pros/cons]
- Option B: [description] — [pros/cons]
- Option C (selected): [description] — [pros/cons]
**Trade-offs Accepted**: [what we give up with the selected option and why it's acceptable]
**Rationale**: [why selected option fits best given the trade-offs]
```

> **⚠️ MANDATORY**: Every DD must include `Options Considered` and `Trade-offs Accepted`. Missing either section fails `validate-technical.sh` with an error (not a warning).

**Sections** (delegate heavy lifting to `sdd-system-designer`):

1. Executive Summary
2. Architecture (Mermaid diagrams - see `standards/diagram-standard.md`)
3.  Platform compliance (conditional - see below)
4.  Services

⛔ INVOKE TOOL (do not print this, CALL the tool — backend projects only):
Skill("sdd-system-designer")

   After the plugin responds, run `project-cli-expert` for live instance discovery (existing vs new).
5. Dependencies (MUST verify from docs - NEVER invent)
6. Design Decisions (with rationale)
7. Data Model
8. REST API Contracts
9. Testing Strategy (unit + integration only; E2E is external)
10. Security (MUST include Secrets Management)
11. Performance
12. Deployment

### Brownfield Mode - Infrastructure Sections

> **CRITICAL**: Before generating technical spec, check `meta.md` for project mode.

**Step 1: Determine Project Mode**
```bash
# Read mode from meta.md
mode=$(grep "mode:" sdd/wip/[feature]/meta.md | cut -d: -f2 | tr -d ' ')
# Returns: greenfield | brownfield
```

**Step 2: Determine Feature Type** (brownfield only)

| Feature Type | Indicators |
|--------------|------------|
| **Touches Infrastructure** | Adds new project service (KeyValueStore, MessageQueue, etc.), requires new database/table, modifies Dockerfile, adds new external dependency requiring secrets, creates new scheduled job |
| **Pure Business Logic** | Adds API endpoints to existing controllers, modifies business rules, updates existing data models, integrates with already-configured services |

**Step 3: Include/Exclude Infrastructure Sections**

| Mode | Feature Type | Infrastructure Sections |
|------|--------------|------------------------|
| greenfield | Any | ✅ Include ALL (Dockerfile, /ping, ) |
| brownfield | Touches infrastructure | ✅ Include ALL |
| brownfield | Pure business logic | ❌ EXCLUDE foundational sections |

**Sections to EXCLUDE in Brownfield Pure-Logic Features:**

| Section | Action | Reason |
|---------|--------|--------|
| Dockerfile status/verification tables | ❌ EXCLUDE | App already has working Dockerfile |
| Dockerfile.runtime mentions | ❌ EXCLUDE | Runtime config already exists |
| /ping endpoint status | ❌ EXCLUDE | Health check already implemented |
| "Platform Compliance" section | ❌ SKIP | Handled by AUTO-TASK-PLATFORM-COMPLIANCE |
| Basic auth patterns (existing token/scope setup) | ❌ EXCLUDE | Auth already configured (reference only if feature needs new scopes) |

4. **Project Services** - query via your internal service directory/registry, if your org has one
5. **Dependencies** ⭐ - **MUST check platform docs for any dependency with known compliance/security requirements** (see Key Rules #11)
6. **Design Decisions** - With rationale
7. **Data Model** - Entities, schemas, migrations
8. **REST API Contracts** - Endpoints, request/response
9. **Frontend Architecture** ⭐ - **CONDITIONAL for frontend features** (see below)
10. **Testing Strategy** - Unit and integration tests only (E2E tests are external - see note below)
11. **Security** ⭐ - **MUST include Secrets Management section** (BLOCKER - see below)
12. **Performance** - Targets, optimization
13. **Deployment** - Rollout strategy

### Frontend Architecture Section ⭐ v2.6.0

> **Lazy-loaded**: When `should_include_frontend_architecture()` is true (Frontend framework/design system detected AND UI keywords in spec), Read `references/frontend-web-architecture.md` for frontend architecture patterns and component guidelines.

---

**Sections to INCLUDE in ALL Technical Specs:**

| Section | Always Include |
|---------|---------------|
| Architecture diagrams | ✅ Feature-specific architecture |
| API contracts | ✅ New/modified endpoints |
| Data model | ✅ New/modified entities |
| Security | ✅ If feature has auth/permission requirements |
| Dependencies | ✅ External services the feature integrates with |
| Design decisions | ✅ Feature-specific technical choices |

**Detection Heuristic for Platform AI docs Agent:**

```
IF mode == "greenfield":
    → Include full section
    → Include Dockerfile verification
    → Include /ping endpoint setup

ELIF mode == "brownfield":
    IF feature creates new project services OR new database tables OR modifies Dockerfile:
        → Include section
        → Include relevant infrastructure setup
    ELSE:
        → SKIP Dockerfile sections
        → SKIP /ping endpoint status
        → SKIP " Platform compliance" (AUTO-TASK handles it)
        → Focus on feature-specific architecture and API contracts
```

**Example - Brownfield Pure Logic Feature:**

```markdown
# ❌ DO NOT include in brownfield pure-logic spec:

##  Platform compliance
| Requirement | Status | Notes |
|-------------|--------|-------|
| Dockerfile exists | ✅ | ... |
| /ping endpoint | ✅ | ... |

# ✅ DO include:

## Architecture Overview
[Feature-specific Mermaid diagram]

## API Contracts
[New endpoints being added]

## Data Model
[New/modified entities]
```

**Template Processing Script** (deterministic cleanup):

```bash
# Process template with conditional sections removed
bash development-agents/framework/tools/templates/process-template.sh \
  --template development-agents/framework/templates/technical-spec.md \
  --mode brownfield \
  --feature-type pure-logic \
  --output sdd/wip/[feature]/2-technical/spec.md

# Or auto-detect from feature path
bash development-agents/framework/tools/templates/process-template.sh \
  --template development-agents/framework/templates/technical-spec.md \
  --feature-path sdd/wip/[feature] \
  --output sdd/wip/[feature]/2-technical/spec.md
```

###  Services with Code Snippets

> When documenting project services, auto-include code examples by delegating to the `sdd-implementer` plugin skill, which fetches live official toolkit documentation.

**Plugin availability check** (before delegating):

```bash
PLUGIN_PATH="$HOME/.claude/plugins/cache/tech-plugins-marketplace/platform-services"
if [ ! -d "$PLUGIN_PATH" ]; then
    echo "⚠️ platform-services plugin not installed — snippets unavailable"
    echo "   Run: sdd-kit init claude --force"
    # Skip snippet section and continue without code examples
fi
```

**Workflow**:
1. After `sdd-explorer` identifies services
2. Verify plugin is installed (check above)
3. For each service, invoke: `Skill("sdd-implementer")` passing the service name and detected project language
4. The skill fetches live documentation from official toolkit repos and returns ready-to-use snippets
5. Include the returned snippet in the spec under the service entry

**Format in Technical Spec**:

```markdown
##  Services

### KeyValueStore - User Sessions
- **Container**: `user-sessions`
- **TTL**: 3600s (1 hour)
- **Criticality**: HIGH

**Implementation Example** (via `sdd-implementer`):
[snippet returned by Skill("sdd-implementer")]

### MessageQueue - Order Events
- **Topic**: `order-events`
- **Visibility**: private
- **Consumer**: `order-processor`

**Implementation Example** (via `sdd-implementer`):
[snippet returned by Skill("sdd-implementer")]
```

**Automatic Detection**:
- Detect project language from `.platform-config` file or file extensions
- Select appropriate snippet language variant
- If multiple languages detected, use primary (Java > Go > Node > Python)

**When to Skip Snippets**:
- Context budget is CRITICAL (>80%) - use concise format
- Service is simple (single-line usage)
- User explicitly requests minimal spec
- **User profile is `non-technical`** - show summary only, no code

**Non-Technical Profile Output** (instead of code snippets):

```markdown
## Platform Services

| Service | Purpose | Status |
|---------|---------|--------|
| Data storage | Store user sessions (1 hour) | ✓ Configured |
| Messaging system | Notify order events | ✓ Configured |

✓ Technical configuration ready - agent will implement automatically
```

###  Service Instance Selection (Live Discovery)

> CRITICAL: When the technical spec identifies project services, run live
> discovery to let the user choose existing instances or create new ones.
> This happens DURING spec creation, NOT during build.

FOR EACH project service type identified:
  1. Read `PROJECT_SERVICES.json` → get `cli_list` and `discovery_skill_prompt`
     for this service
  2. If `cli_list` exists (Tier 1) → run: `project services <type> list`
  3. If `cli_list` is null but `discovery_skill_prompt` exists (Tier 2) →
     invoke `Skill("project-infra-operations")` with that prompt
     (substituting `{app_name}`). The service-specific platform docs
     tools no longer exist.
  4. If neither exists (Tier 3) → inform user: "Manage at the project platform console (from PROJECT.md)"
  5. If CLI/skill call fails (not logged in, VPN) → inform user to fix
     and retry
  6. If instances found → AskUserQuestion: select existing or "Create new"
  7. If no instances found → auto-select "Create new"
  8. Record in spec with `(EXISTING)` or `(NEW)` marker

**Technical Spec Format**:

```markdown
### KeyValueStore - User Sessions
- **Container**: `user-sessions` **(EXISTING)**
- **TTL**: 3600s
- **Discovery**: Found via `project services keyvaluestore list`

### MessageQueue - Order Events
- **Topic**: `order-events` **(NEW)**
- **Action**: Create during /sdd.build
- **CLI**: `project services mq topics create`
```

If ANY services are marked `(NEW)`, add section to spec:

```markdown
## Infrastructure Creation

| Service | Name | CLI Command | Status |
|---------|------|-------------|--------|
| MessageQueue Topic | order-events | `project services mq topics create` | Pending |
```

**Profile-Aware Behavior**:

| Profile | Behavior |
|---------|----------|
| `technical` | Full interactive selection via AskUserQuestion |
| `non-technical` | Auto-select existing if found, create new otherwise |

**Reference**: See `project-cli-expert/SKILL.md` for the complete Service Discovery Protocol.

### Technical Design Anti-Patterns ⚠️ CRITICAL

> **PRINCIPLE**: Be conservative. The simplest solution that works is the best solution.

**NO Over-Engineering**:
```
❌ WRONG: "Let's add a message queue for future scalability"
✅ RIGHT: Direct call. Add queue only when load requires it.

❌ WRONG: "Let's create an abstraction layer for flexibility"
✅ RIGHT: Direct implementation. Abstract when you have 3+ concrete implementations.

❌ WRONG: "Let's use microservices for separation of concerns"
✅ RIGHT: Monolith first. Split only when team/scale demands it.

❌ WRONG: "Let's add caching for performance"
✅ RIGHT: No cache. Add only when measured latency requires it.
```

**NO Data Duplication**:
```
❌ WRONG: Store same data in Object Storage AND MySQL
   → Will get out of sync!

✅ RIGHT: Store data in ONE place, use REFERENCES elsewhere
   Object Storage: { id: "abc", text: "Hello" }
   MySQL: { id: 1, storage_ref: "abc", result: "..." }
```

**Conservative Design Checklist**:
- [ ] Is this the simplest solution that meets requirements?
- [ ] Am I adding complexity for hypothetical future needs?
- [ ] Can I remove any component and still meet requirements?

### Step 5.5: Database Migration Detection (CONDITIONAL)

> After the technical spec is generated and **before** approval, detect if the spec includes database migrations. If detected, annotate `meta.md` so `/sdd.build` knows to handle the `migration/*` branch automatically.

**Detection Logic**:

```
SCAN the generated technical spec (sdd/wip/[feature]/2-technical/spec.md) for:
  1. A "### Migrations" section                    OR
  2. Reference to "your-migration-tool init" command     OR
  3. CREATE TABLE / ALTER TABLE in SQL code blocks  OR
  4. service-type mysql/postgresql in project services

IF any match found:
  → Extract service_name and service_type from the technical spec
  → Update meta.md with migration metadata (see below)
  → Show user notification

IF no match:
  → Set migration.detected: false in meta.md
  → Continue to Step 6 (no further action)
```

**Update meta.md** (append to the `## Database Migrations` section):

```yaml
migration:
  detected: true
  service_name: "<platform-db-service-name>"   # From technical spec  Services section
  service_type: "mysql"                     # mysql | postgresql
  branch_name: null                         # Set by /sdd.build after creation
  branch_status: pending                    # pending | created | pushed | applied
  migration_files: []                       # Populated by /sdd.build
```

**Notify User** (only when migration detected):

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🗄️ Database migration detected
   Service: <service_name> (<service_type>)
   /sdd.build will handle the migration/* branch automatically.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

> **Note**: This step is purely metadata — no git operations happen here. The actual branch orchestration is handled by `/sdd.build` Step 3.5.

### Extension point: after-implementation (spec-technical)

> Resolve and invoke hooks for phase=`spec-technical`, trigger=`after-implementation`.

### Extension point: before-approval (spec-technical)

> Resolve and invoke hooks for phase=`spec-technical`, trigger=`before-approval`.

### Step 6: Show Summary + Approve (with Validation)

> **MANDATORY**: Run deterministic validation before approval - Saves ~3,000-5,000 tokens.

**Step 6a.0: Architect-First Self-Check (BLOCKING for backend/web)**

> **STOP before generating any summary**: Confirm the architect plugin was actually invoked.
>
> If `platform = backend` or `platform = web` (NOT mobile), and the spec contains any of:
> - `## Design Decisions` with DD-* entries that pick project services, OR
> - `##  Services` section with concrete service names (KeyValueStore, MessageQueue, Audits, etc.), OR
> - `## Dependencies` listing  SDKs
>
> Then this spec was generated under the rule "architect plugin is the source of truth".
> Verify in your own working memory:
>
> ```
> [ ] I invoked Skill("project-services-architect") this session BEFORE writing the
>     Design Decisions /  Services / Dependencies sections.
> [ ] The service choices in the spec reflect the plugin's response, not pre-training knowledge.
> [ ] For each selected service, I invoked Skill("project-snippets-expert") to fetch
>     the live SDK details (envvars, dependency coordinates, client setup).
> ```
>
> If ANY checkbox is unchecked: STOP. Do not proceed to Step 6a. Invoke the missing
> skill(s) now, regenerate the affected sections, then resume Step 6.
>
> ❌ ANTI-PATTERN: invoking the skill retroactively after the user asks "did you use
>    the architect skill?". The skill must inform decisions, not ratify them.
> ✅ CORRECT: confirm honestly in this self-check. If you skipped, fix before approval.

**Step 6a: Validate technical spec**

```bash
# Run deterministic validation BEFORE asking for approval
bash development-agents/framework/tools/validation/validate-technical.sh sdd/wip/[feature]

# If exit code != 0: Show errors, DO NOT proceed to approval
# If exit code == 0: Continue to security validation
```

**Step 6a.1: Validate security (OWASP Top 10)**

> **MANDATORY for production projects**: Security validation catches OWASP Top 10 vulnerabilities.

```bash
# Check project type - skip security for prototype
project_type=$(grep "type:" sdd/wip/[feature]/meta.md | head -1 | cut -d: -f2 | tr -d ' ')

if [ "$project_type" != "prototype" ]; then
    bash development-agents/framework/tools/validation/validate-security.sh sdd/wip/[feature] --spec
    # If exit code != 0: Show security issues, DO NOT proceed to approval
    # If exit code == 0: Continue to summary
fi
```

**Security checks include**:
- SQL injection patterns
- XSS vulnerabilities
- CSRF protection
- Authentication/authorization issues
- Sensitive data exposure
- Input validation requirements

**Step 6b: Show concise summary** (if validation passed):
```markdown
## Technical Specification Summary
### Architecture: [1-2 lines]
### Endpoints (N): [list]
### Database: [services + tables]
###  Services: [list]
### Key Decisions: [list]
### Secrets: [count + names]
```

**Step 6b.1: Architecture Diagram (ASCII)**

> **MANDATORY**: After the text summary, generate an ASCII architecture diagram that visually represents the solution. This allows the user to understand the full picture at a glance before approving.

**What to include**:
- Apps/services and their interactions
- Data stores (databases, KeyValueStore, Object Storage)
- Message queues with the full flow: producer app → topic → consumer app
- External service integrations
- Data flow direction with arrows

**Component shapes** (use distinctive shapes per component type):

```
Apps/Services (rectangle):

  ┌──────────────┐
  │ platform_my-app  │
  └──────────────┘


Databases & Storage — MySQL, KeyValueStore, Object Storage (cylinder):

    __________
   /          \
   |  MySQL   |
   |  items   |
   \__________/


Queues/Topics — MessageQueue, KeyValueStore Stream (horizontal tube with segments):

    item-events (MessageQueue)
   ┌──┬──┬──┬──┬──┬──┬──┐
   │  │  │  │  │  │  │  │
   └──┴──┴──┴──┴──┴──┴──┘
```

**Rules**:
- Each component type MUST use its corresponding shape from above
- Arrows (`──▶`, `◀──`, `│`, `▼`) show data flow direction
- Queue topics only contain the topic name and technology type — producers and consumers are separate app boxes
- Keep it compact — focus on component interaction, not internal details
- Adapt complexity to the feature: simple features get simple diagrams

**Example** (feature with Object Storage + KeyValueStore + MessageQueue):

```
                       ┌──────────────┐
                       │ platform_my-app  │
                       └─┬──┬──┬───┬─┘
                         │  │  │   │
         ┌───────────────┘  │  │   └──────────────────────┐
         ▼                  ▼  ▼                           ▼
    __________      __________   _____________   item-events (MessageQueue)
   /          \    /          \ /             \  ┌──┬──┬──┬──┬──┬──┬──┐
   |  MySQL   |    |   KeyValueStore    | | Obj Storage |  │  │  │  │  │  │  │  │
   |  items   |    |   cache  | |    files    |  └──┴──┴──┴──┴──┴──┴──┘
   \__________/    \__________/ \_____________/           │
                                                         ▼
                                                ┌────────────────────┐
                                                │ platform_processor-app │
                                                └────────────────────┘
```

**Example** (simple feature — API + single DB):

```
         ┌──────────────┐
         │ platform_my-app  │
         └──────┬───────┘
                │
                ▼
           __________
          /          \
          |  MySQL   |
          |  users   |
          \__________/
```

**Example** (two apps communicating via MessageQueue):

```
                          order-updates (MessageQueue)
┌──────────────┐         ┌──┬──┬──┬──┬──┬──┬──┐         ┌───────────────────┐
│ platform_my-app  ├────▶    │  │  │  │  │  │  │  │    ────▶│ platform_notifier-app │
└──────────────┘         └──┴──┴──┴──┴──┴──┴──┘         └───────────────────┘
```

> **Note**: The diagram is generated from the technical spec content — it does NOT require additional user input. It's a visual representation of what was already specified in the Architecture,  Services, and Data Model sections.

**Step 6c: Context Check Before Approval**

Before presenting the approval question, estimate context usage. If > 50%, prepend a context advisory:

```
╔═══════════════════════════════════════════════════════╗
║  CONTEXT ADVISORY                                     ║
╠═══════════════════════════════════════════════════════╣
║                                                       ║
║  Context usage: ~[XX]%                                ║
║                                                       ║
║  Tip: After approving, consider /clear before         ║
║  running /sdd.plan. Your spec is saved — a fresh     ║
║  context will give higher quality task generation.     ║
║                                                       ║
╚═══════════════════════════════════════════════════════╝
```

**Step 6d: Approve** (only if validation passed)

**⛔ INVOKE TOOL (do not print this, CALL the tool)**:

```
AskUserQuestion(
  questions=[{
    "question": "The technical spec is ready. What would you like to do?",
    "header": "Approval",
    "options": [
      {"label": "Approve", "description": "Approve and continue to /sdd.plan"},
      {"label": "View full spec", "description": "Display the complete technical spec"},
      {"label": "Request changes", "description": "Iterate on the spec with /sdd.spec --iterate"}
    ],
    "multiSelect": false
  }]
)
```

**If user selects "View full spec"**:
- Read and display the entire file: `sdd/wip/[feature]/2-technical/spec.md`
- After displaying, loop back to the approval question (ask again)

**If user selects "Request changes"**:
- Ask what changes they want to make
- Apply changes using `--iterate` flow

**On approval - Update meta.md:**
```bash
# Get user identity and timestamp (single line to avoid multi-line permission prompts)
approver=$(git config user.name || echo "Unknown"); timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ"); echo "Approver: $approver | Timestamp: $timestamp"
```

Update `meta.md` stages.technical:
- `status: approved`
- `approved_by: <user from git config>` ← NEVER "AI Agent"
- `approved_at: <ISO-8601 timestamp>`

### Step 7: Conflict Detection (GenAI Offloaded)

After technical approval:

```bash
# Try GenAI-powered conflict resolution first
conflict_result=$(bash development-agents/framework/tools/genai/genai-resolve-conflicts.sh sdd/wip/[feature] advisory)
genai_exit=$?

if [ "$genai_exit" -eq 0 ]; then
    total=$(echo "$conflict_result" | grep -o '"total_conflicts":[0-9]*' | cut -d: -f2)
    if [ "$total" -gt 0 ]; then
        # Present classified conflicts with recommendations to user
    fi
else
    # Fallback to deterministic conflict detection
    conflict_result=$(bash development-agents/framework/tools/validation/validate-spec-conflicts.sh sdd/wip/[feature] --json)
fi
```

1. Scan existing specs for conflicts (endpoints, entities, services, tables)
2. Classify severity and recommend resolution (override/extend/deprecate/false_positive)
3. For each conflict: Ask user to confirm recommended action
4. Add annotations to spec
5. Ready for context compaction

### Step 8: Post-Approval Context Compaction

After technical spec is approved and conflicts resolved, compact context for planning phase:

```
/sdd.check --compact
```

**Rationale**:
- Specs are now locked (won't change until build issues arise)
- Planning only needs spec references, not full content
- Prevents context overflow during task generation

**When to skip**:
- Context is low (<40%) - compaction optional
- Small feature with minimal spec content

### Step 9: Interactive Next Steps (After Both Specs Approved)

> **MANDATORY**: Always offer interactive selection after both specs are approved.

**⛔ INVOKE TOOL (do not print this, CALL the tool)**:

```
AskUserQuestion(
  questions=[{
    "question": "Specifications complete. Ready to plan tasks?",
    "header": "Next",
    "options": [
      {"label": "/sdd.plan (Recommended)", "description": "Generate implementation tasks"},
      {"label": "/sdd.spec --iterate", "description": "Make changes to specs"},
      {"label": "/sdd.check", "description": "Review specs before planning"}
    ],
    "multiSelect": false
  }]
)
```

**On user selection**:

| Selection | Action |
|-----------|--------|
| /sdd.plan (Recommended) | `Skill(skill="sdd.plan")` |
| /sdd.spec --iterate | `Skill(skill="sdd.spec", args="--iterate")` |
| /sdd.check | `Skill(skill="sdd.check")` |
| Other | User types custom input |

---

## Key Rules

| Rule | Details |
|------|---------|
| **-stack technologies from PROJECT.md** | See `standards/tech-stack.md` |
| **Smart questioning** | See `sdd-system-designer` plugin skill |
| **MCP delegation** | See `context-guardian` skill |
| **Anti-redundancy** | Use consolidated interview, derive sections |
| **Verify dependencies** | NEVER invent - check platform docs |
| **E2E is external** | Document scenarios only, don't create test files |
| **Java is default** | Use Java + Spring Boot unless user explicitly requests Kotlin |
| **Show summary** | Always before asking for approval |
| **Secrets section** | MANDATORY in technical spec Security section |
| **Deterministic IDs** | Use `generate-ids.sh` for US and E2E IDs (see below) |

### Deterministic ID Generation

> **MANDATORY**: Use script for ID generation - Ensures uniqueness and consistency.

```bash
# Generate next user story ID
next_us=$(bash development-agents/framework/tools/generation/generate-ids.sh us sdd/wip/[feature])
# Returns: US-4 (if US-1, US-2, US-3 exist)

# Generate multiple IDs at once
bash development-agents/framework/tools/generation/generate-ids.sh us sdd/wip/[feature] --count 5
# Returns: US-4 US-5 US-6 US-7 US-8

# Generate E2E scenario ID
next_e2e=$(bash development-agents/framework/tools/generation/generate-ids.sh e2e sdd/wip/[feature])
# Returns: E2E-3 (if E2E-1, E2E-2 exist)
```

**Why deterministic**: Prevents duplicate IDs, maintains sequence integrity, saves LLM tokens.

> **Telemetry**: Captured automatically by hooks - no manual logging required.

---

## Validations

### Functional Spec
- [ ] All required sections present
- [ ] User stories have acceptance criteria
- [ ] Success metrics are measurable
- [ ] No open TODOs

### Technical Spec
- [ ] Architecture documented (Mermaid)
- [ ] Design decisions have rationale
- [ ] REST APIs have contracts
- [ ] Data model complete
- [ ] section (when applicable)
- [ ] Secrets management documented

---

## Output Files

| Phase | Location |
|-------|----------|
| Functional | `sdd/wip/[feature]/1-functional/spec.md` |
| Technical | `sdd/wip/[feature]/2-technical/spec.md` |
| Architecture | `sdd/wip/[feature]/2-technical/architecture.md` |

---

## External Context (--include flag)

| Source | Processing |
|--------|------------|
| Jira URL | Atlassian MCP → Extract summary, AC, comments |
| Confluence URL | Atlassian MCP → Extract page content |
| GitHub PR | WebFetch → Extract description, diff |
| Local file | Read → Based on extension |
| Inline text | Store as context |

### URL Detection for --include

**BEFORE attempting Atlassian MCP call:**

1. **Detect if URL is Jira/Confluence**:
   - `*jira*` or `*atlassian.net/browse/*` → Jira
   - `*confluence*` or `*atlassian.net/wiki/*` → Confluence

2. **Check PROJECT.md for `atlassian_mcp_enabled`**:
   - If `true`: Proceed with AtlassianMCP tool
   - If `false` or missing: Show message:

   ```
   📋 **Jira/Confluence Content Needed**

   I detected a Jira/Confluence URL but can't access it automatically yet.

   **Option 1**: Copy the ticket/page content and paste it below.
   I'll extract the requirements from it.

   **Option 2**: Describe the feature in your own words.

   **Enable auto-fetch for next time** (optional):
   Add to `sdd/PROJECT.md`: `atlassian_mcp_enabled: true`

   **Your input**:
   ```

3. **If enabled but MCP not responding**:
   - User may need to complete OAuth login
   - Show: "AtlassianMCP requires OAuth login. Please complete authentication when prompted."

---

## Command Flow

```
/sdd.spec ─────► Phase Detection
                      │
        ┌─────────────┴─────────────┐
        ▼                           ▼
   Functional                   Technical
   (WHAT)                       (HOW)
        │                           │
        ▼                           ▼
   Consolidated              sdd-system-designer
   Interview (3-5 Q)         sdd-explorer
        │                           │
        ▼                           ▼
   Show Summary              Show Summary
   + Approve                 + Approve
        │                           │
        ▼                           ▼
   API Discovery ──────────► Conflict Detection
                                    │
                                    ▼
                              /sdd.plan
```

---

## References

- **Templates**: `development-agents/framework/templates/functional-spec.md`, `technical-spec.md`
- **Lite template**: `development-agents/framework/templates/lite/spec.md`
- **Gap detection**: `genai-detect-gaps.sh` (GenAI) → inline fallback
- **Diagram standard**: `standards/diagram-standard.md`
- ** tech mapping**: `standards/tech-stack.md`
- **Smart questioning**: `sdd-system-designer` plugin skill
- **Context management**: `context-guardian` skill
- **System design**: `sdd-system-designer` subagent
- ** discovery**: `sdd-explorer` subagent
- **Conflict resolution**: `genai-resolve-conflicts.sh` → `validate-spec-conflicts.sh`
- **Optional modes**: `references/spec-iterate.md`, `spec-summary.md`, `spec-audio.md`

---

## Optional modes

The detailed, conditional instructions for `--iterate`, `--summary`, and
`--audio` are lazy-loaded only when those flags are present:

- `--iterate`: Read `references/spec-iterate.md` before changing any spec.
- `--summary`: Read `references/spec-summary.md`; do not load full specs.
- `--audio`: Read `references/spec-audio.md` before starting capture.

---

## AI Agent Instructions

### Help Flag Detection

**WHEN** the user runs `/sdd.spec help`:
1. Output ONLY the "Quick Help" section (not full documentation)
2. Do NOT execute spec creation logic
3. Keep response concise (~15 lines)

### Description Parameter Handling

**WHEN** user provides inline description:
```bash
/sdd.spec "user authentication with OAuth2 and social login"
/sdd.spec functional "payment processing with refunds"
/sdd.spec technical "REST API for inventory management"
```

**Behavior**:
1. Store the description as `initial_context`
2. Use to **ENRICH** interview questions (not replace them)
3. Pre-populate relevant sections where applicable
4. Ask **more specific** clarifying questions based on the description

**Example Flow**:
```
User: /sdd.spec "payment processing with refunds"

AI: Great! Based on your description, I'll focus the interview on payment flows.

📝 Starting Functional Spec Interview
   Context: "payment processing with refunds"

Q1: What specific payment methods need to be supported?
    (credit card, debit, PIX, MercadoPago wallet, etc.)
```

**Key Rules**:
- Description is **optional** - interview still works without it
- Description does NOT skip the interview, it **seeds** it
- If description is vague, ask clarifying questions first
- Store context in memory for both functional and technical phases

### `--iterate` Flag Detection

When the user runs `/sdd.spec --iterate "change description"`, read
`references/spec-iterate.md` and follow its preview/confirmation flow.

### --approve Flag Detection

**WHEN** the user runs `/sdd.spec functional --approve` or `/sdd.spec technical --approve`:

> **CRITICAL**: Do NOT call `EnterPlanMode()`. Skip Steps 2, 4, 4.5 entirely. This flag is used to resume approval after plan mode was already completed.

1. Detect the target phase from the command: `functional` or `technical`
2. **Locate the spec file**: `sdd/wip/[feature]/1-functional/spec.md` or `sdd/wip/[feature]/2-technical/spec.md`
3. **Validate spec exists**: If the file does not exist, show error and suggest running `/sdd.spec <phase>` first
4. **Check meta.md status**: Read `meta.md` and verify the phase status is `draft` (not already `approved`)
   - If already approved: Show message "Spec already approved" and offer next steps
5. **Run validation** (same as Step 3a/6a depending on phase):
   - Functional: `bash development-agents/framework/tools/validation/validate-functional.sh sdd/wip/[feature]`
   - Technical: `bash development-agents/framework/tools/validation/validate-technical.sh sdd/wip/[feature]`
   - If validation fails: Show errors, do NOT proceed
6. **Show concise summary** (same as Step 3b/6b depending on phase)
7. **Ask for approval** via AskUserQuestion (same as Step 3c/6c depending on phase)
8. **On approval**: Update `meta.md` with `status: approved`, `approved_by: <git config user.name>`, `approved_at: <ISO-8601>`
9. **Context advisory** (optional): Estimate context usage. If > 50%, show:
   ```
   ╔═══════════════════════════════════════════════════════╗
   ║  CONTEXT ADVISORY (optional)                          ║
   ╠═══════════════════════════════════════════════════════╣
   ║                                                       ║
   ║  Context usage: ~[XX]%                                ║
   ║  Phase completed: [spec phase]                        ║
   ║                                                       ║
   ║  All decisions are saved in your spec artifacts.      ║
   ║  Consider /clear before starting next phase           ║
   ║  for maximum available context.                       ║
   ║                                                       ║
   ║  This is optional — you can continue as-is.           ║
   ║                                                       ║
   ╚═══════════════════════════════════════════════════════╝
   ```

**PROHIBITED**:
- ❌ Calling `EnterPlanMode()` — the user already exited plan mode
- ❌ Re-running the interview or spec generation steps
- ❌ Re-entering the full workflow (Steps 1-6)

---

## `--summary` Flag Behavior

When the user runs `/sdd.spec --summary [feature-name]`, read
`references/spec-summary.md`. Read only metadata and section headers; do not
execute spec creation logic or load complete spec files.

---

## `--audio` Flag Behavior

When the user runs `/sdd.spec --audio`, read `references/spec-audio.md` and
follow that capture flow before continuing with the normal interview.

