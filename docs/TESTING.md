# Testing

```bash
make test          # every test (Swift Testing), ~1 minute
make coverage      # tests + coverage per layer
make lint          # crash-safety rules
```

One test target per module: `CoreTests`, `NavigationTests`, `DesignSystemTests`,
`DataSourcesTests`, `PlatformTests`, `DomainTests`, `DataLayerTests`, `FeaturesTests` (one
folder per feature, shared doubles in `Support/`) and `AppTests` (composition
root, tab flows, deep links across features).

## What to test (and what not)

| Test | Example |
|---|---|
| Presenter: every state + every user action | `loadFailureShowsMessage`, `userActionsRoute` |
| Use case (Domain): business rules with an in-memory repository | `highlightsAreMostPopularAndSoonestFirst` |
| Interactor: maps use case results for one screen | `buildsFeaturedAndUpcoming` |
| Repository (DataLayer): mapping + errors with `MockAPIClient` / in-memory `Database` | `decodesAndMapsFixture`, `toggleAddsAndRemoves` |
| Wiring: every Domain contract is registered | `dataAssemblyPlugsImplementationsIntoDomainContracts` |
| Coordinator: start, outputs, deep links, **memory release** | `pushedFlowIsReleasedWhenPopped` |
| App flow: deep link to any depth, tab reset, language reload | `deepestLinkBuildsWholeStack` |
| Localization: every key in every language | `everyKeyIsTranslated` |
| Builder: the screen renders in each state (smoke) | `builderRendersEveryState` |

Don't unit-test layout pixels or Apple frameworks; use previews (and UI tests
for critical journeys).

## Test doubles

| Need | Use |
|---|---|
| Network | `MockAPIClient(responses: ["path": .success(json)])` |
| Event data | `RepositoryStub(events:error:)` (FeaturesTests/Support) |
| Favorites | `FavoritesStub()` / `Database(models:inMemory: true)` |
| Storage | `InMemoryStore()` |
| Any dependency | `Container.shared.x.register { Fake() }` then `Container.shared.reset()` |
| Router / view | `RouterSpy`, `ViewSpy` (generated with every scene) |

Generated scenes come with passing tests; keep them green as you change the screen.

## Memory tests

```swift
weak var weakChild: ProfileCoordinator?
do {
    let child = ProfileCoordinator(navigator: navigator)
    weakChild = child
    parent.startChild(child)
}
navigator.popToRoot(animated: false)
#expect(weakChild == nil)            // released, no retain cycle
```

## Coverage

`make coverage` prints two numbers per layer:

- **Logic** – every layer minus rendering code (SwiftUI views, view controllers, DesignSystem). The team target.
  Enforce it in CI: `MIN_LOGIC_COVERAGE=90 make coverage`.
- **All code** – everything, including SwiftUI bodies and the DesignSystem.

What unit tests can't reach (honest list): system prompts (permissions,
Face ID), real notification delivery, APNs, BGTaskScheduler launches, Keychain
without an app host, MetricKit payloads. These are wrapped behind small
protocols or guards so the logic around them *is* tested; the system call
itself is verified on a device or in UI tests.

## Before you push

```bash
make lint && make test
```
