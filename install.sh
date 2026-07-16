#!/usr/bin/env bash
# =============================================================================
# development-agents — Installer
#
# Exporta o pack SDD para um projeto alvo:
#   - development-agents/  (pack local)
#   - .claude/{commands,agents,skills}
#   - .cursor/{agents,skills} + rule mínima
#   - sdd/{wip,features}
#   - .gitignore             (ignora pack + adapters — repo limpo)
#
# Usage:
#   bash install.sh
#   bash install.sh /path/to/project
#   bash install.sh /path/to/project --claude-only
#   bash install.sh /path/to/project --cursor-only
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR=""
INSTALL_CLAUDE=true
INSTALL_CURSOR=true

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

ok()   { echo -e "  ${GREEN}✓${NC} $1"; }
warn() { echo -e "  ${YELLOW}⚠${NC} $1"; }
fail() { echo -e "  ${RED}✗${NC} $1"; exit 1; }

usage() {
  cat <<'EOF'
Usage:
  bash install.sh [target-dir] [--claude-only|--cursor-only]

Examples:
  bash install.sh
  bash install.sh ~/projects/meu-app
  bash install.sh ~/projects/meu-app --cursor-only
EOF
}

# ── Parse args ────────────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help) usage; exit 0 ;;
    --claude-only) INSTALL_CURSOR=false; shift ;;
    --cursor-only) INSTALL_CLAUDE=false; shift ;;
    -*)
      fail "Unknown flag: $1"
      ;;
    *)
      if [[ -z "$TARGET_DIR" ]]; then
        TARGET_DIR="$1"
      else
        fail "Unexpected argument: $1"
      fi
      shift
      ;;
  esac
done

TARGET_DIR="${TARGET_DIR:-$(pwd)}"
TARGET_DIR="$(cd "$TARGET_DIR" && pwd)"

echo ""
echo "============================================================"
echo "  development-agents — Installer"
echo "============================================================"
echo "  Source : $SCRIPT_DIR"
echo "  Target : $TARGET_DIR"
echo "  Claude : $INSTALL_CLAUDE"
echo "  Cursor : $INSTALL_CURSOR"
echo ""

[[ -d "$TARGET_DIR" ]] || fail "Target directory does not exist: $TARGET_DIR"
[[ -d "$SCRIPT_DIR/agents" ]] || fail "Invalid pack: missing agents/"
[[ -d "$SCRIPT_DIR/skills" ]] || fail "Invalid pack: missing skills/"
[[ -d "$SCRIPT_DIR/commands" ]] || fail "Invalid pack: missing commands/"
[[ -d "$SCRIPT_DIR/framework" ]] || fail "Invalid pack: missing framework/"

copy_dir_contents() {
  local src="$1"
  local dest="$2"
  mkdir -p "$dest"
  # shellcheck disable=SC2086
  cp -R "$src"/. "$dest"/
}

SKIP_PACK_COPY=false
PACK_DEST="$TARGET_DIR/development-agents"

if [[ "$SCRIPT_DIR" == "$TARGET_DIR" ]]; then
  SKIP_PACK_COPY=true
  PACK_DEST="$SCRIPT_DIR"
  echo "Hub detectado na raiz — pulando copia do pack"
  ok "pack na raiz (development-agents repo)"
else
  echo "Installing pack → development-agents/"
  mkdir -p "$PACK_DEST"

  for item in agents skills commands framework AGENTS.md MANIFEST.md README.md; do
    if [[ -e "$SCRIPT_DIR/$item" ]]; then
      if [[ -d "$SCRIPT_DIR/$item" ]]; then
        rm -rf "$PACK_DEST/$item"
        cp -R "$SCRIPT_DIR/$item" "$PACK_DEST/$item"
      else
        cp "$SCRIPT_DIR/$item" "$PACK_DEST/$item"
      fi
    fi
  done

  cp "$SCRIPT_DIR/install.sh" "$PACK_DEST/install.sh" 2>/dev/null || true
  if [[ -f "$SCRIPT_DIR/install.ps1" ]]; then
    cp "$SCRIPT_DIR/install.ps1" "$PACK_DEST/install.ps1"
  fi

  ok "development-agents/ sincronizado no projeto"
fi

echo ""
if [[ "$INSTALL_CLAUDE" == true ]]; then
  echo ""
  echo "Installing Claude Code adapters (.claude/)..."
  mkdir -p "$TARGET_DIR/.claude/commands"
  mkdir -p "$TARGET_DIR/.claude/agents"
  mkdir -p "$TARGET_DIR/.claude/skills"

  copy_dir_contents "$SCRIPT_DIR/commands" "$TARGET_DIR/.claude/commands"
  CMD_COUNT=$(find "$TARGET_DIR/.claude/commands" -maxdepth 1 -name '*.md' | wc -l | tr -d ' ')
  ok "$CMD_COUNT commands → .claude/commands/"

  copy_dir_contents "$SCRIPT_DIR/agents" "$TARGET_DIR/.claude/agents"
  AGENT_COUNT=$(find "$TARGET_DIR/.claude/agents" -maxdepth 1 -name '*.md' | wc -l | tr -d ' ')
  ok "$AGENT_COUNT agents → .claude/agents/"

  for skill_dir in "$SCRIPT_DIR/skills"/*/; do
    [[ -d "$skill_dir" ]] || continue
    skill_name="$(basename "$skill_dir")"
    rm -rf "$TARGET_DIR/.claude/skills/$skill_name"
    cp -R "$skill_dir" "$TARGET_DIR/.claude/skills/$skill_name"
    ok "  skill: $skill_name → .claude/skills/"
  done
fi

# ── 3) Cursor adapters ────────────────────────────────────────────────────────
if [[ "$INSTALL_CURSOR" == true ]]; then
  echo ""
  echo "Installing Cursor adapters (.cursor/)..."
  mkdir -p "$TARGET_DIR/.cursor/agents"
  mkdir -p "$TARGET_DIR/.cursor/skills"
  mkdir -p "$TARGET_DIR/.cursor/rules"

  copy_dir_contents "$SCRIPT_DIR/agents" "$TARGET_DIR/.cursor/agents"
  AGENT_COUNT=$(find "$TARGET_DIR/.cursor/agents" -maxdepth 1 -name '*.md' | wc -l | tr -d ' ')
  ok "$AGENT_COUNT agents → .cursor/agents/"

  for skill_dir in "$SCRIPT_DIR/skills"/*/; do
    [[ -d "$skill_dir" ]] || continue
    skill_name="$(basename "$skill_dir")"
    rm -rf "$TARGET_DIR/.cursor/skills/$skill_name"
    cp -R "$skill_dir" "$TARGET_DIR/.cursor/skills/$skill_name"
    ok "  skill: $skill_name → .cursor/skills/"
  done

  # Rule mínima: aponta para o pack e o pipeline
  RULE_FILE="$TARGET_DIR/.cursor/rules/sdd-workflow.mdc"
  if [[ "$SKIP_PACK_COPY" == true ]]; then
    cat > "$RULE_FILE" <<'EOF'
---
description: Workflow SDD via development-agents — specs antes de código
alwaysApply: true
---

# SDD Workflow (development-agents)

Este repositório é o pack development-agents (raiz).

## Pipeline

`/sdd.start` → `/sdd.spec` → `/sdd.plan` → `/sdd.test` → `/sdd.build` → `/sdd.check` → `/sdd.finish`

## Referências

- Pack: `AGENTS.md`
- Commands: `commands/` (também em `.claude/commands/`)
- Skills: `.cursor/skills/`
- Agents: `.cursor/agents/`
- Framework: `framework/`
EOF
  else
    cat > "$RULE_FILE" <<'EOF'
---
description: Workflow SDD via development-agents — specs antes de código
alwaysApply: true
---

# SDD Workflow (development-agents)

Este projeto usa o pack `development-agents/`.

## Pipeline

`/sdd.start` → `/sdd.spec` → `/sdd.plan` → `/sdd.test` → `/sdd.build` → `/sdd.check` → `/sdd.finish`

## Referências

- Pack: `development-agents/AGENTS.md`
- Commands: `development-agents/commands/` (também em `.claude/commands/`)
- Skills: `.cursor/skills/`
- Agents: `.cursor/agents/`
- Framework: `development-agents/framework/`
EOF
  fi
  ok "rule → .cursor/rules/sdd-workflow.mdc"
fi

# ── 4) Working dirs sdd/ ──────────────────────────────────────────────────────
echo ""
echo "Creating sdd/ working directories..."
mkdir -p "$TARGET_DIR/sdd/wip"
mkdir -p "$TARGET_DIR/sdd/features"
ok "sdd/wip/ e sdd/features/"

# ── 5) .gitignore (projeto alvo — pack local, não versionar) ─────────────────
if [[ "$SKIP_PACK_COPY" == false ]]; then
  echo ""
  echo "Updating .gitignore (pack e adapters locais)..."
  GITIGNORE="$TARGET_DIR/.gitignore"
  MARKER="# development-agents pack (instalacao local"
  SNIPPET="$SCRIPT_DIR/framework/templates/project-gitignore.snippet"

  if [[ -f "$SNIPPET" ]]; then
    if [[ -f "$GITIGNORE" ]] && grep -qF "$MARKER" "$GITIGNORE"; then
      warn ".gitignore já contém regras development-agents — skipping"
    elif [[ -f "$GITIGNORE" ]]; then
      { echo ""; cat "$SNIPPET"; } >> "$GITIGNORE"
      ok "Regras development-agents adicionadas ao .gitignore"
    else
      cp "$SNIPPET" "$GITIGNORE"
      ok ".gitignore criado com regras development-agents"
    fi
  else
    warn "Snippet gitignore não encontrado — pulando"
  fi
fi

# ── Done ──────────────────────────────────────────────────────────────────────
echo ""
echo "============================================================"
echo -e "  ${GREEN}✓ development-agents instalado${NC}"
echo "============================================================"
echo ""
echo "  Próximos passos:"
echo "  1. Abra o projeto no Cursor ou Claude Code"
echo "  2. /sdd.project     (se ainda não houver sdd/PROJECT.md)"
echo "  3. checkout main/master + pull (manual)"
echo "  4. /sdd.start \"JIRA-1234 resumo da task\""
echo "  5. /sdd.spec functional --include \"<card ou link>\""
echo ""
