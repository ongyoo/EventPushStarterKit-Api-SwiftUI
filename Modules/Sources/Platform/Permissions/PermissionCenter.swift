//
//  PermissionCenter.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import AppTrackingTransparency
import AVFoundation
import Contacts
import Core
import CoreLocation
import EventKit
import Foundation
import Photos
import UIKit
import UserNotifications

/// One API for every permission:
///
///     let status = await PermissionCenter.shared.request(.camera)
///     switch status {
///     case .authorized, .limited: openCamera()
///     case .denied: showGoToSettings()          // PermissionCenter.shared.openSettings()
///     case .restricted, .unavailable: hideCameraFeature()
///     default: break
///     }
///
/// Best practices built in:
/// - never crashes: a missing Info.plist purpose string returns `.unavailable`
///   instead of letting iOS terminate the app;
/// - only asks when the status is `.notDetermined` (iOS shows the prompt once);
/// - ask in context (when the user taps the feature), not at launch.
///
/// Remove the permissions you don't use (and their Info.plist keys):
/// App Store Connect warns about APIs referenced without a purpose string.
@MainActor
public final class PermissionCenter {
    /// Reads purpose strings from the main bundle Info.plist.
    public static let shared = PermissionCenter()

    private let infoDictionary: [String: Any]
    private var locationRequester: LocationRequester?

    /// Tests pass a custom Info.plist dictionary.
    public init(infoDictionary: [String: Any] = Bundle.main.infoDictionary ?? [:]) {
        self.infoDictionary = infoDictionary
    }

    // MARK: - Status

    /// Current status, never shows a prompt.
    public func status(_ permission: Permission) async -> PermissionStatus {
        if let missing = missingUsageDescription(permission) { return .unavailable(missing) }
        switch permission {
        case .notifications:
            guard LocalNotificationCenter.isAvailable else { return .unavailable("Not running in an app") }
            return Self.map(await UNUserNotificationCenter.current().notificationSettings().authorizationStatus)
        case .camera:
            return Self.map(AVCaptureDevice.authorizationStatus(for: .video))
        case .microphone:
            return Self.map(AVCaptureDevice.authorizationStatus(for: .audio))
        case .photoLibrary:
            return Self.map(PHPhotoLibrary.authorizationStatus(for: .readWrite))
        case .photoLibraryAddOnly:
            return Self.map(PHPhotoLibrary.authorizationStatus(for: .addOnly))
        case .locationWhenInUse:
            return Self.map(CLLocationManager().authorizationStatus)
        case .contacts:
            return Self.map(CNContactStore.authorizationStatus(for: .contacts))
        case .calendar:
            return Self.map(EKEventStore.authorizationStatus(for: .event))
        case .tracking:
            return Self.map(ATTrackingManager.trackingAuthorizationStatus)
        }
    }

    /// Status of several permissions (Settings screens).
    public func statuses(_ permissions: [Permission] = Permission.allCases) async -> [Permission: PermissionStatus] {
        var result: [Permission: PermissionStatus] = [:]
        for permission in permissions {
            result[permission] = await status(permission)
        }
        return result
    }

    // MARK: - Request

    /// Shows the system prompt if possible and returns the new status.
    /// - Parameter provisional: notifications only – deliver quietly without a prompt.
    @discardableResult
    public func request(_ permission: Permission, provisional: Bool = false) async -> PermissionStatus {
        let current = await status(permission)
        guard current.canRequest else { return current }

        switch permission {
        case .notifications:
            var options: UNAuthorizationOptions = [.alert, .badge, .sound]
            if provisional { options.insert(.provisional) }
            _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: options)
        case .camera:
            _ = await AVCaptureDevice.requestAccess(for: .video)
        case .microphone:
            _ = await AVCaptureDevice.requestAccess(for: .audio)
        case .photoLibrary:
            _ = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        case .photoLibraryAddOnly:
            _ = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        case .locationWhenInUse:
            let requester = LocationRequester()
            locationRequester = requester
            await requester.requestWhenInUse()
            locationRequester = nil
        case .contacts:
            _ = try? await CNContactStore().requestAccess(for: .contacts)
        case .calendar:
            _ = try? await EKEventStore().requestFullAccessToEvents()
        case .tracking:
            // Only works while the app is active (not at launch before the UI shows).
            _ = await ATTrackingManager.requestTrackingAuthorization()
        }
        return await status(permission)
    }

    // MARK: - Settings

    /// Opens Settings > <App>. The only way to recover from `.denied`.
    public func openSettings() {
        open(UIApplication.openSettingsURLString)
    }

    /// Opens Settings > <App> > Notifications.
    public func openNotificationSettings() {
        open(UIApplication.openNotificationSettingsURLString)
    }

    // MARK: - Private

    func missingUsageDescription(_ permission: Permission) -> String? {
        guard let key = permission.usageDescriptionKey else { return nil }
        let value = infoDictionary[key] as? String
        guard value?.isEmpty == false else {
            Log.app.fault("Missing \(key, privacy: .public) in Info.plist: \(permission.rawValue, privacy: .public) not requested")
            return "Missing \(key) in Info.plist"
        }
        return nil
    }

    private func open(_ string: String) {
        guard let url = URL(string: string) else { return }
        UIApplication.shared.open(url)
    }

    // MARK: - Mapping

    static func map(_ status: UNAuthorizationStatus) -> PermissionStatus {
        switch status {
        case .notDetermined: .notDetermined
        case .authorized: .authorized
        case .provisional: .provisional
        case .ephemeral: .limited
        case .denied: .denied
        @unknown default: .denied
        }
    }

    static func map(_ status: AVAuthorizationStatus) -> PermissionStatus {
        switch status {
        case .notDetermined: .notDetermined
        case .authorized: .authorized
        case .restricted: .restricted
        case .denied: .denied
        @unknown default: .denied
        }
    }

    static func map(_ status: PHAuthorizationStatus) -> PermissionStatus {
        switch status {
        case .notDetermined: .notDetermined
        case .authorized: .authorized
        case .limited: .limited
        case .restricted: .restricted
        case .denied: .denied
        @unknown default: .denied
        }
    }

    static func map(_ status: CLAuthorizationStatus) -> PermissionStatus {
        switch status {
        case .notDetermined: .notDetermined
        case .authorizedWhenInUse, .authorizedAlways: .authorized
        case .restricted: .restricted
        case .denied: .denied
        @unknown default: .denied
        }
    }

    static func map(_ status: CNAuthorizationStatus) -> PermissionStatus {
        switch status {
        case .notDetermined: .notDetermined
        case .authorized: .authorized
        case .limited: .limited
        case .restricted: .restricted
        case .denied: .denied
        @unknown default: .denied
        }
    }

    static func map(_ status: EKAuthorizationStatus) -> PermissionStatus {
        switch status {
        case .notDetermined: .notDetermined
        case .fullAccess: .authorized
        case .writeOnly: .limited
        case .restricted: .restricted
        case .denied: .denied
        @unknown default: .denied
        }
    }

    static func map(_ status: ATTrackingManager.AuthorizationStatus) -> PermissionStatus {
        switch status {
        case .notDetermined: .notDetermined
        case .authorized: .authorized
        case .restricted: .restricted
        case .denied: .denied
        @unknown default: .denied
        }
    }
}

/// CLLocationManager reports the answer through its delegate; this turns it into `await`.
@MainActor
private final class LocationRequester: NSObject, @preconcurrency CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private var continuation: CheckedContinuation<Void, Never>?

    func requestWhenInUse() async {
        await withCheckedContinuation { continuation in
            self.continuation = continuation
            manager.delegate = self
            manager.requestWhenInUseAuthorization()
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        guard manager.authorizationStatus != .notDetermined else { return }
        continuation?.resume()
        continuation = nil
    }
}
