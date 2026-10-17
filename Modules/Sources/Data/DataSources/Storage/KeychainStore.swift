//
//  KeychainStore.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import Core
import Foundation
import LocalAuthentication
import Security

/// Keychain wrapper for secrets (tokens, passwords, PIN, encryption keys).
///
///     let store = KeychainStore(service: "com.app.auth")
///     store[.accessToken] = token
///
/// Biometric-protected item (Face ID / Touch ID required to read):
///
///     let vault = KeychainStore(service: "com.app.vault", protection: .biometry)
///
/// Reading a `.biometry` item shows the system prompt and blocks the thread:
/// call it from a background task, never from the main thread.
public struct KeychainStore: KeyValueStore {
    /// When the item can be read (see docs/DATA_STORAGE.md).
    public enum Protection: Sendable {
        /// Readable after the first unlock since boot, this device only.
        /// Good default: works for background refresh, never synced/backed up.
        case afterFirstUnlock
        /// Readable only while the device is unlocked, this device only.
        case whenUnlocked
        /// Requires Face ID / Touch ID on every read. Invalidated if
        /// biometrics change (a new face/finger is enrolled).
        case biometry
        /// Device must have a passcode; item deleted if passcode is removed.
        case passcodeSet
    }

    private let service: String
    private let protection: Protection
    private let accessGroup: String?

    /// - Parameter accessGroup: share items with app extensions / other apps
    ///   of the same team (needs the Keychain Sharing capability).
    public init(service: String, protection: Protection = .afterFirstUnlock, accessGroup: String? = nil) {
        self.service = service
        self.protection = protection
        self.accessGroup = accessGroup
    }

    public func data(for key: String) -> Data? {
        var query = baseQuery(for: key)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        if protection == .biometry {
            let context = LAContext()
            context.localizedReason = "Unlock your secure data"
            query[kSecUseAuthenticationContext as String] = context
        }

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        switch status {
        case errSecSuccess:
            return result as? Data
        case errSecItemNotFound, errSecUserCanceled, errSecAuthFailed:
            return nil
        default:
            Log.app.error("Keychain read failed (\(status))")
            return nil
        }
    }

    public func set(_ data: Data?, for key: String) {
        let query = baseQuery(for: key)
        SecItemDelete(query as CFDictionary)
        guard let data else { return }

        var attributes = query
        attributes[kSecValueData as String] = data
        switch protection {
        case .afterFirstUnlock:
            attributes[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        case .whenUnlocked:
            attributes[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        case .passcodeSet:
            attributes[kSecAttrAccessible as String] = kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly
        case .biometry:
            attributes[kSecAttrAccessControl as String] = SecAccessControlCreateWithFlags(
                nil,
                kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
                .biometryCurrentSet,
                nil
            )
        }

        let status = SecItemAdd(attributes as CFDictionary, nil)
        if status != errSecSuccess {
            Log.app.error("Keychain write failed (\(status))")
        }
    }

    /// Deletes every item of this service.
    public func removeAll() {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
        ]
        if let accessGroup { query[kSecAttrAccessGroup as String] = accessGroup }
        SecItemDelete(query as CFDictionary)
    }

    private func baseQuery(for key: String) -> [String: Any] {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecAttrSynchronizable as String: false,
        ]
        if let accessGroup { query[kSecAttrAccessGroup as String] = accessGroup }
        return query
    }
}
