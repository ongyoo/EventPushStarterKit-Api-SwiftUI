//
//  AppCoordinator.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import Core
import DesignSystem
import LiquidGlassKit
import Navigation
import Platform
import UIKit

/// Root of the navigation tree. Owns the window, the tab bar and one
/// flow coordinator per tab, and is the single entry point for deep links
/// (custom scheme, universal links, push notifications, widgets...).
///
///     AppCoordinator
///      └─ HomeFlowCoordinator   (tab "home")
///          ├─ HomeCoordinator (root)
///          └─ feature coordinators pushed on top (released on pop)
@MainActor
public final class AppCoordinator {
    private let window: UIWindow
    private let environment: AppEnvironment
    let tabBarController: UITabBarController

    private(set) var flows: [AppTab: TabFlowCoordinator] = [:]
    private var pendingLink: DeepLink?
    private let privacyShield = PrivacyShield()
    private var languageObservation: ObservationToken?

    /// Blur the App Switcher snapshot (turn on for banking / health / PII apps).
    public var hidesContentInAppSwitcher = false

    /// - Parameter tabBarStyle: `.belowIOS26(.glass)` = floating glass bar on
    ///   iOS 17–18, system Liquid Glass on iOS 26. `.system` = UIKit's bar everywhere.
    public init(
        window: UIWindow,
        environment: AppEnvironment = Container.shared.appEnvironment(),
        tabBarStyle: LiquidGlassTabBarController.Style = .belowIOS26(.glass)
    ) {
        self.window = window
        self.environment = environment
        let tabs = LiquidGlassTabBarController(style: tabBarStyle)
        tabs.minimizeBehavior = .onScrollDown
        self.tabBarController = tabs
    }

    public var isStarted: Bool { !flows.isEmpty }

    public func start() {
        guard !isStarted else { return }
        buildTabs()
        tabBarController.tabBar.tintColor = .brandPrimary
        window.rootViewController = tabBarController
        window.makeKeyAndVisible()

        // Notification taps, Siri, widgets... all arrive through the inbox.
        DeepLinkInbox.shared.setHandler { [weak self] link in
            self?.handle(link) ?? false
        }
        languageObservation = LocalizationManager.shared.observe { [weak self] _ in
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

    public func sceneWillResignActive() {
        if hidesContentInAppSwitcher { privacyShield.show(on: window) }
    }

    public func sceneDidBecomeActive() {
        privacyShield.hide()
    }

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
    /// (`profile/42`) goes to the Home tab, which understands shared routes.
    @discardableResult
    func handle(_ link: DeepLink) -> Bool {
        let tab = link.first.flatMap(AppTab.init(rawValue:))
        let target = tab ?? .home
        let rest = tab == nil ? link : link.dropFirst()

        guard let flow = flows[target] else { return false }
        tabBarController.selectedViewController = flow.rootViewController
        let handled = flow.handle(rest)
        Log.navigation.info("Deep link \(link.description, privacy: .public) handled: \(handled)")
        return handled
    }
}
