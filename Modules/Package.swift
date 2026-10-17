// swift-tools-version: 6.0
import PackageDescription

// One package, one module per layer. A module may import only the modules
// listed in its `dependencies`. Enforced on every build by
// scripts/check-layers.py (Xcode alone lets an undeclared import through when
// that module happens to be built earlier in the same build).
//
//   App             Composition root: DI wiring, app routing, tabs, deep links, lifecycle hooks.
//    │              (The Xcode app target is only AppDelegate + SceneDelegate and links `App`.)
//    ▼
//   Features        Presentation: screens, presenters, coordinators. One folder per feature.
//    │ uses business contracts only
//    ▼
//   Domain          Entities, use cases, repository protocols, domain errors. Pure Swift.
//    ▲ implements
//   Data/           (group)
//     DataLayer     Repository implementations, DTO + mapping, cache, fixtures.
//      ▼
//     DataSources   Where data lives: network (Alamofire), database (SwiftData),
//                   Keychain, encrypted files, UserDefaults.
//
//   Platform        Device services: notifications, push, background tasks,
//                   permissions, Live Activities, crash reports, biometrics, analytics.
//
//   Cross-cutting (any layer may use):
//   Core            Foundation (DI, environment, state) · Logging · Concurrency · Utilities
//                   Localization · Routing · Storage and analytics contracts
//   Navigation      Navigator, coordinators, transitions, screen tracking (UIKit)
//   DesignSystem    Tokens, components, animation, layout, keyboard (Kingfisher inside)
//
// Third-party libraries stay inside one module each and never leak:
//   Alamofire -> DataSources (behind APIClient), Kingfisher -> DesignSystem (behind RemoteImage).
let package = Package(
    name: "Modules",
    defaultLocalization: "en",
    platforms: [.iOS(.v17)],
    products: [
        // Linked by the app target.
        .library(name: "App", targets: ["App"]),
        // For app extensions (Live Activity widget, notification extensions): pure, small.
        .library(name: "Domain", targets: ["Domain"]),
    ],
    dependencies: [
        .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.10.0"),
        .package(url: "https://github.com/onevcat/Kingfisher.git", from: "8.1.0"),
        // In-house, no dependencies. Its own package so it can move to its own repo.
        .package(path: "../Packages/LiquidGlassKit"),
        // In-house: BFF screens as JSON, rendered with glass components.
        .package(path: "../Packages/ServerDrivenUI"),
    ],
    targets: [
        // Cross-cutting
        .target(name: "Core"),
        .target(
            name: "DesignSystem",
            dependencies: ["Core", .product(name: "Kingfisher", package: "Kingfisher")],
            resources: [.process("Resources")]
        ),
        .target(
            name: "Navigation",
            dependencies: ["Core", .product(name: "LiquidGlassKit", package: "LiquidGlassKit")]
        ),

        // Layers, bottom to top
        .target(
            name: "DataSources",
            dependencies: ["Core", .product(name: "Alamofire", package: "Alamofire")],
            path: "Sources/Data/DataSources"
        ),
        .target(name: "Platform", dependencies: ["Core"]),
        .target(name: "Domain", dependencies: ["Core"]),
        .target(
            // Not "Data": that would clash with Foundation's `Data` type.
            name: "DataLayer",
            dependencies: ["Core", "Domain", "DataSources"],
            path: "Sources/Data/DataLayer",
            resources: [.process("Resources")]
        ),
        .target(
            // Storyboards / xibs / asset catalogs in feature folders are processed automatically.
            name: "Features",
            dependencies: [
                "Core", "Navigation", "DesignSystem", "Domain",
                .product(name: "LiquidGlassKit", package: "LiquidGlassKit"),
                .product(name: "ServerDrivenUI", package: "ServerDrivenUI"),
            ],
            resources: [.process("Resources")]
        ),
        .target(
            name: "App",
            dependencies: [
                "Core", "Navigation", "DesignSystem", "Platform", "DataSources", "Domain", "DataLayer", "Features",
                .product(name: "LiquidGlassKit", package: "LiquidGlassKit"),
                .product(name: "ServerDrivenUI", package: "ServerDrivenUI"),
            ]
        ),

        .testTarget(name: "CoreTests", dependencies: ["Core"]),
        .testTarget(name: "NavigationTests", dependencies: ["Navigation"]),
        .testTarget(name: "DesignSystemTests", dependencies: ["DesignSystem"]),
        .testTarget(name: "DataSourcesTests", dependencies: ["DataSources"]),
        .testTarget(name: "PlatformTests", dependencies: ["Platform"]),
        .testTarget(name: "DomainTests", dependencies: ["Domain"]),
        .testTarget(name: "DataLayerTests", dependencies: ["DataLayer"]),
        .testTarget(name: "FeaturesTests", dependencies: ["Features"]),
        .testTarget(name: "AppTests", dependencies: ["App"]),
    ]
)
