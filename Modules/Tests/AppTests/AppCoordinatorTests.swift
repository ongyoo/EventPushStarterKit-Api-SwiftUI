//
//  AppCoordinatorTests.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

@testable import App
import Core
import DataSources
import Domain
@testable import Features
import Navigation
import LiquidGlassKit
import PhotosUI
import Platform
import Testing
import UIKit

@MainActor
struct AppCoordinatorTests {
    private let environment = AppEnvironment(
        name: .development,
        apiBaseURL: URL(string: "https://example.com")!,
        deepLinkScheme: "eventpush",
        universalLinkHost: "eventpush.app",
        bundleIdentifier: "test"
    )

    private func makeStartedApp() -> AppCoordinator {
        let app = AppCoordinator(window: UIWindow(frame: UIScreen.main.bounds), environment: environment)
        app.start()
        return app
    }

    private func stackDepth(_ app: AppCoordinator, _ tab: AppTab) -> Int {
        app.flows[tab]?.rootViewController.viewControllers.count ?? 0
    }

    @Test func startBuildsTabs() {
        let app = makeStartedApp()
        app.start() // idempotent
        #expect(app.tabBarController.viewControllers?.count == AppTab.allCases.count)
        #expect(stackDepth(app, .home) == 1)
        #expect(stackDepth(app, .inbox) == 1)
    }

    @Test func eventDeepLinkOpensDetailInHome() throws {
        let app = makeStartedApp()
        #expect(app.open(try #require(URL(string: "eventpush://events/1"))))
        #expect(app.tabBarController.selectedIndex == 0)
        #expect(stackDepth(app, .home) == 2)
        #expect(app.flows[.home]?.children.last is EventDetailCoordinator)
    }

    @Test func deepestLinkBuildsWholeStack() throws {
        let app = makeStartedApp()
        #expect(app.open(try #require(URL(string: "https://eventpush.app/events/1/organizer"))))
        #expect(stackDepth(app, .home) == 3)
        #expect(app.flows[.home]?.rootViewController.topViewController?.title == "Organizer")
    }

    @Test func inboxTabLinks() throws {
        let app = makeStartedApp()
        #expect(app.open(try #require(URL(string: "eventpush://inbox"))))
        #expect(app.tabBarController.selectedIndex == 1)

        #expect(app.handle(DeepLink("inbox/notifications")))
        #expect(app.handle(DeepLink("inbox/events/2/organizer")))
        #expect(stackDepth(app, .inbox) == 3)
    }

    @Test func listAndNotificationLinks() {
        let app = makeStartedApp()
        #expect(app.handle(DeepLink("events?category=music")))
        #expect(app.flows[.home]?.children.last is EventListCoordinator)

        #expect(app.handle(DeepLink("home/notifications")))
        #expect(app.flows[.home]?.children.last is NotificationCoordinator)
        #expect(stackDepth(app, .home) == 1, "Notifications open in a sheet, not pushed")

        #expect(app.handle(DeepLink("home")))
        #expect(stackDepth(app, .home) == 1)
    }

    @Test func newLinkResetsStackAndReleasesOldFlows() {
        let app = makeStartedApp()
        app.handle(DeepLink("events/1/organizer"))
        weak let oldDetail = app.flows[.home]?.children.last as? EventDetailCoordinator
        #expect(oldDetail != nil)

        app.handle(DeepLink("events/2"))
        #expect(stackDepth(app, .home) == 2)
        #expect(oldDetail == nil, "Previous flow leaked")
    }

    @Test func rejectsUnknownAndForeignLinks() throws {
        let app = makeStartedApp()
        #expect(!app.handle(DeepLink("unknown")))
        #expect(!app.handle(DeepLink("events/1/unknown")))
        #expect(!app.handle(DeepLink("inbox/notifications/extra")))
        #expect(!app.open(try #require(URL(string: "https://evil.com/events/1"))))
    }

    @Test func linkBeforeStartIsHandledAfterStart() throws {
        let app = AppCoordinator(window: UIWindow(frame: UIScreen.main.bounds), environment: environment)
        #expect(app.open(try #require(URL(string: "eventpush://events/1"))))
        #expect(!app.isStarted)
        app.start()
        #expect(stackDepth(app, .home) == 2)
    }

    @Test func featureOutputsOpenOtherFeatures() {
        let app = makeStartedApp()
        let flow = app.flows[.home]!
        flow.navigator.withoutAnimation {
            flow.showEventList(category: .all)
            flow.showEventDetail(id: "1")
            flow.showFeaturedEventDetail(id: "2")
        }
        #expect(stackDepth(app, .home) == 4)

        flow.presentEventDetail(id: "3")
        #expect(flow.children.last is EventDetailCoordinator)
        #expect(flow.rootViewController.presentedViewController != nil)
    }
}

@MainActor
struct AppCoordinatorLifecycleTests {
    private func makeStartedApp() -> AppCoordinator {
        let app = AppCoordinator(window: UIWindow(frame: UIScreen.main.bounds), environment: .preview)
        app.start()
        return app
    }

    @Test func languageChangeRebuildsTabsAndReleasesOldOnes() {
        let app = makeStartedApp()
        app.tabBarController.selectedIndex = 2
        weak let oldHome = app.flows[.home]
        app.reloadForLanguageChange()
        #expect(oldHome == nil, "Old flows must be released")
        #expect(app.tabBarController.selectedIndex == 2)
        #expect(app.flows.count == AppTab.allCases.count)
    }

    @Test func settingsTabAndExternalLinks() {
        let app = makeStartedApp()
        #expect(app.handle(DeepLink("settings")))
        #expect(app.tabBarController.selectedIndex == 2)

        AppLinks.open(path: "events/1")
        #expect(app.flows[.home]?.rootViewController.viewControllers.count == 2)
    }

    @Test func sceneLifecycleDoesNotCrash() {
        let app = makeStartedApp()
        app.hidesContentInAppSwitcher = true
        app.sceneWillResignActive()
        app.sceneDidBecomeActive()
        app.sceneDidEnterBackground()
        #expect(app.isStarted)
    }

    @Test func pushBridgeIsInertWhenFeatureIsOff() async {
        AppPush.didRegister(deviceToken: Data([1]))
        AppPush.didFailToRegister(URLError(.unknown))
        AppPush.register()
        #expect(await AppPush.didReceive(["type": "x"]) == .noData)
    }

    @Test func notificationActionsAreHandled() {
        let categories = AppNotifications.categories
        #expect(categories.first?.actions.count == 3)
        #expect(AppNotifications.groupSample().allSatisfy { $0.group == AppNotifications.eventsGroup })
        #expect(AppNotifications.reminder(eventID: "1").trigger == .now)
        #expect(AppNotifications.reminder(eventID: "1", after: 60).trigger == .after(60))

        let center = LocalNotificationCenter()
        for action in [AppNotifications.ActionID.remind, AppNotifications.ActionID.reply, AppNotifications.ActionID.mute, "other"] {
            AppNotifications.handle(NotificationResponse(notificationID: "n", action: .custom(id: action, text: "hi"), deepLink: "events/1", userInfo: [:]), center: center)
        }
        AppNotifications.handle(NotificationResponse(notificationID: "n", action: .opened, deepLink: nil, userInfo: [:]), center: center)
    }

    @Test func detailPushedFromHomeShowsTheBackButton() throws {
        let app = makeStartedApp()
        let homeFlow = try #require(app.flows[.home])
        let nav = homeFlow.rootViewController
        let home = try #require(homeFlow.children.first as? HomeCoordinator)
        nav.delegate?.navigationController?(nav, willShow: try #require(nav.topViewController), animated: false)
        #expect(nav.isNavigationBarHidden, "Home hides the bar")

        homeFlow.navigator.withoutAnimation { home.showEventDetail(id: "1") }
        let detail = try #require(nav.topViewController)
        nav.delegate?.navigationController?(nav, willShow: detail, animated: false)
        #expect(!nav.isNavigationBarHidden, "Detail shows the bar")
        #expect(nav.viewControllers.count == 2, "Back button is shown when there is a previous screen")
    }

    @Test func homeAndInboxOutputsOpenOtherFeatures() throws {
        let app = makeStartedApp()
        let homeFlow = try #require(app.flows[.home])
        let home = try #require(homeFlow.children.first as? HomeCoordinator)
        homeFlow.navigator.withoutAnimation {
            home.showFeaturedEvent(id: "1")
            home.showEventDetail(id: "1")
            home.showAllEvents(category: .music)
        }
        #expect(homeFlow.rootViewController.viewControllers.count == 4)

        // Event list -> full-screen modal detail with its own stack.
        let list = try #require(homeFlow.children.first { $0 is EventListCoordinator } as? EventListCoordinator)
        list.showEvent(id: "2")
        #expect(homeFlow.children.last is EventDetailCoordinator)

        // Bell -> sheet; a notification pushes the detail INSIDE the sheet.
        home.showNotifications()
        let notifications = try #require(homeFlow.children.last as? NotificationCoordinator)
        notifications.navigator.withoutAnimation { notifications.openEvent(id: "3") }
        #expect(notifications.children.first is EventDetailCoordinator)
        #expect(notifications.navigator.navigationController.viewControllers.count == 2)

        // Inbox tab: notification -> detail pushed in the tab.
        let inbox = try #require(app.flows[.inbox]?.children.first as? NotificationCoordinator)
        inbox.navigator.withoutAnimation { inbox.openEvent(id: "4") }
        #expect(app.flows[.inbox]?.rootViewController.viewControllers.count == 2)
    }

    @Test func debugAnimationsLink() {
        let app = makeStartedApp()
        #expect(app.handle(DeepLink("debug/animations")))
        #expect(!app.handle(DeepLink("debug/other")))
    }

    @Test func capabilitiesConfigureWithEverythingOn() {
        AppAssembly.configureCapabilities(.all, container: Container())
        #expect(AppEnvironment.preview.features == .all)
    }
}

@MainActor
struct AppAssemblyTests {
    @Test func mockModeRegistersMockClient() async throws {
        let container = Container()
        AppAssembly.registerMockAPI(in: container)
        #expect(container.apiClient() is MockAPIClient)
    }

    @Test func configureRegistersEnvironment() {
        let container = Container()
        let environment = AppEnvironment.preview
        AppAssembly.configure(environment: environment, container: container)
        #expect(container.appEnvironment() == environment)
    }

    private func startedApp() -> AppCoordinator {
        let app = AppCoordinator(window: UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844)), environment: .preview)
        app.start()
        return app
    }

    @Test func serverDrivenScreensOpenFromAnyTab() {
        let app = startedApp()
        #expect(app.handle(DeepLink("screens/showcase")))
        #expect(app.flows[.home]?.rootViewController.viewControllers.count == 2)
        #expect(!app.handle(DeepLink("screens")))
    }

    @Test func cameraIsATabBarActionNotATab() throws {
        let app = startedApp()
        let tabs = try #require(app.tabBarController as? LiquidGlassTabBarController)
        #expect(tabs.actionButton?.title == L10n.Tab.camera)
        #expect(tabs.viewControllers?.count == AppTab.allCases.count)
        #expect(CameraLauncher.makePicker(prefersCamera: false) is PHPickerViewController)
        // Simulator: no camera, so the library even when the camera is preferred.
        let picker = CameraLauncher.makePicker()
        #expect(UIImagePickerController.isSourceTypeAvailable(.camera) ? picker is UIImagePickerController : picker is PHPickerViewController)
    }
}
