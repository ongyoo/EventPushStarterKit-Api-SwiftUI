//
//  SettingsPresenter.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import Core
import Foundation
import Observation

@MainActor
@Observable
final class SettingsPresenter {
    private(set) var permissions: [Permission: PermissionStatus] = [:]
    private(set) var pendingCount = 0
    /// Short feedback shown at the top of the list.
    private(set) var message: String?
    private(set) var languageSelection: LocalizationManager.Selection
    /// "Share usage analytics" switch (Privacy section).
    private(set) var isAnalyticsEnabled: Bool
    private(set) var tabBarLook: TabBarLook
    private(set) var isTabBarMinimizeEnabled: Bool

    let languages: [LocalizationManager.Language]
    let features: AppFeatures
    let appVersion: String
    let orderedPermissions = Permission.allCases

    @ObservationIgnored private let interactor: any SettingsInteracting
    @ObservationIgnored private weak var router: (any SettingsRouting)?
    @ObservationIgnored private let analytics: any AnalyticsTracking

    init(
        interactor: any SettingsInteracting,
        router: (any SettingsRouting)?,
        analytics: any AnalyticsTracking = Container.shared.analytics()
    ) {
        self.interactor = interactor
        self.router = router
        self.analytics = analytics
        self.isAnalyticsEnabled = interactor.isAnalyticsEnabled
        self.tabBarLook = interactor.tabBarLook
        self.isTabBarMinimizeEnabled = interactor.isTabBarMinimizeEnabled
        self.languages = interactor.languages
        self.features = interactor.features
        self.appVersion = interactor.appVersion
        self.languageSelection = interactor.languageSelection
    }

    func load() async {
        permissions = await interactor.permissionStatuses()
        pendingCount = await interactor.pendingNotificationCount()
    }

    // MARK: - Language

    func didSelectLanguage(_ selection: LocalizationManager.Selection) {
        guard selection != languageSelection else { return }
        languageSelection = selection
        if case let .language(code) = selection {
            analytics.track(.languageChanged(code))
        } else {
            analytics.track(.languageChanged("system"))
        }
        // The app coordinator rebuilds every screen in the new language.
        interactor.selectLanguage(selection)
    }

    func didTapOpenSystemSettings() {
        interactor.openSystemSettings()
    }

    // MARK: - Permissions

    /// Not asked -> system prompt. Denied -> iOS Settings (the only way back).
    func didTapPermission(_ permission: Permission) async {
        let status = permissions[permission] ?? .notDetermined
        if status.needsSettings {
            interactor.openSystemSettings()
        } else if status.canRequest {
            let result = await interactor.request(permission)
            permissions[permission] = result
            analytics.track(.permissionRequested(permission, granted: result.isGranted))
        }
    }

    // MARK: - Privacy

    /// Opting out stops every event immediately, including this screen's.
    func didToggleAnalytics(_ isOn: Bool) {
        isAnalyticsEnabled = isOn
        interactor.setAnalyticsEnabled(isOn)
    }

    // MARK: - Tab bar

    func didSelectTabBarLook(_ look: TabBarLook) {
        guard look != tabBarLook else { return }
        tabBarLook = look
        interactor.setTabBarLook(look)
    }

    func didToggleTabBarMinimize(_ isOn: Bool) {
        isTabBarMinimizeEnabled = isOn
        interactor.setTabBarMinimizeEnabled(isOn)
    }

    // MARK: - Notifications & capabilities

    func didTapSend(_ demo: DemoNotification) async {
        let sent = await interactor.send(demo)
        message = sent ? L10n.tr("settings.notifications.sent") : L10n.tr("settings.notifications.denied")
        permissions[.notifications] = await interactor.permissionStatuses()[.notifications]
        pendingCount = await interactor.pendingNotificationCount()
    }

    func didTapRemoveAllNotifications() async {
        await interactor.removeAllNotifications()
        pendingCount = await interactor.pendingNotificationCount()
    }

    func didTapScheduleBackgroundTasks() {
        interactor.scheduleBackgroundTasks()
        message = L10n.tr("settings.background.scheduled")
    }

    func didTapStartLiveActivity() async {
        message = await interactor.startLiveActivity() ? nil : L10n.tr("permission.status.unavailable")
    }

    func didTapEndLiveActivities() async {
        await interactor.endLiveActivities()
    }

    func didTapNavigationDemo(_ demo: NavigationDemo) {
        router?.showNavigationDemo(demo)
    }

    func didTapKeyboardDemo() {
        router?.showKeyboardDemo()
    }

    func didTapAnimations() {
        router?.showAnimationGallery()
    }

    func dismissMessage() {
        message = nil
    }
}
