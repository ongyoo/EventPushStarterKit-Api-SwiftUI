//
//  NotificationCoordinatorTests.swift
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
struct NotificationCoordinatorTests {
    @Test func startAsRootSetsStack() {
        let navigator = Navigator()
        let coordinator = NotificationCoordinator(navigator: navigator, isRoot: true)
        coordinator.start()
        #expect(navigator.navigationController.viewControllers.count == 1)
    }

    @Test func routingEmitsOutput() {
        let coordinator = NotificationCoordinator(navigator: Navigator())
        var outputs: [NotificationCoordinator.Output] = []
        coordinator.onOutput = { outputs.append($0) }
        coordinator.openEvent(id: "1")
        #expect(outputs == [.eventSelected(id: "1")])
    }

    @Test func handlesOnlyKnownDeepLinks() {
        let coordinator = NotificationCoordinator(navigator: Navigator())
        #expect(coordinator.handle(DeepLink("")))
        #expect(!coordinator.handle(DeepLink("unknown/path")))
    }

    @Test func pushedFlowIsReleasedWhenPopped() {
        let navigator = Navigator()
        navigator.setRoot(UIViewController())
        let parent = Coordinator(navigator: navigator)
        weak let weakChild: NotificationCoordinator?
        do {
            let child = NotificationCoordinator(navigator: navigator)
            weakChild = child
            parent.startChild(child)
        }
        navigator.popToRoot(animated: false)
        #expect(parent.children.isEmpty)
        #expect(weakChild == nil)
    }
}
