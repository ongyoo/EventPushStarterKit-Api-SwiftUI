//
//  LocalizationManagerTests.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

@testable import Core
import Foundation
import Testing

@MainActor
@Suite(.serialized)
struct LocalizationManagerTests {
    private func makeDefaults() -> (UserDefaults, String) {
        let suite = "tests.\(UUID().uuidString)"
        return (UserDefaults(suiteName: suite) ?? .standard, suite)
    }

    @Test func followsDeviceLanguageByDefault() {
        let manager = LocalizationManager(supportedCodes: ["en", "th"], defaults: makeDefaults().0, systemLanguages: ["th-TH", "en"])
        #expect(manager.selection == .system)
        #expect(manager.current.code == "th")
        #expect(manager.supported.map(\.nativeName).allSatisfy { !$0.isEmpty })
        #expect(manager.locale.identifier == "th")
    }

    @Test func unsupportedDeviceLanguageFallsBackToFirst() {
        let manager = LocalizationManager(supportedCodes: ["en", "th"], defaults: makeDefaults().0, systemLanguages: ["ja"])
        #expect(manager.current.code == "en")
    }

    @Test func selectingNotifiesObserversAndSyncsAppleLanguages() {
        let (defaults, suite) = makeDefaults()
        let manager = LocalizationManager(supportedCodes: ["en", "th"], defaults: defaults, systemLanguages: ["en"])
        var changes: [String] = []
        let token = manager.observe { changes.append($0.code) }

        manager.select(.language("th"))
        manager.select(.language("th"))      // same language: no event
        manager.select(.language("xx"))      // unsupported -> first supported
        #expect(changes == ["th", "en"])
        #expect(defaults.stringArray(forKey: "AppleLanguages") == ["en"])
        #expect(AppLocale.current.identifier == "en")

        manager.select(.system)
        // Only the app-level override is removed (the global device value remains).
        #expect(defaults.persistentDomain(forName: suite)?["AppleLanguages"] == nil)
        _ = token
    }

    @Test func droppingTheTokenStopsObservation() {
        let manager = LocalizationManager(supportedCodes: ["en", "th"], defaults: makeDefaults().0, systemLanguages: ["en"])
        var count = 0
        var token: ObservationToken? = manager.observe { _ in count += 1 }
        manager.select(.language("th"))
        token = nil
        manager.select(.language("en"))
        #expect(count == 1)
        _ = token
    }

    @Test func storedChoiceAndSettingsAppChoiceAreRestored() {
        let (defaults, _) = makeDefaults()
        defaults.set("th", forKey: "app.language")
        defaults.set(["th"], forKey: "AppleLanguages")
        #expect(LocalizationManager(supportedCodes: ["en", "th"], defaults: defaults, systemLanguages: ["en"]).current.code == "th")

        // User then picked English in Settings > App > Language.
        defaults.set(["en"], forKey: "AppleLanguages")
        let manager = LocalizationManager(supportedCodes: ["en", "th"], defaults: defaults, systemLanguages: ["en"])
        #expect(manager.selection == .language("en"))
    }

    @Test func missingKeyReturnsKey() {
        let manager = LocalizationManager(supportedCodes: ["en"], defaults: makeDefaults().0, systemLanguages: ["en"])
        #expect(manager.localized("no.such.key", bundle: .main) == "no.such.key")
    }
}
