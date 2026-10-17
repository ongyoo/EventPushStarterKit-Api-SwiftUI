//
//  FoundationTests.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

@testable import Core
import Foundation
import Testing

struct FoundationTests {
    @Test func loadableAccessors() {
        let states: [Loadable<Int>] = [.idle, .loading, .loaded(1), .failed("x")]
        #expect(states.map(\.value) == [nil, nil, 1, nil])
        #expect(states.map(\.isLoading) == [false, true, false, false])
        #expect(states.map(\.errorMessage) == [nil, nil, nil, "x"])
    }

    @Test func collectionHelpers() {
        #expect([1, 2, 3][safe: 1] == 2)
        #expect([1, 2, 3][safe: 9] == nil)
        #expect([1, 2, 3].limited(to: 2) == [1, 2])
    }

    @Test func formatting() throws {
        let date = try #require(Date(iso8601: "2025-09-30T10:00:00Z"))
        #expect(!date.monthDayText.isEmpty && !date.monthText.isEmpty && !date.dayText.isEmpty)
        #expect(!date.relativeText.isEmpty)
        #expect(Date(iso8601: "not a date") == nil)
        #expect(1200.0.currencyText(code: "THB").contains("1,200"))
        #expect(9700.0.compactText.contains("9.7"))
        #expect(9700.compactText.contains("9.7"))
    }

    @Test func environmentFromInfoPlist() {
        let environment = AppEnvironment(info: [
            "APP_ENVIRONMENT": "production",
            "API_BASE_URL": "https://api.shop.com",
            "DEEP_LINK_SCHEME": "shop",
            "UNIVERSAL_LINK_HOST": "shop.com",
            "SSL_PINNED_HOSTS": "api.shop.com, cdn.shop.com,",
            "USE_MOCK_API": "yes",
        ], bundleIdentifier: "com.shop")
        #expect(environment.isProduction)
        #expect(environment.apiBaseURL.absoluteString == "https://api.shop.com")
        #expect(environment.deepLinkScheme == "shop")
        #expect(environment.pinnedHosts == ["api.shop.com", "cdn.shop.com"])
        #expect(environment.useMockAPI)

        let fallback = AppEnvironment(info: ["API_BASE_URL": ""], bundleIdentifier: nil)
        #expect(fallback.apiBaseURL == AppEnvironment.preview.apiBaseURL)
        #expect(fallback.features == .none, "Missing APP_FEATURES = everything off")
        #expect(AppEnvironment(bundle: .main).apiBaseURL.absoluteString.isEmpty == false)
    }

    @Test func taskBagCancelsOnDeinitAndOnDemand() async {
        var bag: TaskBag? = TaskBag()
        let first = Task { try? await Task.sleep(for: .seconds(10)) }.store(in: bag!)
        bag = nil
        #expect(first.isCancelled)

        let other = TaskBag()
        let second = Task { try? await Task.sleep(for: .seconds(10)) }.store(in: other)
        other.cancelAll()
        #expect(second.isCancelled)
    }

    @MainActor
    @Test func leakDetectorChecksAfterDelay() async throws {
        final class Leaky {}
        let leaked = Leaky()
        LeakDetector.expectDeallocation(of: leaked, after: .milliseconds(10))
        LeakDetector.expectDeallocation(of: Leaky(), after: .milliseconds(10))
        LeakDetector.expectDeallocation(of: nil)
        try await Task.sleep(for: .milliseconds(50))
        let reference = WeakReference(leaked)
        #expect(reference.value === leaked)
        Log.app.debug("leak detector test finished")
    }

    // `authenticate` is not called: it shows a system prompt.
}
