//
//  AppEnvironment.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import Foundation

/// Values that change per build configuration (Debug / Release / Staging...).
///
/// They come from `Config/*.xcconfig` -> `Info.plist` -> here,
/// so no URL or secret is hard-coded in Swift.
public struct AppEnvironment: Sendable, Equatable {
    /// Build flavour, from `APP_ENVIRONMENT` in Config/*.xcconfig.
    public enum Name: String, Sendable {
        case development, staging, production
    }

    public let name: Name
    public let apiBaseURL: URL
    public let deepLinkScheme: String
    public let universalLinkHost: String
    public let bundleIdentifier: String
    /// Hosts that require SSL pinning (Info.plist `SSL_PINNED_HOSTS`, comma separated).
    public let pinnedHosts: [String]
    /// Serve bundled JSON fixtures instead of calling the server (Info.plist `USE_MOCK_API`).
    public let useMockAPI: Bool
    /// Optional capabilities switched on in Config/Features.xcconfig.
    public let features: AppFeatures
    /// Language codes the app ships (Info.plist `APP_LANGUAGES`), first = default.
    public let languages: [String]

    /// Manual environment for tests / previews:
    ///
    ///     AppEnvironment(name: .development, apiBaseURL: url, deepLinkScheme: "app",
    ///                    universalLinkHost: "example.com", bundleIdentifier: "test")
    public init(
        name: Name,
        apiBaseURL: URL,
        deepLinkScheme: String,
        universalLinkHost: String,
        bundleIdentifier: String,
        pinnedHosts: [String] = [],
        useMockAPI: Bool = false,
        features: AppFeatures = .all,
        languages: [String] = ["en"]
    ) {
        self.name = name
        self.apiBaseURL = apiBaseURL
        self.deepLinkScheme = deepLinkScheme
        self.universalLinkHost = universalLinkHost
        self.bundleIdentifier = bundleIdentifier
        self.pinnedHosts = pinnedHosts
        self.useMockAPI = useMockAPI
        self.features = features
        self.languages = languages.isEmpty ? ["en"] : languages
    }

    /// `true` for App Store builds (`APP_ENVIRONMENT = production`).
    public var isProduction: Bool { name == .production }
}

public extension AppEnvironment {
    /// Built once from the main bundle's Info.plist.
    static let current = AppEnvironment(bundle: .main)

    /// Safe defaults so previews and unit tests work without an Info.plist.
    static let preview = AppEnvironment(
        name: .development,
        apiBaseURL: URL(string: "https://example.com") ?? URL(fileURLWithPath: "/"),
        deepLinkScheme: "app",
        universalLinkHost: "example.com",
        bundleIdentifier: "com.example.preview"
    )

    init(bundle: Bundle) {
        self.init(info: bundle.infoDictionary ?? [:], bundleIdentifier: bundle.bundleIdentifier)
    }

    /// Builds from Info.plist values; missing keys fall back to `.preview`.
    init(info: [String: Any], bundleIdentifier: String?) {
        let fallback = AppEnvironment.preview

        func string(_ key: String) -> String? {
            (info[key] as? String).flatMap { $0.isEmpty ? nil : $0 }
        }

        self.init(
            name: string("APP_ENVIRONMENT").flatMap(Name.init(rawValue:)) ?? fallback.name,
            apiBaseURL: string("API_BASE_URL").flatMap(URL.init(string:)) ?? fallback.apiBaseURL,
            deepLinkScheme: string("DEEP_LINK_SCHEME") ?? fallback.deepLinkScheme,
            universalLinkHost: string("UNIVERSAL_LINK_HOST") ?? fallback.universalLinkHost,
            bundleIdentifier: bundleIdentifier ?? fallback.bundleIdentifier,
            pinnedHosts: string("SSL_PINNED_HOSTS")?
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty } ?? [],
            useMockAPI: string("USE_MOCK_API")?.uppercased() == "YES",
            features: AppFeatures(info["APP_FEATURES"] as? [String: String]),
            languages: string("APP_LANGUAGES")?.split(separator: " ").map(String.init) ?? fallback.languages
        )
    }
}

/// Optional capabilities. Off = the service is never started at runtime
/// (and its Info.plist keys / entitlements are removed at build time).
public struct AppFeatures: Sendable, Equatable {
    public var localNotifications: Bool
    public var backgroundTasks: Bool
    public var silentPush: Bool
    public var liveActivities: Bool
    public var siri: Bool

    /// Explicit flags (tests): `AppFeatures(localNotifications: true)`.
    public init(
        localNotifications: Bool = false,
        backgroundTasks: Bool = false,
        silentPush: Bool = false,
        liveActivities: Bool = false,
        siri: Bool = false
    ) {
        self.localNotifications = localNotifications
        self.backgroundTasks = backgroundTasks
        self.silentPush = silentPush
        self.liveActivities = liveActivities
        self.siri = siri
    }

    /// Everything on (previews, tests).
    public static let all = AppFeatures(localNotifications: true, backgroundTasks: true, silentPush: true, liveActivities: true, siri: true)
    /// Everything off (missing `APP_FEATURES`).
    public static let none = AppFeatures()

    /// Parses `APP_FEATURES` (values "YES" / "NO"). Missing dictionary = all off.
    public init(_ info: [String: String]?) {
        func flag(_ key: String) -> Bool { info?[key]?.uppercased() == "YES" }
        self.init(
            localNotifications: flag("localNotifications"),
            backgroundTasks: flag("backgroundTasks"),
            silentPush: flag("silentPush"),
            liveActivities: flag("liveActivities"),
            siri: flag("siri")
        )
    }
}
