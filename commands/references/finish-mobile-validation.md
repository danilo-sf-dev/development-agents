# Reference: Mobile Validation (`/sdd.finish`)

**Used by**: `/sdd.finish`, when `IS_MOBILE = true` (`platform = android` or `platform = ios`).

Mobile projects skip backend CI pipeline, Dockerfile, `/ping`, and project-service compliance checks.

## CI validation (Step 0.5)

Run mobile tests instead of the CI pipeline:

```bash
# Android
./gradlew test  # must pass; same as /sdd.build Step A for mobile

# iOS
xcodebuild test -workspace *.xcworkspace -scheme <scheme> \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

If mobile tests already passed in `/sdd.build` this session → **Skip** (already validated).

## Platform compliance (Step 2)

Run mobile compliance via `sdd-validator` skill:

```
Skill(skill="sdd-validator")
```

The validator auto-detects mobile and runs: build check (`./gradlew assembleDebug` or `xcodebuild build`), unit tests, and design system/mobile SDK compliance scan (no banned libs).
