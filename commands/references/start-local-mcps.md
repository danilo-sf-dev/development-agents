# Reference: Local MCP Configuration

**Used by**: `/sdd.start` Step 6.5 when MCPs need setup.

### Step 6.5: Configure Local MCPs (if needed)

> **SKIP IF**: `project_type == "prototype"` (already skipped PROJECT.md)

After loading PROJECT.md, check for optional MCP configurations:

1. **Check `atlassian_mcp_enabled` setting**
2. **If `true`**:
   - Verify Atlassian MCP is usable (tools available **or** project `.mcp.json` already has an Atlassian entry)
   - If **not** configured / not usable → **do not** silently invent a host-specific setup here
   - Tell the user to run the host-agnostic wizard:

     ```
     /sdd.mcp
     ```

     That command (agent `sdd-mcp-setup`) detects Cursor / Claude Code / VS Code / JetBrains / other, guides native or generic `.mcp.json`, runs a read-only smoke test, and keeps `PROJECT.md` in sync.

   - Optional shortcut if the user already approved a quick merge in this session: you may merge the generic Atlassian entry into project-root `.mcp.json` using the shapes in `commands/references/mcp-atlassian-hosts.md` / `framework/MCP_SETUP_GUIDE.md`, then still recommend `/sdd.mcp --test "<url>"` for OAuth + smoke test
   - Note: first use usually requires OAuth login to Atlassian in the host UI

3. **If `false` or missing**: Skip (Atlassian MCP not needed). `/sdd.spec --include` will offer paste-manual fallback.

> **Canonical setup**: [`/sdd.mcp`](../sdd.mcp.md) · [`MCP_SETUP_GUIDE.md`](../../framework/MCP_SETUP_GUIDE.md)
