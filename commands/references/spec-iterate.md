# Reference: `/sdd.spec --iterate`

**Used by**: `/sdd.spec --iterate "change description"`.

## Purpose

Refine an existing functional or technical specification without silently
changing the approved contract.

## Mandatory flow

1. Read the current spec files and `meta.md`.
2. Analyze the requested change and identify affected sections.
3. Generate a complete preview containing every proposed change.
4. Show the preview to the user.
5. Ask for explicit confirmation with `AskUserQuestion`.
6. Apply changes only after the user selects **Yes, apply**.
7. Preserve existing task statuses and warn when task regeneration may be needed.

Never apply a partial or unconfirmed iteration.

## Usage

```text
/sdd.spec --iterate "add retry logic to payment endpoint"
/sdd.spec --iterate "change user authentication from JWT to OAuth2"
```

## Preview format

```markdown
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔄 Spec Iteration Preview
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

**Requested Change**: "[user's description]"

**Files Affected**:
- `1-functional/spec.md` (if applicable)
- `2-technical/spec.md` (if applicable)

**Proposed Changes**:

### Functional Spec Changes (if any)
**Section: [section name]**
```diff
- Current: [old text]
+ Proposed: [new text]
```

### Technical Spec Changes (if any)
**Section: [section name]**
```diff
- Current: [old text]
+ Proposed: [new text]
```

**Impact Assessment**:
- Tasks affected: [task IDs]
- Breaking changes: [yes/no]
- Requires task regeneration: [yes/no]
```

Then ask:

- **Yes, apply** — apply all proposed changes.
- **Modify** — revise the proposal before applying.
- **Cancel** — discard the proposal.

## After applying

Report the changed files and warn:

- Completed task statuses were preserved.
- Existing tasks may now be incomplete.
- Use `/sdd.plan --refine` to regenerate tasks when the change requires it.

## Agent guard

When `--iterate` is present, do not run the normal interview or approval flow
before showing the preview. If the user cancels, leave every spec unchanged.
