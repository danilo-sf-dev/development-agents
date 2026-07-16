# Reference: Frontend Web Architecture Patterns

**Used by**: `/sdd.spec` (technical spec), when `should_include_frontend_architecture()` is true — a frontend framework/design system was detected in the stack **and** the spec mentions UI/screens/components.

> If your project has a dedicated frontend-expert skill/agent configured, prefer that as the source of truth for framework-specific idioms. Use this file as the generic checklist when no such skill exists, or as a sanity check on top of it.

---

## Sections to include in the Technical Spec

### 1. Rendering Strategy
State which one applies and why:
- **CSR** (client-side rendering) — SPA, no SEO requirement
- **SSR** (server-side rendering) — SEO-sensitive pages, faster first paint
- **SSG** (static generation) — content that rarely changes
- **Hybrid** (per-route) — mix of the above, common in meta-frameworks

### 2. Component Hierarchy
- Sketch the page → layout → feature-component → shared-component tree for the new feature only (not the whole app)
- Identify which components are **new** vs **reused** from the existing design system/component library
- Call out any component that needs new props/variants on an existing shared component (cheaper than a new one)

### 3. State Management
- Where does this feature's state live? (local component state / URL-driven / route params / global store / server cache)
- If it needs cross-component state: name the mechanism already used in this codebase (don't introduce a second state library)
- Server data: which caching/fetching pattern does the project already use (e.g. query cache, SWR-like hook, plain fetch + effect)?

### 4. Routing
- New routes/pages this feature introduces
- Route guards/permissions if the feature has access control
- Deep-linking / shareable-URL requirements, if any

### 5. Data Fetching & API Contracts
- Which endpoints (from the API Contracts section of this same spec) does the UI call, and when (on mount, on user action, polling)?
- Loading/empty/error states for each fetch — this is often skipped and causes rework later

### 6. Accessibility
- Keyboard navigation for any new interactive component
- ARIA roles/labels for non-native interactive elements
- Color contrast if introducing new visual states (success/warning/error)

### 7. Responsive/Layout Behavior
- Breakpoints affected
- Any component that behaves differently on mobile vs desktop beyond the design system's default responsive behavior

---

## Detection Heuristic (for reference — mirrors the caller)

```
should_include_frontend_architecture():
    stack_has_frontend_framework = check package.json / PROJECT.md for a known frontend framework or design-system package
    spec_mentions_ui = spec text contains UI/screen/page/component keywords
    return stack_has_frontend_framework AND spec_mentions_ui
```

If the feature is backend-only (no UI surface), skip this section entirely — don't force an empty "Frontend Architecture" heading into the spec.
