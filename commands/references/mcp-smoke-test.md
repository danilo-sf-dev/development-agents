# Reference: Atlassian MCP smoke test (read-only)

**Used by**: `sdd-mcp-setup` / `/sdd.mcp` Step 6 and `--test`.

## Goal

Prove the agent can **read** one Jira issue or Confluence page via MCP. No writes, no transitions, no comments.

## Input

- Jira: URL containing `/browse/KEY-123` or `*atlassian.net/browse/*`
- Confluence: URL containing `/wiki/` or `*confluence*`

If user pastes only `PROJ-123`, ask for full browse URL or site base + key.

## Steps

1. Confirm Atlassian MCP tools are available in this session
2. Call the **read** tool that fetches issue/page by URL or key (tool names vary by MCP server version — use whatever the host exposes for get-issue / get-page)
3. Extract and show:
   - **Jira**: key, summary, status (optional: type, assignee)
   - **Confluence**: title, space key/id if present
4. Do **not** modify the remote resource

## Pass criteria

- Tool returns structured content without auth error
- At least key+summary (Jira) or title (Confluence) shown to user

## Fail handling

| Symptom | Action |
|---------|--------|
| No Atlassian tools in session | Reload host MCP; complete OAuth; re-run `/sdd.mcp` |
| 401 / auth required | User completes OAuth in host UI; retry `--test` |
| 404 / wrong site | Confirm URL and Atlassian cloud site access |
| Timeout / MCP down | Suggest paste-manual path in `spec-include-context.md` |
| Only write tools visible | Still attempt read; if impossible, treat as fail — v1 needs read |

## After pass

Allowed to set `atlassian_mcp_enabled: true` in `sdd/PROJECT.md`.

## After fail

Do **not** set the flag to true. Offer:

1. Retry setup steps for detected host
2. Paste content manually into `/sdd.spec --include`
3. Outros

## Example report

```
Smoke test: PASS
Source: https://acme.atlassian.net/browse/PAY-42
Key: PAY-42
Summary: Enable PIX refund path
Status: In Progress
```
)
