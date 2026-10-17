//
//  SettingsView.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import Core
import DesignSystem
import SwiftUI

struct SettingsView: View {
    let presenter: SettingsPresenter

    var body: some View {
        Form {
            if let message = presenter.message {
                Section {
                    Label(message, systemImage: "info.circle")
                        .onTapGesture(perform: presenter.dismissMessage)
                        .transition(.dsSlideDown)
                }
            }
            languageSection
            tabBarSection
            privacySection
            permissionsSection
            if presenter.features.localNotifications {
                notificationsSection
            }
            capabilitiesSection
            navigationSection
            developerSection
        }
        .animation(.dsStandard, value: presenter.message)
        // Reloads on every appearance on purpose: permission statuses may have
        // changed in iOS Settings. Content stays on screen while it refreshes.
        .task { await presenter.load() }
        .refreshable { await presenter.load() }
    }

    // MARK: - Sections

    private var languageSection: some View {
        Section {
            Picker(L10n.tr("settings.language"), selection: Binding(
                get: { presenter.languageSelection },
                set: { presenter.didSelectLanguage($0) }
            )) {
                Text(L10n.tr("settings.language.system")).tag(LocalizationManager.Selection.system)
                ForEach(presenter.languages) { language in
                    Text(language.nativeName).tag(LocalizationManager.Selection.language(language.code))
                }
            }
            .pickerStyle(.inline)
            .labelsHidden()
            Button(L10n.tr("settings.openSystemSettings"), systemImage: "gear", action: presenter.didTapOpenSystemSettings)
        } header: {
            Text(L10n.tr("settings.language"))
        } footer: {
            Text(L10n.tr("settings.language.footer"))
        }
    }

    private var tabBarSection: some View {
        Section {
            Toggle(isOn: Binding(get: { presenter.isTabBarMinimizeEnabled }, set: { presenter.didToggleTabBarMinimize($0) })) {
                Label(L10n.tr("settings.tabBar.minimize"), systemImage: "arrow.down.right.and.arrow.up.left")
            }
            ForEach(TabBarLook.allCases, id: \.self) { look in
                Button {
                    presenter.didSelectTabBarLook(look)
                } label: {
                    HStack {
                        Label(L10n.tr("tabBar.\(look.rawValue)"), systemImage: look.systemImage)
                            .foregroundStyle(Color.primary)
                        Spacer()
                        if presenter.tabBarLook == look {
                            Image(systemName: "checkmark").foregroundStyle(Color.accentColor)
                        }
                    }
                }
            }
        } header: {
            Text(L10n.tr("settings.tabBar"))
        } footer: {
            Text(L10n.tr("settings.tabBar.footer"))
        }
    }

    private var privacySection: some View {
        Section {
            Toggle(isOn: Binding(get: { presenter.isAnalyticsEnabled }, set: { presenter.didToggleAnalytics($0) })) {
                Label(L10n.tr("settings.analytics"), systemImage: "chart.bar")
            }
        } header: {
            Text(L10n.tr("settings.privacy"))
        } footer: {
            Text(L10n.tr("settings.analytics.footer"))
        }
    }

    private var permissionsSection: some View {
        Section {
            ForEach(presenter.orderedPermissions) { permission in
                PermissionRow(
                    title: L10n.permission(permission),
                    systemImage: permission.systemImage,
                    status: presenter.permissions[permission] ?? .notDetermined
                ) {
                    Task { await presenter.didTapPermission(permission) }
                }
            }
        } header: {
            Text(L10n.tr("settings.permissions"))
        } footer: {
            Text(L10n.tr("settings.permissions.footer"))
        }
    }

    private var notificationsSection: some View {
        Section {
            demoButton(L10n.tr("settings.notifications.now"), "bell", .now)
            demoButton(L10n.tr("settings.notifications.later"), "clock", .later)
            demoButton(L10n.tr("settings.notifications.group"), "square.stack", .group)
            demoButton(L10n.tr("settings.notifications.actions"), "hand.tap", .actions)
            Button(L10n.tr("settings.notifications.clear"), systemImage: "trash", role: .destructive) {
                Task { await presenter.didTapRemoveAllNotifications() }
            }
        } header: {
            Text(L10n.tr("settings.notifications"))
        } footer: {
            Text(L10n.tr("settings.notifications.pending", presenter.pendingCount))
        }
    }

    private var capabilitiesSection: some View {
        Section(L10n.tr("settings.capabilities")) {
            capability("settings.capability.localNotifications", presenter.features.localNotifications)
            capability("settings.capability.backgroundTasks", presenter.features.backgroundTasks)
            capability("settings.capability.silentPush", presenter.features.silentPush)
            capability("settings.capability.liveActivities", presenter.features.liveActivities)
            capability("settings.capability.siri", presenter.features.siri)
            if presenter.features.backgroundTasks {
                Button(L10n.tr("settings.background.schedule"), systemImage: "arrow.clockwise", action: presenter.didTapScheduleBackgroundTasks)
            }
            if presenter.features.liveActivities {
                Button(L10n.tr("settings.liveActivity.start"), systemImage: "livephoto") {
                    Task { await presenter.didTapStartLiveActivity() }
                }
                Button(L10n.tr("settings.liveActivity.end"), systemImage: "stop.circle") {
                    Task { await presenter.didTapEndLiveActivities() }
                }
            }
        }
    }

    private var navigationSection: some View {
        Section(L10n.tr("settings.navigation")) {
            ForEach(NavigationDemo.allCases, id: \.self) { demo in
                Button(L10n.tr("nav.\(demo.rawValue)"), systemImage: demo.systemImage) {
                    presenter.didTapNavigationDemo(demo)
                }
            }
        }
    }

    private var developerSection: some View {
        Section(L10n.tr("settings.developer")) {
            #if DEBUG
            Button(L10n.tr("settings.animations"), systemImage: "sparkles", action: presenter.didTapAnimations)
            #endif
            Button(L10n.tr("keyboard.title"), systemImage: "keyboard", action: presenter.didTapKeyboardDemo)
            LabeledContent(L10n.tr("settings.version"), value: presenter.appVersion)
        }
    }

    // MARK: - Rows

    private func demoButton(_ title: String, _ systemImage: String, _ demo: DemoNotification) -> some View {
        Button(title, systemImage: systemImage) {
            Task { await presenter.didTapSend(demo) }
        }
    }

    private func capability(_ key: String, _ isOn: Bool) -> some View {
        LabeledContent(L10n.tr(key)) {
            Text(isOn ? L10n.tr("settings.capability.on") : L10n.tr("settings.capability.off"))
                .foregroundStyle(isOn ? Color.green : .textSecondary)
        }
    }
}

private struct PermissionRow: View {
    let title: String
    let systemImage: String
    let status: PermissionStatus
    let action: () -> Void

    var body: some View {
        HStack {
            Label(title, systemImage: systemImage)
            Spacer()
            Text(L10n.permissionStatus(status))
                .font(.dsCaption)
                .foregroundStyle(color)
            if status.canRequest || status.needsSettings {
                Button(status.canRequest ? L10n.tr("settings.permission.request") : L10n.tr("settings.permission.settings"), action: action)
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            }
        }
    }

    private var color: Color {
        if status.isGranted { return .green }
        if status.needsSettings { return .red }
        return .textSecondary
    }
}
