//
//  SettingsCoordinator.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import Core
import DesignSystem
import Navigation
import UIKit

/// Settings tab: language, permissions, notifications and capability demos.
///
/// Deep links: `settings` (root).
///
/// Device services (permissions, notifications, background tasks, Live
/// Activities) live in Platform, which Features cannot import: the app's
/// composition root provides them through `makeInteractor`.
public final class SettingsCoordinator: Coordinator {
    private let isRoot: Bool
    private let makeInteractor: @MainActor () -> any SettingsInteracting

    public init(navigator: Navigator, isRoot: Bool = false, makeInteractor: @escaping @MainActor () -> any SettingsInteracting) {
        self.isRoot = isRoot
        self.makeInteractor = makeInteractor
        super.init(navigator: navigator)
    }

    override public func start() {
        showFirstScreen(SettingsBuilder.build(router: self, interactor: makeInteractor()), asRoot: isRoot)
    }

    @discardableResult
    override public func handle(_ link: DeepLink) -> Bool {
        link.isEmpty
    }
}

extension SettingsCoordinator: SettingsRouting {
    func showAnimationGallery() {
        navigator.push(HostingController(rootView: AnimationGallery(), title: L10n.tr("settings.animations")))
    }

    func showKeyboardDemo() {
        navigator.push(HostingController(rootView: KeyboardDemoView(), title: L10n.tr("keyboard.title")))
    }

    func showNavigationDemo(_ demo: NavigationDemo) {
        switch demo {
        case .pushFade:
            navigator.push(demoScreen(demo), transition: .fade)
        case .pushSlideUp:
            navigator.push(demoScreen(demo), transition: .slideUp)
        case .pushScale:
            navigator.push(demoScreen(demo), transition: .scale)
        case .sheet:
            navigator.present(demoScreen(demo, closable: true), style: .sheet(detents: [.medium, .large]))
        case .fullScreen:
            navigator.present(demoScreen(demo, closable: true), style: .fullScreen, transition: .fade)
        case .modalFlow:
            presentChild(style: .formSheet) { NavigationDemoCoordinator(navigator: $0) }
        case .backTinted:
            // Before iOS 26: brand chevron + previous title. iOS 26: system glass button.
            navigator.push(demoScreen(demo, backButton: .belowIOS26(.chevron(tint: .brandPrimary, showsTitle: true))))
        case .serverDriven:
            // Whole screen described by the BFF (bundled copy when offline).
            startChild(DynamicScreenCoordinator(navigator: navigator, screenID: "showcase"))
        case .backArrow:
            navigator.push(demoScreen(demo, backButton: .belowIOS26(.chevron(symbol: "arrow.backward"))))
        }
    }

    private func demoScreen(_ demo: NavigationDemo, closable: Bool = false, backButton: BackButtonStyle? = nil) -> UIViewController {
        let close = NavigationDemoView.Action(title: L10n.tr("nav.close")) { [weak navigator] in
            navigator?.dismiss()
        }
        let view = NavigationDemoView(title: L10n.tr("nav.\(demo.rawValue)"), actions: closable ? [close] : [])
        return HostingController(rootView: view, title: L10n.tr("nav.\(demo.rawValue)"), backButton: backButton)
    }
}
