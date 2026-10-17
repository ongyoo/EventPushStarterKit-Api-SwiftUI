//
//  EventDetailCoordinatorTests.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import Core
import DesignSystem
@testable import Features
import Navigation
import Testing
import UIKit

@MainActor
struct EventDetailCoordinatorTests {
    private func makeNavigator() -> Navigator {
        let navigator = Navigator()
        navigator.setRoot(UIViewController())
        return navigator
    }

    @Test func startPushesDetail() {
        let navigator = makeNavigator()
        let coordinator = EventDetailCoordinator(navigator: navigator, eventID: "1")
        coordinator.start()
        #expect(navigator.navigationController.viewControllers.count == 2)
        #expect(coordinator.eventID == "1")
    }

    @Test func deepLinkToOrganizerPushesTwoScreens() {
        let navigator = makeNavigator()
        let coordinator = EventDetailCoordinator(navigator: navigator, eventID: "1")
        coordinator.start()

        #expect(coordinator.handle(DeepLink("")))
        #expect(coordinator.handle(DeepLink("organizer")))
        #expect(navigator.topViewController?.title == "Organizer")
        #expect(navigator.navigationController.viewControllers.count == 3)
    }

    @Test func rejectsUnknownOrTooDeepLinks() {
        let coordinator = EventDetailCoordinator(navigator: makeNavigator(), eventID: "1")
        #expect(!coordinator.handle(DeepLink("tickets")))
        #expect(!coordinator.handle(DeepLink("organizer/unknown")))
    }

    @Test func routingPushesOrganizer() {
        let navigator = makeNavigator()
        let coordinator = EventDetailCoordinator(navigator: navigator, eventID: "1")
        coordinator.showOrganizer(ofEventID: "1")
        #expect(navigator.topViewController?.title == "Organizer")
    }

    @Test func openingAnotherEventStartsChildThatIsReleasedOnPop() {
        let navigator = makeNavigator()
        let coordinator = EventDetailCoordinator(navigator: navigator, eventID: "1")
        coordinator.start()

        weak let weakChild: EventDetailCoordinator?
        coordinator.showEvent(id: "2")
        weakChild = coordinator.children.first as? EventDetailCoordinator
        #expect(weakChild?.eventID == "2")

        navigator.pop(to: navigator.navigationController.viewControllers[1], animated: false)
        #expect(coordinator.children.isEmpty)
        #expect(weakChild == nil)
    }

    @Test func modalRootHasCloseButtonAndOrganizerFades() throws {
        let navigator = Navigator()
        let coordinator = EventDetailCoordinator(navigator: navigator, eventID: "1", isModalRoot: true)
        coordinator.start()
        #expect(navigator.navigationController.viewControllers.count == 1)
        let close = try #require(navigator.topViewController?.navigationItem.leftBarButtonItem)
        close.primaryAction?.performWithSender(nil, target: nil)

        let pushed = EventDetailCoordinator(navigator: makeNavigator(), eventID: "1", transition: .fade)
        pushed.start()
        pushed.showOrganizer(ofEventID: "1")
        let nav = pushed.navigator.navigationController
        let organizer = try #require(nav.topViewController)
        let animator = pushed.navigator.navigationController(nav, animationControllerFor: .push, from: nav.viewControllers[1], to: organizer)
        #expect(animator != nil, "Organizer uses a fade")
    }

    @Test func otherEventFromOrganizerFlips() throws {
        let navigator = makeNavigator()
        let coordinator = EventDetailCoordinator(navigator: navigator, eventID: "1")
        coordinator.start()
        coordinator.showEvent(id: "2")
        let nav = navigator.navigationController
        let animator = navigator.navigationController(nav, animationControllerFor: .push, from: nav.viewControllers[1], to: try #require(nav.topViewController))
        #expect(animator is FlipAnimator)
    }

    @Test func wholeFlowIsReleasedWhenPoppedToRoot() {
        let navigator = makeNavigator()
        let parent = Coordinator(navigator: navigator)
        weak let weakChild: EventDetailCoordinator?
        do {
            let child = EventDetailCoordinator(navigator: navigator, eventID: "1")
            weakChild = child
            parent.startChild(child)
            child.handle(DeepLink("organizer"))
        }
        navigator.popToRoot(animated: false)
        #expect(parent.children.isEmpty)
        #expect(weakChild == nil)
    }
}
