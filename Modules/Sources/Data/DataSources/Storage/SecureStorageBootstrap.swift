//
//  SecureStorageBootstrap.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import Core
import Foundation

/// Keychain items SURVIVE app deletion. Without this, a user who deletes and
/// reinstalls the app (or a new owner of a resold device restored from backup)
/// could be logged in automatically with an old token.
///
/// Call once at launch, before reading any secret:
///
///     SecureStorageBootstrap.run()
public enum SecureStorageBootstrap {
    private static let installedKey = "app.hasLaunchedBefore"

    /// Wipes `storesToWipe` once, on the first launch after (re)install.
    /// Safe to call on every launch: `SecureStorageBootstrap.run()`.
    public static func run(
        preferences: UserDefaults = .standard,
        storesToWipe: [any KeyValueStore] = [Container.shared.secureStore(), Container.shared.encryptedStore()]
    ) {
        guard !preferences.bool(forKey: installedKey) else { return }
        storesToWipe.forEach { $0.removeAll() }
        preferences.set(true, forKey: installedKey)
        Log.app.info("Fresh install: secure storage wiped")
    }
}
