# Reference: New App / Repository Scaffolding

**Used by**: `/sdd.start` (Step 2.5, when `freshly_scaffolded=true` and no org-specific tooling has run yet)

This is a **generic checklist**, not a specific tool integration. If your organization already has its own app-creation CLI, internal developer portal, or scaffolding service, use that *before* running `/sdd.start` — this file is only here to help you improvise the same checklist manually when no such tool exists (or you're bootstrapping a personal/small-team project).

---

## Checklist: Before `/sdd.start` on a brand-new project

1. **Repository exists and is git-initialized**
   ```bash
   git init
   git remote add origin <your-repo-url>   # if you have a remote already
   ```

2. **Pick a starter/template matching your stack** (adjust to your org's conventions):

   | Stack | Common starter |
   |-------|-----------------|
   | Java/Spring | `spring init` or your internal Maven/Gradle archetype |
   | Node/TypeScript | `npm create`, a company Yeoman/Plop generator, or a minimal Express/Nest template |
   | Python | `cookiecutter`, a Poetry/uv template, or a minimal FastAPI/Flask skeleton |
   | Go | `go mod init` + your team's standard `main.go`/handler layout |
   | Mobile (Android/iOS) | Android Studio "New Project" / Xcode "New Project" template |

3. **Register the app wherever your org tracks services** (internal catalog, service registry, on-call ownership tool, etc.), if applicable. This is entirely org-specific — `/sdd.start` has no opinion on it and will not attempt to call any external API for you.

4. **Confirm the basics exist before running `/sdd.start`**:
   - [ ] A working build/test command (`build`, `test` — whatever your `PROJECT.md` will declare)
   - [ ] A `Dockerfile` or equivalent runtime descriptor, if your deployment target needs one
   - [ ] A health-check endpoint (e.g. `/ping`, `/health`) if this is a network service
   - [ ] CI pipeline config present (even a minimal one), if your org requires it before merging

5. **Commit the initial scaffold** so `/sdd.start` sees at least one commit:
   ```bash
   git add -A && git commit -m "chore: initial scaffold"
   ```

Once these are in place, `/sdd.start "your feature description"` will detect `freshly_scaffolded=true`, offer to clean up obvious sample/example files (see Step 2.6 in `sdd.start.md`), run stack detection, and proceed to create the first feature.

## Notes

- `/sdd.start` never calls any external app-registration API. If you want that automation, wire it into your own pre-`/sdd.start` tooling and simply make sure the repo looks "ready" (git history + recognizable stack files) by the time you invoke the command.
- If you skip this checklist entirely and just run `/sdd.start` in an empty folder, it still works — you'll just be asked more questions along the way (stack, profile, etc.) instead of having them pre-filled.
