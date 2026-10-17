//
//  AnalyticsCenter.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 17/10/2569 BE.
//

import Core
import Foundation

/// The app's `AnalyticsTracking`: checks consent, applies SDK limits, strips
/// personal data, then forwards to every provider.
///
///     let center = AnalyticsCenter(providers: [ConsoleAnalyticsProvider()], consentStore: preferences)
///     Container.shared.analytics.register { center }
///     center.isEnabled = false   // user opted out: nothing is sent any more
public final class AnalyticsCenter: AnalyticsTracking, @unchecked Sendable {
    private static let consentKey = StorageKey<Bool>("analytics.consent")

    private let providers: [any AnalyticsProvider]
    private let consentStore: any KeyValueStore
    private let enabledByDefault: Bool
    private let lock = NSLock()

    /// - Parameters:
    ///   - consentStore: where the user's choice is kept (preferences).
    ///   - enabledByDefault: value before the user chooses. Use `false` where
    ///     the law requires opt-in (e.g. GDPR for non-essential analytics).
    public init(providers: [any AnalyticsProvider], consentStore: any KeyValueStore, enabledByDefault: Bool = true) {
        self.providers = providers
        self.consentStore = consentStore
        self.enabledByDefault = enabledByDefault
    }

    /// The user's choice (Settings > Privacy). Turning it off resets every provider.
    public var isEnabled: Bool {
        get { lock.withLock { consentStore[Self.consentKey] ?? enabledByDefault } }
        set {
            lock.withLock { consentStore[Self.consentKey] = newValue }
            if !newValue { providers.forEach { $0.reset() } }
        }
    }

    public func track(_ event: AnalyticsEvent) {
        guard isEnabled else { return }
        let (clean, dropped) = event.sanitized()
        if !dropped.isEmpty {
            Log.analytics.warning("Dropped from \(event.name, privacy: .public): \(dropped.joined(separator: ", "), privacy: .public)")
        }
        guard let clean else { return }
        providers.forEach { $0.send(clean) }
    }

    public func setUserID(_ id: String?) {
        guard isEnabled else { return }
        providers.forEach { $0.setUserID(id) }
    }

    public func setUserProperty(_ value: String?, forName name: String) {
        guard isEnabled, AnalyticsEvent.isValidName(name) else { return }
        providers.forEach { $0.setUserProperty(value, forName: name) }
    }
}

public extension Container {
    /// The concrete center (for the consent switch). Features use `analytics`.
    /// `AppAssembly` registers the real one (SDK providers + persistent consent).
    var analyticsCenter: Dependency<AnalyticsCenter> {
        Dependency(self) { AnalyticsCenter(providers: [], consentStore: InMemoryStore()) }.singleton
    }
}
