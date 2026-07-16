# Reference: Hub Workflows

**Used by**: `/sdd.hub` sub-commands.

All hub actions operate on the members declared in `sdd/PROJECT.md`. Resolve
each member's path from the `Path` column. The hub coordinates artifacts; it
does not clone repositories, pull branches, or commit changes.

## `start <name>`

1. Validate the hub members table and member paths.
2. Create the hub feature folder and `meta.md`.
3. Record the participating apps and dependency order.
4. Prepare the functional specification.

## `spec functional|technical`

- Functional: describe cross-app outcomes, user stories, and acceptance
  criteria without locking implementation details.
- Technical: define shared architecture, contracts, data ownership, and the
  per-app scope.
- Export or link child-spec stubs only after the shared decision is recorded.
- Apply the normal approval and validation gates.

## `plan`

1. Read the approved hub technical spec.
2. Export child spec stubs into each member's `sdd/wip/<feature>/`.
3. Generate member tasks with dependency layers.
4. Present the cross-app task plan for approval.

## `build`

Execute member tasks in dependency order. A blocked prerequisite blocks
dependent apps. Use each member repository's normal `/sdd.build` workflow and
preserve the approved tests-first gate.

## `check`

Compare hub contracts and member specs/tasks. Report missing exports, contract
drift, dependency-order violations, and member status. With `--sync`, run the
normal cross-layer consistency checks in each member.

## `finish`

Verify all member tasks and validations are complete, confirm no contract drift,
and archive the hub feature plus child artifacts. `--force` may skip only
non-critical completion checks and must be reported.

## `list`

Read the members table and current feature metadata. Show member names, paths,
branch/status information available locally, and active hub features.

## `cancel`

Ask for confirmation, then mark the hub feature cancelled and remove only
generated child WIP artifacts. Never delete member source code or unrelated
features.

## `go "description"`

Run `start → spec → plan → build → finish` in express mode, while retaining
human approval gates required by the project configuration.

## `sync`

Inspect member repositories and report branch, dirty-tree, and behind/ahead
status. With `--pull`, ask before pulling any member repository; the kit does
not perform destructive Git operations.

## `add <app-name>`

Validate the supplied member path, then add or update the app in the
`## Hub members` table in `sdd/PROJECT.md`. Do not create or register external
applications.
