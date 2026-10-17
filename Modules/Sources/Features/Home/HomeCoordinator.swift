//
//  HomeCoordinator.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import Core
import DesignSystem
import Domain
import Navigation
import UIKit

/// Entry point of the Home feature.
///
/// Home only shows its own screen. Opening an event, the event list or
/// notifications belongs to other features, so Home reports an `Output`
/// and the parent flow decides what to start.
public final class HomeCoordinator: Coordinator {
    public enum Output: Equatable {
        /// Card in the "Popular" carousel (opened with a hero transition).
        case featuredEventSelected(id: String)
        case eventSelected(id: String)
        case seeAllEvents(category: EventCategory)
        case notificationsSelected
    }

    /// Set by the parent with `[weak self]`.
    public var onOutput: ((Output) -> Void)?

    private let isRoot: Bool

    public init(navigator: Navigator, isRoot: Bool = false) {
        self.isRoot = isRoot
        super.init(navigator: navigator)
    }

    override public func start() {
        showFirstScreen(HomeBuilder.build(router: self), asRoot: isRoot)
    }

    @discardableResult
    override public func handle(_ link: DeepLink) -> Bool {
        link.isEmpty
    }
}

// MARK: - HomeRouting

extension HomeCoordinator: HomeRouting {
    func showFeaturedEvent(id: String) {
        onOutput?(.featuredEventSelected(id: id))
    }

    func showEventDetail(id: String) {
        onOutput?(.eventSelected(id: id))
    }

    func showAllEvents(category: EventCategory) {
        onOutput?(.seeAllEvents(category: category))
    }

    func showNotifications() {
        onOutput?(.notificationsSelected)
    }
}
