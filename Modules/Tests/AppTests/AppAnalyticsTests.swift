//
//  AppAnalyticsTests.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 17/10/2569 BE.
//

@testable import App
import Core
import DataSources
import Foundation
import Navigation
import Platform
import Testing
import UIKit

@MainActor
struct AppAnalyticsTests {
    private let environment = AppEnvironment.preview

    @Test func compositionRootRegistersTheAnalyticsCenter() {
        let container = Container()
        container.preferences.register { InMemoryStore() }
        AppAssembly.registerAnalytics(in: container)
        #expect(container.analytics() is AnalyticsCenter)
        #expect(container.analyticsCenter() === (container.analytics() as? AnalyticsCenter))
        #expect(container.analyticsCenter().isEnabled, "Opt-out model by default")
    }

    @Test func routesHideIdsAndQueryValues() {
        #expect(AppCoordinator.route(of: DeepLink("events/42/organizer")) == "events/:id/organizer")
        #expect(AppCoordinator.route(of: DeepLink("inbox")) == "inbox")
        #expect(AppCoordinator.route(of: DeepLink("events?category=music")) == "events")
        #expect(AppCoordinator.route(of: DeepLink("")) == "/")
    }

    @Test func deepLinksTabsAndLanguageAreTracked() throws {
        let analytics = RecordingAnalytics()
        let app = AppCoordinator(window: UIWindow(frame: UIScreen.main.bounds), environment: environment, analytics: analytics)
        app.start()
        #expect(analytics.properties["app_language"] != nil)

        app.handle(DeepLink("events/7"))
        let deepLink = try #require(analytics.events.last { $0.name == "deep_link_opened" })
        #expect(deepLink.parameters["route"] == "events/:id")
        #expect(deepLink.parameters["handled"] == true)

        app.handle(DeepLink("settings"))
        #expect(analytics.events.contains(.screenView("settings")), "Tab switch by link is a screen view")

        let inbox = try #require(app.flows[.inbox]?.rootViewController)
        app.tabBarController.delegate?.tabBarController?(app.tabBarController, didSelect: inbox)
        #expect(analytics.events.last == .screenView("notification"))
    }

    @Test func settingsAdapterControlsConsent() {
        let center = AnalyticsCenter(providers: [], consentStore: InMemoryStore())
        let interactor = SettingsInteractor(analytics: center)
        #expect(interactor.isAnalyticsEnabled)
        interactor.setAnalyticsEnabled(false)
        #expect(!center.isEnabled && !interactor.isAnalyticsEnabled)
    }
}
