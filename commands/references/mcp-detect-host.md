# Reference: MCP host detection

**Used by**: `sdd-mcp-setup` / `/sdd.mcp` Step 1.

## Goal

Guess which coding assistant is running so setup steps match reality. **Never block** on detection failure — fall back to AskUserQuestion or generic wizard.

## Signals (best effort)

| Signal | Suggests |
|--------|----------|
| Workspace has `.cursor/` adapters or user mentions Cursor | Cursor |
| `.claude/` settings, Claude Code CLI context, `CLAUDE.md` IDE path | Claude Code |
| `.vscode/mcp.json` or `mcp` in VS Code settings; user in VS Code chat | VS Code |
| IntelliJ / WebStorm / JetBrains AI; `.idea/` heavy workspace | JetBrains |
| None / conflicting | Unknown → ask user |

## Heuristic order

1. If the **runtime** already exposes Atlassian MCP tools → host is whatever loaded them; skip reinstall, go to smoke test
2. Else inspect project markers (`.cursor/`, `.claude/`, `.vscode/`, `.idea/`)
3. Else AskUserQuestion (options include **Outros**)
4. Map Outros free text to closest host or **generic**

## Confidence labels

| Label | When |
|-------|------|
| high | Runtime MCP tools visible or user confirmed |
| medium | Clear project marker + consistent chat product |
| low | Guess only — always confirm with user before writing config |

## Output for wizard

```
Host: <cursor|claude-code|vscode|jetbrains|generic>
Confidence: <high|medium|low>
Native path available: <yes|no|unknown>
```

`Native path available`:
- **Cursor**: yes (Atlassian marketplace plugin / MCP UI)
- **Claude Code**: yes (`claude mcp add` / project `.mcp.json`)
- **VS Code**: yes (MCP settings / `.vscode/mcp.json` depending on client)
- **JetBrains**: unknown/partial — many installs have Jira *UI* plugins but not agent MCP; prefer generic MCP if the AI assistant supports it
- **Generic**: no native — use `.mcp.json` wizard only
)
