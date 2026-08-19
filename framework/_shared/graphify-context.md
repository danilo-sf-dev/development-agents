# Reference: Graphify — Optional Code Graph Context

**Used by**: `/sdd.start` (preflight), `/sdd.spec`, `/sdd.plan`, `/sdd.build`, `/sdd.check`,
`/sdd.reverse-eng` (preflight + query-first exploration + refresh), `/sdd.finish` (cleanup), and
`skills/commit-workflow/SKILL.md` (opportunistic refresh before commit). This is the **single
source of truth** for every Graphify mechanic in the SDD pipeline — commands reference this
file by name instead of repeating detection/preflight/git-safety/query/cleanup logic inline. If
you find Graphify commands or rules duplicated inline in a command file, that is a bug in that
file, not a documented exception.

---

## What Graphify is here

Graphify is an **optional, local, disposable structural index** of the target codebase — a
pre-built graph of modules/classes/dependencies that lets an agent ask "where is X" via a
query instead of `Glob → Grep → Read → Read → Read → …`. It is an accelerator, never a
dependency:

- The SDD pipeline **must function 100% identically with Graphify completely absent.**
- Nothing in this mechanism is ever installed automatically — no `pip install`, `uv tool
  install`, `npm install`, `winget`/`choco`/`brew`/`apt`, no API key prompt, **ever**, without
  an explicit per-command confirmation from the user (see § 4).
- Nothing in this mechanism requires Python **as an SDD dependency**. Graphify's own
  installation may happen to be a Python package on some machines — that is Graphify's
  implementation detail, not something the SDD framework depends on. If neither a `graphify`
  binary nor a working `python`/`python3 -m graphify` exists, Graphify is simply unavailable.
- `graphify-out/` is treated as **local, disposable cache** — never committed, never shared
  across branches, never a permanent artifact — regardless of what Graphify's own upstream
  documentation says is possible. This is this SDD Kit's own policy choice, not a Graphify
  requirement.
- **The user decides, explicitly, every time a graph would be created or refreshed.** Nothing
  in this mechanism runs `extract` or `update` just because Graphify happens to be available —
  see § 4 for the exact questions asked and § 5 for why this doesn't mean asking on every phase.

## Execution principle: GRAPH FIRST → SOURCE SECOND

When `GRAPHIFY_MODE=active` and `GRAPHIFY_GRAPH=ready` for the current flow (§ 5), the
exploration order for the commands listed above is:

1. Consult the graph for structural orientation (`query` / `path` / `explain`).
2. Identify the small set of files/classes/methods actually relevant.
3. Open only those source files with `Read`.
4. Use `Grep`/`Glob` as fallback or confirmation, not as the first, indiscriminate strategy.

Graphify **orients** exploration; it never substitutes for reading real code when
implementation or validation needs evidence. `/sdd.build` still edits and reads actual source;
`/sdd.check` still runs real validators. The graph narrows *where to look*, not *what to trust*.

This does not apply to `/sdd.test` (test-writing is spec/AC-driven, not exploration-driven),
`/sdd.finish` (no exploration phase), or purely documentational operations.

---

## 1. Detection

Detection and capability probing are handled entirely by one script — commands never
reimplement this logic:

```bash
bash development-agents/framework/tools/detect-graphify.sh
```

Output (KEY=value lines, always exit 0):

```
GRAPHIFY_AVAILABLE=true|false
GRAPHIFY_CMD=<human-readable resolved command — DISPLAY ONLY, never invoke this directly>
GRAPHIFY_EXEC=<the executable — safe to invoke ONLY as a single quoted token>
GRAPHIFY_ARGS=<prefix args, space-joined, safe to `read -ra` — "" or "-m graphify">
GRAPHIFY_CODE_ONLY=true|unknown|false
GRAPHIFY_QUERY=true|false
GRAPHIFY_PATH=true|false
GRAPHIFY_EXPLAIN=true|false
GRAPHIFY_UPDATE=true|false
```

**Resolution is a real-execution cascade, not a presence check.** `command -v` finding a name
on PATH is never sufficient by itself — real-machine testing found `command -v graphify`
succeeding (a `uv`-installed launcher/trampoline script exists) while `graphify --version`
itself failed (the trampoline's underlying venv was broken). The winner is whichever tier is
the **first to actually run `--version` successfully**; every tier is attempted only if the
previous one didn't already produce a working command — none of them is "the Windows path" or
"the Python path" by assumption, each is simply tried in order until something really runs:

| Tier | Condition | `GRAPHIFY_EXEC` | `GRAPHIFY_ARGS` |
| --- | --- | --- | --- |
| A | `graphify` on PATH AND `graphify --version` actually succeeds | `graphify` | *(empty)* |
| B | Tier A failed AND `cmd.exe` is reachable (`command -v cmd.exe` — Git Bash/MSYS/Cygwin/WSL-interop, never an OS-name check): ask it where a `graphify` executable really lives (`cmd.exe //c where graphify`), resolve each candidate to something bash can exec (`cygpath`/`wslpath` when available), and try `--version` on each until one really succeeds | the resolved absolute executable path (may contain spaces) | *(empty)* |
| C | Tiers A/B failed AND `python` on PATH AND `python -m graphify --version` actually succeeds | `python` | `-m graphify` |
| D | Tiers A/B/C failed AND `python3` on PATH AND `python3 -m graphify --version` actually succeeds | `python3` | `-m graphify` |
| E | none of the above | *(empty)* | *(empty)* — `GRAPHIFY_AVAILABLE=false` |

Tier B is what recovers from tier A's uv-trampoline failure: `where` finds the real
`graphify.exe` installed alongside/instead of the broken launcher, and running that real
executable directly works even though the PATH-resolved `graphify` command did not. A machine
with no `cmd.exe` skips tier B entirely and falls straight to C; a machine with `cmd.exe` but
no matching Windows executable falls through to C/D exactly the same way tier A's failure does.
Python (tiers C/D) is Graphify's own interpreter dependency on some installs — never an SDD
framework requirement; PowerShell, `uv`, and `jq` are never required by any tier either.

### Invocation — the one canonical, safe way to run Graphify

A resolved tier B path can contain a space (a real case: `C:\Users\Jane Doe\.local\bin\
graphify.exe`). A single flattened string cannot represent "one argument that contains a
space" without something to interpret its quoting — no amount of quoting discipline at an
individual call site fixes that once executable and args have been joined into one unquoted
string. So **`GRAPHIFY_CMD` is display-only. Never build a command from it — never do
`$GRAPHIFY_CMD <args>`, anywhere, for any reason.**

The safe primitives are the two separate fields, `GRAPHIFY_EXEC` and `GRAPHIFY_ARGS` — but no
caller should even reconstruct an invocation from those two fields by hand either. There is
**one canonical wrapper**, and every command file, skill, or ad-hoc script that needs to run
Graphify shells out to it instead:

```bash
bash development-agents/framework/tools/graphify-run.sh <graphify-subcommand-or-flag> [args...]
```

Examples:

```bash
bash development-agents/framework/tools/graphify-run.sh extract . --code-only
bash development-agents/framework/tools/graphify-run.sh update .
bash development-agents/framework/tools/graphify-run.sh query "payment calculation flow" --budget 1500
bash development-agents/framework/tools/graphify-run.sh path Foo Bar
```

`graphify-run.sh` re-resolves `GRAPHIFY_EXEC`/`GRAPHIFY_ARGS` itself (in its own process — no
array is ever serialized to text and re-parsed across a process boundary; `GRAPHIFY_ARGS` is
safe to `read -ra` back into an array specifically because it is only ever `""` or the literal
`-m graphify`, both fully controlled, neither containing whitespace itself) and execs with
real bash array semantics — `"$EXEC" "${PREFIX_ARGS[@]}" "$@"` — no `eval`, anywhere. Every
argument given to `graphify-run.sh` reaches the real Graphify invocation exactly as given,
whether that's a single multi-word quoted argument (`query "payment calculation flow"`) or
several separate ones (`path Foo Bar`). It passes through the real invocation's exit code, and
exits `127` with a short diagnostic if Graphify could not be resolved at all — callers should
already have checked `GRAPHIFY_AVAILABLE` before ever reaching it; this is a backstop, not the
primary availability check, and it never blocks the wider SDD pipeline, only that one call.

`GRAPHIFY_CODE_ONLY` is a tri-state (`true`/`unknown`/`false`), not a plain boolean — see § 3
for why, and why only `false` withholds bootstrap (`unknown` proceeds to the real test in § 4
Step 4.2). Do not try to work around a `false`/`unknown` result with an API key or a different
extraction mode either way.

## 2. Repository protection — the mandatory guard

**Order is mandatory, before ANY of `extract`/`update`/`query`/`path`/`explain`, every single
time — not only before the first extract, and not skipped just because `graphify-out/` already
existed before this SDD flow started:**

```
PROTECT GIT → VALIDATE IGNORE → USE GRAPHIFY
```

This is one script, always run first:

```bash
bash development-agents/framework/tools/graphify-git-guard.sh [--gitignore]
```

- Uses a **real git check** (`git check-ignore`), never a text search inside `.gitignore`.
- Unstages any already-staged `graphify-out/` path **before** validating ignore status — a
  tracked/staged path is reported as "not ignored" by `git check-ignore` regardless of exclude
  rules, so staging must be corrected first or the check gives a false negative.
- **Scenario A (default, no flag)** — Graphify/`graphify-out/` pre-existed this SDD flow (the
  project already had it before `/sdd.start` or `/sdd.reverse-eng` touched anything): only
  `.git/info/exclude` is written. The project's own `.gitignore` is never edited automatically
  just because Graphify was detected.
- **Scenario B (`--gitignore`)** — the user explicitly chose, via the preflight ASK_USER (§ 4),
  to install/configure Graphify through this SDD flow: `.gitignore` is also updated (only if it
  doesn't already cover `graphify-out/`), because the user's own choice to bring Graphify into
  the project makes the ignore rule worth sharing with the team. Any other line in an existing
  `.gitignore` is left untouched.
- Output: `GUARD_PROTECTED=true|false`, `GUARD_STAGED_CORRECTED=true|false`. Exit 0 only when
  protected. **If it exits nonzero, do not proceed with the Graphify CLI call** — treat
  Graphify as unavailable for that specific call and fall back to normal Read/Grep/Glob. This
  never blocks the wider SDD pipeline; it only withholds that one Graphify invocation.
- If `graphify-out/` ever shows up staged for any other reason, this guard is what corrects it:
  unstage **only** `graphify-out/` paths (`git restore --staged` / `git reset --`), never touch
  any other file, never `git clean`/`git reset --hard`.

Every section below that says "run `graphify-run.sh ...`" implies "run the guard first" — this
is not repeated at every call site in prose, but it is not optional.

## 3. Capability check — not a version gate

Different Graphify releases have shown different flag support in practice, so this mechanism
checks **capability**, not a hardcoded minimum version — see § 1's `GRAPHIFY_CODE_ONLY` /
`GRAPHIFY_QUERY` / `GRAPHIFY_PATH` / `GRAPHIFY_EXPLAIN` / `GRAPHIFY_UPDATE` fields, each a
best-effort probe of that installed version's own `--help` output.

**`GRAPHIFY_CODE_ONLY` is a tri-state, not a boolean — `true | unknown | false`.** Real-machine
testing found `extract --help` text that never mentions `--code-only` on an install where
`extract . --code-only` itself worked perfectly. Help text is not a reliable oracle for this
one flag, so a missing mention means **`unknown`, not `false`**:

- `true` — `extract --help` responded and explicitly documents `--code-only`.
- `unknown` — `extract --help` responded (the `extract` subcommand exists) but doesn't mention
  `--code-only` either way. The flag may still work — this script does not know, and it never
  runs `extract . --code-only` itself just to find out (that would create/alter
  `graphify-out/` in the target project as a side effect of a detection probe, which this
  mechanism never does outside an explicit user decision — see § 4).
- `false` — `extract --help` itself did not respond cleanly. No confirmed path to `extract` at
  all, so none to a code-only graph either.

**`unknown` never blocks the preflight.** Only `false` does. The actual, definitive capability
test is the real `extract . --code-only` call the user authorizes in Step 4.2 — its own exit
code is ground truth, confirmed or refuted in real time, never assumed in advance from static
`--help` text.

### HTML / visualization output — UNVERIFIED, not implemented

A real corporate E2E confirmed Graphify 0.9.45 and the working `extract . --code-only` path
(378 files, 2339 nodes, no API key). It did **not** confirm any HTML/visualization flag or
subcommand — no session with a real Graphify install has yet run `graphify --help` or `graphify
extract --help` to see whether `--html` (or any visualization flag) actually exists on that
version, on `extract`, on a separate subcommand, or at all.

**Status: UNVERIFIED.** This mechanism deliberately does not implement, document as available,
or offer HTML/visualization support until a session with real Graphify access runs those two
`--help` commands and records the actual output here. Do not guess a flag name from the CLI
conventions of other tools, from what a user request describes wanting, or from what "seems
likely" for a 0.9.x CLI — every other command in this file is grounded in a real, observed
`--help`/`--version` response (§ 1's detection cascade, § 3's tri-state above); this is the one
capability where that evidence does not yet exist, so it stays undocumented rather than invented.

When a future session verifies the real syntax, wire it in following the same shape already
established here, not a new mechanism:
- If Graphify can render HTML **from the existing `graph.json`** (no re-extraction) — e.g. a
  separate `graphify visualize`/`graphify render`-style subcommand, or an `extract` flag that
  operates on cached output — prefer that path exclusively. **Never run a second full `extract`
  call just to obtain HTML** — `graph.json` from the one `--code-only` extraction already run
  (§ 4 Step 4.2) is the only extraction this mechanism performs per flow.
- Add the confirmed flag/subcommand to `detect-graphify.sh`'s capability probes (same tri-state
  pattern as `GRAPHIFY_CODE_ONLY` if the real behavior turns out to need one) — never invoke it
  from `graphify-context.md` prose directly without a corresponding detection field, the same
  discipline every other capability here already follows.
- Keep `graphify-out/graph.json` as the one deterministic readiness signal (§ 4 below) — an HTML
  artifact, if one is ever produced, is an optional additional output alongside it, never a
  replacement for it and never itself checked for readiness.

Until then: **the proven `extract . --code-only` → `graph.json` path is the only supported
mechanism.** No command file, skill, or reference should mention `--html` or any other
visualization flag as if it were confirmed working.

---

## 4. Preflight — the only place ASK_USER happens for setup decisions

Runs **once per flow**: in `/sdd.start`, after the feature branch exists (its Step 9); or, for
a standalone run with no feature branch, at the start of `/sdd.reverse-eng`. Every gate below
is `ASK_USER` per `framework/_shared/harness-capabilities.md` — degrades per-harness exactly
like every other gate in this pipeline; no Claude/Codex-specific logic lives here or anywhere
in core.

### Step 4.1 — Absence

```
detect-graphify.sh → GRAPHIFY_AVAILABLE?
  true, GRAPHIFY_CODE_ONLY=true or unknown  → go to Step 4.2 (unknown is NOT a block —
                                                see § 3; the real test happens in Step 4.2)
  false, or GRAPHIFY_CODE_ONLY=false
    ↓
  graphify-state.sh pref-get <repo>/.git/sdd-graphify-pref → DONT_ASK_ABSENT?
    true  → GRAPHIFY_MODE=disabled for this flow, no question asked, continue silently
    false → ASK_USER:
      "Graphify não foi encontrado (ou está incompleto). Deseja instalar/configurar?"
      1. Instalar/configurar Graphify
      2. Continuar sem Graphify
      3. Continuar sem Graphify e não perguntar novamente neste projeto
      4. Outros
```

- **Option 1**: show the concrete install command(s) for the detected environment (e.g. `uv
  tool install graphifyy`, then `graphify install`) and ask for **explicit per-command
  confirmation before running each one** — never chain them, never run silently. After the
  attempt (success or failure), re-run `detect-graphify.sh`. If now available → continue to
  Step 4.2 with Scenario B (`--gitignore`) for the guard. If still unavailable → behave as
  option 2.
- **Option 2**: `GRAPHIFY_MODE=disabled` for this flow only. Nothing persisted.
- **Option 3**: `GRAPHIFY_MODE=disabled` for this flow, **and** persist the preference:
  `graphify-state.sh pref-set-dont-ask <repo>/.git/sdd-graphify-pref`. Future flows in this
  project skip this question entirely (§ "Local no-ask preference" below).
- **Option 4 (Outros)**: free text; degrade to option 2's behavior unless the text clearly
  states otherwise.

If `GRAPHIFY_MODE=disabled` from this step, skip Step 4.2 entirely and go straight to
persisting state (§ 5).

### Step 4.2 — Graph existence (only reached when available)

Run the guard (§ 2) before checking `graphify-out/graph.json`.

```
graphify-out/graph.json exists and looks valid?
  NO → ASK_USER:
    "Graphify está disponível, mas ainda não existe um grafo local.
     Deseja gerar o grafo para este fluxo?"
    1. Sim, gerar agora
    2. Não, continuar sem Graphify
    3. Outros

  YES → ASK_USER:
    "Graphify detectado e existe um grafo local.
     Deseja atualizá-lo antes de continuar?"
    1. Sim, atualizar agora
    2. Não, usar o grafo atual
    3. Não usar Graphify neste fluxo
    4. Outros
```

**Graph missing, option 1 (gerar agora)**:
```
run the guard (§ 2), Scenario A unless this flow is also the one that just installed
Graphify in Step 4.1 (then Scenario B)
  ↓
bash framework/tools/graphify-run.sh extract . --code-only
  ↓
CRITICAL: bash framework/tools/graphify-readiness.sh — deterministic check, not a narrated
one; never assume readiness from the extract call's exit code alone (a real-machine run found
`extract` exit 0 with a corrupted/partial graph.json)
  
  ✓ success (GRAPH_READY=true):
    → GRAPHIFY_MODE=active
    → GRAPHIFY_GRAPH=ready
    → write graphify-out/.sdd-managed (marks this run as creator)
    → continue with Graphify-active exploration
  
  ✗ failure (GRAPH_READY=false — graphify-out/graph.json missing, empty, or malformed):
    → Print one short diagnostic: "Graphify extraction failed or produced invalid graph"
    → GRAPHIFY_MODE=disabled (not "stale" — stale implies a valid prior graph)
    → GRAPHIFY_GRAPH=missing (remain at missing, not flip to ready)
    → Treat graph.json as false/unreliable (do not use a partial/invalid graph)
    → Continue pipeline normally WITHOUT Graphify
    → Never auto-retry extraction
    → Never block the wider SDD pipeline on Graphify's success
```
**Graph missing, option 2**: `GRAPHIFY_MODE=disabled`, `GRAPHIFY_GRAPH=missing`. **Option 3**:
free text, degrade to option 2 unless clearly otherwise.

**Graph exists, option 1 (atualizar agora)**:
```
run the guard (§ 2)
  ↓
bash framework/tools/graphify-run.sh update .
  ↓
CRITICAL: bash framework/tools/graphify-readiness.sh — same deterministic check as above,
run again after update since a failed update can corrupt a previously-valid graph.json
  
  ✓ success (GRAPH_READY=true):
    → GRAPHIFY_MODE=active
    → GRAPHIFY_GRAPH=ready (updated successfully)
    → continue with Graphify-active exploration
  
  ✗ failure (GRAPH_READY=false — graph.json removed, became empty, or corrupted during update):
    → Print one short diagnostic: "Graphify update failed or produced invalid graph"
    → GRAPHIFY_MODE=disabled (not "active" — update didn't succeed)
    → GRAPHIFY_GRAPH=stale (prior graph was destroyed/invalidated, not viable to use)
    → Continue pipeline normally WITHOUT Graphify
    → The file graphify-out/graph.json MUST NOT be trusted
    → Consider the prior extraction compromised; fall back to full read/grep
```
**Graph exists, option 2 (usar o grafo atual)**: `GRAPHIFY_MODE=active`, `GRAPHIFY_GRAPH=ready`
— **no `update` call is made.** "Not updating" is different from "not using" — using the
existing graph as-is is a fully valid choice. **Option 3 (não usar Graphify neste fluxo)**:
`GRAPHIFY_MODE=disabled` for this flow (graph file is left untouched on disk either way).
**Option 4**: free text, degrade sensibly.

Never run `cluster-only` automatically. Never generate an HTML visualization just because
extraction ran — `graph.json` alone is sufficient for `query`/`path`/`explain`.

### `/sdd.reverse-eng` standalone case

Same two questions, same options, at the very start of the run (before Phase 0 exploration),
since there is no feature branch or `meta.md` to gate on. The resolved `GRAPHIFY_MODE`/
`GRAPHIFY_GRAPH` apply for the remainder of that single continuous run (Phases 0-7) — no
persistence file is needed for a standalone run that completes in one invocation. If this
run's own `extract` created `graphify-out/`, write `.sdd-managed`.

---

## 5. States — deliberately simple, no state machine

```
GRAPHIFY_MODE:  active | disabled
GRAPHIFY_GRAPH: missing | ready | stale
```

Persisted (feature flows) in the feature's own `meta.md`, via:

```bash
bash development-agents/framework/tools/graphify-state.sh get   sdd/wip/<feature>/meta.md
bash development-agents/framework/tools/graphify-state.sh set   sdd/wip/<feature>/meta.md --mode <active|disabled> --graph <missing|ready|stale>
bash development-agents/framework/tools/graphify-state.sh mark-stale sdd/wip/<feature>/meta.md
```

Written once by the preflight (§ 4). Downstream phases (`/sdd.spec`, `/sdd.plan`, `/sdd.build`,
`/sdd.check`) **read this state, they never re-detect or re-ask** — this is what keeps the
pipeline from asking the same question at every phase. The only two events that change state
after the preflight are:

1. `/sdd.build` calling `mark-stale` after a structural code change (§ 6) — a state flip, not a
   question.
2. `/sdd.check` resolving that staleness with one question, right before it would use the graph
   (§ 6) — the one legitimate second ask in a flow, and only when state actually changed.

No other command asks about Graphify again. "The decision made at the start of the flow holds
for the rest of that flow" — re-asking happens only on a real, relevant state transition
(code changed since the graph was last built/refreshed), never on a fixed schedule or per-phase.

### Local no-ask preference (absence only, project-wide, never versioned)

Separate from the per-flow states above. Stored at:

```
<repo>/.git/sdd-graphify-pref
```

— inside `.git/`, exactly like `.git/info/exclude`: inherently never tracked, never committed,
never pushed, with zero risk of ending up in a `.gitignore` entry that needs maintaining.
Written only by Step 4.1 option 3. Read by `graphify-state.sh pref-get` at the start of every
future preflight in this project; when `DONT_ASK_ABSENT=true`, Step 4.1 is skipped silently and
`GRAPHIFY_MODE=disabled` is set without asking.

---

## 6. Build → stale → Check (never trust a stale graph)

```
/sdd.build finishes all tasks + final validation
  ↓
read state: GRAPHIFY_MODE (meta.md)
  disabled → nothing to do
  active
    ↓
  did this run change actual code (not just docs/spec/Markdown)?
    no  → nothing to do
    yes → graphify-state.sh mark-stale sdd/wip/<feature>/meta.md
          (GRAPHIFY_GRAPH: ready → stale; a state flip only — no update call here,
           no question here; the decision moves to /sdd.check, once)
```

```
/sdd.check, before the graph would be consulted (i.e. before --sync's graph-assisted analysis)
  ↓
read state: GRAPHIFY_MODE / GRAPHIFY_GRAPH (meta.md)
  disabled → normal Read/Grep/Glob, no question
  active + ready → use the graph, no question (nothing changed since last build/refresh)
  active + stale → ASK_USER:
    "Código estrutural mudou e o grafo pode estar desatualizado.
     Deseja atualizar o Graphify antes da validação?"
    1. Sim, atualizar
    2. Não, executar CHECK sem Graphify
    3. Outros

    1: run the guard (§ 2) → bash framework/tools/graphify-run.sh update . → validate
         success → GRAPHIFY_GRAPH=ready (persist); this CHECK run uses the graph
         failure → GRAPHIFY_GRAPH stays stale (persist); this CHECK run falls back, warn once
    2: GRAPHIFY_GRAPH stays stale (persist, unchanged); this CHECK run falls back to
       normal Read/Grep/Glob — the graph is NOT consulted
    3: Outros, degrade to option 2 unless clearly otherwise
```

**Mandatory rule: never silently trust a graph known to be stale.** A `stale` state is only
ever resolved by this explicit question — never bypassed, never assumed fresh. This question
fires again only the next time `/sdd.build` re-marks the graph stale (a new structural change)
— not on every subsequent `/sdd.check` call while the state is already `ready` or already
`disabled`.

## 7. Query-first usage, per command

When `GRAPHIFY_MODE=active` and `GRAPHIFY_GRAPH=ready` for the current flow:

| Command | What to ask the graph for, before broad exploration |
| --- | --- |
| `/sdd.reverse-eng` | Modules, entry points, dependencies, services, controllers, repositories, integrations, cross-layer flows — Graphify is the **first** tool in Phase 0-3, before `sdd-explorer`'s own Read/Grep. Validate in code only what the synthesis phase actually needs. |
| `/sdd.spec` | Before file exploration: turn the feature description into a question, run `graphify-run.sh query "<question>"` (optionally `path`/`explain` for named concepts), and use the result to pick which files are worth `Read`ing. |
| `/sdd.plan` | Impact, dependencies, likely-affected files/classes, structural ordering of changes. Do not re-explore the whole repo if `/sdd.spec` already gathered enough evidence via the graph. |
| `/sdd.build` | Not mandatory per task. Use when locating an extension point, discovering callers/dependents, or deciding reuse vs. new code — i.e. when impact isn't already clear from the plan. Always edit/read real source afterward; the graph never substitutes for the actual diff. |
| `/sdd.check` (`--sync`) | Query the graph (only when state is `ready` — see § 6) for affected dependencies, callers, cross-layer impact, structural drift, forgotten consumers. Still run the real deterministic validators — Graphify narrows scope, it does not replace `sdd-validator`. |

Not applied to `/sdd.test` as a general rule, nor to `/sdd.finish`'s (nonexistent) exploration
phase, nor to purely documentational operations. Every query goes through the guard (§ 2)
first, same as extract/update.

## 8. Graph validity & the "never load it whole" rule

`graphify-out/graph.json` existing and non-empty, plus the resolved Graphify command (§ 1)
responding, is what `GRAPHIFY_GRAPH=ready` means in practice — but the authoritative signal for
whether to use the graph in any given command is the **persisted state** (§ 5), not a fresh
existence check every time.

**Critical rule — never load `graph.json` directly into context.** No command in this pipeline
may `Read graphify-out/graph.json`. The whole point of this mechanism is token economy:
interact exclusively through `graphify-run.sh query|path|explain`, never by dumping the raw
graph file into the conversation.

## 9. Query budget — token economy

Always request a modest budget when the CLI supports it, rather than a full report:

```bash
bash framework/tools/graphify-run.sh query "<question>" --budget 1500
```

Do not dump a full report by default. `GRAPH_REPORT.md` (if Graphify produces one) is reserved
for broad reverse-engineering / global-architecture needs where `query`/`path`/`explain`
individually proved insufficient — not a default first move. Never load an HTML visualization
into the conversation context under any circumstance.

## 10. Ownership marker & cleanup

To know whether `/sdd.finish` (or a standalone `/sdd.reverse-eng` run) is allowed to delete
`graphify-out/`, the process that **created** it (via a Step 4.2 "sim, gerar agora" answer)
writes a local marker:

```
graphify-out/.sdd-managed
```

- Never staged, never committed (lives inside the already-guarded `graphify-out/`).
- If `graphify-out/` already existed before this SDD flow touched it (the user had their own
  pre-existing graph), **no marker is written**, and nothing downstream may delete that
  directory automatically — only ensure it stays untracked/unstaged via the guard.

`/sdd.finish` cleanup (after all gates, before final conclusion):

```
graphify-out/ exists?
  no  → nothing to do
  yes
    ↓
  graphify-out/.sdd-managed exists?
    no  → do NOT delete; run the guard (§ 2) once more to re-confirm protection; done
    yes
      ↓
    run the guard (§ 2) to re-confirm nothing is staged
      ↓
    remove ONLY graphify-out/ — never a generic cleanup, never touching anything else
      ↓
    on failure to remove: warn, do not block finish, re-run the guard once more
```

`/sdd.reverse-eng`'s standalone case (no feature, no `/sdd.finish` to do this): if it created
`graphify-out/` itself for that run, prefer removing it at the end of the run to keep the
project clean, unless the user explicitly asks to keep it.

## 11. Benchmark support (Graphify ON vs OFF)

To make it possible to tell, at the end of a phase, whether Graphify actually contributed —
without polluting the normal UX — commands MAY append one compact line group after their
usual phase-completion output:

```
Context
- graphify: used
- queries: 2
- fallback reads: 4
```

or, when inactive:

```
Context
- graphify: unavailable
```
or
```
Context
- graphify: disabled (user choice)
```

Keep the counters simple (a running count of graph queries issued and of Read calls that
happened as fallback/confirmation within that phase) — do not build a sophisticated
attribution system for this. This is a **separate, local execution-metadata field**, never
mixed into any model-usage telemetry a harness might report natively — no LLM token/cost
accounting ever attributes tokens to Graphify, and Graphify never appears as if it were a model
in any usage report. This pipeline does not track token/cost telemetry itself (see
`framework/_shared/agent-instructions.md`); this note only clarifies that Graphify's own local
counters are conceptually distinct from that, wherever/however usage is measured.

---

## Explicitly out of scope for this version

Do not implement any of the following yet — revisit only after the ON/OFF benchmark:

- **No automatic hook installation.** Never run `graphify hook install` or equivalent. Every
  extract/query/update/cleanup call in this pipeline is explicit, decided by ASK_USER (§ 4) —
  not by a Graphify-side hook that forces a query before every Read/Grep.
- **No MCP Graphify integration.** CLI-only in this version.
- **No API key requirement, ever.** If a capability seems to need one, treat Graphify as
  unavailable for that capability rather than prompting for a key.
- **No committing/versioning of `graphify-out/`**, regardless of what Graphify's own docs say
  is supported elsewhere.
- **No `/status`/quota/rate-limit scraping.** This mechanism only touches `extract`/`query`/
  `path`/`explain`/`update`/`--help`/`--version` — nothing interactive, nothing screen-scraped.
- **No question fatigue.** One preflight per flow (§ 4), one re-ask only on a real stale
  transition (§ 6) — never a question per phase, never a question with no state change behind it.

## Fallback rules (mandatory, mirror the telemetry resilience rules)

1. **Never block the pipeline on Graphify.** Any detection/guard/capability/extract/query/
   update failure → continue with normal Read/Grep/Glob.
2. **Never install anything without an explicit, per-command confirmation.** Absence is
   resolved by ASK_USER (§ 4), never by silently installing Graphify, Python, or any package.
3. **Never require Python as an SDD dependency.** Tiers C/D exist only because Graphify itself
   may be packaged that way on some machines — the SDD framework's own scripts
   (`detect-graphify.sh`, `graphify-run.sh`, `graphify-git-guard.sh`, `graphify-state.sh`, and
   every command referencing this file) never call `python`/`python3` themselves.
4. **Never load `graph.json` into context.** Interact only through the CLI's own
   query/path/explain subcommands.
5. **Never stage or commit `graphify-out/`.** § 2's guard is the enforcement point, run before
   every use, not just the first.
6. **Never trust a graph known to be stale.** § 6 is the only path past a `stale` state.
7. **A green SDD phase with Graphify unavailable/disabled is still green.** Graphify is
   observability plus a search accelerator, never a correctness requirement.
