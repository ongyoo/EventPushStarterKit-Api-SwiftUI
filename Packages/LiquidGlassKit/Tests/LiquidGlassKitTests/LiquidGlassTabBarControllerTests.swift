//
//  LiquidGlassTabBarControllerTests.swift
//  LiquidGlassKit
//
//  Created by Komsit Chusangthong on 17/10/2569 BE.
//

@testable import LiquidGlassKit
import Testing
import UIKit

@MainActor
struct LiquidGlassTabBarControllerTests {
    private final class Delegate: NSObject, UITabBarControllerDelegate {
        var allow = true
        var selected: [UIViewController] = []

        func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
            allow
        }

        func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
            selected.append(viewController)
        }
    }

    private func makeTabs(_ style: LiquidGlassTabBarController.Style, count: Int = 3) -> (LiquidGlassTabBarController, [UINavigationController], UIWindow) {
        let tabs = LiquidGlassTabBarController(style: style)
        let stacks = (0..<count).map { index in
            let stack = UINavigationController(rootViewController: UIViewController())
            stack.tabBarItem = UITabBarItem(title: "Tab \(index)", image: UIImage(systemName: "star"), tag: index)
            return stack
        }
        tabs.viewControllers = stacks
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        window.rootViewController = tabs
        window.makeKeyAndVisible()
        tabs.view.layoutIfNeeded()
        return (tabs, stacks, window)
    }

    @Test func belowIOS26KeepsTheSystemBarWhereItIsGlass() {
        #expect(LiquidGlassTabBarController.Style.select(.glass, systemIsGlass: true) == .system)
        #expect(LiquidGlassTabBarController.Style.select(.glass, systemIsGlass: false) == .glass)
        #expect(LiquidGlassTabBarController.Style.belowIOS26(.glass) == (LiquidGlass.isSystemDesign ? .system : .glass))
    }

    @Test func systemStyleIsAPlainTabBarController() {
        let (tabs, _, _) = makeTabs(.system)
        #expect(tabs.glassBar == nil)
        #expect(!tabs.tabBar.isHidden)
    }

    @Test func glassStyleReplacesTheBarAndShowsEveryItem() throws {
        let (tabs, stacks, _) = makeTabs(.glass)
        let bar = try #require(tabs.glassBar)
        #expect(tabs.tabBar.isHidden)
        #expect(bar.buttons.count == 3)
        #expect(bar.buttons[0].accessibilityLabel == "Tab 0")
        #expect(bar.buttons[0].isSelected)
        #expect(bar.frame.maxY < tabs.view.bounds.maxY)
        #expect(bar.frame.width <= tabs.view.bounds.width - 32)
        // Screens keep their last row above the floating bar.
        #expect(stacks.allSatisfy { $0.additionalSafeAreaInsets.bottom > 0 })
    }

    @Test func tapSelectsAndInformsTheDelegate() throws {
        let (tabs, stacks, _) = makeTabs(.glass)
        let delegate = Delegate()
        tabs.delegate = delegate
        let bar = try #require(tabs.glassBar)

        bar.buttons[1].sendActions(for: .touchUpInside)
        #expect(tabs.selectedIndex == 1)
        #expect(delegate.selected == [stacks[1]])
        #expect(bar.selectedIndex == 1)
        #expect(bar.buttons[1].isSelected && !bar.buttons[0].isSelected)
        #expect(bar.buttons[1].accessibilityTraits.contains(.selected))

        delegate.allow = false
        bar.buttons[2].sendActions(for: .touchUpInside)
        #expect(tabs.selectedIndex == 1)
    }

    private final class SpyStack: UINavigationController {
        var poppedToRoot = 0
        override func popToRootViewController(animated: Bool) -> [UIViewController]? {
            poppedToRoot += 1
            return super.popToRootViewController(animated: animated)
        }
    }

    @Test func secondTapOnCurrentTabPopsToRoot() throws {
        let (tabs, stacks, _) = makeTabs(.glass)
        let spy = SpyStack(rootViewController: UIViewController())
        tabs.viewControllers = [spy] + stacks.dropFirst()
        tabs.selectedIndex = 0
        tabs.userSelected(0)
        #expect(spy.poppedToRoot == 1)
        tabs.userSelected(1) // another tab: selects, no pop
        #expect(spy.poppedToRoot == 1)
        #expect(tabs.selectedIndex == 1)
    }

    @Test func programmaticSelectionMovesThePill() throws {
        let (tabs, stacks, _) = makeTabs(.glass)
        let bar = try #require(tabs.glassBar)
        tabs.selectedIndex = 2
        #expect(bar.selectedIndex == 2)
        tabs.selectedViewController = stacks[1]
        #expect(bar.selectedIndex == 1)
        tabs.userSelected(9) // out of range: ignored
        #expect(tabs.selectedIndex == 1)
    }

    @Test func itemChangesShowUpLive() async throws {
        let (tabs, stacks, _) = makeTabs(.glass)
        let button = try #require(tabs.glassBar?.buttons[1])
        stacks[1].tabBarItem.badgeValue = "3"
        await settle()
        #expect(button.accessibilityValue == "3")
        stacks[1].tabBarItem.badgeValue = nil
        await settle()
        #expect(button.accessibilityValue == nil)
        stacks[1].tabBarItem.title = "Inbox"
        await settle()
        #expect(button.accessibilityLabel == "Inbox")
    }

    /// Lets the main-actor updates queued by KVO run.
    private func settle() async {
        for _ in 0..<5 { await Task.yield() }
    }

    @Test func replacingViewControllersRebuildsTheBar() throws {
        let (tabs, stacks, _) = makeTabs(.glass)
        tabs.setViewControllers(Array(stacks.prefix(2)), animated: false)
        #expect(tabs.glassBar?.buttons.count == 2)
        tabs.viewControllers = stacks
        #expect(tabs.glassBar?.buttons.count == 3)
    }

    @Test func hidingTheBarGivesTheSpaceBack() throws {
        let (tabs, stacks, _) = makeTabs(.glass)
        let bar = try #require(tabs.glassBar)
        tabs.setGlassBarHidden(true, animated: false)
        tabs.view.layoutIfNeeded()
        #expect(bar.alpha == 0)
        #expect(stacks[0].additionalSafeAreaInsets.bottom == 0)
        tabs.setGlassBarHidden(false, animated: true)
        tabs.view.layoutIfNeeded()
        #expect(stacks[0].additionalSafeAreaInsets.bottom > 0)

        let (system, _, _) = makeTabs(.system)
        system.setGlassBarHidden(true, animated: false) // no-op
        #expect(system.glassBar == nil)
    }

    @Test func barFitsItsItemsAndRendersBothAppearances() throws {
        let (tabs, _, window) = makeTabs(.glass, count: 2)
        let bar = try #require(tabs.glassBar)
        #expect(bar.preferredWidth(maxWidth: 1000) == 184)
        #expect(bar.preferredWidth(maxWidth: 100) == 100)
        window.overrideUserInterfaceStyle = .dark
        bar.updateTraitsIfNeeded()
        bar.layoutIfNeeded()
        bar.buttons[1].isHighlighted = true
        bar.buttons[1].isHighlighted = false
        bar.buttons[1].bounce()
        bar.select(1, animated: true)
        #expect(bar.selectedIndex == 1)
    }
}

// MARK: - Liquid Glass interaction

@MainActor
struct LiquidGlassTabBarInteractionTests {
    private func makeTabs() -> (LiquidGlassTabBarController, LiquidGlassTabBar, UIWindow) {
        let tabs = LiquidGlassTabBarController(style: .glass)
        tabs.viewControllers = ["house", "bell", "gearshape"].enumerated().map { index, icon in
            let stack = UINavigationController(rootViewController: UIViewController())
            stack.tabBarItem = UITabBarItem(title: "Tab \(index)", image: UIImage(systemName: icon), tag: index)
            return stack
        }
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        window.rootViewController = tabs
        window.makeKeyAndVisible()
        tabs.view.layoutIfNeeded()
        return (tabs, tabs.glassBar!, window)
    }

    private func x(of index: Int, in bar: LiquidGlassTabBar) -> CGFloat {
        bar.buttons[index].convert(CGPoint(x: bar.buttons[index].bounds.midX, y: 0), to: bar).x
    }

    @Test func pressAndSlideSelectsTheTabUnderTheDroplet() {
        let (tabs, bar, _) = makeTabs()
        let y = bar.bounds.midY
        bar.handlePress(state: .began, at: CGPoint(x: x(of: 0, in: bar), y: y))
        #expect(bar.isDragging)
        #expect(bar.droplet.alpha == 1)
        #expect(bar.glass.isPressed)
        bar.handlePress(state: .changed, at: CGPoint(x: x(of: 1, in: bar), y: y))
        bar.handlePress(state: .changed, at: CGPoint(x: x(of: 2, in: bar) + 300, y: y)) // rubber band
        bar.handlePress(state: .ended, at: CGPoint(x: x(of: 2, in: bar), y: y))
        #expect(tabs.selectedIndex == 2)
        #expect(!bar.isDragging)
        #expect(!bar.glass.isPressed)
    }

    @Test func slidingAwayOrCancellingKeepsTheSelection() {
        let (tabs, bar, _) = makeTabs()
        let y = bar.bounds.midY
        bar.handlePress(state: .began, at: CGPoint(x: x(of: 1, in: bar), y: y))
        bar.handlePress(state: .ended, at: CGPoint(x: x(of: 1, in: bar), y: -100))
        #expect(tabs.selectedIndex == 0)

        bar.handlePress(state: .began, at: CGPoint(x: x(of: 2, in: bar), y: y))
        bar.handlePress(state: .cancelled, at: .zero)
        #expect(tabs.selectedIndex == 0)
        #expect(!bar.isDragging)
    }

    @Test func dropletMagnifiesTheItemsUnderIt() {
        let (_, bar, _) = makeTabs()
        bar.handlePress(state: .began, at: CGPoint(x: x(of: 1, in: bar), y: bar.bounds.midY))
        let items = bar.droplet.items
        #expect(items.image != nil)
        // Magnified: the copy is larger than the bar's item row.
        #expect(items.frame.height > bar.bounds.height - 8)
        bar.handlePress(state: .ended, at: CGPoint(x: x(of: 1, in: bar), y: bar.bounds.midY))
    }

    @Test func minimizesOnScrollDownAndComesBack() {
        let (tabs, bar, _) = makeTabs()
        tabs.minimizeBehavior = .onScrollDown
        tabs.handleScroll(offset: 0, isScrollable: true, isUserScrolling: true)
        tabs.handleScroll(offset: 20, isScrollable: true, isUserScrolling: true)
        #expect(!bar.isMinimized)
        tabs.handleScroll(offset: 60, isScrollable: true, isUserScrolling: true)
        #expect(bar.isMinimized)
        tabs.view.layoutIfNeeded()
        #expect(bar.frame.width == 54)

        tabs.handleScroll(offset: 50, isScrollable: true, isUserScrolling: true)
        #expect(bar.isMinimized) // small move up: stays
        tabs.handleScroll(offset: 30, isScrollable: true, isUserScrolling: true)
        #expect(!bar.isMinimized)

        tabs.handleScroll(offset: 90, isScrollable: true, isUserScrolling: true)
        #expect(bar.isMinimized)
        tabs.handleScroll(offset: 4, isScrollable: true, isUserScrolling: true)
        #expect(!bar.isMinimized) // back at the top
    }

    @Test func minimizeIgnoresProgrammaticScrollAndShortContent() {
        let (tabs, bar, _) = makeTabs()
        tabs.minimizeBehavior = .onScrollDown
        tabs.handleScroll(offset: 200, isScrollable: true, isUserScrolling: false)
        tabs.handleScroll(offset: 400, isScrollable: false, isUserScrolling: true)
        #expect(!bar.isMinimized)
        tabs.minimizeBehavior = .never
        tabs.handleScroll(offset: 600, isScrollable: true, isUserScrolling: true)
        #expect(!bar.isMinimized)
    }

    @Test func minimizesOnScrollUpForBottomAnchoredContent() {
        let (tabs, bar, _) = makeTabs()
        tabs.minimizeBehavior = .onScrollUp
        tabs.handleScroll(offset: 600, isScrollable: true, isUserScrolling: true)
        tabs.handleScroll(offset: 560, isScrollable: true, isUserScrolling: true)
        #expect(bar.isMinimized)
        #expect(tabs.isMinimized)
        tabs.handleScroll(offset: 590, isScrollable: true, isUserScrolling: true)
        #expect(!bar.isMinimized)
    }

    @Test func turningMinimizeOffExpandsAndStopsShrinking() {
        let (tabs, bar, _) = makeTabs()
        tabs.minimizeBehavior = .onScrollDown
        tabs.setMinimized(true, animated: false)
        tabs.minimizeBehavior = .never
        #expect(!bar.isMinimized)
        tabs.handleScroll(offset: 0, isScrollable: true, isUserScrolling: true)
        tabs.handleScroll(offset: 300, isScrollable: true, isUserScrolling: true)
        #expect(!bar.isMinimized)
        // Manual control still works with `.never`.
        tabs.setMinimized(true, animated: false)
        #expect(tabs.isMinimized)
        #expect(LiquidGlassTabBarController.MinimizeBehavior.allCases.count == 3)
    }

    @Test func systemStyleCannotMinimizeTheGlassBar() {
        let tabs = LiquidGlassTabBarController(style: .system)
        tabs.loadViewIfNeeded()
        for behavior in LiquidGlassTabBarController.MinimizeBehavior.allCases {
            tabs.minimizeBehavior = behavior // forwarded to the system bar on iOS 26
        }
        tabs.setMinimized(true, animated: false)
        #expect(!tabs.isMinimized)
    }

    @Test func tapOnTheMinimizedBarExpandsIt() {
        let (tabs, bar, _) = makeTabs()
        tabs.minimizeBehavior = .onScrollDown
        tabs.setMinimized(true, animated: false)
        #expect(bar.isMinimized)
        #expect(bar.accessibilityElements?.count == 1)
        bar.handlePress(state: .began, at: CGPoint(x: 20, y: 20))
        bar.handlePress(state: .ended, at: CGPoint(x: 20, y: 20))
        #expect(!bar.isMinimized)
        tabs.setMinimized(true, animated: false)
        tabs.contentWillChange() // navigating expands it again
        #expect(!bar.isMinimized)
    }

    @Test func findsTheMainVerticalScrollView() {
        let root = UIView(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        let main = UIScrollView(frame: root.bounds)
        let carousel = UIScrollView(frame: CGRect(x: 0, y: 100, width: 390, height: 200))
        carousel.alwaysBounceHorizontal = true
        main.addSubview(carousel)
        let small = UIScrollView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        root.addSubview(small)
        root.addSubview(main)
        #expect(LiquidGlassTabBarController.mainScrollView(in: root) === main)
        #expect(LiquidGlassTabBarController.mainScrollView(in: nil) == nil)
    }

    @Test func voiceOverActivationSelects() {
        let (tabs, bar, _) = makeTabs()
        #expect(bar.buttons[2].accessibilityActivate())
        #expect(tabs.selectedIndex == 2)
    }

    @Test func glassFollowsTheSelectedScreen() {
        let (tabs, bar, _) = makeTabs()
        #expect(bar.glass.backdrop === tabs.selectedViewController?.view)
        tabs.selectedIndex = 1
        #expect(bar.glass.backdrop === tabs.viewControllers?[1].view)
    }
}
