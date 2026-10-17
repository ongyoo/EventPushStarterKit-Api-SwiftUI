//
//  PushService.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import Core
import Foundation
import UIKit

/// Remote / silent push (`"content-available": 1`).
///
/// Payload convention: a `type` key selects the handler, optional `deeplink`
/// opens a screen when the user taps a visible push.
///
///     { "aps": { "content-available": 1 }, "type": "events.refresh" }
///
///     PushService.shared.on("events.refresh") { _ in
///         (try? await repository.events()) != nil   // true = new data
///     }
///
/// Enabled with `FEATURE_SILENT_PUSH = YES` (adds the entitlement and
/// `remote-notification` background mode at build time).
@MainActor
public final class PushService {
    public typealias Handler = @MainActor ([String: String]) async -> Bool

    /// Forwarded from `AppDelegate` through `AppPush` when `FEATURE_SILENT_PUSH = YES`.
    public static let shared = PushService()

    /// Hex APNs token. Send it to your backend in `onTokenChange`.
    public private(set) var deviceToken: String?
    /// Called with each new token: send it to your backend.
    public var onTokenChange: ((String) -> Void)?

    private var handlers: [String: Handler] = [:]

    /// Separate instance for tests.
    public init() {}

    /// Asks APNs for a token. Silent push does not need user permission;
    /// visible push also needs `PermissionCenter.request(.notifications)`.
    public func register() {
        UIApplication.shared.registerForRemoteNotifications()
    }

    /// Handles silent pushes whose payload `type` matches. Return `true` if new data was fetched.
    public func on(_ type: String, handler: @escaping Handler) {
        handlers[type] = handler
    }

    /// From `application(_:didRegisterForRemoteNotificationsWithDeviceToken:)`.
    public func didRegister(deviceToken data: Data) {
        let token = data.map { String(format: "%02x", $0) }.joined()
        deviceToken = token
        Log.app.info("APNs token received")
        onTokenChange?(token)
    }

    /// From `application(_:didFailToRegisterForRemoteNotificationsWithError:)`.
    public func didFailToRegister(_ error: any Error) {
        Log.app.error("APNs registration failed: \(error.localizedDescription, privacy: .public)")
    }

    /// Call from `application(_:didReceiveRemoteNotification:)`.
    /// iOS gives ~30 seconds; return quickly.
    public func handle(_ userInfo: [AnyHashable: Any]) async -> UIBackgroundFetchResult {
        let payload = userInfo.reduce(into: [String: String]()) { result, pair in
            if let key = pair.key as? String, let value = pair.value as? String { result[key] = value }
        }
        guard let type = payload["type"], let handler = handlers[type] else {
            Log.app.info("Silent push without handler: \(payload["type"] ?? "nil", privacy: .public)")
            return .noData
        }
        return await handler(payload) ? .newData : .noData
    }
}
