# Reference: `/sdd.project --hub`

**Used by**: `/sdd.project --hub`.

A hub repo is a coordination layer for specs — it has no production code, no tests, and no architecture pattern of its own. **Do NOT run the standard wizard.** Instead, run the hub-specific flow:

## Step 1 — Spec language

**⛔ INVOKE TOOL (do not print this, CALL the tool):**
```
AskUserQuestion(
  questions=[{
    "question": "What language should specs be written in?",
    "header": "Spec Language",
    "options": [
      {"label": "English (default)", "description": "en"},
      {"label": "Español", "description": "es"},
      {"label": "Português", "description": "pt"}
    ],
    "multiSelect": false
  }]
)
```

## Step 2 — Hub member apps

Output this question as plain text and wait for the user to reply in the chat. Do NOT use AskUserQuestion — this requires free-text input, not a selector.

```
Which apps will be members of this hub?
Type the app names separated by commas (e.g. campaign-api, campaign-web, campaign-android), or type Skip to create an empty hub:
```

**STOP and wait for the user's reply before continuing to Step 3.** Do not proceed, do not generate placeholders.

If the user replies `Skip` (case-insensitive): skip Steps 3 and 4, go directly to Step 5 and generate PROJECT.md with an empty `## Hub members` table (commented placeholder rows only).

## Step 3 — Resolve apps

For each app name provided:

1. Look up the app via your org's internal app registry/service directory, if one exists (check `PROJECT.md` or team tooling). Otherwise ask the user for git URL, stack, and a one-line summary.
2. If the app is not found, show a warning: `⚠ App "{name}" not found — it will be added with placeholder values.`
3. From the resolved technology/stack, derive the **platform** and **technology folder**:

   | Stack signal | Platform | Technology folder |
   |---|---|---|
   | `kotlin` + `android` indicators | `mobile` | `android` |
   | `swift` + `ios` indicators | `mobile` | `ios` |
   | `frontend-framework`, `react`, `vue`, `angular`, or UI framework signals | `frontend` | `react` / `vue` / `angular` (as detected) |
   | `go` | `backend` | `go` |
   | `java` | `backend` | `java` |
   | `python` | `backend` | `python` |
   | `rust` | `backend` | `rust` |
   | `node` without UI signals | `backend` | `node` |
   | Undetected or ambiguous | `misc` | stack value or `unknown` |

4. Build the default path: `platform-apps/{platform}/{technology-folder}/{app-name}`

## Step 4 — Show resolved table and confirm

Display the pre-filled table for the user to review:

```
Hub members resolved:

| Member         | Path                              | Git URL                        | Stack  | Summary                |
|----------------|-----------------------------------|--------------------------------|--------|------------------------|
| campaign-api   | platform-apps/backend/go/campaign-api | git@github.com:org/campaign-api | Go     | Campaign REST API      |
| campaign-web   | platform-apps/frontend/react/campaign-web | git@github.com:org/campaign-web | React | Campaign frontend  |

Do any paths need adjustment? (Enter corrections as "app-name: new/path", or press Enter to accept all)
```

Apply any corrections the user provides before writing the file.

## Step 5 — Generate PROJECT.md

Write `sdd/PROJECT.md` with:
- Language setting (if non-default)
- The `## Hub members` section populated with the resolved and confirmed rows (real data, not commented placeholders)

Skip architecture, testing, PR size, and all frontend settings — these belong in each member app's own PROJECT.md.

## Step 6 — Generate .gitignore

Create or update `.gitignore` at the hub root to ignore all member app directories:

```gitignore
# Hub member apps — managed independently, not tracked by this repo
platform-apps/
```

Then append each specific member path as well. If `.gitignore` already has a `# Hub member apps` section, replace it with the updated list.

## Step 7 — Show confirmation

```
Hub workspace initialized.
Members added: {n} apps → sdd/PROJECT.md
.gitignore updated — member app directories will not be tracked by this repo.

Next: clone your apps into these paths or run /sdd.hub start
```

> Architecture, testing standards, and PR conventions are configured per member app, not at the hub level.

## When PROJECT.md already exists

1. Read existing PROJECT.md
2. If `## Hub members` already exists: show "Hub section already present in PROJECT.md" and stop
3. If not: run Steps 2–6 above and append the populated `## Hub members` section to the existing file, and update `.gitignore`
