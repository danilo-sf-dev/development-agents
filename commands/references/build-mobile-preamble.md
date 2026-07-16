# Reference: Mobile Build Preamble (`/sdd.build`)

**Used by**: `/sdd.build` Step 4, when `platform.type` is `android` or `ios` **and** PROJECT.md names stack docs/skills.

```
IF PROJECT.md declares mobile/design-system skills:
    Prepend a short reminder to read those skills before implementing.
ELSE:
    Use repo conventions + technical spec only.
```

Mobile projects skip backend Dockerfile, `/ping`, and CI pipeline checks — see `references/finish-mobile-validation.md` for finish-time validation.
