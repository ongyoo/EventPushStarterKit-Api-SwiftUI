# Architecture

## 1. The big picture

```
┌──────────────────────────────────────────────────────────────────────┐
│ App layer                                                            │
│   App target   AppDelegate · SceneDelegate · Siri intents  (tiny)    │
│   App module   composition root (AppAssembly) · DI wiring ·          │
│                app routing (AppCoordinator, tab flows, deep links) · │
│                adapters (device services for Settings)               │
└──────────────────────────────────┬───────────────────────────────────┘
                                   ▼
┌──────────────────────────────────────────────────────────────────────┐
│ Features (Presentation)                                              │
│   Home · EventDetail · EventList · Notification · Settings · Shared  │
│   VIPER screens, presenters, UI state, feature coordinators          │
└──────────────────────────────────┬───────────────────────────────────┘
                                   ▼  uses business contracts only
┌──────────────────────────────────────────────────────────────────────┐
│ Domain                                                               │
│   entities · value objects · use cases · repository protocols ·      │
│   domain errors                                     (pure Swift)     │
└──────────────────────────────────▲───────────────────────────────────┘
                                   │  implements the Domain contracts
┌──────────────────────────────────┴───────────────────────────────────┐
│ Data (group)                                                         │
│ ┌──────────────────────────────────────────────────────────────────┐ │
│ │ DataLayer     repository implementations · DTO + mapping ·       │ │
│ │               cache · fixtures                                   │ │
│ └───────────────────────────────┬──────────────────────────────────┘ │
│                                 ▼  reads / writes through            │
│ ┌──────────────────────────────────────────────────────────────────┐ │
│ │ DataSources   network (APIClient, Alamofire) · database          │ │
│ │               (SwiftData) · Keychain · encrypted files ·         │ │
│ │               UserDefaults                                       │ │
│ └──────────────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────────┐
│ Platform (device services, used by the App layer)                    │
│   notifications · push · background tasks · permissions ·            │
│   Live Activities · crash reports · biometrics · device integrity ·  │
│   analytics (AnalyticsCenter)                                        │
└──────────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────────┐
│ Cross-cutting foundation (any layer may use)                         │
│   Core          Foundation (DI, environment, state) · Logging ·      │
│                 Concurrency · Utilities · Localization · Routing ·   │
│                 Storage + Analytics contracts                        │
│   Navigation    Navigator · Coordinator · transitions · HostingController │
│   DesignSystem  tokens · components · animation · layout · keyboard  │
└──────────────────────────────────────────────────────────────────────┘
```

Every box is a Swift module in one package (`Modules/Package.swift`). A module
can import only the modules in its `dependencies`, and **breaking an arrow
fails the build**, not a code review:

- `scripts/check-layers.py` reads the arrows from `Package.swift` and checks
  every `import`. It runs as the first build phase of the app (errors show
  inline in Xcode) and in `make lint`.
- Why a script and not only the compiler: Xcode builds all modules into one
  folder, so `import DataLayer` inside Features compiles if DataLayer was
  built earlier in the same build. Splitting into several packages has the
  same hole.

| Module | May import | Owns | Must NOT contain |
|---|---|---|---|
| **App** | everything | Composition root, DI registrations, tabs, app routing, adapters | Screens, business rules |
| **Features** | Domain, Navigation, DesignSystem, Core, LiquidGlassKit, ServerDrivenUI | What the user sees and does (including server-driven screens) | Networking, storage, DTOs, system APIs |
| **Domain** | Core | What the business is: `Event`, `GetOrganizerUseCase`, `EventRepository` | UIKit, SwiftUI, Alamofire, SwiftData |
| **DataLayer** | Domain, DataSources, Core | `RemoteEventRepository`, `EventDTO`, `SwiftDataFavoritesRepository` | UI, business decisions |
| **DataSources** | Core | Where data lives: `APIClient`, `Database`, `KeychainStore`, `EncryptedFileStore`, `UserDefaultsStore` | Business types (`Event`...), mapping |
| **Platform** | Core | Device services: `PermissionCenter`, `LocalNotificationCenter`, `PushService`, `AnalyticsCenter`... | Business types, screens |
| **Core** | — | Tools every layer needs | UIKit screens, business, third-party code |
| **Navigation** | Core, LiquidGlassKit | How screens are shown | Business |
| `Packages/LiquidGlassKit` | — | Glass views, tab bar, components (own package, no dependencies) | App code |
| `Packages/ServerDrivenUI` | LiquidGlassKit | BFF screen schema + renderer (own package) | App code, networking |
| **DesignSystem** | Core | How things look and move | API calls, business rules |

Why `Data` is a group of two modules: the repository (decides what to fetch,
maps DTOs, caches) and the data sources (know *how* to talk to HTTP, SwiftData,
Keychain) change for different reasons. The folder `Sources/Data/` keeps them
together; two modules keep DTO mapping out of the HTTP client. The module is
`DataLayer`, not `Data`, because `Data` would clash with Foundation's `Data`.

Why `Platform` is separate from Data: push, notifications, permissions,
background tasks or analytics are not data sources. They are device services
the App layer wires in (Settings uses them through a port).

Contracts shared by both live in Core: `KeyValueStore` / `StorageKey`
(implemented by DataSources, used by Platform for the analytics consent) and
`AnalyticsTracking`.

Why `Core` is one module and not `CoreFoundation`, `CoreLogging`,
`CoreConcurrency`, `CoreUtilities`: those are folders inside `Core`.
`CoreFoundation` is an Apple framework name, and four tiny modules would add
build and linking cost without a real boundary to protect.

Third-party libraries are confined: Alamofire only in
`DataSources/Network/AlamofireAPIClient`, Kingfisher only in
`DesignSystem/Components/RemoteImage`. Swapping one touches one file.

## 2. Folders

```
Modules/Sources/
  App/              AppAssembly · AppCoordinator · AppLinks · AppNotifications · AppTab
                    Flows/ (one flow per tab) · Adapters/ (ports implemented with Platform)
  Features/         <Feature>/<Feature>Coordinator.swift + Scenes/ · Shared/ · Resources/
  Domain/           <Area>/Entities · <Area>/UseCases · <Area>/Repositories · DomainError
  Data/             group
    DataLayer/        <Area>/Remote (DTO, endpoints, API repository) · <Area>/Local (SwiftData)
                      Persistence/DataSchema · DataAssembly · Resources/Fixtures
    DataSources/      Network · Database · Storage (Keychain, encrypted files, UserDefaults)
  Platform/         Notifications · Push · Background · Permissions · LiveActivity · Crash
                    Security (biometrics, integrity) · Analytics
  Core/             Foundation/{DI,Environment,State} · Logging · Concurrency · Utilities
                    Localization · Memory · Routing (DeepLink) · Capabilities (Permission)
                    Storage (KeyValueStore contract) · Analytics (contract)
  Navigation/       Navigator · Coordinator · Transition · HostingController · TransitionSource
  DesignSystem/     Tokens · Components · Animation · Layout · Keyboard · UIKit · Security
Modules/Tests/      one test target per module (CoreTests ... AppTests)
```

## 3. How the layers meet: ports and the composition root

Features need data, but cannot import DataLayer. They depend on a **protocol in
Domain**; the **composition root** in the App layer decides the implementation.

```swift
// Domain: the contract + a key with a safe default (throws, never crashes)
public protocol EventRepository: Sendable { func events() async throws -> [Event] ... }
public extension Container {
    var eventRepository: Dependency<any EventRepository> {
        Dependency(self) { UnconfiguredEventRepository() }.singleton
    }
}

// DataLayer: the implementation, plugged in by DataAssembly
container.eventRepository.register { RemoteEventRepository(api: container.apiClient()) }

// App: composition root, once at launch
AppAssembly.configure()   // ... DataAssembly.register(in: container)

// Features: only the contract
init(repository: any EventRepository = Container.shared.eventRepository())
```

Device services (permissions, notifications, background tasks, Live
Activities) live in Platform. A feature that needs them declares a port
(`SettingsInteracting`, public) and the App layer implements it
(`App/Adapters/SettingsInteractor`), passing it in:
`SettingsCoordinator(navigator:) { SettingsInteractor() }`.

## 4. Why one package and not one package per feature?

One package with a module per layer gives clear boundaries **without** the
cost of dozens of packages: Xcode shows a single local package (`Modules`,
editable, under *Package Dependencies*), adding a feature is adding a folder,
and there is a single `Package.swift`.

> If Xcode ever shows *Missing package product 'App'*: close Xcode, delete
> `Modules/.swiftpm` and the project's DerivedData, reopen, then
> File → Packages → Reset Package Caches.

Inside `Features`, boundaries between features are kept by convention:

- a feature never calls another feature's screens or builders;
- its coordinator is its only public API; it emits an `Output`, and the
  **flow** in the App layer decides what happens next;
- shared feature code goes to `Features/Shared`.

### One package or many?

Each layer is already its own **module**: that is the unit that has
dependencies and is checked. A separate **package** per layer adds 8
manifests, duplicated third-party versions and slower package resolution,
and gives no extra isolation. Split into packages for distribution reasons:
a second app or repo reuses the foundation, independent versions, or teams
owning separate repos. Then split by owner (e.g. a `Platform` package with
Core, Navigation, DesignSystem, DataSources, Platform), not one package per layer.
Module names stay the same, so no code changes.

### Growing into a super app

Split by **business group (mini-app)**, never by screen. When a group gets its
own team or its build time hurts, move its folders into new modules:

```
Features/Payments/...   ─►  .target(name: "PaymentsFeature", dependencies: ["Core", "Navigation", "DesignSystem", "PaymentsDomain"])
Domain/Payment/...      ─►  .target(name: "PaymentsDomain", dependencies: ["Core"])
Data/DataLayer/Payment/ ─►  .target(name: "PaymentsData", dependencies: ["PaymentsDomain", "DataSources"])
App                     ─►  depends on the three, registers PaymentsData in AppAssembly
```

Nothing else changes: the coordinator API and deep links stay the same.

## 5. Anatomy of a feature

```
Features/EventDetail/
├─ EventDetailCoordinator.swift     public entry point: starts screens, handles deep links, emits Output
└─ Scenes/
   ├─ EventDetail/                  one VIPER scene = one screen
   │  ├─ EventDetailContract.swift      protocols: Routing, Interacting (+ screen models)
   │  ├─ EventDetailBuilder.swift       assembles V-I-P, returns UIViewController
   │  ├─ EventDetailView.swift          SwiftUI (or ViewController + .storyboard)
   │  ├─ EventDetailPresenter.swift     state + user actions
   │  ├─ EventDetailInteractor.swift    calls use cases / repositories (Domain)
   │  └─ Components/                    views used only by this screen
   └─ Organizer/
```

### Who does what (VIPER + Coordinator)

```
 user tap                          Use case / Repository (Domain)
    │                                              ▲
┌───▼────┐ action  ┌───────────┐  async call ┌─────┴──────┐
│  View  ├────────►│ Presenter ├────────────►│ Interactor │
│        │◄────────┤  (state)  │◄────────────┤            │
└────────┘ render  └─────┬─────┘   result    └────────────┘
                         │ weak
                   ┌─────▼──────┐
                   │ Router =   │  push / present / Output to parent flow
                   │ Coordinator│
                   └────────────┘
```

| Part | Knows | Never |
|---|---|---|
| View | Presenter (reads state, forwards taps) | Business logic, navigation |
| Presenter | Interactor, Router (weak) | UIKit/SwiftUI types, networking |
| Interactor | Use cases, repository protocols (Domain) | UI, navigation, DataLayer types |
| Coordinator | Navigator, Builders | Business logic |
| Builder | Everything, once | Being called outside the coordinator |

Use cases vs interactors: an interactor serves **one screen**. A business rule
used by more than one screen, or worth testing on its own (e.g. "featured =
the 5 most favorited events"), is a **use case** in Domain
(`GetEventHighlightsUseCase`, `GetOrganizerUseCase`), and interactors call it.

The SwiftUI and Storyboard variants differ only in the view part:
`@Observable` presenter + SwiftUI view, or a `ViewInput` protocol implemented
by a `UIViewController` from a storyboard. Both plug into the same coordinator.

## 6. Data flow

```
APIClient (DataSources) ─► RemoteEventRepository (DataLayer) ─► Use case (Domain) ─► Interactor ─► Presenter ─► View
   Alamofire                     DTO → Entity, cache                 rules                              Loadable<T>

Database (DataSources) ─► SwiftDataFavoritesRepository (DataLayer, @ModelActor) ─► Interactor ...
   SwiftData container          @Model → Sendable struct
```

- `Endpoint` describes a call; `APIClient` sends it; DTOs never leave DataLayer.
- Screen state is always `Loadable<Value>` (`idle / loading / loaded / failed`).

## 7. Dependency injection

A tiny in-house container (`Core/Foundation/DI`, ~100 lines):

```swift
let repository = Container.shared.eventRepository()        // resolve
Container.shared.apiClient.register { MockAPIClient() }    // replace (tests, mock mode)
Container.shared.reset()                                   // back to defaults
```

- DataSources and Platform keys (`apiClient`, `secureStore`, `analyticsCenter`...) have real
  defaults next to their implementation.
- Domain keys (`eventRepository`, `favoritesRepository`) default to an
  "unconfigured" implementation that throws `DomainError.notConfigured`;
  `DataAssembly` registers the real ones. `AppCoordinatorTests` and
  `DataLayerTests` check the wiring.
- Interactors take dependencies in `init` with a `Container` default, so tests
  pass fakes directly.

## 8. App launch

```
AppDelegate.didFinishLaunching
  └─ AppAssembly.configure()        environment, secure storage wipe on reinstall,
                                    mock API (Debug), DataAssembly.register,
                                    image cache, crash monitor, feature-flagged services
SceneDelegate.willConnect
  └─ AppCoordinator.start()         window → tab bar → one flow per tab
       └─ pending deep link handled (cold start)
```
