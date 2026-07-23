# development-agents

Hub do time de agents SDD — **language- and platform-agnostic**.  
Não é um app: é o pack exportável de workflow Spec-Driven Development.

## Stack resolution

Stack, linguagem e infra **nunca** vêm de defaults corporativos neste pack. Resolva a partir do **projeto alvo**:

1. `framework/tools/detect-language.sh`
2. `framework/tools/detect-stack.sh`
3. `sdd/PROJECT.md` no repo alvo
4. Código e technical spec existentes

Suporte multi-linguagem (Java, TypeScript, Go, Python, Rust, mobile) é via **detecção**, não via hardcoding.

## Estrutura (este repositório)

O repo **é** o pack — sem subpasta:

```
development-agents/          ← raiz do git (clone = pack pronto)
├── install.sh / install.ps1
├── AGENTS.md
├── MANIFEST.md
├── FLUXOS-FEATURE-E-FIX.md  ← guia: fluxo Feature vs fluxo Fix (bug)
├── SUGESTAO-MODELOS.md      ← dica informativa de modelo forte/barato
├── agents/
├── skills/
├── commands/
└── framework/
```

## Instalar em um projeto alvo

Duas formas — mesmo resultado:

| Método | Quando usar |
|--------|-------------|
| **Script** (`install.ps1` / `install.sh`) | Máquina permite executar scripts |
| **Agente** (`/sdd.install`) | Script bloqueado ou prefere instalar via chat |

### Opção A — Script

Clone este repo e rode o instalador **da raiz** apontando para o projeto alvo:

**PowerShell (Windows):**

```powershell
.\install.ps1 -TargetDir "E:\Projects\meu-app"
# só Cursor:
.\install.ps1 -TargetDir "E:\Projects\meu-app" -CursorOnly
# só Claude Code:
.\install.ps1 -TargetDir "E:\Projects\meu-app" -ClaudeOnly
```

**Bash (Git Bash / WSL / macOS / Linux):**

```bash
bash install.sh /path/to/meu-app
bash install.sh /path/to/meu-app --cursor-only
bash install.sh /path/to/meu-app --claude-only
```

### Opção B — Agente (sem script)

1. Clone ou copie este repo para o projeto (ou rode `/sdd.install` a partir do clone).
2. Abra o projeto alvo no Cursor ou Claude Code.
3. No chat:

```
/sdd.install
/sdd.install --cursor-only
/sdd.install --target E:\Projects\meu-app
```

O agente `development-agents-installer` cria as mesmas pastas que o script — **sem** rodar `install.ps1` nem `install.sh`.

**Primeira vez (bootstrap):** se ainda não tem `.cursor/` nem `.claude/`, use no chat:

```
Siga development-agents/commands/sdd.install.md e instale o pack neste projeto.
```

(Se o pack está na **raiz** do workspace aberto, use `commands/sdd.install.md`.)

Depois da primeira instalação, `/sdd.install` passa a funcionar normalmente.

### O que é criado no projeto alvo

O instalador cria/atualiza **localmente** (não commita nada):

| Destino | Conteúdo |
|---------|----------|
| `development-agents/` | Pack canônico |
| `.claude/commands\|agents\|skills` | Adapter Claude Code |
| `.cursor/agents\|skills` + rule | Adapter Cursor |
| `sdd/wip`, `sdd/features` | Working dirs SDD |
| `.gitignore` | **Append** se já existir; **cria** se não existir |

O agente/instalador **nunca** roda `git commit`. Só você commita se quiser — inclusive o `.gitignore` atualizado.

Depois:

1. `/sdd.project` (se não houver `sdd/PROJECT.md`)
2. `/sdd.reverse-eng` (brownfield — uma vez por serviço)
3. checkout `main`/`master` + pull (manual)
4. Abrir o card com `/sdd.start "JIRA-1234 resumo"`
5. Seguir o fluxo certo — ver [`FLUXOS-FEATURE-E-FIX.md`](./FLUXOS-FEATURE-E-FIX.md):
   - **Feature** → `spec → plan → test → build → finish → pr`
   - **Bug** → `fix → finish → pr`
6. Playbook completo: [`framework/PLAYBOOK.md`](./framework/PLAYBOOK.md)

## Origem

Export seletivo do núcleo SDD — sem skills de produto específico.  
Detalhes: [MANIFEST.md](./MANIFEST.md).
