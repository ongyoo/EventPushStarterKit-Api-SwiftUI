___FILEHEADER___

import Core
import Navigation
import Testing
import UIKit
@testable import Features

@MainActor
struct ___VARIABLE_featureName___CoordinatorTests {
    @Test func startAsRootSetsStack() {
        let navigator = Navigator()
        let coordinator = ___VARIABLE_featureName___Coordinator(navigator: navigator, isRoot: true)
        coordinator.start()
        #expect(navigator.navigationController.viewControllers.count == 1)
    }

    @Test func routingEmitsOutput() {
        let coordinator = ___VARIABLE_featureName___Coordinator(navigator: Navigator())
        var outputs: [___VARIABLE_featureName___Coordinator.Output] = []
        coordinator.onOutput = { outputs.append($0) }
        coordinator.showItem(id: "1")
        #expect(outputs == [.itemSelected(id: "1")])
    }

    @Test func handlesOnlyKnownDeepLinks() {
        let coordinator = ___VARIABLE_featureName___Coordinator(navigator: Navigator())
        #expect(coordinator.handle(DeepLink("")))
        #expect(!coordinator.handle(DeepLink("unknown/path")))
    }

    @Test func pushedFlowIsReleasedWhenPopped() {
        let navigator = Navigator()
        navigator.setRoot(UIViewController())
        let parent = Coordinator(navigator: navigator)
        weak let weakChild: ___VARIABLE_featureName___Coordinator?
        do {
            let child = ___VARIABLE_featureName___Coordinator(navigator: navigator)
            weakChild = child
            parent.startChild(child)
        }
        navigator.popToRoot(animated: false)
        #expect(parent.children.isEmpty)
        #expect(weakChild == nil)
    }
}
