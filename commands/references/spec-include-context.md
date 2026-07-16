# Reference: External Context (--include)

**Used by**: `/sdd.spec` when `--include` provides Jira/Confluence/GitHub/local/inline context.

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
   Run `/sdd.mcp` (host-agnostic wizard: detect IDE → configure → smoke test → sets `atlassian_mcp_enabled`).
   Or add manually to `sdd/PROJECT.md`: `atlassian_mcp_enabled: true` and configure MCP per `framework/MCP_SETUP_GUIDE.md`.

   **Your input**:
   ```

3. **If enabled but MCP not responding**:
   - User may need to complete OAuth login
   - Show: "Atlassian MCP requires OAuth login. Complete authentication when prompted, or run `/sdd.mcp --status` / `/sdd.mcp` to repair."
   - Keep paste-manual as immediate fallback so the spec is not blocked.

---
