//
//  DynamicScreenCoordinator.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 17/10/2569 BE.
//

import Core
import Navigation
import ServerDrivenUI
import UIKit

/// Entry point of server-driven screens (BFF).
///
/// Deep links: `screens/<id>` (any tab) opens the screen `<id>`.
/// The screen's own actions: deep links go to the app router, `screen`
/// pushes or presents another server-driven screen, `openURL` leaves the app.
public final class DynamicScreenCoordinator: Coordinator {
    private let screenID: String
    private let isModalRoot: Bool

    public init(navigator: Navigator, screenID: String, isModalRoot: Bool = false) {
        self.screenID = screenID
        self.isModalRoot = isModalRoot
        super.init(navigator: navigator)
    }

    override public func start() {
        showFirstScreen(DynamicScreenBuilder.build(screenID: screenID, router: self, showsClose: isModalRoot), asRoot: isModalRoot)
    }

    @discardableResult
    override public func handle(_ link: DeepLink) -> Bool {
        link.isEmpty
    }
}

extension DynamicScreenCoordinator: DynamicScreenRouting {
    func open(_ url: URL) {
        let environment = Container.shared.appEnvironment()
        if let link = DeepLink(url: url, scheme: environment.deepLinkScheme, universalLinkHost: environment.universalLinkHost) {
            DeepLinkInbox.shared.post(link)
        } else {
            openExternal(url)
        }
    }

    func openExternal(_ url: URL) {
        guard ["http", "https", "mailto", "tel"].contains(url.scheme?.lowercased() ?? "") else { return }
        UIApplication.shared.open(url)
    }

    func showScreen(id: String, presentation: DynamicAction.Presentation) {
        switch presentation {
        case .push:
            startChild(DynamicScreenCoordinator(navigator: navigator, screenID: id))
        case .sheet:
            presentChild(style: .sheet(detents: [.medium, .large])) { DynamicScreenCoordinator(navigator: $0, screenID: id, isModalRoot: true) }
        case .fullScreen:
            presentChild(style: .fullScreen) { DynamicScreenCoordinator(navigator: $0, screenID: id, isModalRoot: true) }
        }
    }

    func close() {
        if isModalRoot {
            dismissFlow()
        } else {
            navigator.pop()
        }
    }
}
