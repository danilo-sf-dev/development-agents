# Reference: Mobile Task Generation (`/sdd.plan`)

**Used by**: `/sdd.plan` Step 5, when `platform = android` or `platform = ios` in `meta.md`.

## Mandatory task rules (mobile)

- ❌ DO NOT generate: Dockerfile task, Dockerfile.runtime task, `/ping` endpoint task
- ✅ INSTEAD generate: mobile build validation task (`./gradlew test` or `xcodebuild test`)
- ✅ INSTEAD generate: design system + mobile SDK compliance task (correct lib usage, no custom networking)

## Mobile SDK library enforcement

Every task description, title, and acceptance criterion that references a technical capability **must** use the mobile SDK library name from the technical spec (Section 3 — "mobile SDK Libraries"), derived from PROJECT.md mobile SDK docs.

The technical spec's "mobile SDK Libraries" section is the source of truth for task generation:
- If a capability is covered by an mobile SDK library listed there → use that library name
- If a task description contains a generic Android/iOS ecosystem library instead of the mobile SDK equivalent from the spec → replace it before writing `tasks.json`
