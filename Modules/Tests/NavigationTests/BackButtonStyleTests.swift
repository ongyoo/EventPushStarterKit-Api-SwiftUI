//
//  BackButtonStyleTests.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 17/10/2569 BE.
//

@testable import Navigation
import Core
import SwiftUI
import Testing
import UIKit

@MainActor
struct BackButtonStyleTests {
    private func makeNavigator(_ style: BackButtonStyle) -> (Navigator, UIWindow) {
        let navigator = Navigator(backButton: style, analytics: NoopAnalytics())
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        window.rootViewController = navigator.navigationController
        window.makeKeyAndVisible()
        navigator.setRoot(UIViewController())
        return (navigator, window)
    }

    private func show(_ screen: UIViewController, on navigator: Navigator) {
        navigator.push(screen, animated: false)
        navigator.navigationController(navigator.navigationController, willShow: screen, animated: false)
    }

    // MARK: - Styles

    private let light = UITraitCollection(userInterfaceStyle: .light)
    private let dark = UITraitCollection(userInterfaceStyle: .dark)

    @Test func belowIOS26KeepsSystemWhereTheBackButtonIsGlass() {
        let style = BackButtonStyle.minimal
        #expect(BackButtonStyle.select(style, systemHasGlassBackButton: true).isSystem)
        #expect(BackButtonStyle.select(style, systemHasGlassBackButton: false).titleMode == .minimal)
        // Real value on the test simulator (run on iOS 18 and iOS 26 to see both).
        let glass = ProcessInfo.processInfo.operatingSystemVersion.majorVersion >= 26
        #expect(BackButtonStyle.systemHasGlassBackButton == glass)
        #expect(BackButtonStyle.belowIOS26(style).isSystem == glass)
    }

    @Test func titleModes() {
        #expect(BackButtonStyle.system.titleMode == .default)
        #expect(BackButtonStyle.minimal.titleMode == .minimal)
        #expect(BackButtonStyle.generic.titleMode == .generic)
        #expect(BackButtonStyle.chevron().titleMode == .minimal)
        #expect(BackButtonStyle.chevron(showsTitle: true).titleMode == .default)
        #expect(BackButtonStyle.image(UIImage(), showsTitle: true).titleMode == .default)
        #expect(BackButtonStyle.circle().titleMode == .minimal)
    }

    @Test func tintedChevronColorsIndicatorAndTitle() throws {
        let tinted = BackButtonStyle.chevron(tint: .red, showsTitle: true)
        #expect(try #require(tinted.indicator?(light)).renderingMode == .alwaysOriginal)
        #expect(BackButtonStyle.chevron().indicator?(light)?.renderingMode != .alwaysOriginal)

        let appearance = tinted.applied(to: UINavigationBarAppearance(), traits: light)
        #expect(appearance.backButtonAppearance.normal.titleTextAttributes[.foregroundColor] as? UIColor == .red)
        let restored = BackButtonStyle.system.applied(to: appearance, traits: light)
        #expect(restored.backButtonAppearance.normal.titleTextAttributes[.foregroundColor] == nil)
    }

    @Test func circleIsDrawnPerAppearanceAndSitsOnTheTitleBaseline() throws {
        let style = BackButtonStyle.circle(diameter: 30)
        let lightImage = try #require(style.indicator?(light))
        let darkImage = try #require(style.indicator?(dark))
        #expect(lightImage.size == CGSize(width: 30, height: 30))
        #expect(lightImage.renderingMode == .alwaysOriginal)
        #expect(lightImage.baselineOffsetFromBottom == 9)
        #expect(lightImage.pngData() != darkImage.pngData())
        #expect(BackButtonStyle.circle(border: nil).indicator?(light) != nil)
    }

    @Test func appliedSetsAndSystemRestoresTheIndicator() {
        let image = UIImage(systemName: "arrow.backward")!
        let arrow = BackButtonStyle.image(image).applied(to: UINavigationBarAppearance(), traits: light)
        #expect(arrow.backIndicatorImage === image)
        #expect(BackButtonStyle.system.applied(to: arrow, traits: light).backIndicatorImage !== image)
        #expect(BackButtonStyle.minimal.applied(to: arrow, traits: light).backIndicatorImage !== image)
    }

    // MARK: - Navigator

    @Test func systemStyleLeavesTheBarUntouched() {
        let (navigator, _) = makeNavigator(.system)
        let bar = navigator.navigationController.navigationBar
        #expect(bar.scrollEdgeAppearance == nil)
        let screen = UIViewController()
        show(screen, on: navigator)
        #expect(navigator.navigationController.viewControllers[0].navigationItem.backButtonDisplayMode == .default)
    }

    @Test func navigatorStyleAppliesToTheWholeStack() throws {
        let (navigator, _) = makeNavigator(.chevron(symbol: "arrow.backward"))
        let bar = navigator.navigationController.navigationBar
        let indicator = bar.standardAppearance.backIndicatorImage
        #expect(indicator !== UINavigationBar().standardAppearance.backIndicatorImage)
        #expect(try #require(bar.scrollEdgeAppearance).backIndicatorImage === indicator)

        show(UIViewController(), on: navigator)
        #expect(navigator.navigationController.viewControllers[0].navigationItem.backButtonDisplayMode == .minimal)
    }

    @Test func screenOverridesAndRestoresTheTitleMode() {
        let (navigator, _) = makeNavigator(.minimal)
        let root = navigator.navigationController.viewControllers[0]

        let titled = HostingController(rootView: EmptyView(), backButton: .chevron(showsTitle: true))
        show(titled, on: navigator)
        #expect(root.navigationItem.backButtonDisplayMode == .default)
        #expect(titled.navigationItem.standardAppearance != nil)
        #expect(titled.navigationItem.scrollEdgeAppearance != nil)

        navigator.pop(animated: false)
        let plain = UIViewController()
        show(plain, on: navigator)
        #expect(root.navigationItem.backButtonDisplayMode == .minimal)
        #expect(plain.navigationItem.standardAppearance == nil)
    }

    @Test func systemOverrideOnACustomStackRestoresTheDefaults() {
        let (navigator, _) = makeNavigator(.chevron(symbol: "arrow.backward"))
        let root = navigator.navigationController.viewControllers[0]
        let arrow = navigator.navigationController.navigationBar.standardAppearance.backIndicatorImage
        let screen = HostingController(rootView: EmptyView(), backButton: .system)
        show(screen, on: navigator)
        #expect(root.navigationItem.backButtonDisplayMode == .default)
        #expect(screen.navigationItem.standardAppearance?.backIndicatorImage !== arrow)
    }

    @Test func systemOverrideOnASystemStackDoesNothing() {
        let (navigator, _) = makeNavigator(.system)
        let screen = HostingController(rootView: EmptyView(), backButton: .system)
        show(screen, on: navigator)
        #expect(screen.navigationItem.standardAppearance == nil)
    }

    @Test func rootScreenHasNoBackItemToStyle() {
        let (navigator, _) = makeNavigator(.minimal)
        let root = navigator.navigationController.viewControllers[0]
        navigator.navigationController(navigator.navigationController, willShow: root, animated: false)
        #expect(root.navigationItem.backButtonDisplayMode == .default)
    }

    @Test func lightDarkChangeRedrawsTheCircle() {
        let (navigator, _) = makeNavigator(.circle())
        let controller = navigator.navigationController
        let bar = controller.navigationBar
        controller.overrideUserInterfaceStyle = .light
        controller.updateTraitsIfNeeded()
        navigator.restyleBackButton()
        let before = bar.standardAppearance.backIndicatorImage.pngData()
        controller.overrideUserInterfaceStyle = .dark
        controller.updateTraitsIfNeeded()
        navigator.restyleBackButton()
        #expect(bar.standardAppearance.backIndicatorImage.pngData() != before)
    }

    @Test func defaultStyleIsUsedByNewNavigators() {
        let previous = Navigator.defaultBackButton
        defer { Navigator.defaultBackButton = previous }
        Navigator.defaultBackButton = .chevron(symbol: "arrow.backward")
        let navigator = Navigator(analytics: NoopAnalytics())
        #expect(navigator.navigationController.navigationBar.scrollEdgeAppearance != nil)
    }
}
