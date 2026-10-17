//
//  NotificationCoordinator.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import Core
import DesignSystem
import Navigation
import UIKit

/// Public entry point of NotificationFeature.
/// Its screen is built with UIKit + Storyboard to show that both UI
/// technologies plug into the same Coordinator / VIPER structure.
/// Everything else in the module stays `internal`.
///
/// Deep links (relative to this feature, the parent strips its own prefix):
///
/// | Path      | Screen                |
/// |-----------|-----------------------|
/// | (empty)   | Notification (first screen) |
public final class NotificationCoordinator: Coordinator {
    /// Things this feature can't decide alone (e.g. open another feature).
    /// The parent flow handles them, so features never import each other.
    public enum Output: Equatable {
        case eventSelected(id: String)
    }

    /// Set by the parent with `[weak self]`.
    public var onOutput: ((Output) -> Void)?

    private let isRoot: Bool

    /// - Parameter isRoot: `true` when this feature is a tab root.
    public init(navigator: Navigator, isRoot: Bool = false) {
        self.isRoot = isRoot
        super.init(navigator: navigator)
    }

    override public func start() {
        showFirstScreen(NotificationBuilder.build(router: self), asRoot: isRoot)
    }

    @discardableResult
    override public func handle(_ link: DeepLink) -> Bool {
        // Empty = first screen, already shown by start().
        // Add cases for deeper screens: case "settings": showSettings()
        link.isEmpty
    }
}

// MARK: - Routing

extension NotificationCoordinator: NotificationRouting {
    func openEvent(id: String) {
        onOutput?(.eventSelected(id: id))
    }
}
