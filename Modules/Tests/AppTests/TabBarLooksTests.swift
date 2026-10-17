//
//  TabBarLooksTests.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 17/10/2569 BE.
//

@testable import App
import Core
import Features
import LiquidGlassKit
import Testing
import UIKit

@MainActor
struct TabBarLooksTests {
    @Test func lookIsSavedAndObserversHearIt() {
        let looks = TabBarLooks(store: InMemoryStore())
        #expect(looks.current == .glass)
        var changes = 0
        looks.observe { changes += 1 }
        looks.current = .minimal
        #expect(looks.current == .minimal)
        #expect(looks.minimizesOnScroll)
        looks.minimizesOnScroll = false
        #expect(!looks.minimizesOnScroll)
        #expect(changes == 2)

        let tabs = LiquidGlassTabBarController(style: .glass)
        looks.apply(to: tabs)
        #expect(tabs.appearance.selection.style == .dot)
        #expect(tabs.minimizeBehavior == .never)
    }

    @Test func everyLookMapsToItsPreset() {
        #expect(TabBarLooks.appearance(for: .glass).selection.style == .glass)
        #expect(TabBarLooks.appearance(for: .tinted).selection.style == .tint)
        #expect(TabBarLooks.appearance(for: .solid).selection.style == .solid)
        #expect(TabBarLooks.appearance(for: .minimal).selection.style == .dot)
        #expect(TabBarLooks.appearance(for: .underline).selection.style == .underline)
    }

    @Test func settingsChangeTheTabBarLive() throws {
        let app = AppCoordinator(window: UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844)), tabBarStyle: .glass)
        app.start()
        let tabs = try #require(app.tabBarController as? LiquidGlassTabBarController)
        let previous = (TabBarLooks.shared.current, TabBarLooks.shared.minimizesOnScroll)
        defer {
            TabBarLooks.shared.current = previous.0
            TabBarLooks.shared.minimizesOnScroll = previous.1
        }

        SettingsInteractor().setTabBarLook(.solid)
        #expect(tabs.appearance.selection.style == .solid)
        #expect(SettingsInteractor().tabBarLook == .solid)

        SettingsInteractor().setTabBarMinimizeEnabled(false)
        #expect(tabs.minimizeBehavior == .never)
        #expect(!SettingsInteractor().isTabBarMinimizeEnabled)
        SettingsInteractor().setTabBarMinimizeEnabled(true)
        #expect(tabs.minimizeBehavior == .onScrollDown)
    }
}
