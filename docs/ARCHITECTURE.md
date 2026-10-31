# FitTracker Architecture

> Living document. Update it whenever an architectural decision changes, and record the
> reason in `docs/adr/` (Architecture Decision Records).

## 1. Goals

| Goal | What it means for the code |
|---|---|
| **Testable** | Business logic runs in unit tests without a simulator, network, or Bluetooth. |
| **Modular** | Features are isolated Swift Package targets with explicit dependencies. |
| **Offline-first** | The app works with no network; data syncs when connectivity returns. |
| **Scalable** | Client and backend are designed for 1M+ users (stateless server, batching, backoff). |
| **Secure & private** | Health data is sensitive: Keychain, Face ID lock, TLS pinning, minimal data collection. |

## 2. Layers (Clean Architecture)

```
┌──────────────────────────────────────────────────────────┐
│ App (Composition Root)  – creates & wires all objects    │
├──────────────────────────────────────────────────────────┤
│ Features (SwiftUI Views + @Observable ViewModels)        │
├──────────────────────────────────────────────────────────┤
│ Domain  – Entities, Use Cases, Repository PROTOCOLS      │  ← the core, no dependencies
├──────────────────────────────────────────────────────────┤
│ Data    – Repository IMPLEMENTATIONS, DTO ↔ Entity maps  │
├──────────────────────────────────────────────────────────┤
│ Infrastructure – Networking, Persistence (Core Data),    │
│ Bluetooth, Motion, ML, Security, Health                  │
└──────────────────────────────────────────────────────────┘
```

### The Dependency Rule
**Dependencies point inward, toward Domain.** Domain knows nothing about SwiftUI, Core Data,
CoreBluetooth, or URLSession. Outer layers implement Domain's protocols (Dependency Inversion).

Why: the rules that make FitTracker *FitTracker* (zones, workout stats, exercise rules) are
the most valuable and most stable code. Frameworks change every WWDC; your business rules
should not have to.

## 3. Module map (`FitTrackerKit` package)

| Module | Depends on | Contains |
|---|---|---|
| `Domain` | — | `HeartRateZone`, `Workout`, `HeartRateSample`, use cases, repository protocols |
| `DesignSystem` | — | Colors, typography, spacing, Liquid Glass components |
| `Networking` | — | `APIClient`, `Endpoint`, auth/token refresh, TLS pinning |
| `Persistence` | — | Core Data stack, managed objects, background contexts |
| `Bluetooth` | — | CoreBluetooth heart-rate client (`AsyncStream` of measurements) |
| `Motion` | — | CoreMotion sensor streams |
| `ExerciseML` | — | Core ML exercise classifier wrapper |
| `Security` | — | Keychain, Face ID (LocalAuthentication) |
| `Data` | Domain + infrastructure modules | Repository implementations, mapping, sync engine |
| `HeartRateFeature`, `WorkoutFeature`, `HistoryFeature`, `SettingsFeature` | Domain, DesignSystem | Screens + ViewModels |
| `TestSupport` | Domain | Fakes / stubs shared by all test targets |

Rules:
- **Features never import `Data` or infrastructure.** They only see Domain protocols. The
  App target injects the real implementations.
- **Infrastructure never imports Domain.** `Data` translates between them (Adapter pattern).
- A module is added to `Package.swift` only when the first code for it is written.

## 4. Design patterns

| Pattern | Where | Why |
|---|---|---|
| MVVM + unidirectional data flow | Features | View renders state; user actions call ViewModel methods; ViewModel updates state. Logic is testable without UI. |
| Use Case | Domain | One business action per type (`StartWorkoutUseCase`). Single Responsibility. |
| Repository | Domain protocol / Data impl | Hides whether data comes from Core Data, network, or BLE. |
| Constructor Dependency Injection | Everywhere | Tests pass fakes; no singletons, no hidden globals. |
| Composition Root | App target (`AppContainer`) | The only place that knows concrete types. |
| Adapter | Bluetooth, Motion, Persistence | Wraps delegate/callback Apple APIs as `async` / `AsyncStream`. |
| Router | App navigation | `NavigationStack` driven by a `Route` enum; deep links and notifications map to routes. |
| Strategy | ML models, max-HR formulas | Swap algorithms without changing callers. |
| Outbox | Sync | Changes are queued locally and retried until the server confirms. |
| Actor | Repositories / sync engine with mutable state | Compiler-checked thread safety (Swift 6). |

## 5. Data flow example: live heart rate

```
HR monitor ──BLE──▶ Bluetooth.HeartRateClient        (AsyncStream<HeartRateMeasurement>)
                          │
                          ▼
                Data.LiveHeartRateRepository          (maps measurement → Domain.HeartRateSample)
                          │   implements Domain.HeartRateRepository
                          ▼
                Domain.ObserveHeartRateUseCase        (adds zone via HeartRateZoneCalculator)
                          │
                          ▼
            HeartRateFeature.LiveWorkoutViewModel     (@Observable, @MainActor state)
                          │
                          ▼
                   LiveWorkoutView (SwiftUI)
```

## 6. Persistence & sync (offline-first)

- Core Data is the **local source of truth**. The UI always reads local data.
- `NSManagedObject`s never leave the `Data`/`Persistence` layer. They are mapped to Domain
  structs, so they can't be mutated or touched from the wrong thread elsewhere.
- Writes go into an **outbox**. `SyncEngine` uploads in batches with **exponential backoff +
  jitter**, so 1M devices coming online at once don't flood the server.
- Each workout has a client-generated `UUID`, which also serves as an **idempotency key**.
  Retries can never create duplicates.
- Conflicts: last-write-wins using `updatedAt`. Revisit if multi-device editing appears.

## 7. Concurrency

- Swift 6 language mode with `ApproachableConcurrency`.
- ViewModels are `@MainActor`. Domain types are `Sendable` value types.
- Streams (BLE, motion) are exposed as `AsyncStream`; cancellation follows the SwiftUI `.task` lifetime.
- No Combine.

## 8. Error handling

- Each layer has its own error type. `Data` maps infrastructure errors (URLError, Core Data,
  CBError) into Domain errors, so Features never see framework errors.
- ViewModels convert Domain errors into user-facing state (`.error(message)`), never `fatalError`.

## 9. Testing strategy

| Level | Target | Tools | What |
|---|---|---|---|
| Unit | `DomainTests`, `<Feature>Tests` | Swift Testing | Entities, use cases, ViewModels with fakes |
| Integration | `DataTests` | Swift Testing | In-memory Core Data, `URLProtocol`-stubbed network |
| App | `FitTrackerTests` | Swift Testing | Composition root wiring, deep-link → route parsing |
| UI | `FitTrackerUITests` | XCUIAutomation | Critical user flows, launched with fake dependencies |
| Backend | `AppTests` (Vapor) | VaporTesting + Swift Testing | Endpoints, auth, validation |

Workflow: **Red → Green → Refactor.** A bug fix starts with a test that reproduces the bug.

Test doubles vocabulary:
- **Stub**: returns canned data.
- **Fake**: a working lightweight implementation (in-memory repository).
- **Spy**: records how it was called.
- **Mock**: a spy that also asserts expectations.

## 10. Backend (Vapor)

```
App ─HTTPS─▶ Load balancer / CDN ─▶ Vapor instances (stateless, Docker, N replicas)
                                        ├─ PostgreSQL (primary + read replicas)
                                        ├─ Redis (cache, rate limit, queues)
                                        └─ Queue workers (push via APNs, aggregation jobs)
```

- Layers: `Controller → Service → Repository (Fluent)`, the same separation as on iOS.
- JWT access tokens (short-lived) + refresh tokens. No server-side session state.
- Versioned API (`/v1/...`), cursor pagination, request validation, rate limiting per user.
- A shared **`FitTrackerAPI`** Swift package holds request/response DTOs used by both the
  app and the server. One source of truth for the API contract.

## 11. Environments & release

| Config | Backend | Used for |
|---|---|---|
| Debug | localhost / fakes | Development |
| Staging | staging server | TestFlight internal testers |
| Release | production | App Store |

- Settings live in `.xcconfig` files per configuration. No secrets in source control.
- Git: `main` (released) ← `develop` (integration) ← `feature/*`, `fix/*`. Every change goes through a PR.
- CI (GitHub Actions) on every PR: build, lint, all tests. A PR is merged only when green.
- Release: Fastlane → TestFlight (internal → external) → App Store with **phased release**.
  Monitor crashes (Sentry) before going to 100%.
- Versioning: Semantic Versioning (`MAJOR.MINOR.PATCH`), with the build number from CI.
