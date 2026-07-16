# Reference: Spec Completeness Checklist

**Used by**: `/sdd.spec` Step 2.5 when critical gaps remain before generating the functional spec.

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
