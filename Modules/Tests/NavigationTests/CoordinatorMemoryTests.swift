//
//  CoordinatorMemoryTests.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

@testable import Navigation
import Testing
import UIKit

@MainActor
private final class ChildCoordinator: Coordinator {
    override func start() {
        navigator.push(UIViewController(), animated: false) { [weak self] in
            self?.finish()
        }
    }
}

@MainActor
struct CoordinatorMemoryTests {
    @Test func childIsReleasedWhenItsScreenIsPopped() {
        let navigator = Navigator()
        navigator.setRoot(UIViewController())
        let parent = Coordinator(navigator: navigator)

        weak let weakChild: ChildCoordinator?
        do {
            let child = ChildCoordinator(navigator: navigator)
            weakChild = child
            parent.startChild(child)
        }
        #expect(parent.children.count == 1)

        navigator.popToRoot(animated: false)

        #expect(parent.children.isEmpty)
        #expect(weakChild == nil, "Child coordinator leaked")
    }
}
