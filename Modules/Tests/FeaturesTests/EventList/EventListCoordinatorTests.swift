//
//  EventListCoordinatorTests.swift
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
struct EventListCoordinatorTests {
    @Test func startAsRootSetsStack() {
        let navigator = Navigator()
        let coordinator = EventListCoordinator(navigator: navigator, isRoot: true)
        coordinator.start()
        #expect(navigator.navigationController.viewControllers.count == 1)
    }

    @Test func routingEmitsOutput() {
        let coordinator = EventListCoordinator(navigator: Navigator())
        var outputs: [EventListCoordinator.Output] = []
        coordinator.onOutput = { outputs.append($0) }
        coordinator.showEvent(id: "1")
        #expect(outputs == [.eventSelected(id: "1")])
    }

    @Test func handlesOnlyKnownDeepLinks() {
        let coordinator = EventListCoordinator(navigator: Navigator())
        #expect(coordinator.handle(DeepLink("")))
        #expect(!coordinator.handle(DeepLink("unknown/path")))
    }

    @Test func pushedFlowIsReleasedWhenPopped() {
        let navigator = Navigator()
        navigator.setRoot(UIViewController())
        let parent = Coordinator(navigator: navigator)
        weak let weakChild: EventListCoordinator?
        do {
            let child = EventListCoordinator(navigator: navigator)
            weakChild = child
            parent.startChild(child)
        }
        navigator.popToRoot(animated: false)
        #expect(parent.children.isEmpty)
        #expect(weakChild == nil)
    }
}
