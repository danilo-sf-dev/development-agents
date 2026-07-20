---
name: sdd.mcp
description: Configure optional MCP integrations (Atlassian Jira/Confluence read-only first) in a host-agnostic way. Detects IDE/assistant, guides native or generic setup, smoke-tests from a URL. Use when /sdd.spec --include needs Jira or when atlassian_mcp_enabled is desired.
model: sonnet
argument-hint: "[--status|--test <url>|--disable]"
---

### HOW TO READ THIS COMMAND

When you see a block like this:

⛔ INVOKE TOOL (do not print this, CALL the tool):
AskUserQuestion(questions=[{...}])

This is a TOOL CALL you must execute, not content to display.

> **Shared agent instructions**: Read `development-agents/framework/_shared/agent-instructions.md` (or `framework/_shared/agent-instructions.md` on hub) before executing.

# Command: /sdd.mcp

**Description**: Setup wizard for optional MCP integrations. Host-agnostic (Cursor, Claude Code, VS Code, JetBrains, other). v1 focus: **Atlassian Jira/Confluence read-only** for `/sdd.spec --include`.

**Usage**:
- `/sdd.mcp` → Interactive wizard (detect → configure → smoke test → PROJECT.md flag)
- `/sdd.mcp --status` → Report current flag + config (read-only)
- `/sdd.mcp --test "https://…/browse/PROJ-123"` → Smoke test only
- `/sdd.mcp --disable` → Turn off pack flag + removal notes

---

## Quick Help

| Flag | Description |
|------|-------------|
| (none) | Full setup wizard |
| `--status` | Inventory only |
| `--test <url>` | Read-only fetch of Jira/Confluence URL |
| `--disable` | Disable `atlassian_mcp_enabled` |

**Examples**:

```bash
/sdd.mcp
/sdd.mcp --status
/sdd.mcp --test "https://your.atlassian.net/browse/PROJ-123"
/sdd.mcp --disable
```

**See also**: `framework/MCP_SETUP_GUIDE.md` · agent `sdd-mcp-setup` · `/sdd.spec --include`

---

## Fluxo de execução

### 1. Delegar ao agente

Siga **integralmente** as instruções em (primeiro caminho que existir):

- `agents/sdd-mcp-setup.md` (hub / pack na raiz)
- `development-agents/agents/sdd-mcp-setup.md` (pack em subpasta no projeto)

Você é o executor: use Read, Write, Glob, Grep, AskUserQuestion. Prefer isolated subagent when the host supports Task/subagents (`sdd-mcp-setup`); otherwise run the agent instructions in this session.

### 2. Lazy references (agent loads as needed)

| Topic | Reference |
|-------|-----------|
| Detect host | `commands/references/mcp-detect-host.md` |
| Per-host Atlassian steps | `commands/references/mcp-atlassian-hosts.md` |
| Smoke test | `commands/references/mcp-smoke-test.md` |
| Human guide | `framework/MCP_SETUP_GUIDE.md` |

### 3. Flags → comportamento

| Flag | Effect |
|------|--------|
| (none) | Wizard Steps 0–8 in agent |
| `--status` | Status mode |
| `--test` | Smoke-test mode with given URL |
| `--disable` | Disable mode |

### 4. Gates

- Before writing/merging `.mcp.json` → AskUserQuestion (+ **Outros**)
- Before `--disable` → AskUserQuestion (+ **Outros**)
- After smoke fail → offer retry / paste-manual / Outros — do **not** set `atlassian_mcp_enabled: true`

### 5. Success criteria

- Smoke test returns issue key + summary (or Confluence title), **or**
- User explicitly accepts config without smoke test (record risk note in summary)
- `atlassian_mcp_enabled` matches reality

### 6. Next steps

**Model advisory**: Read `references/model-suggestion-advisory.md` — full box for `phase_key`: `mcp→next` (match recommended option: spec → forte; start → barato).

⛔ INVOKE TOOL (do not print this, CALL the tool):
AskUserQuestion(questions=[{
  "question": "MCP setup concluído. Próximo passo?",
  "header": "Próximo",
  "options": [
    {"label": "/sdd.spec --include (Recommended)", "description": "Usar URL Jira/Confluence na spec — sugere modelo forte"},
    {"label": "/sdd.mcp --test", "description": "Rodar outro smoke test"},
    {"label": "/sdd.start", "description": "Iniciar / continuar feature — sugere modelo barato"},
    {"label": "Outros", "description": "Descreva o que você vai fazer"}
  ],
  "multiSelect": false
}])

If Express Mode parent (`/sdd.go`): skip this AskUserQuestion; return summary only.

---

## AI Agent Instructions

1. Do not assume Cursor-only or Claude-only paths
2. JetBrains Jira UI plugins ≠ MCP for the agent — configure MCP for the AI host
3. Keep v1 read-only; never transition issues or edit Confluence via this command
4. Preserve existing unrelated MCP servers when merging `.mcp.json`
5. Manual paste fallback in `spec-include-context.md` remains valid when MCP is off
)
