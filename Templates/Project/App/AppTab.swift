//
//  AppTab.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import Features
import UIKit

/// Tabs of the main screen. `rawValue` is also the deep link prefix.
enum AppTab: String, CaseIterable, Sendable {
    case home

    @MainActor
    var title: String {
        switch self {
        case .home: L10n.Tab.home
        }
    }

    var systemImage: String {
        switch self {
        case .home: "house.fill"
        }
    }

    @MainActor
    var tabBarItem: UITabBarItem {
        UITabBarItem(title: title, image: UIImage(systemName: systemImage), tag: AppTab.allCases.firstIndex(of: self) ?? 0)
    }
}
