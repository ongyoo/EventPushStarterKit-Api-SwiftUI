//
//  HomeCoordinatorTests.swift
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
struct HomeCoordinatorTests {
    @Test func startAsRootSetsStack() {
        let navigator = Navigator()
        let coordinator = HomeCoordinator(navigator: navigator, isRoot: true)
        coordinator.start()
        #expect(navigator.navigationController.viewControllers.count == 1)
    }

    @Test func routingEmitsOutput() {
        let coordinator = HomeCoordinator(navigator: Navigator())
        var outputs: [HomeCoordinator.Output] = []
        coordinator.onOutput = { outputs.append($0) }
        coordinator.showFeaturedEvent(id: "2")
        coordinator.showEventDetail(id: "1")
        coordinator.showAllEvents(category: .music)
        coordinator.showNotifications()
        #expect(outputs == [.featuredEventSelected(id: "2"), .eventSelected(id: "1"), .seeAllEvents(category: .music), .notificationsSelected])
    }

    @Test func handlesOnlyKnownDeepLinks() {
        let coordinator = HomeCoordinator(navigator: Navigator())
        #expect(coordinator.handle(DeepLink("")))
        #expect(!coordinator.handle(DeepLink("unknown/path")))
    }

    @Test func pushedFlowIsReleasedWhenPopped() {
        let navigator = Navigator()
        navigator.setRoot(UIViewController())
        let parent = Coordinator(navigator: navigator)
        weak let weakChild: HomeCoordinator?
        do {
            let child = HomeCoordinator(navigator: navigator)
            weakChild = child
            parent.startChild(child)
        }
        navigator.popToRoot(animated: false)
        #expect(parent.children.isEmpty)
        #expect(weakChild == nil)
    }
}
