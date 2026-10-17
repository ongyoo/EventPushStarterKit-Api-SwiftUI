# Capabilities: notifications, background, push, Live Activities, Siri, permissions

Optional system features are switched **on/off in one file**:

```
Config/Features.xcconfig
FEATURE_LOCAL_NOTIFICATIONS = YES
FEATURE_BACKGROUND_TASKS    = YES
FEATURE_SILENT_PUSH         = NO
FEATURE_LIVE_ACTIVITIES     = NO
FEATURE_SIRI                = YES
```

`NO` really means *not there*:

| Layer | What the flag controls |
|---|---|
| Info.plist | The **Apply Feature Flags** build phase (`scripts/apply-feature-flags.sh`) adds `UIBackgroundModes`, `BGTaskSchedulerPermittedIdentifiers`, `NSSupportsLiveActivities` to the built Info.plist only when on |
| Entitlements | `aps-environment` only when `FEATURE_SILENT_PUSH = YES` |
| App target code | `#if FEATURE_SIRI`, `#if FEATURE_SILENT_PUSH` remove it from the binary |
| Runtime | `AppEnvironment.current.features` – `AppAssembly` starts only enabled services |

After changing a flag: **Product → Clean Build Folder**. See them in the app:
**Settings → Capabilities**.

> `Config/Info.plist` stays a normal plist (safe to edit in Xcode). Capability
> keys are never written there by hand: the build phase manages them.

---

## Local notifications (`LocalNotificationCenter`)

```swift
let center = LocalNotificationCenter.shared

// Schedule
try await center.schedule(LocalNotification(
    title: "Starts soon", body: "King's Cup in 1 hour",
    trigger: .after(3600),                       // .now · .after(sec, repeats:) · .at(DateComponents, repeats:)
    sound: .default,                             // .none · .named("ding.caf")
    badge: 1,
    group: "event-1",                            // stacked together
    categoryID: "event",                         // action buttons
    deepLink: "events/1",                        // opened on tap (any depth)
    attachmentURL: localImageURL,                // rich image
    priority: .timeSensitive                     // .passive · .active · .timeSensitive
))

// Remove
center.cancel(ids: ["reminder-1"])     // scheduled, not shown yet
center.cancelAll()
center.removeDelivered(ids: [...])     // already in Notification Center
await center.removeGroup("event-1")    // whole stack, pending + delivered
center.removeAllDelivered()
await center.setBadge(0)
```

Action buttons (incl. reply text field) are declared in
`App/AppNotifications.swift` and handled in `AppNotifications.handle`.
Taps with a `deepLink` go through `DeepLinkInbox` → normal navigation.

**Custom notification UI** (long-press view): add a *Notification Content
Extension* target and set its `UNNotificationExtensionCategory` to your category id.
**Modify incoming push** (images, decryption): add a *Notification Service Extension*.
Both can link the `Domain` product.

## Background tasks (`BackgroundTaskService`)

| Kind | API | Use for |
|---|---|---|
| App refresh (~30 s, system decides when) | `registerRefresh(every:) { ... }` | fetch fresh content |
| Processing (minutes, often while charging) | `registerProcessing(requiresNetwork:requiresPower:) { ... }` | sync, cleanup, ML |
| Finish after leaving the app (~30 s) | `BackgroundTaskService.runWithExtraTime("upload") { ... }` | complete a save/upload |

Registered in `AppAssembly.configureCapabilities` (must happen during launch).
Scheduled automatically when the app goes to background. Identifiers missing
from Info.plist are logged and ignored instead of crashing.

Test on device: pause in Xcode, then in lldb:
`e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"NathatK.EventPushStarterKit.refresh"]`

## Silent push (`PushService`)

1. Apple Developer: enable Push Notifications for the App ID.
2. `FEATURE_SILENT_PUSH = YES` (adds entitlement + `remote-notification` mode).
3. Send the token to your backend: `PushService.shared.onTokenChange = { token in ... }`.
4. Register handlers by payload `type`:
   ```swift
   PushService.shared.on("events.refresh") { payload in
       (try? await repository.events()) != nil      // true = new data
   }
   ```
   Payload: `{"aps":{"content-available":1},"type":"events.refresh"}`

## Live Activities (`LiveActivityService`)

1. Add the Widget Extension with `Templates/Extensions/LiveActivity/EventLiveActivity.swift` (steps in the file).
2. `FEATURE_LIVE_ACTIVITIES = YES`.
3. Start / update / end from the app:
   ```swift
   let service = LiveActivityService<EventActivityAttributes>()
   let id = try service.start(EventActivityAttributes(event: event),
                              state: .init(status: "Gates open", startsAt: event.startDate))
   await service.update(id, state: .init(status: "Kick-off", startsAt: event.startDate))
   await service.end(id)
   ```
`EventActivityAttributes` is in Domain so the app and the extension share it.

## Siri, Shortcuts, Apple Intelligence (App Intents)

`App/Sources/Intents/AppShortcuts.swift` (compiled only with `FEATURE_SIRI = YES`):

- Intents: *Browse events*, *Open notifications*, *Open event (ID)*.
- Phrases work with no setup: "Show events in EventPush".
- Each intent opens a deep link (`AppLinks.open(path:)`), so navigation code is reused.

Add an intent = add a struct conforming to `AppIntent` + a phrase in `AppShortcuts`.

## Permissions (`PermissionCenter`)

```swift
let permissions = PermissionCenter.shared
switch await permissions.request(.camera) {
case .authorized, .limited:      openCamera()
case .denied:                    showExplanation(); permissions.openSettings()
case .restricted, .unavailable:  hideCameraFeature()
case .notDetermined, .provisional: break
}
let status = await permissions.status(.locationWhenInUse)   // read without asking
```

Covers notifications (incl. provisional), camera, microphone, photos (full /
add-only), location, contacts, calendar, tracking (ATT).

| Status | Meaning | What to do |
|---|---|---|
| `notDetermined` | never asked | ask when the user taps the feature |
| `authorized` / `limited` / `provisional` | can use (fully / partly / quietly) | use it |
| `denied` | user said no | explain + `openSettings()` |
| `restricted` | parental controls / MDM | hide the feature |
| `unavailable` | missing purpose string, not in an app | fix Info.plist |

Rules: ask in context (never at launch), one permission at a time, explain
before the system prompt. Remove unused purpose strings and cases before release.

## Crash monitoring (`CrashMonitor`)

MetricKit delivers crash, hang, CPU and disk-write reports from real users –
no SDK, no size cost. Plug any backend:

```swift
struct MyReporter: CrashReporting {
    func report(_ diagnostic: CrashDiagnostic) { /* upload diagnostic.json */ }
}
CrashMonitor.shared.start(reporter: MyReporter())
```

Debug: Xcode → Debug → Simulate MetricKit Payloads.
