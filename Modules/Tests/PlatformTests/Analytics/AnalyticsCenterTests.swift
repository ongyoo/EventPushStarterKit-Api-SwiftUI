//
//  AnalyticsCenterTests.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 17/10/2569 BE.
//

import Core
import Foundation
@testable import Platform
import Testing

/// Provider double: records what reaches the SDK side.
private final class ProviderSpy: AnalyticsProvider, @unchecked Sendable {
    private let lock = NSLock()
    private var log: [String] = []
    var calls: [String] { lock.withLock { log } }
    func send(_ event: AnalyticsEvent) { lock.withLock { log.append("send \(event.name) \(event.parameters.keys.sorted())") } }
    func setUserID(_ id: String?) { lock.withLock { log.append("user \(id ?? "nil")") } }
    func setUserProperty(_ value: String?, forName name: String) { lock.withLock { log.append("prop \(name)=\(value ?? "nil")") } }
    func reset() { lock.withLock { log.append("reset") } }
}

private struct MinimalProvider: AnalyticsProvider {
    func send(_ event: AnalyticsEvent) {}
}

struct AnalyticsCenterTests {
    @Test func forwardsSanitizedEventsToEveryProvider() {
        let first = ProviderSpy(), second = ProviderSpy()
        let center = AnalyticsCenter(providers: [first, second], consentStore: InMemoryStore())
        center.track(AnalyticsEvent("event_selected", ["event_id": "1", "email": "a@b.co"]))
        center.track(AnalyticsEvent("Invalid Name"))
        center.setUserID("u1")
        center.setUserProperty("th", forName: "app_language")
        center.setUserProperty("x", forName: "Bad Name")
        let expected = ["send event_selected [\"event_id\"]", "user u1", "prop app_language=th"]
        #expect(first.calls == expected)
        #expect(second.calls == expected)
    }

    @Test func consentIsRememberedAndOptOutStopsEverything() {
        let store = InMemoryStore()
        let provider = ProviderSpy()
        let center = AnalyticsCenter(providers: [provider], consentStore: store, enabledByDefault: true)
        #expect(center.isEnabled)
        center.isEnabled = false
        center.track(.screenView("home"))
        center.setUserID("u1")
        center.setUserProperty("th", forName: "app_language")
        #expect(provider.calls == ["reset"])

        // The choice survives a relaunch (new center, same store).
        #expect(!AnalyticsCenter(providers: [], consentStore: store).isEnabled)
        // Opt-in model: nothing is sent before the user agrees.
        #expect(!AnalyticsCenter(providers: [], consentStore: InMemoryStore(), enabledByDefault: false).isEnabled)
    }

    @Test func providerDefaultsAndConsole() {
        let minimal = MinimalProvider()
        minimal.setUserID("x")
        minimal.setUserProperty("x", forName: "y")
        minimal.reset()
        let console = ConsoleAnalyticsProvider()
        console.send(AnalyticsEvent("event_selected", ["event_id": "1"]))
        console.setUserID("u1")
        console.setUserProperty(nil, forName: "app_language")
        #expect(Container().analyticsCenter().isEnabled)
    }
}
