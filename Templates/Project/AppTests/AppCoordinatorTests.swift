//
//  AppCoordinatorTests.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

@testable import App
import Core
import DataSources
@testable import Features
import Navigation
import Platform
import Testing
import UIKit

@MainActor
struct AppCoordinatorTests {
    private let environment = AppEnvironment(
        name: .development,
        apiBaseURL: URL(string: "https://example.com")!,
        deepLinkScheme: "app",
        universalLinkHost: "example.com",
        bundleIdentifier: "test"
    )

    @Test func startBuildsTabs() {
        let app = AppCoordinator(window: UIWindow(), environment: environment)
        app.start()
        #expect(app.tabBarController.viewControllers?.count == AppTab.allCases.count)
    }

    @Test func languageChangeRebuildsTabs() {
        let app = AppCoordinator(window: UIWindow(), environment: environment)
        app.start()
        weak var oldHome = app.flows[.home]
        app.reloadForLanguageChange()
        #expect(oldHome == nil)
        app.sceneWillResignActive()
        app.sceneDidBecomeActive()
        app.sceneDidEnterBackground()
    }

    @Test func handlesRootLinksAndRejectsUnknown() throws {
        let app = AppCoordinator(window: UIWindow(), environment: environment)
        #expect(app.open(try #require(URL(string: "app://home"))))
        app.start()
        #expect(app.handle(DeepLink("home")))
        #expect(!app.handle(DeepLink("unknown")))
        #expect(!app.open(try #require(URL(string: "https://evil.com/home"))))
    }

    @Test func mockModeRegistersMockClient() {
        let container = Container()
        AppAssembly.registerMockAPI(in: container)
        #expect(container.apiClient() is MockAPIClient)
    }
}
