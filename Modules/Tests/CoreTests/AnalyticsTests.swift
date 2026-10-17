//
//  AnalyticsTests.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 17/10/2569 BE.
//

@testable import Core
import Foundation
import Testing

struct AnalyticsTests {
    @Test func literalsAndScreenView() {
        let event = AnalyticsEvent("x", ["s": "a", "i": 1, "d": 1.5, "b": true])
        #expect(event.parameters.mapValues(\.description) == ["s": "a", "i": "1", "d": "1.5", "b": "true"])
        #expect(AnalyticsEvent.screenView("home") == AnalyticsEvent("screen_view", ["screen_name": "home"]))
    }

    @Test func namesFollowSDKRules() {
        #expect(AnalyticsEvent.isValidName("event_selected"))
        #expect(AnalyticsEvent.isValidName("step_2"))
        #expect(!AnalyticsEvent.isValidName("EventSelected"))
        #expect(!AnalyticsEvent.isValidName("2_steps"))
        #expect(!AnalyticsEvent.isValidName("has space"))
        #expect(!AnalyticsEvent.isValidName("firebase_reserved"))
        #expect(!AnalyticsEvent.isValidName(String(repeating: "a", count: 41)))
        #expect(!AnalyticsEvent.isValidName(""))
    }

    @Test func sanitizingDropsPersonalDataAndAppliesLimits() throws {
        var parameters: [String: AnalyticsValue] = [
            "event_id": "42",
            "user_email": "x",
            "contact": "someone@example.com",
            "BadKey": 1,
            "long": .string(String(repeating: "x", count: 150)),
        ]
        for index in 0..<30 { parameters["p\(index)"] = .int(index) }
        let (clean, dropped) = AnalyticsEvent("shared", parameters).sanitized()
        let event = try #require(clean)
        #expect(event.parameters["event_id"] == "42")
        #expect(event.parameters["user_email"] == nil && event.parameters["contact"] == nil)
        #expect(event.parameters.count == AnalyticsEvent.Limits.parameterCount)
        #expect(dropped.contains("user_email (personal data)"))
        #expect(dropped.contains("contact (personal data)"))
        #expect(dropped.contains("BadKey (invalid name)"))
        #expect(dropped.contains { $0.contains("over 25 parameters") })
        if case let .string(text)? = event.parameters["long"] { #expect(text.count == 100) }

        #expect(AnalyticsEvent("Bad Name").sanitized().event == nil)
    }

    @Test func defaultsAreSafe() {
        let noop = NoopAnalytics()
        noop.track(.screenView("x"))
        noop.setUserID("1")
        noop.setUserProperty("th", forName: "app_language")
        #expect(Container().analytics() is NoopAnalytics)

        let recording = RecordingAnalytics()
        recording.track(.screenView("x"))
        recording.setUserID("u1")
        recording.setUserProperty("th", forName: "app_language")
        #expect(recording.eventNames == ["screen_view"])
        #expect(recording.userID == "u1" && recording.properties == ["app_language": "th"])
    }
}
