# UI & design system

Everything visual lives in the `DesignSystem` module. Features use tokens and
components; they never hard-code colors, spacing or fonts.

## Tokens

```swift
.padding(.m)                         // DS.Space: xxs 4 · xs 8 · s 12 · m 16 · l 20 · xl 24 · xxl 32 · xxxl 48
.cornerRadius(.l)                    // DS.Radius: s 8 · m 12 · l 16 · xl 24 · pill
.font(.dsHeadline)                   // dsLargeTitle · dsTitle · dsHeadline · dsBody · dsCallout · dsCaption (Dynamic Type)
.foregroundStyle(.textSecondary)     // brandPrimary · textPrimary/Secondary/Tertiary · backgroundPrimary/Secondary · border · divider
.background(LinearGradient.brand)
.cardStyle()                         // rounded card + soft shadow
```

UIKit gets the same palette: `UIColor.brandPrimary`, `UIColor.textSecondary`...

## Components

| Component | Use |
|---|---|
| `RemoteImage(url:)` | Cached, downsampled remote image (Kingfisher inside) |
| `imageView.setRemoteImage(url)` | Same for UIKit; call `cancelRemoteImage()` in `prepareForReuse` |
| `ErrorStateView(message:retry:)` | Failed state with retry |
| `EmptyStateView(_:systemImage:message:)` | Empty state |
| `.skeleton(isLoading)` | Shimmering placeholder over real layout with sample data |
| `HostingController(rootView:title:)` | SwiftUI screen in UIKit navigation (logs deinit in Debug) |
| `embed(_:in:)` | SwiftUI view inside a Storyboard screen |
| `StoryboardInstantiable` | `MyViewController.instantiate()` from a package storyboard |
| `tableView.register(Cell.self)` / `dequeue(Cell.self, for:)` | Type-safe cells |
| `.asPreview()` | Preview any UIViewController (Storyboard / VIPER builder) |
| `LiquidGlassView` / `.liquidGlass()` | iOS 26 Liquid Glass on iOS 17+ (LiquidGlassKit, see below) |

## Liquid Glass (iOS 17+)

Glass lives in its own package, [`Packages/LiquidGlassKit`](../Packages/LiquidGlassKit/README.md)
(no dependencies, ready to move to its own repository). It gives you:

- `LiquidGlassView`: iOS 26 glass for any UIKit view (refraction, rim light
  that follows tilt, adaptive light/dark, touch swell);
- `.liquidGlass()`: the same as a SwiftUI background;
- `LiquidGlassTabBarController`: the app's tab bar (see [Navigation](NAVIGATION.md)).

```swift
import LiquidGlassKit

let glass = LiquidGlassView()
glass.backdrop = contentView          // what is behind: refraction + adaptive color
glass.contentView.addSubview(button)
glass.glassTint = .brandPrimary

Button("Follow") { }.padding().liquidGlass()
```

Modules that use it add `.product(name: "LiquidGlassKit", package: "LiquidGlassKit")`
to their dependencies in `Modules/Package.swift`.

## Adaptive layout (iPhone, iPad, split view, rotation)

Width-based, measured from the real container (not the device model):

| `LayoutClass` | Width | Typical |
|---|---|---|
| `.compact` | < 600 pt | iPhone portrait, iPad ⅓ split |
| `.medium` | 600–899 pt | iPhone landscape, iPad portrait |
| `.expanded` | ≥ 900 pt | iPad landscape |

```swift
var body: some View {
    content.adaptiveLayout()                       // once, at the screen root
}

@Environment(\.layoutClass) private var layout     // in any child
LazyVGrid(columns: .columns(layout.value(compact: 1, medium: 2, expanded: 3)))
LazyVGrid(columns: .adaptive(minWidth: 160))
AdaptiveStack { Poster(); Details() }              // vertical on phones, side by side on wide screens
.pageMargin()                                      // 16 / 24 / 32 pt
.readableWidth()                                   // caps long text at 680 pt, centered
```

UIKit: `viewController.layoutClass`, `traitCollection.isRegularWidth`, `view.pinEdges(to:)`.

## Animation

All helpers respect **Reduce Motion** (movement becomes a fade).
Open **Settings → Developer → Animation gallery** (Debug) to try them.

```swift
withAnimation(.dsSpring) { ... }       // dsQuick · dsStandard · dsSlow · dsSpring · dsBouncy

.appearAnimation(.slideUp)             // fade · slideUp · slideFromLeading/Trailing · scale · blur
.staggeredAppear(index: i)             // lists
.shake(trigger: attempts)              // validation error
.pop(trigger: likes)                   // like / add to cart
.pulse() · .floating() · .shimmer()
.buttonStyle(.pressable)               // shrink on press
.transition(.dsSlideDown)              // dsScaleFade · dsSlideUp · dsSlideDown · dsPush
AnimatedNumberText(value: total, format: .currency(code: "THB"))
```

UIKit: `view.fadeIn()`, `slideIn()`, `shake()`, `pop()`, `startPulse()`,
`tableView.animateVisibleCells()`.

Screen transitions (push/present) are in [Navigation](NAVIGATION.md).

## Keyboard

All in `DesignSystem/Keyboard`, same API everywhere in the app:

| Need | SwiftUI | UIKit |
|---|---|---|
| Hide it | `Keyboard.dismiss()` | `Keyboard.dismiss()` |
| Tap outside hides it | **automatic, app-wide** (`AppCoordinator` calls `Keyboard.enableTapToDismiss(in:)`) | same |
| Swipe down hides it | `.scrollDismissesKeyboard(.interactively)` | `scrollView.keyboardDismissMode = .interactive` |
| Return → next field | `.focused($focus, equals: .email).focusNext($focus, to: .password)` | `TextFieldChain([name, email, password]) { submit() }` |
| "Done" on number pads | `.keyboardDoneButton()` | `inputAccessoryView` |
| Keep content visible | automatic (safe area); `.keyboardPadding()` if you ignore it | `scrollView.adjustsForKeyboard()` |
| Bar above keyboard | `.safeAreaInset(edge: .bottom)` | `view.pinAboveKeyboard(bar, spacing: 8)` |
| Height / visible | `KeyboardObserver.shared.height`, `.isVisible` | `KeyboardObserver.shared.onChange` |

Try it: **Settings → Developer → Keyboard**.

## Load more (pagination)

`Paginator<Item>` (Core) runs infinite scrolling for any list:

```swift
// Presenter
let paginator = Paginator<Event>(pageSize: 20) { request in
    try await interactor.fetchEvents(page: request)        // request.page / request.offset / request.size
}

// SwiftUI view
ForEach(paginator.items) { event in
    Row(event).task { await paginator.loadMoreIfNeeded(currentItem: event) }
}
LoadMoreFooter(phase: paginator.phase) { Task { await paginator.loadNextPage() } }
.refreshable { await paginator.loadFirstPage() }

// UIKit
func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
    Task { await paginator.loadMoreIfNeeded(index: indexPath.row) }
}
```

| `phase` | Show |
|---|---|
| `.loading` (no items) | full-screen spinner |
| `.failed` | full-screen error + retry (`loadFirstPage`) |
| `.loadingMore` | footer spinner |
| `.failedToLoadMore` | list stays, footer retry (`loadNextPage`) |

Repositories return `Page<Item>(items:hasMore:)`. If the API has no paging,
`Page.slice(all, request)` pages in memory (see `EventRepository.events(in:page:)`).
Example: **Home → See all** (8 events per page, 30 events).

## SwiftUI and Storyboard together

Both are first-class. Pick per screen:

| | SwiftUI scene | Storyboard scene |
|---|---|---|
| Generate | `make scene FEATURE=X NAME=Y` | `make scene FEATURE=X NAME=Y UI=uikit` |
| View | `YView` + `@Observable` presenter | `YViewController` + `Y.storyboard` + `YViewInput` |
| Wrapped as | `HostingController` | `instantiate()` |
| Navigation | same coordinator, same `Navigator` | same |

Storyboards inside the package: set **Module** = `Features` and **Storyboard ID** =
class name (the template does it).

## Performance tips

- Lists: `LazyVStack` / `LazyVGrid`, stable `id`s, no heavy work in `body`.
- Make only the long list lazy. A lazy stack destroys rows that leave the screen,
  so a horizontal carousel inside it loses its position. Put headers and
  carousels in a plain `VStack`, and the list in a `LazyVStack` under them
  (see `HomeView`).
- No programmatic scrolling to restore position: `.scrollPosition(id:)` and
  `ScrollViewReader.scrollTo` also move the parent scroll view (the page jumps).
  A screen that stays in the navigation stack keeps its offset by itself.
- Hero sources (`.transitionSource(id:)`) are measured when the transition
  starts, not on every frame.
- A screen that summarizes (Home) shows a capped list in a plain `VStack`:
  rows are built once and scrolling costs no SwiftUI layout. Lazy stacks
  re-measure rows of varying height while scrolling (measured on Home: ~2 %
  dropped frames lazy, 0 % with a capped `VStack`). Long lists go to a
  paginated screen (`Paginator` + `LazyVStack`).
- `CADisableMinimumFrameDurationOnPhone` is on (Config/Info.plist): animations
  run at 120 Hz on ProMotion iPhones instead of 60 Hz.
- Judge smoothness on a device with a Release build; Debug and the simulator
  are slower.
- Images: always `RemoteImage` (downsampled to view size, memory + disk cache).
- `@Observable` presenters: views only re-render for properties they read.
- Formatters: use `FormatStyle` (`date.monthDayText`), never create `DateFormatter` per cell.
