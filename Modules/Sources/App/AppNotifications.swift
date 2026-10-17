//
//  AppNotifications.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import Core
import Features
import Foundation
import Platform

/// App-specific notification setup: action categories, sample notifications
/// and what each action does. Generic plumbing lives in Core
/// (`LocalNotificationCenter`).
@MainActor
enum AppNotifications {
    static let eventCategoryID = "event"
    static let eventsGroup = "events"

    enum ActionID {
        static let remind = "remind"
        static let reply = "reply"
        static let mute = "mute"
    }

    /// Re-registered after a language change so button titles are translated.
    static var categories: [NotificationCategory] {
        [
            NotificationCategory(id: eventCategoryID, actions: [
                .init(id: ActionID.remind, title: L10n.tr("notification.action.remind")),
                .init(id: ActionID.reply, title: L10n.tr("notification.action.reply"),
                      textInput: L10n.tr("notification.action.replyPlaceholder")),
                .init(id: ActionID.mute, title: L10n.tr("notification.action.mute"), style: .destructive),
            ]),
        ]
    }

    /// Taps with a deep link are already routed by `LocalNotificationCenter`;
    /// this handles the custom buttons.
    static func handle(_ response: NotificationResponse, center: LocalNotificationCenter = .shared) {
        guard case let .custom(actionID, text) = response.action else { return }
        switch actionID {
        case ActionID.remind:
            Task {
                try? await center.schedule(reminder(eventID: response.deepLink.map { DeepLink($0).path.last ?? "1" } ?? "1", after: 10 * 60))
            }
        case ActionID.reply:
            Log.app.info("Reply received (\(text?.count ?? 0) characters)")
        case ActionID.mute:
            Task { await center.removeGroup(eventsGroup) }
        default:
            break
        }
    }

    static func reminder(eventID: String, after seconds: TimeInterval = 1) -> LocalNotification {
        LocalNotification(
            id: "reminder-\(eventID)",
            title: L10n.tr("notification.reminder.title"),
            body: L10n.tr("notification.reminder.body"),
            trigger: seconds <= 1 ? .now : .after(seconds),
            categoryID: eventCategoryID,
            deepLink: "events/\(eventID)",
            priority: .active,
            relevance: 1
        )
    }

    /// Three notifications stacked into one group.
    static func groupSample() -> [LocalNotification] {
        ["2", "3", "4"].map { id in
            LocalNotification(
                id: "group-\(id)",
                title: L10n.tr("notification.group.title"),
                body: "#\(id)",
                group: eventsGroup,
                deepLink: "events/\(id)"
            )
        }
    }
}
