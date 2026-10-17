//
//  TabFlowCoordinator.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import Core
import DesignSystem
import Domain
import Features
import Navigation
import UIKit

/// Base for every tab. Knows the routes shared by all tabs
/// (`events`, `notifications`) so an event can be opened from any tab
/// with the same code and the same deep links.
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

    /// Routes relative to the tab root. Override to add tab-specific routes,
    /// then call `super.route(link)`.
    func route(_ link: DeepLink) -> Bool {
        switch link.first {
        case nil:
            return true
        case "events":
            return routeEvents(link.dropFirst())
        case "notifications":
            presentNotifications()
            return link.dropFirst().isEmpty
        case "screens":
            // Server-driven screen from the BFF: `screens/<id>`.
            guard let id = link.dropFirst().first else { return false }
            showDynamicScreen(id: id)
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

    /// `events`                     -> list
    /// `events?category=music`      -> list filtered
    /// `events/<id>[/...]`          -> detail, rest handled by EventDetailCoordinator
    private func routeEvents(_ link: DeepLink) -> Bool {
        guard let eventID = link.first else {
            let category = link.query["category"].flatMap(EventCategory.init(rawValue:)) ?? .all
            showEventList(category: category)
            return true
        }
        return showEventDetail(id: eventID).handle(link.dropFirst())
    }

    // MARK: - Shared destinations
    //
    // Navigation showcase: every entry point uses a different style.
    //
    // | From                      | To            | Style                                |
    // |---------------------------|---------------|--------------------------------------|
    // | Popular card              | Event detail  | hero expand from the card            |
    // | Upcoming row, deep link   | Event detail  | system push                          |
    // | See all                   | Event list    | push · slide up                      |
    // | Event list row            | Event detail  | full-screen modal (fade) + Close     |
    // | Bell / `notifications`    | Notifications | sheet (medium/large), own stack      |
    // | Notification row          | Event detail  | push · scale                         |
    // | Organizer row             | Organizer     | push · fade (EventDetailCoordinator) |
    // | Organizer's event         | Event detail  | custom 3D flip (EventDetailCoordinator) |

    @discardableResult
    func showEventDetail(id: String, transition: Transition = .system) -> EventDetailCoordinator {
        let coordinator = EventDetailCoordinator(navigator: navigator, eventID: id, transition: transition)
        startChild(coordinator)
        return coordinator
    }

    func showFeaturedEventDetail(id: String) {
        showEventDetail(id: id, transition: .expand(sourceID: HeroID.event(id)))
    }

    /// Detail in its own full-screen stack, closed with the Close button.
    func presentEventDetail(id: String) {
        presentChild(style: .fullScreen, transition: .fade) { navigator in
            EventDetailCoordinator(navigator: navigator, eventID: id, isModalRoot: true)
        }
    }

    func showDynamicScreen(id: String) {
        startChild(DynamicScreenCoordinator(navigator: navigator, screenID: id))
    }

    func showEventList(category: EventCategory) {
        let coordinator = EventListCoordinator(navigator: navigator, category: category, transition: .slideUp)
        coordinator.onOutput = { [weak self] output in
            switch output {
            case let .eventSelected(id): self?.presentEventDetail(id: id)
            }
        }
        startChild(coordinator)
    }

    /// Notifications in a sheet with their own stack: events open inside it.
    func presentNotifications() {
        let notifications = presentChild(style: .sheet(detents: [.medium, .large])) { navigator in
            NotificationCoordinator(navigator: navigator, isRoot: true)
        }
        notifications.onOutput = { [weak notifications] output in
            guard let notifications else { return }
            switch output {
            case let .eventSelected(id):
                notifications.startChild(EventDetailCoordinator(navigator: notifications.navigator, eventID: id, transition: .scale))
            }
        }
    }

    /// Notifications as the root of this tab (Inbox).
    func startNotifications(isRoot: Bool) {
        let coordinator = NotificationCoordinator(navigator: navigator, isRoot: isRoot)
        coordinator.onOutput = { [weak self] output in
            switch output {
            case let .eventSelected(id): self?.showEventDetail(id: id, transition: .scale)
            }
        }
        startChild(coordinator)
    }
}
