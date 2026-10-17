//
//  LocalNotificationCenter.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import Core
import Foundation
import UserNotifications

/// Wrapper around `UNUserNotificationCenter`: schedule, group, actions,
/// remove (by id, by group, all), badge, and tap handling.
///
/// Start once at launch (only if `FEATURE_LOCAL_NOTIFICATIONS = YES`):
///
///     LocalNotificationCenter.shared.activate(categories: [...]) { response in ... }
///
/// Permission: `PermissionCenter.shared.request(.notifications)`.
@MainActor
public final class LocalNotificationCenter: NSObject {
    /// Activated by `AppAssembly` when `FEATURE_LOCAL_NOTIFICATIONS = YES`.
    public static let shared = LocalNotificationCenter()

    /// What to show when a notification arrives while the app is open.
    public var foregroundPresentation: UNNotificationPresentationOptions = [.banner, .list, .sound, .badge]

    private var onResponse: ((NotificationResponse) -> Void)?

    /// `UNUserNotificationCenter.current()` raises an exception outside an
    /// app bundle (unit tests, some extensions). Every call is guarded by this.
    nonisolated static var isAvailable: Bool {
        Bundle.main.bundleURL.pathExtension == "app"
    }

    private var center: UNUserNotificationCenter? {
        Self.isAvailable ? .current() : nil
    }

    // MARK: - Setup

    /// Becomes the notification delegate, registers action categories and
    /// forwards taps. Taps with a `deepLink` are posted to `DeepLinkInbox`.
    public func activate(
        categories: [NotificationCategory] = [],
        onResponse: ((NotificationResponse) -> Void)? = nil
    ) {
        self.onResponse = onResponse
        guard let center else { return }
        center.delegate = self
        center.setNotificationCategories(Set(categories.map { $0.makeCategory() }))
    }

    // MARK: - Schedule

    /// Schedules one notification. Same `id` replaces the previous one.
    ///
    ///     try await LocalNotificationCenter.shared.schedule(LocalNotification(title: "Hi", body: "There"))
    public func schedule(_ notification: LocalNotification) async throws {
        try await center?.add(notification.makeRequest())
    }

    /// Schedules several notifications (e.g. a reminder series).
    public func schedule(_ notifications: [LocalNotification]) async throws {
        for notification in notifications {
            try await schedule(notification)
        }
    }

    // MARK: - Query

    /// IDs scheduled but not shown yet.
    public func pendingIDs() async -> [String] {
        await center?.pendingNotificationRequests().map(\.identifier) ?? []
    }

    /// IDs currently in Notification Center.
    public func deliveredIDs() async -> [String] {
        await center?.deliveredNotifications().map(\.request.identifier) ?? []
    }

    // MARK: - Remove

    /// Cancels scheduled (not yet shown) notifications.
    public func cancel(ids: [String]) {
        center?.removePendingNotificationRequests(withIdentifiers: ids)
    }

    /// Cancels every scheduled notification.
    public func cancelAll() {
        center?.removeAllPendingNotificationRequests()
    }

    /// Removes notifications already shown in Notification Center.
    public func removeDelivered(ids: [String]) {
        center?.removeDeliveredNotifications(withIdentifiers: ids)
    }

    /// Removes a whole stack (pending + delivered) by its `group`.
    public func removeGroup(_ group: String) async {
        guard let center else { return }
        let pending = await center.pendingNotificationRequests()
            .filter { $0.content.threadIdentifier == group }
            .map(\.identifier)
        let delivered = await center.deliveredNotifications()
            .filter { $0.request.content.threadIdentifier == group }
            .map(\.request.identifier)
        cancel(ids: pending)
        removeDelivered(ids: delivered)
    }

    public func removeAllDelivered() {
        center?.removeAllDeliveredNotifications()
    }

    /// Sets the app icon badge (0 clears it).
    public func setBadge(_ count: Int) async {
        try? await center?.setBadgeCount(count)
    }

    // MARK: - Responses

    func handle(_ response: NotificationResponse) {
        if let path = response.deepLink, response.action != .dismissed {
            DeepLinkInbox.shared.post(DeepLink(path))
        }
        onResponse?(response)
    }

    nonisolated static func makeResponse(
        actionID: String,
        text: String?,
        notificationID: String,
        userInfo: [AnyHashable: Any]
    ) -> NotificationResponse {
        let info = userInfo.reduce(into: [String: String]()) { result, pair in
            if let key = pair.key as? String, let value = pair.value as? String { result[key] = value }
        }
        let action: NotificationResponse.Action = switch actionID {
        case UNNotificationDefaultActionIdentifier: .opened
        case UNNotificationDismissActionIdentifier: .dismissed
        default: .custom(id: actionID, text: text)
        }
        return NotificationResponse(
            notificationID: notificationID,
            action: action,
            deepLink: info[LocalNotification.deepLinkKey],
            userInfo: info
        )
    }
}

extension LocalNotificationCenter: UNUserNotificationCenterDelegate {
    public nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        await MainActor.run { foregroundPresentation }
    }

    public nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let parsed = Self.makeResponse(
            actionID: response.actionIdentifier,
            text: (response as? UNTextInputNotificationResponse)?.userText,
            notificationID: response.notification.request.identifier,
            userInfo: response.notification.request.content.userInfo
        )
        await MainActor.run { handle(parsed) }
    }
}
