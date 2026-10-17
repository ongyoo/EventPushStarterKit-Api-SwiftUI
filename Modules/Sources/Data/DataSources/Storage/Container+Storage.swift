//
//  Container+Storage.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import Core
import Foundation

/// Where each kind of data goes (see docs/DATA_STORAGE.md).
public extension Container {
    /// Secrets: tokens, passwords, PIN. Keychain, this device only.
    var secureStore: Dependency<any KeyValueStore> {
        Dependency(self) {
            KeychainStore(service: "\(AppEnvironment.current.bundleIdentifier).secure")
        }.singleton
    }

    /// Larger sensitive data: profile, PII, documents. AES-GCM encrypted files.
    var encryptedStore: Dependency<any KeyValueStore> {
        Dependency(self) {
            EncryptedFileStore(keyStore: KeychainStore(service: "\(AppEnvironment.current.bundleIdentifier).keys"))
        }.singleton
    }

    /// Non-sensitive preferences and flags. UserDefaults.
    var preferences: Dependency<any KeyValueStore> {
        Dependency(self) { UserDefaultsStore() }.singleton
    }
}
