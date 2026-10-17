//
//  DynamicScreenPresenterTests.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 17/10/2569 BE.
//

import Core
import Domain
@testable import Features
import Foundation
import Navigation
import ServerDrivenUI
import SwiftUI
import Testing
import UIKit

@MainActor
struct DynamicScreenPresenterTests {
    private let json = Data(#"""
    { "schemaVersion": 1, "id": "promo", "title": "Promo",
      "body": [ { "type": "event_card", "props": { "eventId": "1" } }, { "type": "text", "props": { "text": "Hi" } } ] }
    """#.utf8)

    @Test func loadsAndDecodesTheScreen() async throws {
        let presenter = DynamicScreenPresenter(screenID: "promo", interactor: ScreenInteractorStub(result: .success(sampleScreen())), router: nil, analytics: RecordingAnalytics())
        await presenter.loadIfNeeded()
        #expect(presenter.state.value?.title == "Promo")
        #expect(presenter.revision == 1)
        await presenter.loadIfNeeded() // already loaded
        #expect(presenter.revision == 1)
    }

    @Test func versionErrorsAskForAnUpdate() async {
        let old = DynamicScreenPresenter(screenID: "x", interactor: ScreenInteractorStub(result: .failure(DynamicScreenError.unsupportedSchema(version: 9))), router: nil)
        await old.load()
        #expect(old.state.errorMessage == L10n.tr("dynamic.updateRequired"))

        let broken = DynamicScreenPresenter(screenID: "x", interactor: ScreenInteractorStub(result: .failure(DynamicScreenError.invalid("bad"))), router: nil)
        await broken.load()
        #expect(broken.state.errorMessage == L10n.tr("dynamic.unavailable"))

        let offline = DynamicScreenPresenter(screenID: "x", interactor: ScreenInteractorStub(result: .failure(DynamicScreenRepositoryError.unavailable(id: "x"))), router: nil)
        await offline.load()
        #expect(offline.state.errorMessage != nil)
    }

    @Test func actionsGoToTheRouterAndAnalytics() {
        let router = ScreenRouterSpy()
        let analytics = RecordingAnalytics()
        let presenter = DynamicScreenPresenter(screenID: "promo", interactor: ScreenInteractorStub(result: .success(sampleScreen())), router: router, analytics: analytics)
        let link = URL(string: "eventpush://events/1")!
        let web = URL(string: "https://example.com")!
        presenter.perform(.sequence([
            .deepLink(link),
            .openURL(web),
            .screen(id: "next", presentation: .sheet),
            .track(event: "promo_tapped", params: ["slot": "hero", "rank": 2, "score": 1.5, "vip": true, "skip": .null]),
            .dismiss,
            .setState(key: "a", value: "b"),
            .toggleState(key: "a"),
            .custom(type: "share", props: [:]),
        ]))
        #expect(router.opened == [link])
        #expect(router.external == [web])
        #expect(router.screens.first?.0 == "next")
        #expect(router.closed == 1)
        #expect(analytics.eventNames == ["promo_tapped"])
        #expect(analytics.events.first?.parameters["rank"] == .int(2))
        #expect(analytics.events.first?.parameters["skip"] == nil)
    }

    @Test func interactorDecodesThePayload() async throws {
        let interactor = DynamicScreenInteractor(repository: ScreenRepositoryStub(json: json), appVersion: "1.0")
        let screen = try await interactor.screen(id: "promo")
        #expect(screen.body.count == 2)
    }

    @Test func builderAndAppComponentsRender() {
        #expect(AppComponents.registry.renderer(for: "event_card") != nil)
        let controller = DynamicScreenBuilder.build(screenID: "promo", router: ScreenRouterSpy(), showsClose: true, interactor: ScreenInteractorStub(result: .success(sampleScreen())))
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        window.rootViewController = UINavigationController(rootViewController: controller)
        window.makeKeyAndVisible()
        controller.view.layoutIfNeeded()
        #expect((controller as? AnalyticsScreenNaming)?.analyticsScreenName == "dynamic_promo")
    }

    @Test func coordinatorRoutes() {
        let navigator = Navigator(analytics: RecordingAnalytics())
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        window.rootViewController = navigator.navigationController
        window.makeKeyAndVisible()
        navigator.setRoot(UIViewController())
        let coordinator = DynamicScreenCoordinator(navigator: navigator, screenID: "promo")
        coordinator.start()
        #expect(navigator.navigationController.viewControllers.count == 2)
        #expect(coordinator.handle(DeepLink(path: [])))
        coordinator.showScreen(id: "next", presentation: .push)
        #expect(navigator.navigationController.viewControllers.count == 3)
        coordinator.showScreen(id: "sheet", presentation: .sheet)
        coordinator.showScreen(id: "full", presentation: .fullScreen)
        coordinator.open(URL(string: "eventpush://events/1")!) // in-app: posted to the inbox
        coordinator.openExternal(URL(string: "ftp://nope")!) // not allowed: ignored
        coordinator.close()
    }

    private func sampleScreen() -> DynamicScreen {
        DynamicScreen(id: "promo", title: "Promo", body: [DynamicComponent(type: "text", props: ["text": "Hi"])])
    }
}

private struct ScreenInteractorStub: DynamicScreenInteracting {
    let result: Result<DynamicScreen, any Error>
    func screen(id: String) async throws -> DynamicScreen { try result.get() }
}

private struct ScreenRepositoryStub: DynamicScreenRepository {
    let json: Data
    func screen(id: String) async throws -> DynamicScreenPayload {
        DynamicScreenPayload(id: id, json: json, source: .network)
    }
}

private final class ScreenRouterSpy: DynamicScreenRouting {
    var opened: [URL] = []
    var external: [URL] = []
    var screens: [(String, DynamicAction.Presentation)] = []
    var closed = 0

    func open(_ url: URL) { opened.append(url) }
    func openExternal(_ url: URL) { external.append(url) }
    func showScreen(id: String, presentation: DynamicAction.Presentation) { screens.append((id, presentation)) }
    func close() { closed += 1 }
}
