# Reference: Atlassian MCP — per-host steps

**Used by**: `sdd-mcp-setup` / `/sdd.mcp` Steps 4–5.

Official cloud MCP (read tools for Jira/Confluence). Auth is OAuth (or org token policy) in the **host UI** — the agent does not store secrets.

## Shared facts

| Item | Value |
|------|-------|
| Modern HTTP URL | `https://mcp.atlassian.com/v1/mcp/authv2` |
| Legacy SSE (mcp-remote) | `https://mcp.atlassian.com/v1/sse` |
| Pack flag | `atlassian_mcp_enabled: true` in `sdd/PROJECT.md` |
| SDD usage | `/sdd.spec --include "<jira-or-confluence-url>"` |
| Access mode (v1) | **Read-only** (cards, epics, pages) |

---

## Cursor (native preferred)

1. Open Cursor Settings → MCP / Plugins
2. Prefer **Atlassian** official plugin / MCP entry if listed in marketplace
3. Complete OAuth when prompted (Atlassian site access)
4. Confirm tools appear (e.g. issue fetch) in the agent tool list
5. Optional project fallback — merge into project-root `.mcp.json`:

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

6. Smoke test with `/sdd.mcp --test "<url>"`

---

## Claude Code (native preferred)

1. Prefer CLI project scope when available:

```bash
claude mcp add --transport http atlassian https://mcp.atlassian.com/v1/mcp/authv2
```

(Adjust flags to current Claude Code docs if the CLI evolved.)

2. Or merge project-root `.mcp.json` (HTTP or mcp-remote fallback — see Generic)
3. Restart session / reconnect MCP
4. Complete OAuth when prompted
5. Smoke test

---

## VS Code

1. Open MCP configuration for the AI chat client in use (Copilot Chat MCP, Continue, etc.)
2. Add server — shape varies by client; common project file:

`.vscode/mcp.json` **or** project-root `.mcp.json`:

```json
{
  "servers": {
    "atlassian": {
      "type": "http",
      "url": "https://mcp.atlassian.com/v1/mcp/authv2"
    }
  }
}
```

If the client expects `mcpServers` (Cursor-compatible), use that key instead — **match the client's schema**, do not invent both.

3. Reload window / restart MCP
4. OAuth in UI
5. Smoke test

> VS Code marketplace “Jira” extensions help humans in the IDE; they are **not** the same as MCP for the agent unless that extension exposes MCP tools.

---

## JetBrains (IntelliJ, WebStorm, …)

1. Clarify: **Jira Connector / Atlassian IDE plugins** ≠ MCP for the AI agent
2. Check whether the AI assistant (JetBrains AI, Continue, Claude plugin, etc.) supports MCP servers
3. If **yes** → add Atlassian via that assistant’s MCP settings (HTTP URL above) or project `.mcp.json` if supported
4. If **no** → use **Generic** steps; SDD still works with **paste-manual** in `/sdd.spec --include`
5. Smoke test only when the assistant actually exposes MCP tools

---

## Generic wizard (any host / Kiro / Antigravity / unknown)

Use when native path is missing or user chooses generic.

### A. Project `.mcp.json` (HTTP)

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

### B. Command bridge (stdio) — if host only supports command MCP

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

Requires Node.js/`npx` on PATH.

### Merge rules

- Preserve other `mcpServers` / `servers` entries
- Do not commit secrets; OAuth stays in host credential store
- Align with team gitignore policy for `.mcp.json` if secrets ever appear there

### Human checklist

1. Approve file write
2. Reload AI session
3. Complete OAuth
4. Run smoke test
5. Enable `atlassian_mcp_enabled` only after pass

---

## Already configured

If tools already work → skip write; go to smoke test; ensure PROJECT.md flag is true.
)
