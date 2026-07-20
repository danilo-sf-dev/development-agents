# Shared Agent Instructions

**Used by**: All `/sdd.*` command files. Read once at the start of any command invocation.

---

## How to read command files

When you see a block like this:

⛔ INVOKE TOOL (do not print this, CALL the tool):
AskUserQuestion(questions=[{...}])

This is a **tool call** you must execute, not content to display.

| WRONG | CORRECT |
|-------|---------|
| Bash(echo "1. Option A") | Directly call the AskUserQuestion tool |
| Print the JSON to terminal | Pass the parameters shown to the tool |

---

## User interaction rules

When a command shows JSON for `AskUserQuestion`, you MUST:

1. CALL the `AskUserQuestion` tool with that exact JSON
2. DO NOT print options using Bash (no echo, cat, printf)
3. DO NOT ask "Which option?" as plain text
4. Tables marked **REFERENCE ONLY** are documentation — do NOT print them to the user

---

## AskUserQuestion format reminder

Blocks marked with ⛔ INVOKE TOOL are executable tool calls. Pass the JSON parameters exactly as written; never simulate the prompt in chat or terminal output.

### Outros (mandatory on gates)

Every **gate** AskUserQuestion (approve / process failure / anti-gaming / ambiguous next step) MUST include an option labeled **Outros** with free-text intent: the user describes what they will do or suggests another path. See `commands/references/ask-user-question-outros.md`.

---

## Model suggestion advisory (informative)

At **phase-boundary** gates (interactive next-steps after approve/promote), show the model advisory **before** `AskUserQuestion`. At **command entry** for spec/plan/test/build/reverse-eng/fix, show the compact line once.

> Read `commands/references/model-suggestion-advisory.md` for `phase_key`, templates, and AskUserQuestion description suffixes.

Informative only — never block or require the user to confirm a model switch.
