# MCP Setup Guide

Optional integrations for the SDD pack. **Nothing here is required** for the core pipeline (`start → spec → plan → test → build → finish → pr`).

> **Preferred command**: [`/sdd.mcp`](../commands/sdd.mcp.md) — host-agnostic wizard (detect → configure → smoke test → `PROJECT.md` flag).

---

## Why MCP?

MCP (Model Context Protocol) lets the AI assistant call external tools. SDD uses it optionally to:

| Integration | SDD use | Default |
|-------------|---------|---------|
| **Atlassian** (Jira / Confluence) | `/sdd.spec --include <url>` auto-fetch | Off (`atlassian_mcp_enabled: false`) |
| Org-internal (E2E, scanners, architecture) | Only if your team adds them | Off |

Without MCP, paste ticket/page content into the chat or `--include` inline text.

---

## Atlassian (Jira / Confluence) — read-only

### Quick path

```text
/sdd.mcp
```

Then:

```text
/sdd.spec --include "https://your.atlassian.net/browse/PROJ-123"
```

### What the wizard does

1. Detects Cursor / Claude Code / VS Code / JetBrains / other
2. Prefers **native** host setup; otherwise writes/merges project `.mcp.json`
3. You complete **OAuth** in the host UI
4. Smoke-tests one URL (read-only)
5. Sets `atlassian_mcp_enabled: true` in `sdd/PROJECT.md` on success

### Manual flag

In `sdd/PROJECT.md` defaults (uncomment / set):

```yaml
defaults:
  atlassian_mcp_enabled: true
```

Flag alone is not enough — the host must load the Atlassian MCP server.

### Example `.mcp.json` (project root)

HTTP (preferred when supported):

```json
{
  "mcpServers": {
    "atlassian": {
      "type": "http",
      "url": "https://mcp.atlassian.com/v1/mcp/authv2"
    }
  }
}
```

Command bridge (Node/`npx`):

```json
{
  "mcpServers": {
    "AtlassianMCP": {
      "command": "npx",
      "args": ["-y", "mcp-remote", "https://mcp.atlassian.com/v1/sse"]
    }
  }
}
```

VS Code clients may use a `servers` key — follow the client schema. Details: `commands/references/mcp-atlassian-hosts.md`.

### Status / test / disable

```text
/sdd.mcp --status
/sdd.mcp --test "https://your.atlassian.net/browse/PROJ-123"
/sdd.mcp --disable
```

---

## Other MCP servers (org-specific)

E2E frameworks, dependency scanners, service catalogs, etc. are **not** shipped by this pack. Configure them in your host’s MCP UI or `.mcp.json` per internal docs. SDD agents may *use* them when present; they never hard-require vendor-specific servers.

---

## Troubleshooting

| Problem | What to try |
|---------|-------------|
| `/sdd.spec --include` asks to paste | Run `/sdd.mcp` or paste manually |
| OAuth loop | Re-auth in host MCP settings; check site access |
| Tools missing after config | Reload window / new agent session |
| JetBrains Jira plugin works but agent cannot read | That plugin is IDE UI, not MCP — run `/sdd.mcp` for the AI host |
| Wrong schema in `.mcp.json` | Match host docs; see `mcp-atlassian-hosts.md` |

---

## Related

- Agent: `agents/sdd-mcp-setup.md`
- Command: `commands/sdd.mcp.md`
- Spec consumption: `commands/references/spec-include-context.md`
- Start Step 6.5: `commands/references/start-local-mcps.md` (delegates to `/sdd.mcp`)
)
