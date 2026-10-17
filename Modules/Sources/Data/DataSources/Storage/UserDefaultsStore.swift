//
//  UserDefaultsStore.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import Core
import Foundation

/// NON-sensitive preferences only: UserDefaults is a plain plist,
/// readable from backups and on jailbroken devices.
///
/// OK: theme, language, onboarding seen, last selected tab, feature flags.
/// NEVER: tokens, passwords, PII, anything you would not print on screen.
public struct UserDefaultsStore: KeyValueStore {
    private let suiteName: String?

    /// `nil` = standard defaults; a suite name shares data with app extensions (App Group).
    public init(suiteName: String? = nil) {
        self.suiteName = suiteName
    }

    private var defaults: UserDefaults {
        suiteName.flatMap(UserDefaults.init(suiteName:)) ?? .standard
    }

    public func data(for key: String) -> Data? {
        defaults.data(forKey: key)
    }

    public func set(_ data: Data?, for key: String) {
        defaults.set(data, forKey: key)
    }

    public func removeAll() {
        if let suiteName {
            defaults.removePersistentDomain(forName: suiteName)
        } else if let domain = Bundle.main.bundleIdentifier {
            defaults.removePersistentDomain(forName: domain)
        }
    }
}
