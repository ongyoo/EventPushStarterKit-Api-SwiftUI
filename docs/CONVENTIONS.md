# Conventions

Short rules. If a rule and the code disagree, fix one of them.

## Naming

| Thing | Pattern | Example |
|---|---|---|
| Feature folder | `Features/<Name>/` | `Features/EventDetail/` |
| Feature entry | `<Name>Coordinator` | `EventDetailCoordinator` |
| Screen files | `<Scene>Contract/Builder/View/Presenter/Interactor` | `OrganizerPresenter` |
| Storyboard screen | `<Scene>ViewController` + `<Scene>.storyboard` | `NotificationViewController` |
| Protocols | capability: `-ing` / role: `-Routing`, `-Interacting`, `-ViewInput` | `HomeRouting` |
| Domain | entity noun + `Repository` | `Event`, `EventRepository` |
| API models | `<Entity>DTO` (internal to Domain) | `EventDTO` |
| Booleans | read as a question | `isLoading`, `hasAnimatedFirstLoad` |
| Localization keys | `area.thing[.detail]` | `home.search.clear` |

One type per file, file named after the type. Extensions: `Type+Topic.swift`.

## Access control

Default is `internal`. Widen only on purpose.

| Where | Rule |
|---|---|
| Core, Navigation, DesignSystem, Domain, DataLayer, DataSources, Platform | `public` only for the API the upper layers use. Everything else `internal`/`private`. |
| Features | `internal` by default. `public` only for what the App layer starts: each feature's coordinator (class, `init`, `Output`, `onOutput`, `start`, `handle`), ports the App implements (`SettingsInteracting`), and the strings it shows (`L10n.Tab`). |
| App | `public` only for what the app target calls: `AppAssembly`, `AppCoordinator`, `AppLinks`, `AppPush`. |
| Domain contracts | Protocol `public`; the "unconfigured" default implementation `internal`. |
| Stored properties | `private` by default; `private(set)` for state others read. |
| Helpers used in one file | `private`. |
| Classes | `final` unless designed for subclassing (`open class Coordinator` is the only base class). |
| DTOs, endpoints, `@Model` records | `internal` to DataLayer: they never leave it. |
| Tests | `@testable import` instead of widening access for tests. |

## Code patterns

- **State:** `Loadable<Value>` for anything async. No separate `isLoading` + `error` + `data` flags.
- **Presenters:** `@MainActor @Observable final class`. Expose `private(set)` state + intent methods named after the user action (`didTapSeeAll()`, `didSelect(_:)`).
- **Interactors:** protocol + `final class`, dependencies through `init` with `Container` defaults. Business rules shared by screens go to a Domain use case.
- **Layers:** a new type goes in the lowest layer that can own it: business → Domain, API mapping/repositories → DataLayer, where data is stored or fetched (HTTP client, database, Keychain) → DataSources, device services and SDKs → Platform, reusable tool → Core.
- **Async:** `async/await`. SwiftUI loads in `.task {}` (auto-cancelled). UIKit uses `Task { [weak self] in ... }.store(in: tasks)`.
- **Errors:** throw typed errors with `LocalizedError` messages; presenters turn them into `.failed(message)`.
- **Texts:** never hard-code user-facing strings: `L10n.Home.popular`.
- **Design values:** never hard-code spacing/colors: `.padding(.m)`, `.foregroundStyle(.textSecondary)`.
- **Comments:** explain *why*, not *what*. Public API gets a `///` doc comment with an example.
- **File header** on every file (Xcode format). Generators add it with your
  name and the Buddhist-era date; set `AUTHOR="Your Name"` in your shell, and
  fix old files with `python3 scripts/add-headers.py`:
  ```
  //
  //  FileName.swift
  //  EventPushStarterKit
  //
  //  Created by Komsit Chusangthong on 16/10/2569 BE.
  //
  ```
- **Public API docs:** every `public` function / init / type has a short `///`
  with a one-line example of how to call it. Stored properties whose name says
  it all (`id`, `title`) don't need one.

## Memory and retain cycles

Ownership always flows one way. Back-references are `weak`.

```
Coordinator ──strong──► children coordinators
Navigator ──strong──► UINavigationController ──► view controllers
UIHostingController ──► View ──► Presenter ──► Interactor ──► Repository
Presenter ──weak──► Router (coordinator)     Presenter ──weak──► ViewInput (UIKit)
Child coordinator ──(closure, [weak self])──► parent
```

Checklist:

- [ ] Every closure stored by an object that `self` owns captures `[weak self]`
      (coordinator `onOutput`, `UIAction`, timers, observers).
- [ ] Router and view references in presenters are `weak`.
- [ ] Long tasks are cancelled with the screen: SwiftUI `.task {}`, UIKit `TaskBag`.
- [ ] No `unowned` (crashes if wrong; lint blocks it).
- [ ] Pushed coordinators finish on pop: use `showFirstScreen(_:asRoot:)` or
      `navigator.push(vc) { [weak self] in self?.finish() }`.
- [ ] Debug console prints `♻️ deinit ...` when a screen/coordinator is released;
      `LeakDetector` logs a fault if a finished coordinator is still alive after 2 s.
- [ ] A test asserts release: `weak var x = ...; ...; #expect(x == nil)`.

## Crash safety (target: 0% crashes)

`make lint` blocks the patterns that crash at runtime:

| Blocked | Use instead |
|---|---|
| `try!` | `do/catch`, `try?` with a fallback |
| `as!` | `as?` + `guard` |
| `value!` after a call / subscript | `guard let`, `??` |
| `fatalError`, `preconditionFailure` | `assertionFailure` (stops in Debug) + safe fallback |
| `var x: Type!` (non-outlet) | optional `?` or inject in `init` |
| `unowned` | `weak` |

Built-in protections:

- Storyboard / cell lookups fall back to an empty controller / cell in Release.
- `PermissionCenter` refuses to ask without the Info.plist purpose string (iOS would kill the app).
- Network and decoding errors are values (`NetworkError`), never crashes.
- `CrashMonitor` (MetricKit) collects real crash and hang reports, no SDK needed.

Exceptions need `// lint:allow – reason` on the line.

## Concurrency

- Swift 6 language mode everywhere: data races are compile errors.
- UI types, presenters, coordinators, system services: `@MainActor`.
- Repositories, clients, stores: `Sendable` (immutable, `actor`, or a lock).
- `nonisolated(unsafe)` only around Apple types not yet marked `Sendable`, with a comment.

## Git

- Branch: `feature/<name>`, `fix/<name>`.
- Commit: `feat: ...`, `fix: ...`, `refactor: ...`, `docs: ...`, `test: ...`.
- Before pushing: `make lint && make test`.
