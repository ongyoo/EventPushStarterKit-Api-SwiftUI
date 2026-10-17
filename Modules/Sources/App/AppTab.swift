//
//  AppTab.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import Features
import UIKit

/// Tabs of the main screen. `rawValue` is also the deep link prefix:
/// `eventpush://inbox/...` opens the Inbox tab.
enum AppTab: String, CaseIterable, Sendable {
    case home
    case inbox
    case settings

    @MainActor
    var title: String {
        switch self {
        case .home: L10n.Tab.home
        case .inbox: L10n.Tab.inbox
        case .settings: L10n.Tab.settings
        }
    }

    var systemImage: String {
        switch self {
        case .home: "house.fill"
        case .inbox: "bell.fill"
        case .settings: "gearshape.fill"
        }
    }

    @MainActor
    var tabBarItem: UITabBarItem {
        UITabBarItem(title: title, image: UIImage(systemName: systemImage), tag: AppTab.allCases.firstIndex(of: self) ?? 0)
    }
}
