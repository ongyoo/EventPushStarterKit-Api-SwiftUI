//
//  TabFlowCoordinator.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import Core
import DesignSystem
import Navigation
import UIKit

/// Base for every tab. Put routes shared by all tabs in `route(_:)`
/// (e.g. `profile/<id>`), so any tab can open them with the same deep link.
///
/// Feature coordinators never know each other: they emit `Output`,
/// and the flow decides which feature to start next.
@MainActor
class TabFlowCoordinator: FlowCoordinator {
    init() {
        super.init(navigator: Navigator())
    }

    /// Resets the tab to its root, then builds the stack for `link`
    /// without animations (the user sees only the final screen).
    override func handle(_ link: DeepLink) -> Bool {
        var handled = false
        navigator.withoutAnimation {
            navigator.dismiss(animated: false)
            navigator.popToRoot(animated: false)
            handled = route(link)
        }
        return handled
    }

    /// Routes relative to the tab root. Example:
    ///
    ///     case "profile":
    ///         guard let id = link.dropFirst().first else { return false }
    ///         return showProfile(id: id).handle(link.dropFirst(2))
    func route(_ link: DeepLink) -> Bool {
        switch link.first {
        case nil:
            return true
        #if DEBUG
        case "debug" where link.dropFirst().first == "animations":
            navigator.push(HostingController(rootView: AnimationGallery(), title: "Animations"))
            return true
        #endif
        default:
            return false
        }
    }
}
