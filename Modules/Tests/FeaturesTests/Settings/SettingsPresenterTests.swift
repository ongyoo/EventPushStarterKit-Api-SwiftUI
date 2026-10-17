//
//  SettingsPresenterTests.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import Core
@testable import Features
import Foundation
import Navigation
import Testing
import UIKit

@MainActor
struct SettingsPresenterTests {
    @Test func loadsStatusesAndPendingCount() async {
        let interactor = InteractorStub()
        let presenter = SettingsPresenter(interactor: interactor, router: nil)
        await presenter.load()
        #expect(presenter.permissions[.camera] == .notDetermined)
        #expect(presenter.pendingCount == 2)
        #expect(presenter.languages.map(\.code) == ["en", "th"])
        #expect(presenter.appVersion == "1.0 (1)")
    }

    @Test func languageSelectionIsForwardedOnce() {
        let interactor = InteractorStub()
        let presenter = SettingsPresenter(interactor: interactor, router: nil)
        presenter.didSelectLanguage(.system)
        presenter.didSelectLanguage(.language("th"))
        #expect(interactor.selections == [.language("th")])
        #expect(presenter.languageSelection == .language("th"))
        presenter.didTapOpenSystemSettings()
        #expect(interactor.openedSettings == 1)
    }

    @Test func permissionTapAsksOrOpensSettings() async {
        let interactor = InteractorStub()
        let presenter = SettingsPresenter(interactor: interactor, router: nil)
        await presenter.load()

        await presenter.didTapPermission(.camera)
        #expect(presenter.permissions[.camera] == .authorized)

        await presenter.didTapPermission(.contacts)
        #expect(interactor.openedSettings == 1)

        await presenter.didTapPermission(.tracking)
        #expect(interactor.requested == [.camera])
    }

    @Test func notificationsAndCapabilities() async {
        let interactor = InteractorStub()
        let presenter = SettingsPresenter(interactor: interactor, router: nil)

        await presenter.didTapSend(.now)
        #expect(presenter.message != nil)
        interactor.sendSucceeds = false
        await presenter.didTapSend(.group)
        #expect(interactor.sent == [.now, .group])

        await presenter.didTapRemoveAllNotifications()
        #expect(presenter.pendingCount == 0)

        presenter.didTapScheduleBackgroundTasks()
        #expect(interactor.scheduled)
        await presenter.didTapStartLiveActivity()
        await presenter.didTapEndLiveActivities()
        #expect(interactor.liveActivityCalls == ["start", "end"])
        presenter.dismissMessage()
        #expect(presenter.message == nil)
    }

    @Test func privacySwitchAndTrackedActions() async {
        let interactor = InteractorStub()
        let analytics = RecordingAnalytics()
        let presenter = SettingsPresenter(interactor: interactor, router: nil, analytics: analytics)
        #expect(presenter.isAnalyticsEnabled)
        presenter.didToggleAnalytics(false)
        #expect(!presenter.isAnalyticsEnabled && !interactor.isAnalyticsEnabled)

        presenter.didSelectLanguage(.language("th"))
        presenter.didSelectLanguage(.system)
        await presenter.load()
        await presenter.didTapPermission(.camera)
        #expect(analytics.eventNames == ["language_changed", "language_changed", "permission_requested"])
        #expect(analytics.events[0].parameters["language"] == "th")
        #expect(analytics.events[1].parameters["language"] == "system")
        #expect(analytics.events[2].parameters["granted"] == true)
    }

    @Test func routes() {
        let router = RouterSpy()
        let presenter = SettingsPresenter(interactor: InteractorStub(), router: router)
        presenter.didTapAnimations()
        presenter.didTapKeyboardDemo()
        presenter.didTapNavigationDemo(.sheet)
        #expect(router.calls == ["animations", "keyboard", "sheet"])
    }

    @Test func builderRendersWithEveryFeature() {
        let interactor = InteractorStub()
        interactor.features = .all
        let viewController = SettingsBuilder.build(router: RouterSpy(), interactor: interactor)
        render(viewController)
        #expect(viewController.title != nil)
    }
}

@MainActor
struct SettingsCoordinatorTests {
    private func makeCoordinator() -> (SettingsCoordinator, Navigator, UIWindow) {
        let navigator = Navigator()
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        window.rootViewController = navigator.navigationController
        window.makeKeyAndVisible()
        let coordinator = SettingsCoordinator(navigator: navigator, isRoot: true) { InteractorStub() }
        coordinator.start()
        return (coordinator, navigator, window)
    }

    @Test func startsAsRootAndHandlesOnlyRootLink() {
        let (coordinator, navigator, _) = makeCoordinator()
        #expect(navigator.navigationController.viewControllers.count == 1)
        #expect(coordinator.handle(DeepLink("")))
        #expect(!coordinator.handle(DeepLink("other")))
    }

    @Test func navigationDemosPushAndPresent() {
        let (coordinator, navigator, _) = makeCoordinator()
        navigator.withoutAnimation {
            coordinator.showNavigationDemo(.pushFade)
            coordinator.showNavigationDemo(.pushSlideUp)
            coordinator.showNavigationDemo(.pushScale)
            coordinator.showAnimationGallery()
            coordinator.showKeyboardDemo()
        }
        #expect(navigator.navigationController.viewControllers.count == 6)
        render(navigator.navigationController)

        coordinator.showNavigationDemo(.modalFlow)
        #expect(coordinator.children.last is NavigationDemoCoordinator)
        #expect(navigator.navigationController.presentedViewController != nil)
    }

    @Test func sheetAndFullScreenDemos() {
        for demo in [NavigationDemo.sheet, .fullScreen] {
            let (coordinator, navigator, _) = makeCoordinator()
            coordinator.showNavigationDemo(demo)
            #expect(navigator.navigationController.presentedViewController != nil)
        }
        #expect(NavigationDemo.allCases.allSatisfy { !$0.systemImage.isEmpty })
    }

    @Test func demoFlowPushesInsideItsOwnStack() {
        let navigator = Navigator()
        let flow = NavigationDemoCoordinator(navigator: navigator)
        flow.start()
        render(navigator.navigationController)
        navigator.withoutAnimation { flow.pushNext() }
        #expect(navigator.navigationController.viewControllers.count == 2)
        flow.dismissFlow(animated: false)
    }

    @Test func choosingATabBarLookSavesIt() {
        let interactor = InteractorStub()
        let presenter = SettingsPresenter(interactor: interactor, router: nil)
        #expect(presenter.tabBarLook == .glass)
        presenter.didSelectTabBarLook(.solid)
        #expect(presenter.tabBarLook == .solid)
        #expect(interactor.tabBarLook == .solid)
        presenter.didSelectTabBarLook(.solid) // same: nothing to do
        #expect(presenter.isTabBarMinimizeEnabled)
        presenter.didToggleTabBarMinimize(false)
        #expect(!presenter.isTabBarMinimizeEnabled)
        #expect(!interactor.isTabBarMinimizeEnabled)
        #expect(TabBarLook.allCases.allSatisfy { !$0.systemImage.isEmpty })
    }
}

// MARK: - Test doubles

@MainActor
private final class InteractorStub: SettingsInteracting {
    var languages: [LocalizationManager.Language] = [.init(code: "en"), .init(code: "th")]
    var languageSelection: LocalizationManager.Selection = .system
    var features: AppFeatures = .none
    var appVersion = "1.0 (1)"
    private(set) var isAnalyticsEnabled = true

    func setAnalyticsEnabled(_ isOn: Bool) { isAnalyticsEnabled = isOn }
    private(set) var tabBarLook: TabBarLook = .glass
    func setTabBarLook(_ look: TabBarLook) { tabBarLook = look }
    private(set) var isTabBarMinimizeEnabled = true
    func setTabBarMinimizeEnabled(_ isOn: Bool) { isTabBarMinimizeEnabled = isOn }

    var sendSucceeds = true
    private(set) var selections: [LocalizationManager.Selection] = []
    private(set) var requested: [Permission] = []
    private(set) var sent: [DemoNotification] = []
    private(set) var openedSettings = 0
    private(set) var scheduled = false
    private(set) var liveActivityCalls: [String] = []
    private var pending = 2

    func selectLanguage(_ selection: LocalizationManager.Selection) { selections.append(selection) }

    func permissionStatuses() async -> [Permission: PermissionStatus] {
        var result = Dictionary(uniqueKeysWithValues: Permission.allCases.map { ($0, PermissionStatus.notDetermined) })
        result[.contacts] = .denied
        result[.tracking] = .restricted
        return result
    }

    func request(_ permission: Permission) async -> PermissionStatus {
        requested.append(permission)
        return .authorized
    }

    func openSystemSettings() { openedSettings += 1 }

    func send(_ demo: DemoNotification) async -> Bool {
        sent.append(demo)
        return sendSucceeds
    }

    func pendingNotificationCount() async -> Int { pending }
    func removeAllNotifications() async { pending = 0 }
    func scheduleBackgroundTasks() { scheduled = true }

    func startLiveActivity() async -> Bool {
        liveActivityCalls.append("start")
        return false
    }

    func endLiveActivities() async { liveActivityCalls.append("end") }
}

@MainActor
private final class RouterSpy: SettingsRouting {
    private(set) var calls: [String] = []
    func showAnimationGallery() { calls.append("animations") }
    func showKeyboardDemo() { calls.append("keyboard") }
    func showNavigationDemo(_ demo: NavigationDemo) { calls.append(demo.rawValue) }
}
