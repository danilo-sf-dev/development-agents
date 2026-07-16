# Reference: AskUserQuestion — always include Outros

**Used by**: Any SDD gate that pauses for human authorization (process compliance, anti-gaming, ambiguous validator verdict).

## Rule (mandatory)

Every AskUserQuestion at a **gate** must include an **Outros** option so the user can freely say what they will do or suggest another path. Closed options are shortcuts; Outros is never optional.

## Minimal shape

```
AskUserQuestion(
  questions=[{
    "question": "<clear question>",
    "header": "<short header>",
    "options": [
      {"label": "<recommended closed option>", "description": "..."},
      {"label": "<other closed option>", "description": "..."},
      {"label": "Outros", "description": "Descreva o que você vai fazer ou sugira outro caminho (texto livre)"}
    ],
    "multiSelect": false
  }]
)
```

## Handling Outros

1. Read the user’s free-text answer
2. Do **not** invent a path they did not state
3. If unclear → ask one clarifying question, then proceed or STOP
4. Log the choice briefly in the task/feature report when relevant (`meta.md` notes or task report)

## Model switch

Gates are a natural pause to switch LLM model (e.g. stronger model for `sdd-validator-runner`). Mention that in the question description when the next step is a validator/process pass.
