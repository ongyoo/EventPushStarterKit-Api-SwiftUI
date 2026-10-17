//
//  SettingsInteractorTests.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

@testable import App
import Core
import Features
import Foundation
import Platform
import Testing

/// Real interactor with system services that are safe in unit tests.
@MainActor
struct SettingsInteractorTests {
    private func makeInteractor(features: AppFeatures) -> SettingsInteractor {
        SettingsInteractor(
            localization: LocalizationManager(supportedCodes: ["en", "th"], defaults: UserDefaults(suiteName: "settings.\(UUID().uuidString)") ?? .standard, systemLanguages: ["en"]),
            permissions: PermissionCenter(infoDictionary: [:]),
            notifications: LocalNotificationCenter(),
            background: BackgroundTaskService(infoDictionary: [:]),
            environment: AppEnvironment(name: .development, apiBaseURL: URL(fileURLWithPath: "/"), deepLinkScheme: "x",
                                        universalLinkHost: "x", bundleIdentifier: "x", features: features)
        )
    }

    @Test func exposesLanguagesFeaturesAndVersion() {
        let interactor = makeInteractor(features: .all)
        #expect(interactor.languages.map(\.code) == ["en", "th"])
        #expect(interactor.languageSelection == .system)
        #expect(interactor.features == .all)
        #expect(!interactor.appVersion.isEmpty)
        interactor.selectLanguage(.language("th"))
        #expect(interactor.languageSelection == .language("th"))
    }

    @Test func everyActionIsSafeWithoutAppHost() async {
        for features in [AppFeatures.all, .none] {
            let interactor = makeInteractor(features: features)
            #expect(await interactor.permissionStatuses().count == Permission.allCases.count)
            if case .unavailable = await interactor.request(.camera) {} else { Issue.record("camera needs a purpose string") }
            for demo in DemoNotification.allCases {
                #expect(await interactor.send(demo) == false, "Not allowed outside an app")
            }
            #expect(await interactor.pendingNotificationCount() == 0)
            await interactor.removeAllNotifications()
            interactor.scheduleBackgroundTasks()
            _ = await interactor.startLiveActivity()
            await interactor.endLiveActivities()
        }
    }
}
