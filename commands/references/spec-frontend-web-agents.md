# Reference: Frontend Web Agent Routing (`/sdd.spec`)

**Used by**: `/sdd.spec technical`, when the project has a Frontend framework/design system Web stack.

**Detection**: Check `package.json` for `"frontend-framework"` or `"@design-system/*"` dependencies.

## Skill routing

> `sdd-system-design` requires `OFFLOAD_REASONING` (`model_role: STRONG`) — see
> `framework/_shared/harness-capabilities.md` for the capability and `adapters/<harness>/README.md`
> for the concrete dispatch on the installed harness.

```
sdd-system-design → All frontend architecture decisions
                      Uses Skill(frontend-web-expert) internally

WHY: Single Skill delegates to frontend-web-expert skill as source of truth
     for Frontend framework/design system patterns, rendering strategy, and
     component decisions.
```

| Decision Type | Skill | Example |
|---------------|-------|---------|
| Architecture + rendering strategy | `sdd-system-design` | "SSR vs Islands, page hierarchy" |
| Component selection + Frontend framework patterns | `sdd-system-design` | "Which design system components?" |

## Stack detection rules

- **Backend only** (`pom.xml`, `go.mod`, `requirements.txt`): Use backend Skills only
- **Frontend only** (`package.json` with `frontend-framework`/`@design-system/*`): Use frontend skills only
- **Fullstack**: Use both as appropriate

For frontend architecture patterns in the technical spec, also read `references/frontend-web-architecture.md` when `should_include_frontend_architecture()` is true.
