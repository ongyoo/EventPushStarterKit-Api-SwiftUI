//
//  AnalyticsTracking.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 17/10/2569 BE.
//

import Foundation

/// What every layer uses to record usage. No SDK here: the composition root
/// (`AppAssembly`) decides where events go (console, Firebase, your backend...).
///
///     let analytics = Container.shared.analytics()
///     analytics.track(.screenView("home"))
public protocol AnalyticsTracking: Sendable {
    /// Records an event. Never blocks, never throws.
    func track(_ event: AnalyticsEvent)
    /// Pseudonymous id (e.g. your backend's user id), `nil` on logout. Never an email.
    func setUserID(_ id: String?)
    /// A property of the user, e.g. `("language", "th")`. `nil` removes it.
    func setUserProperty(_ value: String?, forName name: String)
}

/// Does nothing. Default until the app registers a real implementation, and in previews.
public struct NoopAnalytics: AnalyticsTracking {
    public init() {}
    public func track(_ event: AnalyticsEvent) {}
    public func setUserID(_ id: String?) {}
    public func setUserProperty(_ value: String?, forName name: String) {}
}

public extension Container {
    /// Registered by `AppAssembly`. Tests: `Container.shared.analytics.register { spy }`.
    var analytics: Dependency<any AnalyticsTracking> {
        Dependency(self) { NoopAnalytics() }.singleton
    }
}

/// Keeps events in memory. For unit tests (assert what a screen sends) and
/// debugging; never registered in production.
///
///     let analytics = RecordingAnalytics()
///     let presenter = HomePresenter(interactor: stub, router: nil, analytics: analytics)
///     presenter.didTapSeeAll()
///     #expect(analytics.eventNames == ["see_all_tapped"])
public final class RecordingAnalytics: AnalyticsTracking, @unchecked Sendable {
    private let lock = NSLock()
    private var storedEvents: [AnalyticsEvent] = []
    private var storedProperties: [String: String] = [:]
    private var storedUserID: String?

    public init() {}

    public var events: [AnalyticsEvent] { lock.withLock { storedEvents } }
    public var eventNames: [String] { events.map(\.name) }
    public var properties: [String: String] { lock.withLock { storedProperties } }
    public var userID: String? { lock.withLock { storedUserID } }

    public func track(_ event: AnalyticsEvent) {
        lock.withLock { storedEvents.append(event) }
    }

    public func setUserID(_ id: String?) {
        lock.withLock { storedUserID = id }
    }

    public func setUserProperty(_ value: String?, forName name: String) {
        lock.withLock { storedProperties[name] = value }
    }
}
