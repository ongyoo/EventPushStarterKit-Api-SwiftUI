//
//  SettingsInteractor.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import Core
import Domain
import Features
import Foundation
import Platform

/// Settings screen port implemented with the device services of Platform.
final class SettingsInteractor: SettingsInteracting {
    private let localization: LocalizationManager
    private let permissions: PermissionCenter
    private let notifications: LocalNotificationCenter
    private let background: BackgroundTaskService
    private let environment: AppEnvironment
    private let liveActivities: LiveActivityService<EventActivityAttributes>
    private let analytics: AnalyticsCenter

    init(
        localization: LocalizationManager = .shared,
        permissions: PermissionCenter = .shared,
        notifications: LocalNotificationCenter = .shared,
        background: BackgroundTaskService = .shared,
        environment: AppEnvironment = Container.shared.appEnvironment(),
        analytics: AnalyticsCenter = Container.shared.analyticsCenter()
    ) {
        self.analytics = analytics
        self.localization = localization
        self.permissions = permissions
        self.notifications = notifications
        self.background = background
        self.environment = environment
        self.liveActivities = LiveActivityService(isFeatureEnabled: environment.features.liveActivities)
    }

    var languages: [LocalizationManager.Language] { localization.supported }
    var languageSelection: LocalizationManager.Selection { localization.selection }
    var features: AppFeatures { environment.features }

    var appVersion: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "-"
        let build = info?["CFBundleVersion"] as? String ?? "-"
        return "\(version) (\(build))"
    }

    func selectLanguage(_ selection: LocalizationManager.Selection) {
        localization.select(selection)
    }

    var tabBarLook: TabBarLook { TabBarLooks.shared.current }

    func setTabBarLook(_ look: TabBarLook) {
        TabBarLooks.shared.current = look
    }

    var isTabBarMinimizeEnabled: Bool { TabBarLooks.shared.minimizesOnScroll }

    func setTabBarMinimizeEnabled(_ isOn: Bool) {
        TabBarLooks.shared.minimizesOnScroll = isOn
    }

    var isAnalyticsEnabled: Bool { analytics.isEnabled }

    func setAnalyticsEnabled(_ isOn: Bool) {
        analytics.isEnabled = isOn
    }

    func permissionStatuses() async -> [Permission: PermissionStatus] {
        await permissions.statuses()
    }

    func request(_ permission: Permission) async -> PermissionStatus {
        await permissions.request(permission)
    }

    func openSystemSettings() {
        permissions.openSettings()
    }

    func send(_ demo: DemoNotification) async -> Bool {
        guard features.localNotifications else { return false }
        guard await permissions.request(.notifications).isGranted else { return false }
        do {
            switch demo {
            case .now: try await notifications.schedule(AppNotifications.reminder(eventID: "1"))
            case .later: try await notifications.schedule(AppNotifications.reminder(eventID: "2", after: 5))
            case .group: try await notifications.schedule(AppNotifications.groupSample())
            case .actions: try await notifications.schedule(AppNotifications.reminder(eventID: "3", after: 3))
            }
            return true
        } catch {
            Log.app.error("Notification failed: \(error.localizedDescription, privacy: .public)")
            return false
        }
    }

    func pendingNotificationCount() async -> Int {
        await notifications.pendingIDs().count
    }

    func removeAllNotifications() async {
        notifications.cancelAll()
        notifications.removeAllDelivered()
        await notifications.setBadge(0)
    }

    func scheduleBackgroundTasks() {
        background.scheduleAll()
    }

    func startLiveActivity() async -> Bool {
        let attributes = EventActivityAttributes(event: .sample)
        let state = EventActivityAttributes.ContentState(status: L10n.Event.title, startsAt: .now.addingTimeInterval(3600))
        return (try? liveActivities.start(attributes, state: state)) != nil
    }

    func endLiveActivities() async {
        await liveActivities.endAll()
    }
}
