//
//  EventListCoordinator.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import Core
import DesignSystem
import Domain
import Navigation
import UIKit

/// Entry point of the EventList feature.
///
/// Deep links: the parent maps `events?category=music` to
/// `EventListCoordinator(navigator:category: .music)`.
public final class EventListCoordinator: Coordinator {
    public enum Output: Equatable {
        case eventSelected(id: String)
    }

    public var onOutput: ((Output) -> Void)?

    private let category: EventCategory
    private let isRoot: Bool
    private let transition: Transition

    public init(navigator: Navigator, category: EventCategory = .all, isRoot: Bool = false, transition: Transition = .system) {
        self.category = category
        self.isRoot = isRoot
        self.transition = transition
        super.init(navigator: navigator)
    }

    override public func start() {
        showFirstScreen(EventListBuilder.build(category: category, router: self), asRoot: isRoot, transition: transition)
    }

    @discardableResult
    override public func handle(_ link: DeepLink) -> Bool {
        link.isEmpty
    }
}

extension EventListCoordinator: EventListRouting {
    func showEvent(id: String) {
        onOutput?(.eventSelected(id: id))
    }
}
