# ADR-0001: Agent/Skill/Execution-Requirement Architecture

**Status**: Accepted
**Date**: 2026-08-13

## Problem

The pack originally shipped 12 dedicated Claude Code "Agent" files under `agents/`, each a standalone
identity with its own `tools:`/`model:`/`isolation:` frontmatter and a large behavioral prompt, invoked
via `Task(subagent_type="sdd-<name>", ...)`. Two problems followed from this:

1. **Core-to-harness coupling.** The pack's stated goal is harness-agnostic core + per-harness adapters,
   but the Agent packaging format itself (`tools:`/`model:`/`isolation:` frontmatter, `Task(subagent_type=...)`
   call syntax) is Claude-Code/Cursor-native. Codex CLI never installed the `agents/` folder at all — it only
   referenced the files as plain text — while Skills (`SKILL.md`) already install natively on Claude Code,
   Cursor, and Codex CLI (`agentskills.io`) with no translation loss.
2. **Conflated concerns.** "Needs a fresh, isolated execution context" (a real technical requirement for
   some roles) had been implicitly treated as "needs a dedicated named Agent identity" (a packaging choice),
   without verifying whether the identity itself was doing any work the context isolation wasn't already doing.

## Alternatives Considered

- **Keep all 12 as Agents.** Rejected — carries the coupling problem above indefinitely, and duplicates
  frontmatter maintenance across 12 files whose actual differentiator (in most cases) is content, not
  permission boundary.
- **Collapse everything to inline Skills, no offload ever.** Rejected — several roles (heavy codebase
  exploration, cross-layer analysis, deep debugging, architecture research, the independent validator)
  generate enough intermediate tool output that inlining them would flood the calling session's context,
  as directly observed when running `sdd-explorer`'s protocol.
- **Skill content + capability-named execution requirement, with the concrete mechanism left to each
  harness adapter.** Adopted.

## Experiments Run (this session, on the live harness)

All of the following were executed, not inferred:

1. A generic read-only worker, given `sdd-explorer`'s and `sdd-layer-analysis`'s content ad hoc, produced
   correctly-formatted compact reports and returned only the summary to the calling session — confirming
   `OFFLOAD_READ` does not require a dedicated named Agent.
2. The same worker attempted `touch`/`echo >`/`rm` via `Bash` despite having no `Write`/`Edit` tool, and
   **all five commands succeeded**. This disproves any claim that "no Write/Edit" is a filesystem-level
   read-only guarantee — it never was, for the original Agent files either (`sdd-explorer` always had
   `Bash`). The guarantee is behavioral, not sandboxed.
3. A generic worker invoked with a per-call `model` override (haiku) and a scrubbed, rationale-free prompt
   produced a valid structured verdict, confirming fresh-context + scrubbed-prompt sufficiency for
   validator-style isolation, independent of agent identity.
4. A dedicated attempt to pass `tools`/`allowed_tools`/`disallowed_tools` as call-time parameters was
   accepted syntactically but had **no effect** — a `Write` call explicitly disallowed still succeeded.
   This is the one hypothesis that did **not** hold: dynamic per-call tool restriction is not available on
   this harness today. Tool-permission boundaries only exist via named worker *types* with fixed grants
   (e.g. a built-in read-only-shaped type), not via arbitrary per-call configuration.
5. `isolation: "worktree"`-equivalent (a per-call parameter, not frontmatter) produced a real, separate git
   worktree, confirmed via `git worktree list`, and a real file write inside it did not leak into the main
   checkout.

## Decision

- **Core** (`skills/`, `commands/`, `framework/`) expresses only **intent and guarantees**, never a
  harness-specific mechanism. All 12 former Agent roles are now Skills.
- **Execution requirements** are named, harness-agnostic capabilities declared by each Skill:
  `OFFLOAD_READ`, `OFFLOAD_REASONING`, `INTERACTIVE_OFFLOAD`, `VALIDATOR_ISOLATED` (new this round),
  alongside the pre-existing `DELEGATE_ISOLATED`, `DELEGATE_OFFLOAD`, `ISOLATED_WORKSPACE`, `ASK_USER`,
  `CONTINUE_WORKFLOW`, `INVOKE_PROCEDURE`, `WRITE_PROJECT_INSTRUCTIONS`. Full definitions and per-harness
  translation tables live in `framework/_shared/harness-capabilities.md`.
- **Adapters** (`adapters/<harness>/README.md`) are the only place a concrete mechanism — a named worker
  type, a dedicated agent file, a manual fresh session — is allowed to appear. `agents/` no longer exists
  as a pack concept; if a harness needs a literal named-agent file to satisfy a capability, that file is
  the adapter's problem to generate, not the core's problem to author and maintain.
- **`sdd-implementation`** and **`sdd-test-writing`** remain separate Skills (never merged in content)
  despite sharing the identical `ISOLATED_WORKSPACE` execution profile — their behavior differs
  (implementation vs. tests-first), and test immutability was never protected by identity separation to
  begin with (it's protected by pipeline ordering + `VALIDATOR_ISOLATED` process compliance).
  `sdd-large-test-writer` is absorbed into `sdd-test-writing` as a lazy-loaded E2E branch, gated on the
  same trigger conditions it always had (`E2E-N` in spec + `testing.e2e.enabled`).
- **`sdd-validator-runner`'s behavior** is merged into the pre-existing `skills/sdd-validator/SKILL.md` as
  an "Isolated Mode" section, rather than kept as a separate identity or a second Skill file. Nothing in
  its validation rules, severity tables, process-compliance checks, or verdict contract was reduced.

## Consequences

- **Positive**: `agents/` folder eliminated (12 → 0 files); Skills now install natively on Codex CLI where
  they previously did not; frontmatter duplication across 12 files eliminated; the `OFFLOAD_*` capabilities
  make explicit which Skills carry a real context-isolation need versus which are safe to run inline.
- **Negative / accepted trade-off**: the honest limit uncovered by experiment 2 above — "no mutation of
  production" is a behavioral + audited guarantee, not a sandbox, on every harness tested — was already
  true before this refactor. This ADR does not introduce that gap; it makes it explicit instead of implicit.
- **Open item**: whether `sdd-implementation`/`sdd-test-writing` can safely share a single *named* worker
  profile on Claude Code (as opposed to two independent per-call configurations) was not tested end-to-end
  (worktree isolation and a real code write were tested separately, not together in one combined
  implementation-plus-test-writing run). Treat as unverified until confirmed.

## Gaps by Harness (see `framework/_shared/harness-capabilities.md` for full detail)

| Harness | `VALIDATOR_ISOLATED` | `OFFLOAD_READ`/`OFFLOAD_REASONING` | `INTERACTIVE_OFFLOAD` | `ISOLATED_WORKSPACE` |
| --- | --- | --- | --- | --- |
| Claude Code | Full (tested) | Full (tested) | Full (tested) | Full (tested) |
| Cursor | Partial — degrades to a fresh tab, manual scrub/paste | Full via inline fallback (no isolation loss, no integrity requirement) | Partial — degraded `ASK_USER` | Full, async only |
| Codex CLI | Partial — manual fresh session by default, real subagents optional and unverified | Full via `/agent` or inline | Partial — plain-text fallback | Not supported — sequential only |
| Generic | Fallback — manual operator procedure | Full via inline fallback | Fallback — plain-text | Not supported |

## Why Behavior Lives in Skills, Not Agents

A Skill is portable Markdown content with no harness-specific packaging requirement. An "Agent" identity
(frontmatter `tools:`/`model:`/`isolation:` + a `subagent_type` name) is only useful when a harness needs a
named, fixed-permission worker type to satisfy a real technical guarantee. This session's experiments found
exactly one class of guarantee that fits that description on Claude Code today — a fixed tool-permission
grant, because per-call tool restriction does not exist — and even that is satisfied by the harness's
existing generic worker types, not by authoring new dedicated agent files. Everything else (fresh context,
model selection, workspace isolation) is available as a call-time parameter, independent of identity.

## Why Workers/Agents Are the Adapter's Responsibility

Different harnesses have different native answers to "give me an isolated execution context": Claude Code
has synchronous subagent dispatch with call-time overrides; Cursor has only asynchronous Background Agents;
Codex CLI has both a native Skill format and an optional, unverified custom-agent mechanism; a fully generic
harness has none of these and relies on a human manually opening a fresh session. None of that variability
belongs in a Skill file that is supposed to be identical Markdown on every harness — it belongs in the one
place designed to hold harness-specific translation: the adapter.
