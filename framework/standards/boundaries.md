# Agent Boundaries — Canonical Source

**Version**: 1.0.0  
**Purpose**: Single source of truth for what SDD agents **may**, **must ask about**, or **must never** do.  
**Used by**: All `/sdd.*` commands, specialized agents, and skills.

> **ONE RULE = ONE PLACE.** Other docs must **not** duplicate this list — only point here.

---

## When to read

| Trigger | Action |
|---------|--------|
| Start of **any** `/sdd.*` command | Scan the **decision tree** below (mandatory) |
| Before **Shell** that deletes, migrates, deploys, or changes git remotes | Read full **⚠️ Ask First** and **🚫 Never Do** tables |
| Before **commit/push** | Read **Git & commits** + **Secrets** |
| Delegating to **sdd-implementer**, **sdd-explorer**, **development-agents-installer**, **sdd-mcp-setup** | Include relevant section in the prompt |
| **Express mode** | Same rules — ⚠️ and 🚫 are **never** auto-waived |

---

## Decision tree

```
Is it in 🚫 Never Do? ──────────────► STOP (propose safe alternative)
Is it in ⚠️ Ask First? ─────────────► AskUserQuestion (include Outros) + explain impact
Is it standard dev work in scope? ──► Proceed
Uncertain? ─────────────────────────► Treat as ⚠️ Ask First
```

---

## ✅ Always Do (safe — no approval needed)

| Category | Allowed |
|----------|---------|
| **Read / search** | Read, Glob, Grep; `git log`, `git diff`, `git status`; list directories |
| **Build & test** | Project build/test commands from `sdd/PROJECT.md` (`mvn test`, `npm test`, etc.) |
| **Feature scope** | Edit production code and configs required by approved specs/tasks |
| **SDD artifacts** | Write/update files under active `sdd/wip/<feature>/` during the current phase |
| **Validation** | Run validators, linters, and code review tooling configured for the project |
| **Inference** | Mark unknowns as `UNKNOWN` instead of guessing (see `core-principles.md`) |

---

## ⚠️ Ask First (potentially destructive — human approval required)

Pause, explain **what** will be affected, and use `AskUserQuestion` (always include **Outros**).

| Category | Examples | Notes |
|----------|----------|-------|
| **File deletion** | `rm -rf`, `rm -r`, `del /s`, bulk delete | Include file count and paths |
| **Git destructive** | `git reset --hard`, `git clean -fd`, branch delete | Not force-push to protected branches — see 🚫 |
| **Git write** | `git add`, `git commit`, `git push` | Only when user explicitly requested commit/push |
| **Database schema/data** | `ALTER TABLE`, `DROP`, `TRUNCATE`, `DELETE` without narrow `WHERE`, migration on shared DB | Prefer migration tool + feature branch workflow |
| **Dependencies** | Add/remove packages, upgrade major versions | Verify against manifest/registry first |
| **Elevated privileges** | `sudo`, `su`, `runas` | Almost always unnecessary for SDD work |
| **Infra / deploy** | Deploy, release, push to staging/production | Agents implement code — humans deploy |
| **External write** | Jira transition, Confluence edit, MCP mutations | v1 MCP is read-only unless user explicitly enables write |
| **Branch switch** | Checkout with uncommitted changes | Warn about stash/loss risk |
| **Rollback / revert** | `/sdd.rollback`, reverting merged work | Snapshot + documented reason |
| **PR creation** | `gh pr create` | Only after human approves draft (`/sdd.pr` gate) |
| **Skip infra task** | Mark `INFRA-TASK-*` skipped | Never silent skip |
| **Overwrite project config** | Replace existing `sdd/PROJECT.md`, `.gitignore` wholesale | Append/merge preferred |

**Enforcement**: If human declines → propose a safer alternative. Log the request in the task/fix report when applicable.

---

## 🚫 Never Do (hard stops)

| ID | Category | Rule |
|----|----------|------|
| B-01 | **Filesystem** | `rm -rf /`, delete system paths, or wipe unrelated project directories |
| B-02 | **Git config** | Alter `git config` (local or global) |
| B-03 | **Git protected** | `git push --force` to `main`, `master`, or other protected branches |
| B-04 | **Secrets in repo** | Commit secrets, tokens, passwords, private keys, or local `.env` files |
| B-05 | **Secrets in code** | Hardcode credentials; output secrets to chat or logs |
| B-06 | **Database prod** | `DROP DATABASE`, `TRUNCATE` production tables, or unbounded `DELETE` on production |
| B-07 | **Tests anti-gaming** | During `/sdd.build` or `/sdd.fix`: edit, delete, rename, disable, or weaken **approved** tests (`tests-manifest.json`) to force green |
| B-08 | **Test skip markers** | Add `@Disabled`, `@Ignore`, `xit()`, `test.skip()`, `@pytest.mark.skip`, `t.Skip()` to pass build |
| B-09 | **SDD meta** | Delete `meta.md`; set `approved_by: "AI Agent"` (use `git config user.name` for human approver) |
| B-10 | **SDD pack in git** | Add `development-agents/`, `sdd/wip/`, or pack adapters to commit unless project policy says otherwise |
| B-11 | **Invention** | Invent dependency versions, SDK APIs, stack choices, or services not in code/`PROJECT.md` |
| B-12 | **MCP v1 write** | Transition Jira issues, edit Confluence, or invent OAuth/API credentials |
| B-13 | **Explorer write** | `sdd-explorer` must not create, edit, delete files, commit, or run builds/tests |
| B-14 | **Install overwrite** | Overwrite existing `sdd/PROJECT.md`, `sdd/backlog.md`, or custom `.cursor/` / `.claude/` content |
| B-15 | **Install scripts** | Run `install.ps1` / `install.sh` from the installer agent (use tool-based install) |
| B-16 | **Root agent files** | Create `AGENTS.md` or `CLAUDE.md` at project target root (would pollute git) |
| B-17 | **Unrequested scope** | Commit or modify files the user did not ask for |
| B-18 | **Working directory** | Run SDD workflow commands with cwd inside `.development-agents/` or pack hub only |

---

## Phase & role sections

Quick index — full rules are in the tables above.

### `/sdd.build`

- 🚫 B-07, B-08 — approved tests are immutable; detection: `commands/references/build-anti-gaming-detection.md`
- ✅ Implement approved tasks only; do not add new test files (that is `/sdd.test`)

### `/sdd.fix`

- 🚫 B-07, B-08 — same test immutability unless `/sdd.test --refine` re-opens tests
- 🚫 Fix code only when spec is wrong — update every impacted layer (procedure: `fix-anti-shortcut.md`)

### `/sdd.plan`

- 🚫 Generate deploy/release tasks: "Deploy to environment", "platform deploy", "Release version", "Push to staging/production"
- 🚫 "Investigate only" with no deliverable, unbounded refactors, test tasks that invent a lighter/skip path
- 🚫 Inventing prototype/MVP/production “modes” or skipping `/sdd.test`, security, or quality gates because a feature “feels experimental”

### `/sdd.finish`

- 🚫 B-09 — move `meta.md` **intact** to `sdd/features/`; never delete

### `/sdd.start`

- 🚫 B-03 — never force-push feature branches

### `/sdd.pr`

- ⚠️ `gh pr create` only after human approves PR draft in this command

### `development-agents-installer`

- 🚫 B-02, B-15, B-14, B-16; never commit/push unless user explicitly asks
- ⚠️ Append `.gitignore` snippet only — never replace entire file
- 🚫 Never delete custom `.cursor/` / `.claude/` content outside SDD scope
- 🚫 Blocker: do not finish install without updating target `.gitignore`

### `sdd-mcp-setup` / `/sdd.mcp`

- 🚫 B-12 — read-only v1; never invent OAuth/API credentials
- 🚫 Never install IDE plugins — print steps for the human
- 🚫 JetBrains *Jira Connector* plugin ≠ MCP for the AI agent
- 🚫 Never require a specific IDE — unknown host → generic wizard

### `sdd-explorer`

- 🚫 B-13 — read-only tools only (`Read`, `Glob`, `Grep`, read-only bash)

### `commit-workflow` skill

- 🚫 B-04, B-17 — see **Secrets**; never stage `graphify-out/` unless user asks

---

## Related (not duplicated here)

| Topic | Document |
|-------|----------|
| Pre-flight validation before commands | `pre-execution-checks.md` |
| Process mistakes (spec-first, vague AC) | `anti-patterns.md` |
| Quality standards (coverage, build) | `mandatory-standards.md` |
| Anti-hallucination behavior | `core-principles.md`, `AI_AGENT_GUIDELINES.md` |
| Governance philosophy | `governance.md` |
