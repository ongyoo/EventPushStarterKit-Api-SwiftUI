//
//  AppNotifications.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import Core
import Foundation
import Platform

/// App-specific notification setup: action categories and what each action does.
@MainActor
enum AppNotifications {
    /// Declare categories with action buttons here (re-registered on language change).
    static var categories: [NotificationCategory] { [] }

    /// Custom button taps. Taps with a deep link are routed automatically.
    static func handle(_ response: NotificationResponse, center: LocalNotificationCenter = .shared) {
        guard case let .custom(actionID, _) = response.action else { return }
        Log.app.info("Notification action \(actionID, privacy: .public)")
    }
}
