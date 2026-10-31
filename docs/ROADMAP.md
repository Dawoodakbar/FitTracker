# FitTracker Roadmap

Each phase is done on its own `feature/*` branch and merged into `develop` through a PR.

## Definition of Done (applies to every task)
- [ ] Tests were written first and are green
- [ ] Code is `public` only where other modules need it, with doc comments on public API
- [ ] No warnings; follows `ARCHITECTURE.md` dependency rules
- [ ] Conventional commit messages (`feat:`, `fix:`, `test:`, `refactor:`, `chore:`, `docs:`)
- [ ] PR opened, CI green, reviewed, merged into `develop`

## Phases

| # | Phase | Deliverable | Status |
|---|---|---|---|
| 0 | Setup | Git, `.gitignore`, package, test targets, docs | 🟡 In progress |
| 1 | Domain | `HeartRateZone`, `HeartRateSample`, `Workout`, `WorkoutSummary` use cases (TDD) | ⬜ |
| 2 | Design System | Tokens, Liquid Glass components, accessibility | ⬜ |
| 3 | Backend v1 | Vapor: auth, workouts API, Postgres, tests, Docker | ⬜ |
| 4 | Networking | `APIClient`, token refresh, error mapping, TLS pinning | ⬜ |
| 5 | Persistence | Core Data stack, repositories, outbox + `SyncEngine` | ⬜ |
| 6 | Security | Keychain, Face ID lock, privacy manifest | ⬜ |
| 7 | Bluetooth | Heart-rate client + simulated peripheral | ⬜ |
| 8 | Motion + ML | CoreMotion stream, Create ML model, `ExerciseML` | ⬜ |
| 9 | Platform | HealthKit, push notifications, deep links, QR sharing | ⬜ |
| 10 | Monetization & ObjC | StoreKit 2 subscription, Objective-C module | ⬜ |
| 11 | Scale | Redis, read replicas, load tests (k6), Instruments profiling | ⬜ |
| 12 | Delivery | GitHub Actions, Fastlane, TestFlight, Sentry, App Store | ⬜ |
