# =============================================================================
# development-agents - Installer (PowerShell)
#
# Exporta o pack SDD para um projeto alvo:
#   - development-agents/  (pack local)
#   - .claude/{commands,agents,skills}
#   - .cursor/{agents,skills} + rule mínima
#   - sdd/{wip,features}
#   - .gitignore             (ignora pack + adapters — repo limpo)
#
# Usage:
#   .\install.ps1
#   .\install.ps1 -TargetDir "E:\Projects\meu-app"
#   .\install.ps1 -TargetDir "E:\Projects\meu-app" -CursorOnly
#   .\install.ps1 -TargetDir "E:\Projects\meu-app" -ClaudeOnly
# =============================================================================

[CmdletBinding()]
param(
    [string]$TargetDir = (Get-Location).Path,
    [switch]$ClaudeOnly,
    [switch]$CursorOnly
)

$ErrorActionPreference = "Stop"

$InstallClaude = -not $CursorOnly.IsPresent
$InstallCursor = -not $ClaudeOnly.IsPresent
if ($ClaudeOnly.IsPresent -and $CursorOnly.IsPresent) {
    throw "Use only one of -ClaudeOnly or -CursorOnly"
}

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$TargetDir = (Resolve-Path -LiteralPath $TargetDir).Path

function Write-Ok([string]$Msg) { Write-Host "  OK $Msg" -ForegroundColor Green }
function Write-WarnMsg([string]$Msg) { Write-Host "  WARN $Msg" -ForegroundColor Yellow }

function Copy-DirContents([string]$Source, [string]$Destination) {
    New-Item -ItemType Directory -Force -Path $Destination | Out-Null
    Copy-Item -Path (Join-Path $Source "*") -Destination $Destination -Recurse -Force
}

function Ensure-Gitignore {
    param([string]$TargetRoot)

    $gitignorePath = Join-Path $TargetRoot ".gitignore"
    $marker = "# development-agents pack (instalacao local"
    $snippetPath = Join-Path $ScriptDir "framework\templates\project-gitignore.snippet"

    if (-not (Test-Path -LiteralPath $snippetPath)) {
        Write-WarnMsg "Snippet gitignore nao encontrado — pulando"
        return
    }

    $snippet = Get-Content -LiteralPath $snippetPath -Raw -Encoding UTF8

    if (Test-Path -LiteralPath $gitignorePath) {
        $existing = Get-Content -LiteralPath $gitignorePath -Raw -Encoding UTF8
        if ($existing -and $existing.Contains($marker)) {
            Write-WarnMsg ".gitignore ja contem regras development-agents — skipping"
            return
        }
        Add-Content -LiteralPath $gitignorePath -Value ("`n" + $snippet.TrimEnd())
        Write-Ok "Regras development-agents adicionadas ao .gitignore"
    } else {
        Set-Content -LiteralPath $gitignorePath -Value $snippet.TrimEnd() -Encoding UTF8
        Write-Ok ".gitignore criado com regras development-agents"
    }
}


Write-Host ""
Write-Host "============================================================"
Write-Host "  development-agents - Installer"
Write-Host "============================================================"
Write-Host "  Source : $ScriptDir"
Write-Host "  Target : $TargetDir"
Write-Host "  Claude : $InstallClaude"
Write-Host "  Cursor : $InstallCursor"
Write-Host ""

foreach ($required in @("agents", "skills", "commands", "framework")) {
    $path = Join-Path $ScriptDir $required
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Invalid pack: missing $required/"
    }
}

# ── 1) Pack canonico ──────────────────────────────────────────────────────────
$PackDest = Join-Path $TargetDir "development-agents"
$SkipPackCopy = $false

if ($ScriptDir -eq $TargetDir) {
    # Hub repo: pack ja esta na raiz — so cria adapters
    $PackDest = $ScriptDir
    $SkipPackCopy = $true
    Write-Host "Hub detectado na raiz — pulando copia do pack"
    Write-Ok "pack na raiz (development-agents repo)"
} else {
    Write-Host "Installing pack -> development-agents/"
    New-Item -ItemType Directory -Force -Path $PackDest | Out-Null

    $items = @(
        "agents", "skills", "commands", "framework",
        "AGENTS.md", "MANIFEST.md", "README.md",
        "install.sh", "install.ps1"
    )

    foreach ($item in $items) {
        $src = Join-Path $ScriptDir $item
        if (-not (Test-Path -LiteralPath $src)) { continue }
        $dest = Join-Path $PackDest $item
        if (Test-Path -LiteralPath $src -PathType Container) {
            if (Test-Path -LiteralPath $dest) {
                Remove-Item -LiteralPath $dest -Recurse -Force
            }
            Copy-Item -LiteralPath $src -Destination $dest -Recurse -Force
        } else {
            Copy-Item -LiteralPath $src -Destination $dest -Force
        }
    }
    Write-Ok "development-agents/ sincronizado no projeto"
}

# ── 2) Claude ─────────────────────────────────────────────────────────────────
if ($InstallClaude) {
    Write-Host ""
    Write-Host "Installing Claude Code adapters (.claude/)..."
    $claudeRoot = Join-Path $TargetDir ".claude"
    New-Item -ItemType Directory -Force -Path (Join-Path $claudeRoot "commands") | Out-Null
    New-Item -ItemType Directory -Force -Path (Join-Path $claudeRoot "agents") | Out-Null
    New-Item -ItemType Directory -Force -Path (Join-Path $claudeRoot "skills") | Out-Null

    Copy-DirContents (Join-Path $ScriptDir "commands") (Join-Path $claudeRoot "commands")
    $cmdCount = @(Get-ChildItem -Path (Join-Path $claudeRoot "commands") -Filter "*.md" -File).Count
    Write-Ok "$cmdCount commands -> .claude/commands/"

    Copy-DirContents (Join-Path $ScriptDir "agents") (Join-Path $claudeRoot "agents")
    $agentCount = @(Get-ChildItem -Path (Join-Path $claudeRoot "agents") -Filter "*.md" -File).Count
    Write-Ok "$agentCount agents -> .claude/agents/"

    Get-ChildItem -Path (Join-Path $ScriptDir "skills") -Directory | ForEach-Object {
        $destSkill = Join-Path (Join-Path $claudeRoot "skills") $_.Name
        if (Test-Path -LiteralPath $destSkill) {
            Remove-Item -LiteralPath $destSkill -Recurse -Force
        }
        Copy-Item -LiteralPath $_.FullName -Destination $destSkill -Recurse -Force
        Write-Ok "  skill: $($_.Name) -> .claude/skills/"
    }
}

# ── 3) Cursor ─────────────────────────────────────────────────────────────────
if ($InstallCursor) {
    Write-Host ""
    Write-Host "Installing Cursor adapters (.cursor/)..."
    $cursorRoot = Join-Path $TargetDir ".cursor"
    New-Item -ItemType Directory -Force -Path (Join-Path $cursorRoot "agents") | Out-Null
    New-Item -ItemType Directory -Force -Path (Join-Path $cursorRoot "skills") | Out-Null
    New-Item -ItemType Directory -Force -Path (Join-Path $cursorRoot "rules") | Out-Null

    Copy-DirContents (Join-Path $ScriptDir "agents") (Join-Path $cursorRoot "agents")
    $agentCount = @(Get-ChildItem -Path (Join-Path $cursorRoot "agents") -Filter "*.md" -File).Count
    Write-Ok "$agentCount agents -> .cursor/agents/"

    Get-ChildItem -Path (Join-Path $ScriptDir "skills") -Directory | ForEach-Object {
        $destSkill = Join-Path (Join-Path $cursorRoot "skills") $_.Name
        if (Test-Path -LiteralPath $destSkill) {
            Remove-Item -LiteralPath $destSkill -Recurse -Force
        }
        Copy-Item -LiteralPath $_.FullName -Destination $destSkill -Recurse -Force
        Write-Ok "  skill: $($_.Name) -> .cursor/skills/"
    }

    $ruleFile = Join-Path $cursorRoot "rules\sdd-workflow.mdc"
    if ($SkipPackCopy) {
        $ruleContent = @"
---
description: Workflow SDD via development-agents - specs antes de codigo
alwaysApply: true
---

# SDD Workflow (development-agents)

Este repositorio e o pack development-agents (raiz).

## Pipeline

/sdd.start -> /sdd.spec -> /sdd.plan -> /sdd.build -> /sdd.check -> /sdd.finish

## Referencias

- Pack: AGENTS.md
- Commands: commands/ (tambem em .claude/commands/)
- Skills: .cursor/skills/
- Agents: .cursor/agents/
- Framework: framework/
"@
    } else {
        $ruleContent = @"
---
description: Workflow SDD via development-agents - specs antes de codigo
alwaysApply: true
---

# SDD Workflow (development-agents)

Este projeto usa o pack development-agents/.

## Pipeline

/sdd.start -> /sdd.spec -> /sdd.plan -> /sdd.build -> /sdd.check -> /sdd.finish

## Referencias

- Pack: development-agents/AGENTS.md
- Commands: development-agents/commands/ (tambem em .claude/commands/)
- Skills: .cursor/skills/
- Agents: .cursor/agents/
- Framework: development-agents/framework/
"@
    }
    Set-Content -LiteralPath $ruleFile -Value $ruleContent -Encoding UTF8
    Write-Ok "rule -> .cursor/rules/sdd-workflow.mdc"
}

# ── 4) sdd/ ───────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "Creating sdd/ working directories..."
$wip = Join-Path $TargetDir "sdd\wip"
$features = Join-Path $TargetDir "sdd\features"
New-Item -ItemType Directory -Force -Path $wip | Out-Null
New-Item -ItemType Directory -Force -Path $features | Out-Null
Write-Ok "sdd/wip/ e sdd/features/"

# ── 5) .gitignore (projeto alvo — pack local, nao versionar) ─────────────────
if (-not $SkipPackCopy) {
    Write-Host ""
    Write-Host "Updating .gitignore (pack e adapters locais)..."
    Ensure-Gitignore -TargetRoot $TargetDir
}

Write-Host ""
Write-Host "============================================================"
Write-Host "  development-agents instalado" -ForegroundColor Green
Write-Host "============================================================"
Write-Host ""
Write-Host "  Proximos passos:"
Write-Host "  1. Abra o projeto no Cursor ou Claude Code"
Write-Host "  2. Confirme: git status nao deve listar development-agents/, .cursor/, .claude/, sdd/"
Write-Host "  3. /sdd.project     (se ainda nao houver sdd/PROJECT.md)"
Write-Host "  4. checkout main/master + pull (manual)"
Write-Host '  5. /sdd.start "JIRA-1234 resumo da task"'
Write-Host '  6. /sdd.spec functional --include "<card ou link>"'
Write-Host ""
