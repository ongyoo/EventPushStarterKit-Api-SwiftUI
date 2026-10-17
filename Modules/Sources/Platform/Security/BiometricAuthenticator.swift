//
//  BiometricAuthenticator.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import Foundation
import LocalAuthentication

/// Face ID / Touch ID check for sensitive actions (show card number, confirm payment).
///
///     if await BiometricAuthenticator().authenticate(reason: "Confirm payment") { ... }
///
/// Needs `NSFaceIDUsageDescription` in Info.plist.
/// For protecting stored secrets prefer `KeychainStore(protection: .biometry)`:
/// a bool result can be bypassed on a compromised device, a Keychain ACL cannot.
public struct BiometricAuthenticator: Sendable {
    /// Biometry available on this device.
    public enum Kind: Sendable { case none, touchID, faceID, opticID }

    /// Stateless; create where needed: `BiometricAuthenticator().authenticate(reason:)`.
    public init() {}

    /// `.faceID`, `.touchID`, `.opticID` or `.none` (not enrolled / unsupported).
    public var availableKind: Kind {
        let context = LAContext()
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil) else { return .none }
        switch context.biometryType {
        case .faceID: return .faceID
        case .touchID: return .touchID
        case .opticID: return .opticID
        default: return .none
        }
    }

    /// - Parameter allowPasscodeFallback: allow the device passcode if biometrics fail.
    public func authenticate(reason: String, allowPasscodeFallback: Bool = true) async -> Bool {
        let context = LAContext()
        let policy: LAPolicy = allowPasscodeFallback
            ? .deviceOwnerAuthentication
            : .deviceOwnerAuthenticationWithBiometrics
        guard context.canEvaluatePolicy(policy, error: nil) else { return false }
        return (try? await context.evaluatePolicy(policy, localizedReason: reason)) ?? false
    }
}
