//
//  L10n.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import Core
import Foundation

/// Every user-facing text of the Features module. Keys live in
/// Resources/Localizable.xcstrings (edit in Xcode or with scripts/strings.py).
///
/// Public only for the App layer (tab titles, notification texts).
@MainActor
public enum L10n {
    @MainActor
    public enum Tab {
        public static var home: String { tr("tab.home") }
    }

    public static func tr(_ key: String) -> String {
        LocalizationManager.shared.localized(key, bundle: .module)
    }

    public static func tr(_ key: String, _ arguments: any CVarArg...) -> String {
        String(format: tr(key), locale: AppLocale.current, arguments: arguments)
    }
}
