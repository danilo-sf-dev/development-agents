# Reference: Mobile Technical Spec (`/sdd.spec`)

**Used by**: `/sdd.spec technical`, when `platform = android` or `platform = ios`.

#### Mobile Technical Spec (platform = android | ios)

> **PREREQUISITE**: Verify mobile skills are available before generating the spec.
>
> ```bash
> skill_dir="mobile-android-expert"
> plugin_name="mobile-android"
> [ "$platform" = "ios" ] && skill_dir="mobile-ios-expert"
> [ "$platform" = "ios" ] && plugin_name="mobile-ios"
> PLUGIN_PATH="$HOME/.claude/plugins/$plugin_name/skills/$skill_dir"
>
> if [ ! -d "$PLUGIN_PATH" ]; then
>     echo "❌ Mobile plugin not found: $plugin_name"
>     echo "   Re-run: sdd-kit install claude"
>     exit 1
> fi
> ```
>
> If skills are not found, **stop here** — do not generate the spec without documentation.

> **MANDATORY — 3-STEP SEQUENCE (all steps required, no skipping)**:
>
> **Step A — Invoke the mobile skill** (loads mobile SDK/design system documentation into context):
> ```
> Skill("mobile-android-expert")   # if platform = android
> Skill("mobile-ios-expert")       # if platform = ios
> ```
>
> **Step B — Read the skill documentation** (ALWAYS — before writing any section of the spec):
> ```bash
> # SKILL_PATH was resolved in the PREREQUISITE block above
> cat "$SKILL_PATH/SKILL.md"
> ```
> Read SKILL.md fully. Identify and follow the documentation navigation workflows it references
> for mobile SDK libraries and design system components.
> Use those workflows to map **every feature requirement** from the functional spec to its
> corresponding mobile SDK library or design system component. SKILL.md is the single source of truth — no assumptions.
>
> **Step C — Enforce ML-only library selection**:
> The index from Step B is the **only allowed source** for library decisions.
> For each feature requirement, the answer is one of exactly two outcomes:
>
> - **Found in index** → use that mobile SDK library. No alternatives, no substitutions.
> - **Not in index** → the capability does not exist in mobile SDK → document as
>   "no mobile SDK equivalent — use native [X]" in the spec.
>
> Generic Android/iOS ecosystem libraries (e.g. Retrofit, SharedPreferences, Coil,
> Hilt, Jetpack Navigation, UserDefaults, Alamofire, etc.) are **NEVER a valid answer**
> when an mobile SDK library exists for that need.
> The index tells you what exists — trust the index, not pre-training knowledge.

**Sections for mobile**:

1. Executive Summary
2. Architecture (MVVM layers: UI → ViewModel → Repository → DataSource)
3. mobile SDK Libraries — **derived from Step B index read**; list each library name + purpose; NO generic Android/iOS alternatives allowed
4. design system Components (list UI components needed — check design system component map via the skill)
5. Screen/Flow Design (screens, navigation deeplinks if applicable)
6. Data Model (local persistence schema — use the mobile SDK storage library identified in Step B's index read; NEVER SharedPreferences, DataStore, or UserDefaults)
7. Dependencies (mobile SDK lib versions — query via mobile skill index)
8. Testing Strategy (unit tests for ViewModel/Repository; UI tests via screenshot testing)
9. Accessibility (design system components handle this natively)
10. Performance (ANR analysis for Android; App Hangs for iOS)

**Subagents for mobile**:

| Decision type | Subagent | Notes |
|---|---|---|
| Architecture + mobile SDK libs | `Skill("mobile-android-expert")` or `Skill("mobile-ios-expert")` | **MANDATORY (Step A above)** |
| Conflict detection | `sdd-conflict-resolver` | Same as backend |

> ❌ Do NOT invoke `sdd-explorer` for mobile projects
> ❌ Do NOT include  Services, Dockerfile, /ping, or  Compliance sections
> ❌ Do NOT include specific import statements — your team library imports are ML-internal APIs that change across versions and are ONLY reliably known from the skill's official documentation. List libraries by name/purpose only; leave all imports to be resolved at build time.
>
> **IMAGE LOADING — MANDATORY RULE**:
> ❌ NEVER mention Coil, AsyncImage, Glide, Picasso, Fresco (Android) or Kingfisher, SDWebImage, Nuke, PinRemoteImage (iOS) in any spec
> ✅ ALWAYS use the image loading library provided by mobile SDK — the exact library name is in the skill's mobile SDK index (read in Step B above)
> This applies to the spec text, dependency tables, component lists, and code snippets

---
