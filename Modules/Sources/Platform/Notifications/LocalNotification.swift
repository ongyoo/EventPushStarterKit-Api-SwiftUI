//
//  LocalNotification.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import Foundation
import UserNotifications

/// Everything needed to show one local notification.
///
///     try await LocalNotificationCenter.shared.schedule(
///         LocalNotification(title: "Starts soon", body: "King's Cup in 1 hour",
///                           trigger: .after(3600), group: "event-1", deepLink: "events/1")
///     )
public struct LocalNotification: Sendable, Equatable {
    /// When to deliver.
    public enum Trigger: Sendable, Equatable {
        /// Deliver right away (1 second, the system minimum).
        case now
        /// After `seconds`. Repeating requires at least 60 seconds.
        case after(TimeInterval, repeats: Bool = false)
        /// At a calendar date, e.g. every day 09:00: `DateComponents(hour: 9)` + repeats.
        case at(DateComponents, repeats: Bool = false)
    }

    /// What to play.
    public enum Sound: Sendable, Equatable {
        case none
        case `default`
        /// File in the main bundle, e.g. "ding.caf".
        case named(String)
    }

    /// How strongly to interrupt (Focus modes).
    public enum Priority: Sendable, Equatable {
        /// Silent, no wake (digest-like).
        case passive
        /// Normal.
        case active
        /// Breaks through Focus. Needs the Time Sensitive capability.
        case timeSensitive
    }

    public var id: String
    public var title: String
    public var subtitle: String?
    public var body: String
    public var trigger: Trigger
    public var sound: Sound
    public var badge: Int?
    /// Notifications with the same group are stacked together.
    public var group: String?
    /// `NotificationCategory.id` to show action buttons.
    public var categoryID: String?
    /// Path opened when tapped, e.g. "events/42" (routed through `DeepLinkInbox`).
    public var deepLink: String?
    /// Local image/video file shown in the notification.
    public var attachmentURL: URL?
    public var priority: Priority
    /// 0...1, used to pick the featured notification in a summary.
    public var relevance: Double
    public var userInfo: [String: String]

    /// Only `title` and `body` are required; see the type docs for every option.
    public init(
        id: String = UUID().uuidString,
        title: String,
        subtitle: String? = nil,
        body: String,
        trigger: Trigger = .now,
        sound: Sound = .default,
        badge: Int? = nil,
        group: String? = nil,
        categoryID: String? = nil,
        deepLink: String? = nil,
        attachmentURL: URL? = nil,
        priority: Priority = .active,
        relevance: Double = 0.5,
        userInfo: [String: String] = [:]
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.body = body
        self.trigger = trigger
        self.sound = sound
        self.badge = badge
        self.group = group
        self.categoryID = categoryID
        self.deepLink = deepLink
        self.attachmentURL = attachmentURL
        self.priority = priority
        self.relevance = relevance
        self.userInfo = userInfo
    }

    static let deepLinkKey = "deeplink"

    /// Builds the system request. Exposed for tests.
    func makeRequest() throws -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = title
        content.subtitle = subtitle ?? ""
        content.body = body
        content.badge = badge.map(NSNumber.init(value:))
        content.threadIdentifier = group ?? ""
        content.categoryIdentifier = categoryID ?? ""
        content.relevanceScore = min(max(relevance, 0), 1)
        content.interruptionLevel = switch priority {
        case .passive: .passive
        case .active: .active
        case .timeSensitive: .timeSensitive
        }
        content.sound = switch sound {
        case .none: nil
        case .default: .default
        case let .named(name): UNNotificationSound(named: UNNotificationSoundName(name))
        }
        var info: [String: String] = userInfo
        if let deepLink { info[Self.deepLinkKey] = deepLink }
        content.userInfo = info
        if let attachmentURL {
            content.attachments = [try UNNotificationAttachment(identifier: id, url: attachmentURL)]
        }
        return UNNotificationRequest(identifier: id, content: content, trigger: makeTrigger())
    }

    private func makeTrigger() -> UNNotificationTrigger {
        switch trigger {
        case .now:
            UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        case let .after(seconds, repeats):
            UNTimeIntervalNotificationTrigger(timeInterval: max(seconds, repeats ? 60 : 1), repeats: repeats)
        case let .at(components, repeats):
            UNCalendarNotificationTrigger(dateMatching: components, repeats: repeats)
        }
    }
}

/// Action buttons shown when the user long-presses a notification.
///
///     NotificationCategory(id: "event", actions: [
///         .init(id: "remind", title: "Remind me later"),
///         .init(id: "reply", title: "Reply", textInput: "Message"),
///         .init(id: "cancel", title: "Cancel booking", style: .destructive),
///     ])
public struct NotificationCategory: Sendable, Equatable {
    /// One button.
    public struct Action: Sendable, Equatable {
        /// Red (destructive) or normal.
        public enum Style: Sendable { case normal, destructive }

        public let id: String
        public let title: String
        public let style: Style
        /// Opens the app when tapped.
        public let opensApp: Bool
        /// Requires an unlocked device.
        public let requiresUnlock: Bool
        /// Shows a text field (reply-style). Value = placeholder.
        public let textInput: String?

        /// `.init(id: "reply", title: "Reply", textInput: "Message")`
        public init(
            id: String,
            title: String,
            style: Style = .normal,
            opensApp: Bool = false,
            requiresUnlock: Bool = false,
            textInput: String? = nil
        ) {
            self.id = id
            self.title = title
            self.style = style
            self.opensApp = opensApp
            self.requiresUnlock = requiresUnlock
            self.textInput = textInput
        }
    }

    public let id: String
    public let actions: [Action]
    /// Hidden preview placeholder (when previews are off), e.g. "%u new events".
    public let hiddenPreviewsBody: String?

    /// - Parameter hiddenPreviewsBody: text shown when previews are hidden.
    public init(id: String, actions: [Action], hiddenPreviewsBody: String? = nil) {
        self.id = id
        self.actions = actions
        self.hiddenPreviewsBody = hiddenPreviewsBody
    }

    func makeCategory() -> UNNotificationCategory {
        let actions: [UNNotificationAction] = actions.map { action in
            var options: UNNotificationActionOptions = []
            if action.style == .destructive { options.insert(.destructive) }
            if action.opensApp { options.insert(.foreground) }
            if action.requiresUnlock { options.insert(.authenticationRequired) }
            if let placeholder = action.textInput {
                return UNTextInputNotificationAction(
                    identifier: action.id, title: action.title, options: options,
                    textInputButtonTitle: action.title, textInputPlaceholder: placeholder
                )
            }
            return UNNotificationAction(identifier: action.id, title: action.title, options: options)
        }
        guard let hiddenPreviewsBody else {
            return UNNotificationCategory(identifier: id, actions: actions, intentIdentifiers: [], options: [.customDismissAction])
        }
        return UNNotificationCategory(
            identifier: id,
            actions: actions,
            intentIdentifiers: [],
            hiddenPreviewsBodyPlaceholder: hiddenPreviewsBody,
            options: [.customDismissAction]
        )
    }
}

/// What the user did with a notification.
public struct NotificationResponse: Sendable, Equatable {
    /// What the user did.
    public enum Action: Sendable, Equatable {
        case opened
        case dismissed
        case custom(id: String, text: String?)
    }

    public let notificationID: String
    public let action: Action
    public let deepLink: String?
    public let userInfo: [String: String]

    /// Built by `LocalNotificationCenter`; public for tests.
    public init(notificationID: String, action: Action, deepLink: String?, userInfo: [String: String]) {
        self.notificationID = notificationID
        self.action = action
        self.deepLink = deepLink
        self.userInfo = userInfo
    }
}
