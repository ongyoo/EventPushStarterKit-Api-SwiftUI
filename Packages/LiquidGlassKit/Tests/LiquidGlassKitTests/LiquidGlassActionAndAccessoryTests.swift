//
//  LiquidGlassActionAndAccessoryTests.swift
//  LiquidGlassKit
//
//  Created by Komsit Chusangthong on 17/10/2569 BE.
//

@testable import LiquidGlassKit
import Testing
import UIKit

@MainActor
struct LiquidGlassActionAndAccessoryTests {
    private func makeTabs(_ style: LiquidGlassTabBarController.Style = .glass, tabs count: Int = 3) -> (LiquidGlassTabBarController, UIWindow) {
        let tabs = LiquidGlassTabBarController(style: style)
        tabs.viewControllers = (0..<count).map { index in
            let stack = UINavigationController(rootViewController: UIViewController())
            stack.tabBarItem = UITabBarItem(title: "Tab \(index)", image: UIImage(systemName: "star"), tag: index)
            return stack
        }
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        window.rootViewController = tabs
        window.makeKeyAndVisible()
        tabs.view.layoutIfNeeded()
        return (tabs, window)
    }

    private func camera(
        _ placement: LiquidGlassTabBarAction.Placement = .center,
        style: LiquidGlassTabBarAction.Style = .raised,
        onTap: @escaping @MainActor (LiquidGlassTabBarController) -> Void = { _ in }
    ) -> LiquidGlassTabBarAction {
        LiquidGlassTabBarAction(image: UIImage(systemName: "camera.fill"), title: "Camera", placement: placement, style: style, handler: onTap)
    }

    // MARK: - Action button

    @Test func centeredActionSitsInTheMiddleAndRaisesAboveTheBar() throws {
        let (tabs, _) = makeTabs()
        tabs.actionButton = camera()
        tabs.view.layoutIfNeeded()
        let bar = try #require(tabs.glassBar)
        bar.layoutIfNeeded()
        #expect(!bar.actionButton.isHidden)
        #expect(abs(bar.actionButton.center.x - bar.bounds.midX) < 1)
        #expect(bar.actionButton.frame.minY < 0) // sticks out
        #expect(bar.point(inside: CGPoint(x: bar.actionButton.center.x, y: bar.actionButton.frame.minY + 2), with: nil))
        #expect(bar.accessibilityElements?.count == 4)
    }

    @Test func tappingTheActionRunsTheHandlerNotATab() throws {
        var opened: LiquidGlassTabBarController?
        let (tabs, _) = makeTabs()
        tabs.actionButton = camera { opened = $0 }
        tabs.view.layoutIfNeeded()
        let bar = try #require(tabs.glassBar)
        bar.layoutIfNeeded()
        let center = bar.actionButton.center
        bar.handlePress(state: .began, at: center)
        bar.handlePress(state: .changed, at: center)
        bar.handlePress(state: .ended, at: center)
        #expect(opened === tabs)
        #expect(tabs.selectedIndex == 0)

        // Slide off before lifting: nothing runs.
        opened = nil
        bar.handlePress(state: .began, at: center)
        bar.handlePress(state: .changed, at: CGPoint(x: center.x + 200, y: center.y))
        bar.handlePress(state: .ended, at: CGPoint(x: center.x + 200, y: center.y))
        #expect(opened == nil)
        bar.handlePress(state: .began, at: center)
        bar.handlePress(state: .cancelled, at: center)
        #expect(opened == nil)

        #expect(bar.actionButton.accessibilityActivate())
        #expect(opened === tabs)
    }

    @Test func tabsAroundTheSlotStillSelect() throws {
        let (tabs, _) = makeTabs()
        tabs.actionButton = camera()
        tabs.view.layoutIfNeeded()
        let bar = try #require(tabs.glassBar)
        bar.layoutIfNeeded()
        // Just left/right of the camera slot: the neighbor tabs, never the slot.
        let slot = bar.actionButton.center.x
        #expect(bar.index(atX: slot - 5) == 0)
        #expect(bar.index(atX: slot + 5) == 1)
        #expect(bar.index(atX: bar.bounds.maxX - 10) == 2)
        bar.buttons[2].sendActions(for: .touchUpInside)
        #expect(tabs.selectedIndex == 2)
    }

    @Test func placementsAndInlineStyle() throws {
        for placement in [LiquidGlassTabBarAction.Placement.leading, .trailing, .index(1), .index(99)] {
            let (tabs, _) = makeTabs()
            tabs.actionButton = camera(placement, style: .inline)
            tabs.view.layoutIfNeeded()
            let bar = try #require(tabs.glassBar)
            bar.layoutIfNeeded()
            #expect(bar.actionButton.frame.minY >= 0) // inline: inside the bar
            #expect(bar.preferredWidth(maxWidth: 1000) == 360)
        }
        #expect(camera(.leading).slotIndex(tabCount: 4) == 0)
        #expect(camera(.trailing).slotIndex(tabCount: 4) == 4)
        #expect(camera(.center).slotIndex(tabCount: 4) == 2)
        #expect(camera(.index(-3)).slotIndex(tabCount: 4) == 0)
    }

    @Test func actionHidesWhenMinimizedAndCanBeRemoved() throws {
        let (tabs, _) = makeTabs()
        var action = camera()
        let custom = UIView()
        action.customView = custom
        action.tint = .systemOrange
        tabs.actionButton = action
        let bar = try #require(tabs.glassBar)
        #expect(custom.superview != nil)
        tabs.setMinimized(true, animated: false)
        #expect(bar.actionButton.alpha == 0)
        #expect(!bar.point(inside: CGPoint(x: 10, y: -30), with: nil))
        tabs.setMinimized(false, animated: false)
        tabs.actionButton = nil
        #expect(bar.actionButton.isHidden)
        #expect(bar.accessibilityElements == nil)
    }

    @Test func haloWrapsTheButtonAndReactsToPress() throws {
        let (tabs, _) = makeTabs()
        tabs.actionButton = camera()
        tabs.view.layoutIfNeeded()
        let bar = try #require(tabs.glassBar)
        bar.layoutIfNeeded()
        let button = bar.actionButton
        // Default: frosted halo 6 pt around the 60 pt circle; tilt effects on.
        #expect(!button.halo.isHidden)
        #expect(button.bounds.width == 72)
        #expect(button.glass.bounds.width == 60)
        #expect(button.followsMotion)
        #expect(button.glass.effects.contains(.motion))

        bar.handlePress(state: .began, at: button.center)
        #expect(button.isPressed && button.halo.isPressed)
        bar.handlePress(state: .changed, at: CGPoint(x: button.center.x + 200, y: button.center.y))
        #expect(!button.isPressed) // slid off
        bar.handlePress(state: .ended, at: CGPoint(x: button.center.x + 200, y: button.center.y))
        #expect(!button.halo.isPressed)

        // Easy to change: no halo, no tilt.
        var plain = camera()
        plain.halo = nil
        plain.followsMotion = false
        tabs.actionButton = plain
        bar.layoutIfNeeded()
        #expect(button.halo.isHidden)
        #expect(button.bounds.width == 60)
        #expect(!button.followsMotion)
        #expect(!button.glass.effects.contains(.motion))
        bar.handlePress(state: .began, at: button.center)
        #expect(button.glass.isPressed) // the circle itself swells
        bar.handlePress(state: .cancelled, at: button.center)
        #expect(!button.isPressed)

        var thick = camera()
        thick.halo = .clear.padding(10).tint(.systemPurple)
        tabs.actionButton = thick
        bar.layoutIfNeeded()
        #expect(button.halo.isClear && button.halo.glassTint == .systemPurple)
        #expect(button.bounds.width == 80)
    }

    @Test func inlineHaloStaysInsideTheBar() throws {
        let (tabs, _) = makeTabs()
        tabs.actionButton = camera(style: .inline)
        tabs.view.layoutIfNeeded()
        let bar = try #require(tabs.glassBar)
        bar.layoutIfNeeded()
        let button = bar.actionButton
        #expect(button.frame.minY >= 0 && button.frame.maxY <= bar.bounds.maxY)
        #expect(button.glass.bounds.width > button.bounds.width * 0.65)
    }

    @Test func systemStyleFloatsTheActionAboveUIKitsBar() throws {
        var runs = 0
        let (tabs, _) = makeTabs(.system)
        tabs.tabBar.tintColor = .systemPink
        tabs.actionButton = camera(.trailing) { _ in runs += 1 }
        tabs.view.layoutIfNeeded()
        let floating = try #require(tabs.floatingActionButton)
        #expect(floating.frame.maxY <= tabs.tabBar.frame.minY)
        tabs.runAction()
        #expect(runs == 1)
        tabs.actionButton = nil
        #expect(tabs.floatingActionButton == nil)
    }

    // MARK: - Accessory

    @Test func accessorySitsAboveTheBarAndMovesNextToTheMinimizedOne() throws {
        let (tabs, _) = makeTabs()
        let player = UILabel()
        tabs.accessoryView = player
        tabs.view.layoutIfNeeded()
        let host = try #require(tabs.accessoryHost)
        let bar = try #require(tabs.glassBar)
        #expect(player.superview === host.contentView)
        #expect(host.frame.maxY <= bar.frame.minY)
        #expect(tabs.viewControllers?.first?.additionalSafeAreaInsets.bottom ?? 0 > 60)

        tabs.setMinimized(true, animated: false)
        #expect(host.frame.minX >= bar.frame.maxX)
        #expect(abs(host.frame.midY - bar.frame.midY) < 1)

        tabs.accessoryHeight = 56
        tabs.accessoryView = nil
        #expect(tabs.accessoryHost == nil)
        #expect(player.superview == nil)
    }

    @Test func accessoryWithUIKitsBar() throws {
        let (tabs, _) = makeTabs(.system)
        tabs.accessoryView = UIView()
        tabs.view.layoutIfNeeded()
        if LiquidGlass.isSystemDesign {
            #expect(tabs.accessoryHost == nil) // iOS 26: UITabAccessory
        } else {
            let host = try #require(tabs.accessoryHost)
            #expect(host.frame.maxY <= tabs.tabBar.frame.minY)
        }
    }

    // MARK: - Native glass

    @Test func iOS26UsesTheSystemGlassAndOlderSystemsTheKit() {
        let glass = LiquidGlassView(frame: CGRect(x: 0, y: 0, width: 200, height: 60))
        #expect(glass.usesSystemGlass == LiquidGlass.isSystemDesign)
        #expect(glass.isSystemGlass == LiquidGlass.isSystemDesign)
        glass.tintOpacity = 0.9
        glass.glassTint = .systemPurple
        glass.usesSystemGlass = false
        #expect(!glass.isSystemGlass)
        glass.usesSystemGlass = true
        glass.isClear = true
        glass.layoutIfNeeded()
    }
}
