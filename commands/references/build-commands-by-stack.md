# Reference: Build Commands by Stack

**Used by**: `/sdd.build` when choosing build/test commands.

## Build Commands

### Backend Technologies

| Technology | Build | Test |
|------------|-------|------|
| Java/Maven | `mvn compile` | `mvn test` |
| Java/Gradle | `./gradlew build` | `./gradlew test` |
| Go | `go build ./...` | `go test ./...` |
| Python | N/A | `pytest` |
| **Android** | `./gradlew assembleDebug` | `./gradlew test` |
| **iOS** | `xcodebuild build` | `xcodebuild test` |

### Frontend / Web

Use the project's package scripts (examples — adapt to repo):

| Command | Purpose |
|---------|---------|
| 
pm run dev / pnpm dev | Development server |
| 
pm run build | Production build |
| 
pm test | Unit/integration tests |
| 
pm run test:e2e | E2E (only if configured) |
| 
pm run lint | Linting |

Resolve exact commands from package.json, Makefile, or PROJECT.md.

---
