//
//  SettingsContract.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import Core
import Foundation

// MARK: - Entity (screen model)

public enum DemoNotification: CaseIterable, Sendable {
    case now, later, group, actions
}

/// Glass tab bar looks the user can switch between (LiquidGlassKit presets).
public enum TabBarLook: String, CaseIterable, Codable, Sendable {
    case glass, tinted, solid, minimal, underline

    var systemImage: String {
        switch self {
        case .glass: "capsule"
        case .tinted: "capsule.fill"
        case .solid: "button.horizontal.fill"
        case .minimal: "circle.fill"
        case .underline: "underline"
        }
    }
}

enum NavigationDemo: String, CaseIterable, Sendable {
    case pushFade, pushSlideUp, pushScale, sheet, fullScreen, modalFlow, backTinted, backArrow, serverDriven

    var systemImage: String {
        switch self {
        case .pushFade: "circle.lefthalf.filled"
        case .pushSlideUp: "arrow.up.square"
        case .pushScale: "arrow.up.left.and.arrow.down.right"
        case .sheet: "rectangle.bottomhalf.filled"
        case .fullScreen: "rectangle.inset.filled"
        case .modalFlow: "square.stack.3d.up"
        case .backTinted: "chevron.backward.circle"
        case .backArrow: "arrow.backward.circle"
        case .serverDriven: "server.rack"
        }
    }
}

// MARK: - Router (implemented by SettingsCoordinator)

@MainActor
protocol SettingsRouting: AnyObject {
    func showAnimationGallery()
    func showKeyboardDemo()
    func showNavigationDemo(_ demo: NavigationDemo)
}

// MARK: - Interactor (port: implemented by the App layer with Platform servicure services)

@MainActor
public protocol SettingsInteracting: AnyObject {
    var languages: [LocalizationManager.Language] { get }
    var languageSelection: LocalizationManager.Selection { get }
    var features: AppFeatures { get }
    var appVersion: String { get }

    func selectLanguage(_ selection: LocalizationManager.Selection)

    /// Look of the glass tab bar (Settings > Tab bar). Applied live.
    var tabBarLook: TabBarLook { get }
    func setTabBarLook(_ look: TabBarLook)
    /// Tab bar shrinks while scrolling down (iOS 26 style). Off = always full size.
    var isTabBarMinimizeEnabled: Bool { get }
    func setTabBarMinimizeEnabled(_ isOn: Bool)

    /// User's analytics consent (Settings > Privacy).
    var isAnalyticsEnabled: Bool { get }
    func setAnalyticsEnabled(_ isOn: Bool)
    func permissionStatuses() async -> [Permission: PermissionStatus]
    func request(_ permission: Permission) async -> PermissionStatus
    func openSystemSettings()

    /// `false` when notifications are off or not allowed.
    func send(_ demo: DemoNotification) async -> Bool
    func pendingNotificationCount() async -> Int
    func removeAllNotifications() async

    func scheduleBackgroundTasks()
    func startLiveActivity() async -> Bool
    func endLiveActivities() async
}
