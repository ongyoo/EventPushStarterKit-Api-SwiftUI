# Localization

Languages: **English (en)** and **Thai (th)**. Texts live in String Catalogs:

```
Modules/Sources/Features/Resources/Localizable.xcstrings      app texts
Modules/Sources/DesignSystem/Resources/Localizable.xcstrings  shared states (error, retry...)
App/Resources/InfoPlist.xcstrings                              app name under the icon
```

## Use a text

```swift
Text(L10n.Home.popular)                    // typed accessors (Features/Shared/L10n.swift)
L10n.Event.eventsCount(3)                  // plurals: "3 events" / "3 อีเวนต์"
L10n.category(.music)
L10n.tr("settings.title")                  // one-off keys
```

Never write user-facing text as a literal. Data from the server is already
localized by the backend (send `Accept-Language` from `AppLocale.current` if needed).

## Add a text

1. Add the key to `scripts/strings.py` (en + th) and run `make strings`,
   **or** add it in Xcode's String Catalog editor.
2. Add a typed accessor in `L10n` if used more than once.
3. `make test` – `LocalizationTests` fails if any key is missing in any language.

## Change language

| Where | What happens |
|---|---|
| In the app (Settings tab → Language) | Instant: `LocalizationManager.select(_:)` → `AppCoordinator` rebuilds every screen on the same tab. Dates/numbers switch too (`AppLocale`). |
| iOS Settings → EventPush → Language | iOS relaunches the app in that language. Shown because `UIPrefersShowingLanguageSettings` + `CFBundleLocalizations` are in the Info.plist. |
| "Same as device" | Follows the iPhone language; falls back to the first supported language. |

Both stay in sync: the in-app choice is written to `AppleLanguages`, which is
what iOS Settings shows.

## Add a language

1. `Config/Base.xcconfig`: `APP_LANGUAGES = en th ja`
2. `Config/Info.plist`: add `ja` to `CFBundleLocalizations`
3. Add translations (`scripts/strings.py` tuples or Xcode catalogs), add `ja` to `knownRegions` (Xcode does it when you add the language in Project > Info).
4. `make test`.
