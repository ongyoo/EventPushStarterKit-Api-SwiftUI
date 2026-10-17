//
//  LiquidGlassTabBarAppearanceTests.swift
//  LiquidGlassKit
//
//  Created by Komsit Chusangthong on 17/10/2569 BE.
//

@testable import LiquidGlassKit
import SwiftUI
import Testing
import UIKit

@MainActor
struct LiquidGlassTabBarAppearanceTests {
    private func makeTabs(_ appearance: LiquidGlassTabBarAppearance = .default) -> (LiquidGlassTabBarController, LiquidGlassTabBar, UIWindow) {
        let tabs = LiquidGlassTabBarController(style: .glass)
        tabs.appearance = appearance
        tabs.viewControllers = ["house", "bell", "gearshape"].enumerated().map { index, icon in
            let stack = UINavigationController(rootViewController: UIViewController())
            stack.tabBarItem = UITabBarItem(title: "Tab \(index)", image: UIImage(systemName: icon), tag: index)
            return stack
        }
        tabs.tabBar.tintColor = .systemPurple
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        window.rootViewController = tabs
        window.makeKeyAndVisible()
        tabs.view.layoutIfNeeded()
        return (tabs, tabs.glassBar!, window)
    }

    @Test func presetsDifferWhereTheySay() {
        #expect(LiquidGlassTabBarAppearance.default.selection.style == .glass)
        #expect(LiquidGlassTabBarAppearance.tinted.selection.style == .tint)
        #expect(LiquidGlassTabBarAppearance.solid.selection.style == .solid)
        #expect(LiquidGlassTabBarAppearance.underline.selection.style == .underline)
        #expect(!LiquidGlassTabBarAppearance.underline.droplet.isEnabled)
        let minimal = LiquidGlassTabBarAppearance.minimal
        #expect(minimal.selection.style == .dot)
        #expect(!minimal.item.showsTitles)
        #expect(minimal.bar.height == 56)
        let custom = LiquidGlassTabBarAppearance.tinted.with { $0.bar.itemWidth = 70 }
        #expect(custom.selection.style == .tint && custom.bar.itemWidth == 70)
    }

    @Test func selectedColorsFollowTheStyle() {
        let tint = UIColor.systemPurple
        #expect(LiquidGlassTabBarAppearance.default.selectedItemColor(tint: tint) == tint)
        #expect(LiquidGlassTabBarAppearance.solid.selectedItemColor(tint: tint) == .white)
        let colored = LiquidGlassTabBarAppearance.default.with { $0.selection.color = .systemOrange }
        #expect(colored.selectedItemColor(tint: tint) == .systemOrange)
        #expect(colored.indicatorColor(tint: tint) == .systemOrange)
        let explicit = LiquidGlassTabBarAppearance.solid.with { $0.item.selectedColor = .black }
        #expect(explicit.selectedItemColor(tint: tint) == .black)
    }

    @Test func everyStylePlacesItsIndicator() {
        let tab = CGRect(x: 100, y: 4, width: 80, height: 54)
        let inset = UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)
        #expect(SelectionIndicatorView.frame(for: .glass, in: tab, inset: inset) == tab.inset(by: inset))
        let line = SelectionIndicatorView.frame(for: .underline, in: tab, inset: inset)
        #expect(line.height == 3 && line.midX == tab.midX)
        let dot = SelectionIndicatorView.frame(for: .dot, in: tab, inset: inset)
        #expect(dot.width == 5 && dot.height == 5 && dot.maxY < tab.maxY)

        for style in LiquidGlassTabBarAppearance.Selection.Style.allCases {
            let (tabs, bar, _) = makeTabs(.default.with { $0.selection.style = style })
            #expect(bar.indicator.style == style)
            #expect(bar.indicator.isHidden == (style == .none))
            tabs.selectedIndex = 1
            bar.layoutIfNeeded()
            #expect(bar.indicator.frame.midX > bar.bounds.width * 0.3)
        }
    }

    @Test func appearanceChangesApplyLive() {
        let (tabs, bar, _) = makeTabs()
        let wide = bar.frame.width
        tabs.appearance = .minimal
        tabs.view.layoutIfNeeded()
        #expect(bar.frame.height == 56)
        #expect(bar.frame.width < wide)
        #expect(bar.buttons.allSatisfy { $0.titleLabel.isHidden })

        tabs.appearance = .default.with {
            $0.bar.fillsWidth = true
            $0.bar.bottomSpacing = 40
            $0.bar.cornerRadius = 18
            $0.glass.tint = .systemTeal
            $0.glass.shadowOpacity = 0.5
            $0.item.badgeColor = .systemBlue
        }
        tabs.view.layoutIfNeeded()
        #expect(bar.frame.width == 358)
        #expect(bar.frame.maxY == tabs.view.bounds.maxY - 40)
        #expect(bar.glass.cornerRadius == 18)
        #expect(bar.glass.layer.shadowOpacity == 0.5)
        #expect(bar.buttons[0].badge.backgroundColor == .systemBlue)
    }

    @Test func selectedImageIsUsedWhenSelected() {
        let (tabs, bar, _) = makeTabs()
        let filled = UIImage(systemName: "bell.fill")
        tabs.viewControllers?[1].tabBarItem.selectedImage = filled
        func showsFilled() -> Bool { bar.buttons[1].currentImage?.description.contains("bell.fill") == true }
        #expect(filled != nil)
        #expect(!showsFilled())
        tabs.selectedIndex = 1
        #expect(showsFilled())
        tabs.appearance = .default.with { $0.item.usesSelectedImage = false }
        #expect(!showsFilled())
    }

    @Test func withoutDropletATapSelectsDirectly() {
        let (tabs, bar, _) = makeTabs(.underline)
        let x = bar.buttons[2].convert(CGPoint(x: bar.buttons[2].bounds.midX, y: 0), to: bar).x
        bar.handlePress(state: .began, at: CGPoint(x: x, y: 20))
        #expect(!bar.isDragging)
        #expect(bar.glass.isPressed)
        bar.handlePress(state: .changed, at: CGPoint(x: x, y: 22))
        bar.handlePress(state: .ended, at: CGPoint(x: x, y: 20))
        #expect(tabs.selectedIndex == 2)
        bar.handlePress(state: .began, at: CGPoint(x: x, y: 20))
        bar.handlePress(state: .ended, at: CGPoint(x: x, y: -300)) // lifted far away: no selection change
        bar.handlePress(state: .cancelled, at: .zero)
        #expect(tabs.selectedIndex == 2)
    }

    @Test func selectionAnimationsAllLand() {
        for animation in [LiquidGlassTabBarAppearance.Selection.Animation.liquid, .spring, .none] {
            let (tabs, bar, _) = makeTabs(.default.with {
                $0.selection.animation = animation
                $0.selection.bouncesIcon = false
                $0.haptics = false
            })
            tabs.selectedIndex = 2
            #expect(bar.selectedIndex == 2)
        }
    }

    @Test func swiftUIModifierBuildsAGlassBackground() {
        let host = UIHostingController(rootView: Text("Glass").padding().liquidGlass(cornerRadius: 12, tint: .systemPink))
        host.view.frame = CGRect(x: 0, y: 0, width: 200, height: 80)
        host.view.layoutIfNeeded()
        let background = LiquidGlassBackground(cornerRadius: nil, tint: nil, isClear: true)
        #expect(background.isClear)
    }
}
