//
//  NavigationDemoCoordinator.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import Core
import DesignSystem
import Navigation
import UIKit

/// Modal flow with its own navigation stack (started with `presentChild`).
/// Pushes inside the modal; "Close" calls `dismissFlow()`, which releases it.
final class NavigationDemoCoordinator: Coordinator {
    private var depth = 0

    override func start() {
        navigator.setRoot(makeScreen())
    }

    private func makeScreen() -> UIViewController {
        depth += 1
        let view = NavigationDemoView(title: L10n.tr("nav.screen", depth), actions: [
            .init(title: L10n.tr("nav.pushNext")) { [weak self] in self?.pushNext() },
            .init(title: L10n.tr("nav.close")) { [weak self] in self?.dismissFlow() },
        ])
        return HostingController(rootView: view, title: L10n.tr("nav.modalFlow"))
    }

    func pushNext() {
        navigator.push(makeScreen(), transition: .slideUp)
    }
}
