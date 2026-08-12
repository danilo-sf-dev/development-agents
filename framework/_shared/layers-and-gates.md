# Reference: "Layer" and "Gate" Disambiguation Index

**Read this file when**: you encounter "Layer 1/2/3" (or "Gate") anywhere in the pack and the
surrounding file doesn't make it obvious which system it means. This file does not redefine
anything — each system's real definition stays lazy-loaded in its own home file. This is a
pointer index, not a merge.

---

## Why this file exists

The pack has **four unrelated systems** that all happen to use the label "Layer N", plus a
separate "Gate" concept. They are not duplicates of one idea and must never be merged into one
numbering — they answer different questions. The bug was the naming collision, not the
existence of four systems. Fix = disambiguate, not consolidate into one.

| #   | System                              | Question it answers                                              | Layer 1                                         | Layer 2                               | Layer 3                                            | Layer 4        | Canonical home                                          |
| --- | ----------------------------------- | ---------------------------------------------------------------- | ----------------------------------------------- | ------------------------------------- | -------------------------------------------------- | -------------- | ------------------------------------------------------- |
| A   | **Task Execution Layers**           | "When does this build task run, and what validates it?"          | Local (code, build, unit tests)                 | Platform (services, CI, dependencies) | Quality Gates (performance, security, code review) | —              | `skills/sdd-validator/SKILL.md` § Layer Execution Guide |
| B   | **Spec Traceability Layers**        | "Which spec artifact traces to which?"                           | Functional                                      | Technical                             | Tasks                                              | Implementation | `agents/sdd-layer-analyzer.md`                          |
| C   | **Build Platform Compliance Steps** | "What order does `/sdd.build` final platform validation run in?" | Static Checks                                   | Stack & Service Validation            | Runtime / Test Verification                        | —              | `commands/references/build-platform-compliance.md`      |
| D   | **Configuration Hierarchy Layers**  | "Which config file wins when settings conflict?"                 | Framework Standards (lowest priority, defaults) | PROJECT.md (project-wide overrides)   | meta.md (feature-specific, highest priority)       | —              | `framework/CONFIGURATION.md`                            |

Note the direction reversal in D: Layer 1 is the _lowest_-priority default, Layer 3 is the
_highest_-priority override — the opposite priority direction from A. That's intrinsic to D's own
concept (defaults → overrides) and is not an inconsistency to fix.

System C's three steps are a specific execution order nested inside a `/sdd.build` validation
reference doc; they are not the same thing as System A's "Layer 3: Quality Gates" even though
both live under `/sdd.build` and both use the numbers 1-3 — C is "what checks run and in what
order for platform compliance," A is "which stage of the task lifecycle this work belongs to."

## Gates (a fifth, separate concept — do not confuse with "Layer")

"Gate" refers to pipeline approval checkpoints (Gate 1 = functional spec approval, Gate 2 =
technical spec approval, Gate 2.5 = test plan approval, Gate 3 = finish/completion approval).
This is already single-sourced in `framework/PIPELINE.md` and was not ambiguous — it's listed
here only so "Layer" and "Gate" aren't conflated when both appear near each other (e.g. "Layer 3
quality gates run before Gate 3").

## When writing new content

- If you mean System A (build task lifecycle), write "Layer 1/2/3 (Task Execution — see
  `skills/sdd-validator/SKILL.md`)" the first time it appears in a file, or link to this index.
- Never introduce a fifth "Layer 1/2/3" numbering for a new concept. Prefer names ("Stages",
  "Steps", "Phases") for anything new, and keep "Layer N" reserved for the four systems above.
- If a file's own context already makes the system obvious (e.g. a file that only ever discusses
  spec traceability), no pointer is needed — this index is for genuinely ambiguous mentions.
