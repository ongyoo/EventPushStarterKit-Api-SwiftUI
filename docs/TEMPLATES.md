# Templates: new feature, new screen, new app

## New feature

```bash
make feature NAME=Profile            # SwiftUI first screen
make feature NAME=Wallet UI=uikit    # Storyboard first screen
```

Creates (nothing to register, the folder is picked up automatically):

```
Modules/Sources/Features/Profile/
  ProfileCoordinator.swift                 entry point, Output, deep links
  Scenes/Profile/ProfileContract|Builder|View|Presenter|Interactor.swift
Modules/Tests/FeaturesTests/Profile/
  ProfileCoordinatorTests.swift            start, output, deep links, memory release
  ProfilePresenterTests.swift              states, routing, weak router, rendering
```

The generated tests pass immediately. Then:

1. Replace the sample `ProfileItem` / interactor with real data: entities, use
   cases and a repository protocol in Domain, the implementation in DataLayer
   (registered in `DataAssembly`).
2. Start it from a flow in the App layer (`Modules/Sources/App/Flows/...`) and
   handle its `Output`. The generated coordinator is already `public`.
3. Add its deep link to the flow's `route(_:)`.

## New screen in a feature

```bash
make scene FEATURE=Profile NAME=EditProfile
make scene FEATURE=Profile NAME=Avatar UI=uikit
```

Scene names must be unique across features (one module = one namespace); the
script checks it.

## From Xcode

```bash
make templates        # once; restart Xcode
```

File → New → File → **VIPER** → *VIPER scene (SwiftUI)* or *VIPER scene (UIKit + Storyboard)*.
Same files as the script, without tests.

## New app

```bash
make project NAME=ShopApp BUNDLE=com.acme.shop DEST=~/Projects TEAM=ABCDE12345
```

Copies the app target, Config, Core, Navigation, DesignSystem,
DataSources, Platform, scripts, templates and docs; creates empty Domain and
DataLayer modules and an App layer with one Home tab (generated feature);
renames the Xcode project; sets bundle id, team and deep link scheme; runs
`git init`. Then set `API_BASE_URL` in `Config/*.xcconfig`.

## Where the templates live

```
Templates/Xcode/VIPER/*.xctemplate     screen files (used by Xcode AND scripts)
Templates/Tests/{SwiftUI,UIKit}/       screen tests (scripts only)
Templates/Feature/, FeatureTests/      coordinator + its tests
Templates/Project/                     App / Domain / DataLayer starting point for new apps
Templates/Extensions/LiveActivity/     widget extension source
Templates/Extensions/Analytics/        SDK adapter example (Firebase)
```

Change a template once; scripts and Xcode both use it.
