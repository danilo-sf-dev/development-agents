# Reference: Local MCP Configuration

**Used by**: `/sdd.start` Step 6.5 when MCPs need setup.

### Step 6.5: Configure Local MCPs (if needed)

> **SKIP IF**: `project_type == "prototype"` (already skipped PROJECT.md)

After loading PROJECT.md, check for optional MCP configurations:

1. **Check `atlassian_mcp_enabled` setting**
2. **If `true`**:
   - Check if `.mcp.json` exists in project root
   - Add AtlassianMCP to local `.mcp.json`:

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

   - If `.mcp.json` exists: Merge AtlassianMCP into existing config
   - If `.mcp.json` doesn't exist: Create it with AtlassianMCP only
   - Show: "✓ AtlassianMCP configured locally for this project"
   - Note: "First use will require OAuth login to Atlassian"

3. **If `false` or missing**: Skip (AtlassianMCP not needed)
