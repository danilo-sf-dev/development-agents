# Reference: Frontend Web Agent Routing (`/sdd.spec`)

**Used by**: `/sdd.spec technical`, when the project has a Frontend framework/design system Web stack.

**Detection**: Check `package.json` for `"frontend-framework"` or `"@design-system/*"` dependencies.

## Agent routing

```
sdd-system-designer → All frontend architecture decisions
                      Uses Skill(frontend-web-expert) internally

WORKFLOW:
   Agent("sdd-system-designer", ...)

WHY: Single agent delegates to frontend-web-expert skill as source of truth
     for Frontend framework/design system patterns, rendering strategy, and
     component decisions.
```

| Decision Type | Agent | Example |
|---------------|-------|---------|
| Architecture + rendering strategy | `sdd-system-designer` | "SSR vs Islands, page hierarchy" |
| Component selection + Frontend framework patterns | `sdd-system-designer` | "Which design system components?" |

## Stack detection rules

- **Backend only** (`pom.xml`, `go.mod`, `requirements.txt`): Use backend subagents only
- **Frontend only** (`package.json` with `frontend-framework`/`@design-system/*`): Use frontend skills only
- **Fullstack**: Use both as appropriate

For frontend architecture patterns in the technical spec, also read `references/frontend-web-architecture.md` when `should_include_frontend_architecture()` is true.
