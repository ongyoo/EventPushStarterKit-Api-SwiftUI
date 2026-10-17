# Server-driven UI (BFF)

Some screens are described by the backend instead of being coded in the app:
campaigns, promos, onboarding, a home section. The app renders them natively
with Liquid Glass components, opens them from deep links, and still shows them
offline.

The renderer is a standalone package, [ServerDrivenUI](../Packages/ServerDrivenUI/README.md),
and the JSON format is documented in its [schema](../Packages/ServerDrivenUI/docs/SCHEMA.md).

## How it fits the layers

```
BFF  GET bff/screens/<id>?schema=1&lang=th
 │
 ▼
Data      RemoteDynamicScreenRepository   network → last good copy → copy shipped in the app
 │        (DynamicScreenEndpoint, DynamicScreenFixtures: Resources/Fixtures/screen-<id>.json)
 ▼
Domain    DynamicScreenRepository          JSON payload + where it came from (no UI types)
 ▼
Features  DynamicScreen (VIPER)            decode + version checks, render, actions
          AppComponents                    standard components + app ones (event_card)
 ▼
App       TabFlowCoordinator               deep link screens/<id> from any tab
```

## Open a screen

- Deep link: `eventpush://screens/songkran` (push notification, QR code, web).
- Code: `startChild(DynamicScreenCoordinator(navigator: navigator, screenID: "songkran"))`.
- From another server screen: `{ "type": "screen", "id": "songkran", "presentation": "sheet" }`.
- Demo: Settings → Navigation → *Server-driven screen (BFF)*.

## What the app does with actions

| Action | Here |
|---|---|
| `deepLink` | `DeepLinkInbox` → the normal app router (any tab, any depth) |
| `openURL` | Safari / mail / phone (http, https, mailto, tel only) |
| `screen` | push, sheet or full screen of another server screen |
| `track` | `AnalyticsTracking` (consent and privacy filter apply) |
| `dismiss` / `reload` | close / fetch again |
| `setState`, `toggleState` | inside the screen, no network |

## Add a component the backend can use

1. Register it in `Features/DynamicScreen/AppComponents.swift`:

   ```swift
   registry.register("ticket_tier") { component, context in
       TicketTierRow(name: component.string("name") ?? "", price: component.double("price") ?? 0)
           .onTapGesture { component.action.map(context.perform) }
   }
   ```

2. Document its props for the backend team (add a row to the schema doc).
3. Ship. Older builds skip `ticket_tier` until they update; use `minAppVersion`
   if the screen makes no sense without it.

## Offline and failures

| Situation | What the user sees |
|---|---|
| BFF answers | the fresh screen (kept as the last good copy) |
| BFF down / offline | the last good copy |
| never loaded, offline | the copy shipped in the app (`screen-<id>.json`), if any |
| newer schema / `minAppVersion` | "Update the app to see this page." |
| broken JSON | "This page is not available right now." + retry |

Debug builds use the Mock API: the shipped JSON files answer `bff/screens/<id>`.

## Tests

- `ServerDrivenUITests`: decoding, versions, actions, conditions, every component rendered.
- `RemoteDynamicScreenRepositoryTests`: network, cache, bundled fallbacks.
- `DynamicScreenPresenterTests`: errors, every action, builder, coordinator.
