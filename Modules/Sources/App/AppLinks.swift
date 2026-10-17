//
//  AppLinks.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import Core
import Foundation
import Platform
import UIKit

/// Public entry points for the app target (AppDelegate, App Intents, widgets).
/// The app target only imports `Features`, never Core directly.
@MainActor
public enum AppLinks {
    /// Opens a path like "events/42" from anywhere (Siri, widget, extension).
    public static func open(path: String) {
        DeepLinkInbox.shared.post(DeepLink(path))
    }
}

/// Remote notification callbacks forwarded by `AppDelegate`
/// (compiled in the app only when FEATURE_SILENT_PUSH = YES).
@MainActor
public enum AppPush {
    /// `FEATURE_SILENT_PUSH` at runtime.
    public static var isEnabled: Bool { AppEnvironment.current.features.silentPush }

    /// Requests an APNs token (no-op when the feature is off).
    public static func register() {
        guard isEnabled else { return }
        PushService.shared.register()
    }

    /// Forward from `AppDelegate`.
    public static func didRegister(deviceToken: Data) {
        PushService.shared.didRegister(deviceToken: deviceToken)
    }

    /// Forward from `AppDelegate`.
    public static func didFailToRegister(_ error: any Error) {
        PushService.shared.didFailToRegister(error)
    }

    public static func didReceive(_ userInfo: [AnyHashable: Any]) async -> UIBackgroundFetchResult {
        guard isEnabled else { return .noData }
        return await PushService.shared.handle(userInfo)
    }
}
