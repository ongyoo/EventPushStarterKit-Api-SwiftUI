//
//  Permission.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import Foundation

/// Every runtime permission the kit can ask for.
public enum Permission: String, CaseIterable, Sendable, Identifiable {
    case notifications
    case camera
    case microphone
    case photoLibrary
    case photoLibraryAddOnly
    case locationWhenInUse
    case contacts
    case calendar
    case tracking

    public var id: String { rawValue }

    /// Info.plist key that MUST exist before asking (iOS kills the app otherwise).
    public var usageDescriptionKey: String? {
        switch self {
        case .notifications: nil
        case .camera: "NSCameraUsageDescription"
        case .microphone: "NSMicrophoneUsageDescription"
        case .photoLibrary: "NSPhotoLibraryUsageDescription"
        case .photoLibraryAddOnly: "NSPhotoLibraryAddUsageDescription"
        case .locationWhenInUse: "NSLocationWhenInUseUsageDescription"
        case .contacts: "NSContactsUsageDescription"
        case .calendar: "NSCalendarsFullAccessUsageDescription"
        case .tracking: "NSUserTrackingUsageDescription"
        }
    }

    /// SF Symbol for permission lists.
    public var systemImage: String {
        switch self {
        case .notifications: "bell.badge"
        case .camera: "camera"
        case .microphone: "mic"
        case .photoLibrary, .photoLibraryAddOnly: "photo.on.rectangle"
        case .locationWhenInUse: "location"
        case .contacts: "person.crop.circle"
        case .calendar: "calendar"
        case .tracking: "hand.raised"
        }
    }
}

/// Unified status across all permission APIs.
public enum PermissionStatus: Sendable, Equatable {
    /// Never asked: calling `request` shows the system prompt.
    case notDetermined
    case authorized
    /// Partial access (selected photos / contacts, write-only calendar).
    case limited
    /// Notifications delivered quietly until the user decides.
    case provisional
    /// User said no: only Settings can change it (`openSettings()`).
    case denied
    /// Blocked by parental controls / MDM. The user can't change it.
    case restricted
    /// Can't be used: missing Info.plist key, feature off, or unsupported device.
    case unavailable(String)

    /// Can use the feature (fully or partially).
    public var isGranted: Bool {
        switch self {
        case .authorized, .limited, .provisional: true
        default: false
        }
    }

    /// Asking again will show the system prompt.
    public var canRequest: Bool { self == .notDetermined }

    /// The only way forward is the Settings app.
    public var needsSettings: Bool { self == .denied }
}
