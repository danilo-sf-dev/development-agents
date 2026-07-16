# Reference: Dependency Scanning in Build

**Used by**: `/sdd.build` when adding libraries.

### Dependency Scanning

**MANDATORY before adding any library**: Run a vulnerability check via your dependency-security-scanning MCP/tool, if one is configured for this project (check `PROJECT.md`).

```python
# Example shape — replace with whatever dependency-scanner MCP/tool your project has configured
mcp__<your-dependency-scanner>__safe_add_dependency(
  technology="java",
  ecosystem="maven",
  name_user="<user>",
  name_repository="<repo>",
  dependencies=[{"name": "new-library", "version": "1.0.0"}]
)
```

**Action on vulnerability**: Try latest version. If still vulnerable, warn user and block.

---
