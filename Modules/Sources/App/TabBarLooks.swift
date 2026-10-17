//
//  TabBarLooks.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 17/10/2569 BE.
//

import Core
import Features
import LiquidGlassKit
import UIKit

/// The tab bar look and the shrink-on-scroll choice from Settings: saved in
/// preferences and pushed to the tab bar controller at once. Features only know `TabBarLook`; this file maps
/// it to LiquidGlassKit (the only place, besides `AppCoordinator`, that does).
@MainActor
final class TabBarLooks {
    static let shared = TabBarLooks()

    private static let key = StorageKey<TabBarLook>("ui.tabBarLook")
    private static let minimizeKey = StorageKey<Bool>("ui.tabBarMinimizes")
    private let store: any KeyValueStore
    private var observers: [() -> Void] = []

    init(store: any KeyValueStore = Container.shared.preferences()) {
        self.store = store
    }

    var current: TabBarLook {
        get { store[Self.key] ?? .glass }
        set {
            store[Self.key] = newValue
            observers.forEach { $0() }
        }
    }

    /// Shrink while scrolling down. On by default, like iOS 26 apps.
    var minimizesOnScroll: Bool {
        get { store[Self.minimizeKey] ?? true }
        set {
            store[Self.minimizeKey] = newValue
            observers.forEach { $0() }
        }
    }

    /// `handler` runs on every change.
    func observe(_ handler: @escaping () -> Void) {
        observers.append(handler)
    }

    /// Pushes both choices to `tabs`.
    func apply(to tabs: LiquidGlassTabBarController) {
        tabs.appearance = Self.appearance(for: current)
        tabs.minimizeBehavior = minimizesOnScroll ? .onScrollDown : .never
    }

    /// The kit appearance for a look. Brand tweaks go here.
    static func appearance(for look: TabBarLook) -> LiquidGlassTabBarAppearance {
        switch look {
        case .glass: .default
        case .tinted: .tinted
        case .solid: .solid
        case .minimal: .minimal
        case .underline: .underline
        }
    }
}
