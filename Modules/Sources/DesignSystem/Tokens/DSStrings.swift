//
//  DSStrings.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import Core
import Foundation

/// Texts owned by the design system (shared states, accessibility labels).
@MainActor
enum DSStrings {
    static var errorTitle: String { tr("state.error.title") }
    static var retry: String { tr("state.error.retry") }
    static var emptyTitle: String { tr("state.empty.title") }
    static var loading: String { tr("state.loading") }

    private static func tr(_ key: String) -> String {
        LocalizationManager.shared.localized(key, bundle: .module)
    }
}
