# ServerDrivenUI

Screens described by your backend (BFF) as JSON, rendered as native SwiftUI
with Liquid Glass components (via [LiquidGlassKit](../LiquidGlassKit)). Change
a campaign page, reorder a home section or run an A/B test without an app release.

- Small, versioned [schema](docs/SCHEMA.md): 20 components, 10 actions, state and conditions.
- Safe by design: unknown components and broken actions are skipped; newer
  schemas and `minAppVersion` produce a clear "update the app" state.
- Glass everywhere: native `glassEffect` on iOS 26, LiquidGlassKit on iOS 17–18.
- Extensible: register your own component types with your own views.
- Interactive without the server: `setState`, `bind`, `visibleIf`, `{{key}}` text.
- iOS 17+, depends only on LiquidGlassKit.

## Use

```swift
import ServerDrivenUI

let screen = try DynamicScreenDecoder.decode(jsonData, appVersion: "1.4.0")

DynamicScreenView(screen: screen) { action in
    switch action {
    case let .deepLink(url): router.open(url)
    case let .screen(id, presentation): router.showScreen(id, presentation)
    case let .track(event, params): analytics.track(event, params)
    case .dismiss: router.close()
    default: break
    }
}
```

State actions (`setState`, `toggleState`, inside `sequence` too) run inside
the view; your handler gets the rest.

## Add your own component

```swift
var registry = DynamicComponentRegistry.standard
registry.register("event_card") { component, context in
    EventCard(id: component.string("eventId") ?? "")
        .onTapGesture { component.action.map(context.perform) }
}
DynamicScreenView(screen: screen, registry: registry) { ... }
```

`registry.supportedTypes` lists what the app can draw: send it to the backend
so it only uses components this build knows.

## Tests

```bash
xcodebuild test -scheme ServerDrivenUI -destination 'platform=iOS Simulator,name=iPhone 16 Pro'
```
