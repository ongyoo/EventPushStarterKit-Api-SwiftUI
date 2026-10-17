# Navigation & deep links

## Coordinators

A coordinator owns a flow: it creates screens, decides where to go next and
handles deep links. Screens never navigate by themselves.

```
AppCoordinator                       window, tab bar, deep link entry
 ├─ HomeFlowCoordinator      tab     Home + shared routes (events, notifications)
 │   ├─ HomeCoordinator      root
 │   └─ EventDetailCoordinator       pushed, released when popped
 │       └─ EventDetailCoordinator   (another event from the organizer page)
 ├─ InboxFlowCoordinator     tab     Notifications (Storyboard) as root
 └─ SettingsFlowCoordinator  tab     Settings as root, modal demo flows
```

Features never import each other. A feature reports **what happened**; the flow
decides **what to show**:

```swift
// Features/Home/HomeCoordinator.swift
enum Output { case eventSelected(id: String), seeAllEvents(EventCategory), notificationsSelected }

// App/Flows/HomeFlowCoordinator.swift
home.onOutput = { [weak self] output in
    switch output {
    case let .eventSelected(id): self?.showEventDetail(id: id)
    ...
    }
}
```

## Navigator: push, present, transitions

`Navigator` wraps `UINavigationController`. Every coordinator has one.

```swift
// Push
navigator.push(vc)                               // system slide
navigator.push(vc, transition: .fade)            // custom, reversed on pop
navigator.push(vc, transition: .slideUp)
navigator.push(vc, transition: .scale)
navigator.push(vc, transition: .expand(sourceID: "event.42"))   // hero: card grows into the page
navigator.push(vc, transition: .zoom { [weak cell] in cell })   // iOS 18 system zoom
navigator.push(vc, transition: .custom { isPresenting in MyAnimator(isPresenting) })
navigator.push(vc) { [weak self] in self?.finish() }            // run code when popped

// Present
navigator.present(vc, style: .sheet(detents: [.medium, .large]))
navigator.present(vc, style: .sheet(detents: [.height(240)], grabber: false))
navigator.present(vc, style: .fullScreen, transition: .fade)
navigator.present(vc, style: .overFullScreen)     // keeps the screen below visible
navigator.present(vc, style: .formSheet) { print("dismissed, also by swipe") }
navigator.dismiss()

// Stack
navigator.setRoot(vc)
navigator.pop() / navigator.popToRoot() / navigator.pop(to: vc)
navigator.withoutAnimation { ... }               // build several screens at once
```

### Navigation bar

Screens never hide the bar themselves (it belongs to the whole stack). A screen
with its own header adopts `NavigationBarHiding`
(`HostingController(rootView:, hidesNavigationBar: true)`); `Navigator` shows or
hides the bar for each screen as it appears, so pushed pages always keep their
**Back** button. Swipe-back works with every transition.

### Custom back button (before iOS 26)

iOS 26 draws the back button as Liquid Glass. iOS 17–18 show the classic
chevron + previous title. `BackButtonStyle` restyles the older systems and
leaves iOS 26 alone:

```swift
// AppAssembly: the whole app (every Navigator created afterwards)
Navigator.defaultBackButton = .belowIOS26(.circle())

// One screen (while it is on top)
HostingController(rootView: view, title: "Profile", backButton: .belowIOS26(.chevron(tint: .brandPrimary, showsTitle: true)))

// One stack (e.g. a modal flow)
Navigator(backButton: .minimal)
```

| Style | Looks like |
|---|---|
| `.system` | UIKit default (Liquid Glass on iOS 26) |
| `.minimal` / `.generic` | system chevron, no title / "Back" |
| `.chevron(symbol:weight:tint:showsTitle:)` | any SF Symbol, optional color and title |
| `.circle(symbol:foreground:background:border:diameter:)` | chevron in a round button, close to iOS 26; good on photos |
| `.image(_:showsTitle:)` | your own asset |
| `.belowIOS26(style)` | `style` on iOS 17–18, `.system` on iOS 26 |

How it works: the system back button is kept, only its indicator image and
title are changed (`UINavigationBarAppearance`, `backButtonDisplayMode`). So
tap, swipe back, VoiceOver, the long-press history menu, right-to-left and
`onPop` keep working. Do not replace it with `leftBarButtonItem`: swipe back
and the history menu stop working. The circle is redrawn when the user
switches light/dark. Apps with `UIDesignRequiresCompatibility` (old design on
iOS 26) get the custom style on iOS 26 too.

Try it: Settings → Navigation → *Back button · brand chevron + title* and
*Back button · arrow* (on an iOS 17–18 simulator).

### Liquid Glass tab bar (iOS 17+)

The tab bar comes from [LiquidGlassKit](../Packages/LiquidGlassKit/README.md):
`LiquidGlassTabBarController` is a `UITabBarController` that draws an iOS
26-style floating glass bar on iOS 17 and 18 and keeps the system bar on iOS 26.

```swift
// AppCoordinator (default)
AppCoordinator(window: window, tabBarStyle: .belowIOS26(.glass))
AppCoordinator(window: window, tabBarStyle: .system)    // UIKit's bar everywhere
AppCoordinator(window: window, tabBarStyle: .glass)     // the kit's bar on iOS 26 too
```

Its look is one value, `appearance`: start from a preset (`.default`,
`.tinted`, `.solid`, `.minimal`, `.underline`) and change what you need.

```swift
tabs.appearance = .default.with {
    $0.selection.style = .solid
    $0.item.showsTitles = false
}
```

In this app the user picks the look in **Settings → Tab bar**, and can turn
**Shrink while scrolling** off if the team's UX prefers a bar that always stays
full size. Both are saved and applied live (`App/TabBarLooks.swift`). In code:
`tabs.minimizeBehavior = .never / .onScrollDown / .onScrollUp`, or
`tabs.setMinimized(_:animated:)` to control it yourself.

Glass effects (all from iOS 26): refraction at the rim, rim light that follows
tilt, adaptive light/dark, swell under the finger, a droplet you slide across
tabs (magnifies, stretches, lands with haptics), minimize on scroll
(`tabs.minimizeBehavior = .onScrollDown`, also applied to iOS 26's bar).

It is still a `UITabBarController`: `viewControllers`, `selectedIndex`, deep
links, `delegate` (analytics), `tabBarItem` title, image, selected image and
badge (live), tap on the current tab pops to its root. Screens scroll under the
glass and keep their last row above it. `Navigator` calls
`contentWillChange()` on pushes so the glass follows the new screen.

The camera is a **tab bar action**, not a tab: `tabs.actionButton =
LiquidGlassTabBarAction(image:title:) { tabs in ... }` runs your code (here
`CameraLauncher` presents the camera, or the photo library on the Simulator).
It sits raised at the center of the bar on every iOS version: the app uses the
kit's bar everywhere (`tabBarStyle: .glass`), drawn with Apple's own glass on iOS 26.

Server-driven screens open from any tab with `eventpush://screens/<id>`
(see [Server-driven UI](SERVER_DRIVEN_UI.md)).

See the kit's README for every option, accessibility and performance notes.

### Hero "expand" (tap a card → it grows into the detail page)

```swift
// 1. The card registers where it is on screen (SwiftUI):
EventCardView(event: event).transitionSource(id: HeroID.event(event.id))
// UIKit: TransitionSourceRegistry.shared.register(id, frame: cell.convert(cell.bounds, to: nil))

// 2. The coordinator pushes with the same id:
navigator.push(detail, transition: .expand(sourceID: HeroID.event(id)))
```

Works on iOS 17+. Falls back to a fade if the source is unknown or Reduce Motion is on.

### Showcase: every entry point uses a different style

| From | To | Style |
|---|---|---|
| Home · Popular card | Event detail | **hero expand** from the card |
| Home · Upcoming row, deep links | Event detail | **system push** |
| Home · See all | Event list | **push · slide up** |
| Event list row | Event detail | **full-screen modal (fade)** with its own stack + Close |
| Home · bell | Notifications | **sheet** (medium / large) with its own stack |
| Notification row | Event detail | **push · scale** (inside the sheet, or in the Inbox tab) |
| Event detail · organizer | Organizer | **push · fade** |
| Organizer · another event | Event detail | **custom 3D flip** (`.custom { FlipAnimator(...) }`) |
| Settings → Navigation & transitions | demo screens | every style side by side |

The choices live in one place: `Modules/Sources/App/Flows/TabFlowCoordinator.swift`.

### Modal flows (their own navigation stack)

```swift
presentChild(style: .sheet(detents: [.large])) { navigator in
    CheckoutCoordinator(navigator: navigator)      // pushes inside the modal
}
// inside CheckoutCoordinator, when done:
dismissFlow()
```

The child is released when the modal closes, by button **or** swipe-down.
Try every style in the app: **Settings → Navigation & transitions**.

### Writing a custom transition

Implement `UIViewControllerAnimatedTransitioning` (see `TransitionAnimator`)
and pass it with `.custom { isPresenting in ... }`. Respect
`UIAccessibility.isReduceMotionEnabled` (fall back to a fade).

## Memory: how flows get released

`Navigator` knows when a screen leaves the stack in **any** way (back button,
swipe, `popToRoot`, modal swipe-down) and runs its `onPop`/`onDismiss`, so the
coordinator finishes and its parent drops it. `LeakDetector` then warns if it
is still alive. Tests check this for every feature.

## Deep links

Both forms work and produce the same `DeepLink`:

```
eventpush://events/42/organizer          custom scheme   (Config: DEEP_LINK_SCHEME)
https://eventpush.app/events/42/organizer universal link (Config: UNIVERSAL_LINK_HOST)
```

### Relay routing: any depth, any feature

Each level reads the segment it understands and passes the rest down:

```
"inbox/events/42/organizer"
 AppCoordinator      "inbox"     → select Inbox tab
 InboxFlow           "events"    → (shared route) 
                     "42"        → start EventDetailCoordinator(42)
 EventDetail         "organizer" → push Organizer
```

| Link | Result |
|---|---|
| `home` | Home tab |
| `events` · `events?category=music` | Event list (filtered) |
| `events/42` | Event 42 |
| `events/42/organizer` | Event 42 → Organizer |
| `home/notifications` | Home → Notifications (sheet) |
| `inbox` · `inbox/events/42/organizer` | Inbox tab (+ deeper) |
| `settings` | Settings tab |
| `debug/animations` | Animation gallery (Debug builds) |

A new link resets the tab to its root first (released flows are leak-checked).
Links arriving before the UI exists (cold start, notification tap, Siri) wait in
`DeepLinkInbox` and run as soon as `AppCoordinator` starts.

### Add a deep link

1. In the feature coordinator, handle the segments after its prefix:
   ```swift
   override func handle(_ link: DeepLink) -> Bool {
       switch link.first {
       case nil: return true
       case "settings": showSettings(); return link.dropFirst().isEmpty
       default: return false
       }
   }
   ```
2. In the tab flow (`TabFlowCoordinator.route` for links valid in every tab):
   ```swift
   case "profile":
       guard let id = link.dropFirst().first else { return false }
       return showProfile(id: id).handle(link.dropFirst(2))
   ```
3. Add a test in `AppTests/AppCoordinatorTests.swift`.

### Try it

```bash
# Debug builds accept a launch argument (no system confirmation dialog):
xcrun simctl launch booted NathatK.EventPushStarterKit -DeepLink "eventpush://events/3/organizer"
# Or like a real link:
xcrun simctl openurl booted "eventpush://inbox/events/2"
```

Universal links also need the `applinks:` Associated Domains entitlement and an
`apple-app-site-association` file on your domain.
