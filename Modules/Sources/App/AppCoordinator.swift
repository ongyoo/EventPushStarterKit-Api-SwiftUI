//
//  AppCoordinator.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import Core
import DesignSystem
import Features
import LiquidGlassKit
import Navigation
import Platform
import UIKit

/// Root of the navigation tree. Owns the window, the tab bar and one
/// flow coordinator per tab, and is the single entry point for deep links
/// (custom scheme, universal links, push notifications, widgets...).
///
///     AppCoordinator
///      ├─ HomeFlowCoordinator   (tab "home")
///      │   ├─ HomeCoordinator (root)
///      │   └─ EventDetailCoordinator, EventListCoordinator... (pushed, released on pop)
///      └─ InboxFlowCoordinator  (tab "inbox")
///          ├─ NotificationCoordinator (root)
///          └─ EventDetailCoordinator... (pushed)
@MainActor
public final class AppCoordinator {
    private let window: UIWindow
    private let environment: AppEnvironment
    let tabBarController: UITabBarController

    private(set) var flows: [AppTab: TabFlowCoordinator] = [:]
    private var pendingLink: DeepLink?
    private let privacyShield = PrivacyShield()
    private var languageObservation: ObservationToken?
    private let analytics: any AnalyticsTracking
    private let tabBarDelegate = TabBarDelegate()

    /// Blur the App Switcher snapshot (turn on for banking / health / PII apps).
    public var hidesContentInAppSwitcher = false

    /// Created by `SceneDelegate` with its window.
    /// - Parameter tabBarStyle: `.glass` (default) = the kit's bar on every
    ///   version, drawn with Apple's own glass on iOS 26, so the raised camera
    ///   button sits in the bar everywhere. `.belowIOS26(.glass)` = UIKit's bar
    ///   on iOS 26 (camera floats above it). `.system` = UIKit's bar everywhere.
    public init(
        window: UIWindow,
        environment: AppEnvironment = Container.shared.appEnvironment(),
        analytics: any AnalyticsTracking = Container.shared.analytics(),
        tabBarStyle: LiquidGlassTabBarController.Style = .glass
    ) {
        self.window = window
        let tabs = LiquidGlassTabBarController(style: tabBarStyle)
        // Settings > Tab bar: look + shrink while scrolling (like iOS 26), applied live.
        TabBarLooks.shared.apply(to: tabs)
        TabBarLooks.shared.observe { [weak tabs] in
            guard let tabs else { return }
            UIView.animate(withDuration: 0.3) {
                TabBarLooks.shared.apply(to: tabs)
                tabs.view.layoutIfNeeded()
            }
        }
        // Not a tab: a raised camera button that presents over any tab.
        tabs.actionButton = LiquidGlassTabBarAction(
            image: UIImage(systemName: "camera.fill"),
            title: L10n.Tab.camera
        ) { tabs in
            CameraLauncher.present(from: tabs)
        }
        self.tabBarController = tabs
        self.environment = environment
        self.analytics = analytics
    }

    /// `true` after `start()`.
    public var isStarted: Bool { !flows.isEmpty }

    /// Builds the tabs, shows the window and handles any pending deep link.
    public func start() {
        guard !isStarted else { return }
        buildTabs()
        tabBarController.tabBar.tintColor = .brandPrimary
        // Switching tabs shows a screen without a push: report it like Navigator does.
        tabBarDelegate.onSelect = { [weak self] viewController in
            let top = (viewController as? UINavigationController)?.topViewController ?? viewController
            self?.analytics.track(.screenView(top.resolvedAnalyticsScreenName))
        }
        tabBarController.delegate = tabBarDelegate
        analytics.setUserProperty(LocalizationManager.shared.current.code, forName: "app_language")
        window.rootViewController = tabBarController
        window.makeKeyAndVisible()
        // Tap outside a text field hides the keyboard on every screen.
        Keyboard.enableTapToDismiss(in: window)

        // Notification taps, Siri, widgets... all arrive through the inbox.
        DeepLinkInbox.shared.setHandler { [weak self] link in
            self?.handle(link) ?? false
        }
        languageObservation = LocalizationManager.shared.observe { [weak self] language in
            self?.analytics.setUserProperty(language.code, forName: "app_language")
            self?.reloadForLanguageChange()
        }

        if let link = pendingLink {
            pendingLink = nil
            handle(link)
        }
    }

    private func buildTabs() {
        flows = [
            .home: HomeFlowCoordinator(),
            .inbox: InboxFlowCoordinator(),
            .settings: SettingsFlowCoordinator(),
        ]
        tabBarController.viewControllers = AppTab.allCases.compactMap { tab in
            guard let flow = flows[tab] else { return nil }
            flow.start()
            flow.rootViewController.tabBarItem = tab.tabBarItem
            return flow.rootViewController
        }
    }

    /// Live language switch: rebuild every screen in the new language and
    /// keep the user on the same tab. Old flows are released (leak-checked).
    func reloadForLanguageChange() {
        let selectedIndex = tabBarController.selectedIndex
        let oldFlows = Array(flows.values)
        buildTabs()
        tabBarController.selectedIndex = selectedIndex
        oldFlows.forEach { LeakDetector.expectDeallocation(of: $0) }
        if Container.shared.appEnvironment().features.localNotifications {
            LocalNotificationCenter.shared.activate(categories: AppNotifications.categories, onResponse: { AppNotifications.handle($0) })
        }
    }

    // MARK: - Scene lifecycle

    /// Forward from `SceneDelegate` (privacy blur).
    public func sceneWillResignActive() {
        if hidesContentInAppSwitcher { privacyShield.show(on: window) }
    }

    /// Forward from `SceneDelegate`.
    public func sceneDidBecomeActive() {
        privacyShield.hide()
    }

    /// Forward from `SceneDelegate` (schedules background tasks).
    public func sceneDidEnterBackground() {
        if environment.features.backgroundTasks {
            BackgroundTaskService.shared.scheduleAll()
        }
    }

    // MARK: - Deep links

    /// Entry point for URLs. Links that arrive before `start()` (cold launch)
    /// are kept and handled right after the UI is ready.
    @discardableResult
    public func open(_ url: URL) -> Bool {
        guard let link = DeepLink(
            url: url,
            scheme: environment.deepLinkScheme,
            universalLinkHost: environment.universalLinkHost
        ) else {
            Log.navigation.error("Rejected deep link \(url.absoluteString, privacy: .private)")
            return false
        }
        guard isStarted else {
            pendingLink = link
            return true
        }
        return handle(link)
    }

    /// First segment picks the tab (`home`, `inbox`). Anything else
    /// (`events/42`) goes to the Home tab, which understands shared routes.
    @discardableResult
    func handle(_ link: DeepLink) -> Bool {
        let tab = link.first.flatMap(AppTab.init(rawValue:))
        let target = tab ?? .home
        let rest = tab == nil ? link : link.dropFirst()

        guard let flow = flows[target] else { return false }
        let switchesTab = tabBarController.selectedViewController !== flow.rootViewController
        tabBarController.selectedViewController = flow.rootViewController
        let handled = flow.handle(rest)
        // A link that only switches tab pushes nothing, so Navigator reports nothing.
        if switchesTab, rest.isEmpty, let top = flow.rootViewController.topViewController {
            analytics.track(.screenView(top.resolvedAnalyticsScreenName))
        }
        Log.navigation.info("Deep link \(link.description, privacy: .public) handled: \(handled)")
        analytics.track(AnalyticsEvent("deep_link_opened", ["route": .string(Self.route(of: link)), "handled": .bool(handled)]))
        return handled
    }

    /// `events/42/organizer` -> `events/:id/organizer`: the shape of the link,
    /// without ids or query values (they can identify a user).
    static func route(of link: DeepLink) -> String {
        let segments = link.path.map { segment in
            segment.contains(where: \.isNumber) || segment.count > 24 ? ":id" : segment
        }
        return segments.isEmpty ? "/" : segments.joined(separator: "/")
    }
}

/// `UITabBarControllerDelegate` needs an NSObject; the coordinator stays a plain class.
private final class TabBarDelegate: NSObject, UITabBarControllerDelegate {
    var onSelect: ((UIViewController) -> Void)?

    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        onSelect?(viewController)
    }
}
