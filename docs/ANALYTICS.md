# Analytics

Track what users do without tying the app to an SDK. Screens are tracked
automatically; business events are one line; the user can opt out; personal
data is filtered out before anything leaves the app.

## How it fits the layers

```
Features / App        analytics.track(.eventSelected(id:source:))      what happened
      │  AnalyticsTracking (Core, protocol)
      ▼
Platform              AnalyticsCenter: consent → SDK limits → PII filter → providers
      │  AnalyticsProvider (one adapter per SDK)
      ▼
SDKs                  Console (Debug) · Firebase · Amplitude · your backend ...
```

| Piece | Layer | Role |
|---|---|---|
| `AnalyticsTracking`, `AnalyticsEvent`, `NoopAnalytics`, `RecordingAnalytics` | Core | The contract every layer uses. No SDK. |
| `AnalyticsCenter`, `AnalyticsProvider`, `ConsoleAnalyticsProvider` | Platform | Consent, limits, privacy, fan-out to SDK adapters. |
| Screen tracking (`Navigator`, `ScreenName`, `AnalyticsScreenNaming`) | Navigation | One `screen_view` per screen shown. |
| `AppAssembly.registerAnalytics` | App | Chooses the providers (composition root). |
| `Features/Shared/AnalyticsEvents.swift` | Features | The tracking plan: every business event in one file. |

## What is tracked

| Event | Parameters | Sent by |
|---|---|---|
| `screen_view` | `screen_name` | `Navigator` (push, pop back, modal root), tab switch, deep link to a tab |
| `deep_link_opened` | `route` (`events/:id/organizer`, ids removed), `handled` | `AppCoordinator` |
| `event_selected` | `event_id`, `source` (`popular`, `upcoming`...) | Home |
| `category_selected` | `category` | Home |
| `see_all_tapped` | `category` | Home |
| `favorite_toggled` | `event_id`, `is_favorite` | Event detail (only when saved) |
| `language_changed` | `language` | Settings |
| `permission_requested` | `permission`, `granted` | Settings |
| user property `app_language` | `en` / `th` | `AppCoordinator` |

## Add an event

```swift
// Features/Shared/AnalyticsEvents.swift
static func ticketPurchased(eventID: String, quantity: Int) -> AnalyticsEvent {
    AnalyticsEvent("ticket_purchased", ["event_id": .string(eventID), "quantity": .int(quantity)])
}

// Presenter (injected, so tests can check it)
init(..., analytics: any AnalyticsTracking = Container.shared.analytics())
analytics.track(.ticketPurchased(eventID: event.id, quantity: 2))
```

Rules:

- **snake_case**, past tense, ≤ 40 characters; ≤ 25 parameters; string values ≤ 100 characters.
- **Ids, counts, categories only.** Never names, emails, phone numbers, search
  text or free text. `AnalyticsCenter` drops parameters whose name looks
  personal (`email`, `phone`, `token`, `address`, `first_name`...) or whose value
  looks like an email, and logs a warning in the console.
- Track in the **presenter**, after the action succeeded (not when it was only attempted).
- Screen views are automatic. Name a screen explicitly only when the type name
  is not good: `HostingController(rootView: view, screenName: "checkout")` or
  `AnalyticsScreenNaming` for UIKit screens.

## Screen names

From the screen's type: `EventDetailView` → `event_detail`,
`NotificationViewController` → `notification`, `URLSettingsView` → `url_settings`.

## Consent

- Settings → Privacy → **Share usage analytics**. Off = nothing is sent, and
  every provider is reset (ids and queued data cleared).
- The choice is stored in preferences and survives relaunch.
- Default is set in `AppAssembly.registerAnalytics`: `enabledByDefault: true`
  (opt-out). Use `false` (opt-in) where the law requires consent first, e.g.
  GDPR in the EU.
- Analytics without the advertising identifier does not need the App Tracking
  Transparency prompt. If an SDK uses IDFA, ask `Permission.tracking` first.

## Add an SDK (Firebase example)

1. Add the package to `Modules/Package.swift`, as a dependency of **Platform only**.
2. Copy `Templates/Extensions/Analytics/FirebaseAnalyticsProvider.swift` to
   `Modules/Sources/Platform/Analytics/`.
3. In `AppAssembly.registerAnalytics`: `providers.append(FirebaseAnalyticsProvider())`.
4. Declare the collected data in `PrivacyInfo.xcprivacy`.

Several SDKs at once? Append several providers: every event goes to each.

## See events while developing

Debug builds include `ConsoleAnalyticsProvider`: events appear in the Xcode
console and in Console.app (category `analytics`):

```
📊 property app_language=en
📊 deep_link_opened handled=true route=events/:id/organizer
📊 screen_view screen_name=organizer
```

## Testing

```swift
let analytics = RecordingAnalytics()
let presenter = HomePresenter(interactor: stub, router: nil, analytics: analytics)
presenter.didTapSeeAll()
#expect(analytics.eventNames == ["see_all_tapped"])
```
