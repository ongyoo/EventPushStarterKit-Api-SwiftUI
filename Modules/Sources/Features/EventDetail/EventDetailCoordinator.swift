//
//  EventDetailCoordinator.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import Core
import DesignSystem
import Domain
import Navigation
import UIKit

/// Entry point of the EventDetail feature: one event and its sub-screens.
///
/// Deep links (relative to `events/<id>`, the parent strips that prefix):
///
/// | Path        | Screen                         |
/// |-------------|--------------------------------|
/// | (empty)     | Event detail                   |
/// | `organizer` | Event detail -> Organizer      |
///
/// Example: `eventpush://events/42/organizer`
public final class EventDetailCoordinator: Coordinator {
    let eventID: String
    private let transition: Transition
    private let isModalRoot: Bool

    /// - Parameters:
    ///   - transition: how the detail page is pushed (hero, scale, flip...).
    ///   - isModalRoot: `true` when presented in its own modal stack (adds a Close button).
    public init(navigator: Navigator, eventID: String, transition: Transition = .system, isModalRoot: Bool = false) {
        self.eventID = eventID
        self.transition = transition
        self.isModalRoot = isModalRoot
        super.init(navigator: navigator)
    }

    override public func start() {
        let detail = EventDetailBuilder.build(eventID: eventID, router: self)
        if isModalRoot {
            detail.navigationItem.leftBarButtonItem = UIBarButtonItem(
                systemItem: .close,
                primaryAction: UIAction { [weak self] _ in self?.dismissFlow() }
            )
        }
        showFirstScreen(detail, asRoot: isModalRoot, transition: transition)
    }

    @discardableResult
    override public func handle(_ link: DeepLink) -> Bool {
        switch link.first {
        case nil:
            return true
        case "organizer":
            showOrganizer(ofEventID: eventID, animated: false)
            return link.dropFirst().isEmpty
        default:
            return false
        }
    }

    /// Showcase: the organizer page fades in.
    private func showOrganizer(ofEventID eventID: String, animated: Bool) {
        navigator.push(OrganizerBuilder.build(eventID: eventID, router: self), transition: .fade, animated: animated)
    }
}

// MARK: - Routing

extension EventDetailCoordinator: EventDetailRouting {
    func showOrganizer(ofEventID eventID: String) {
        showOrganizer(ofEventID: eventID, animated: true)
    }
}

extension EventDetailCoordinator: OrganizerRouting {
    /// Opening another event from the organizer page reuses this feature:
    /// a child coordinator for the other event, released when popped.
    /// Showcase: a hand-written `.custom` transition (3D flip).
    func showEvent(id: String) {
        startChild(EventDetailCoordinator(navigator: navigator, eventID: id, transition: .custom { FlipAnimator(isPresenting: $0) }))
    }
}
