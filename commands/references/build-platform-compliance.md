# Reference: Build Platform Compliance

**Used by**: `/sdd.build` final validation for backend/web.

## AUTO-TASK-PLATFORM-COMPLIANCE: Generic Validation

> Validate against **project** standards in PROJECT.md, the technical spec, and
> 	imings-agent/framework/standards/. No vendor platform skill is mandatory.

### Skip / adapt by platform.type

`
IF platform.type in (android, ios) AND PROJECT.md says so:
    Prefer mobile build + unit tests (gradlew / xcodebuild or project scripts)
ELSE:
    Prefer language build + test + lint from detect-stack / package scripts
`

### Layer 1: Static Checks

`ash
bash development-agents/framework/tools/validate-code.sh . --json 2>/dev/null || true
# Also run project linters if present (eslint, ruff, golangci-lint, etc.)
`

**Validates** (when applicable to the project):
- Container / deploy manifests match PROJECT.md conventions
- Health/readiness endpoints if the app type requires them
- No hardcoded secrets
- Coding standards from development-agents/framework/standards/

### Layer 2: Stack & Service Validation

1. Detect language/stack via detect-language.sh / detect-stack.sh + PROJECT.md
2. Optionally invoke stack skills **named in PROJECT.md** (java/ts/go/python/rust experts)
3. Validate project services / platform services from the technical spec against existing config
4. Frontend: follow the project's design system and component library (from PROJECT.md), not a fixed vendor UI kit
5. Design-to-code (Figma etc.): only if the project configures it

### Layer 3: Runtime / Test Verification

Run the project's test suite (unit + integration). E2E only if configured (	esting.e2e.enabled or existing suite).

After fixes that change behavior: /sdd.check --sync.

### Verdict

| Result | Condition |
|--------|-----------|
| APPROVED | Required layers pass |
| WARNINGS | Non-blocking issues |
| FAILED | Critical errors |
