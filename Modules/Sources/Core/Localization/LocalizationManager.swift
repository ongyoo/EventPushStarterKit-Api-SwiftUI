//
//  LocalizationManager.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import Foundation
import Observation

/// App language with live switching.
///
/// - Follows the device language by default (`.system`).
/// - The user can pick a language in the app: texts switch immediately
///   (the app coordinator rebuilds the screens) and the choice is written to
///   `AppleLanguages`, so Settings > <App> > Language shows the same value.
/// - If the user changes it in Settings, iOS relaunches the app and that
///   choice wins.
///
/// Read texts through `localized(_:bundle:)` (wrapped by each module's `L10n`).
@MainActor
@Observable
public final class LocalizationManager {
    /// What the user picked: follow the device, or a fixed language.
    public enum Selection: Hashable, Sendable {
        case system
        case language(String)
    }

    /// A supported language.
    public struct Language: Identifiable, Hashable, Sendable {
        public let code: String
        public var id: String { code }

        /// `Language(code: "th")`
        public init(code: String) {
            self.code = code
        }
        /// Name in its own language: "English", "ไทย".
        public var nativeName: String {
            Locale(identifier: code).localizedString(forLanguageCode: code)?.capitalized ?? code
        }
    }

    /// Used by every `L10n`. Languages come from `APP_LANGUAGES`.
    public static let shared = LocalizationManager()

    /// Languages the app ships, in display order.
    public let supported: [Language]
    public private(set) var selection: Selection
    public private(set) var current: Language

    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private var observers: [UUID: @MainActor (Language) -> Void] = [:]
    @ObservationIgnored private var bundles: [String: Bundle] = [:]

    private static let selectionKey = "app.language"
    private static let appleLanguagesKey = "AppleLanguages"

    public init(
        supportedCodes: [String] = AppEnvironment.current.languages,
        defaults: UserDefaults = .standard,
        systemLanguages: [String] = Locale.preferredLanguages
    ) {
        let codes = supportedCodes.isEmpty ? ["en"] : supportedCodes
        self.supported = codes.map(Language.init(code:))
        self.defaults = defaults

        let stored = defaults.string(forKey: Self.selectionKey)
        let resolvedSystem = Self.resolve(systemLanguages, supported: codes)
        if let stored, stored != "system", codes.contains(stored) {
            // Settings > App > Language rewrites AppleLanguages: it wins over the stored in-app choice.
            let code = Self.resolve(defaults.stringArray(forKey: Self.appleLanguagesKey) ?? [stored], supported: codes)
            self.selection = .language(code)
            self.current = Language(code: code)
        } else {
            self.selection = .system
            self.current = Language(code: resolvedSystem)
        }
        AppLocale.set(Locale(identifier: current.code))
    }

    /// Locale of the current language (for formatting).
    public var locale: Locale { Locale(identifier: current.code) }

    /// Switches language now and notifies observers (the app rebuilds its screens).
    ///
    ///     LocalizationManager.shared.select(.language("th"))   // or .system
    public func select(_ selection: Selection) {
        let previous = current
        self.selection = selection
        switch selection {
        case .system:
            defaults.set("system", forKey: Self.selectionKey)
            defaults.removeObject(forKey: Self.appleLanguagesKey)
            current = Language(code: Self.resolve(Locale.preferredLanguages, supported: supported.map(\.code)))
        case let .language(code):
            let code = supported.contains(where: { $0.code == code }) ? code : supported[0].code
            defaults.set(code, forKey: Self.selectionKey)
            defaults.set([code], forKey: Self.appleLanguagesKey)
            current = Language(code: code)
        }
        AppLocale.set(locale)
        if current != previous {
            observers.values.forEach { $0(current) }
        }
    }

    /// Called after every language change. Keep the token; drop it to stop.
    @discardableResult
    public func observe(_ handler: @escaping @MainActor (Language) -> Void) -> ObservationToken {
        let id = UUID()
        observers[id] = handler
        return ObservationToken { [weak self] in
            MainActor.assumeIsolated { _ = self?.observers.removeValue(forKey: id) }
        }
    }

    /// Text for `key` in the current language, from `bundle` (use `.module`).
    public func localized(_ key: String, bundle: Bundle, table: String? = nil) -> String {
        languageBundle(for: bundle).localizedString(forKey: key, value: nil, table: table)
    }

    private func languageBundle(for bundle: Bundle) -> Bundle {
        let cacheKey = "\(bundle.bundlePath)#\(current.code)"
        if let cached = bundles[cacheKey] { return cached }
        let resolved = bundle.path(forResource: current.code, ofType: "lproj").flatMap(Bundle.init(path:)) ?? bundle
        bundles[cacheKey] = resolved
        return resolved
    }

    private static func resolve(_ preferred: [String], supported: [String]) -> String {
        Bundle.preferredLocalizations(from: supported, forPreferences: preferred).first ?? supported[0]
    }
}

/// Cancels an observation when deallocated.
public final class ObservationToken: Sendable {
    private let cancel: @Sendable () -> Void
    init(_ cancel: @escaping @Sendable () -> Void) { self.cancel = cancel }
    deinit { cancel() }
}

/// Locale for formatting dates / numbers, readable from any thread.
/// Updated by `LocalizationManager` so formats switch with the language.
public enum AppLocale {
    private static let lock = NSLock()
    nonisolated(unsafe) private static var value = Locale.autoupdatingCurrent

    /// Current in-app locale: `date.formatted(.dateTime.locale(AppLocale.current))`.
    public static var current: Locale {
        lock.withLock { value }
    }

    static func set(_ locale: Locale) {
        lock.withLock { value = locale }
    }
}
