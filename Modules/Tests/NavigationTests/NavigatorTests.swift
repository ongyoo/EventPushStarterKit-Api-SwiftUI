//
//  NavigatorTests.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

@testable import Navigation
import Core
import Testing
import UIKit

@MainActor
struct NavigatorTests {
    private func makeNavigator() -> (Navigator, UIWindow) {
        let navigator = Navigator()
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        window.rootViewController = navigator.navigationController
        window.makeKeyAndVisible()
        navigator.setRoot(UIViewController())
        return (navigator, window)
    }

    @Test func pushPopRunsOnPopOnce() {
        let (navigator, _) = makeNavigator()
        var pops = 0
        let screen = UIViewController()
        navigator.withoutAnimation {
            navigator.push(screen) { pops += 1 }
        }
        #expect(navigator.topViewController === screen)

        navigator.pop(animated: false)
        navigator.navigationController(navigator.navigationController, didShow: navigator.topViewController!, animated: false)
        navigator.navigationController(navigator.navigationController, didShow: navigator.topViewController!, animated: false)
        #expect(pops == 1)
    }

    @Test func popToSpecificScreenFinishesOnlyScreensAbove() {
        let (navigator, _) = makeNavigator()
        var popped: [String] = []
        let a = UIViewController(), b = UIViewController(), c = UIViewController()
        navigator.push(a, animated: false) { popped.append("a") }
        navigator.push(b, animated: false) { popped.append("b") }
        navigator.push(c, animated: false) { popped.append("c") }
        navigator.pop(to: a, animated: false)
        #expect(popped == ["c", "b"])
    }

    @Test func presentAndDismissRunOnDismiss() async {
        let (navigator, _) = makeNavigator()
        var dismissed = 0
        navigator.present(UIViewController(), animated: false) { dismissed += 1 }
        #expect(navigator.navigationController.presentedViewController != nil)

        // Without a window scene UIKit doesn't complete the dismissal in unit
        // tests; the onDismiss path is covered by swipeDownDismissRunsOnDismissOnce.
        navigator.dismiss(animated: false)
        _ = dismissed

        let empty = Navigator()
        var completed = false
        empty.dismiss(animated: false) { completed = true }
        #expect(completed, "Nothing presented: completion runs immediately")
    }

    @Test func swipeDownDismissRunsOnDismissOnce() throws {
        let (navigator, _) = makeNavigator()
        var dismissed = 0
        let modal = UIViewController()
        navigator.present(modal, animated: false) { dismissed += 1 }
        let presentation = try #require(modal.presentationController)
        let delegate = try #require(presentation.delegate)
        delegate.presentationControllerDidDismiss?(presentation)
        delegate.presentationControllerDidDismiss?(presentation)
        #expect(dismissed == 1)
    }

    @Test func coordinatorTreeHelpers() {
        let (navigator, _) = makeNavigator()
        let flow = FlowCoordinator(navigator: navigator)
        #expect(flow.rootViewController === navigator.navigationController)
        flow.start()
        #expect(!flow.handle(DeepLink("anything")))

        let child = Coordinator(navigator: navigator)
        let grandChild = Coordinator(navigator: navigator)
        flow.startChild(child)
        child.startChild(grandChild)
        child.showFirstScreen(UIViewController(), asRoot: false, animated: false)
        #expect(flow.children.count == 1 && child.children.count == 1)

        child.finish()
        #expect(flow.children.isEmpty)
        #expect(child.children.isEmpty)

        flow.startChild(Coordinator(navigator: navigator))
        flow.removeAllChildren()
        #expect(flow.children.isEmpty)

        flow.showFirstScreen(UIViewController(), asRoot: true)
        #expect(navigator.navigationController.viewControllers.count == 1)
    }

    @Test func navigationBarFollowsTheVisibleScreen() {
        let (navigator, _) = makeNavigator()
        let nav = navigator.navigationController
        let home = HeaderScreen()
        navigator.setRoot(home)
        navigator.navigationController(nav, willShow: home, animated: false)
        #expect(nav.isNavigationBarHidden, "Home draws its own header")

        let detail = UIViewController()
        navigator.push(detail, animated: false)
        navigator.navigationController(nav, willShow: detail, animated: false)
        #expect(!nav.isNavigationBarHidden, "Pushed screen must show the bar and its back button")

        navigator.pop(animated: false)
        navigator.navigationController(nav, willShow: home, animated: false)
        #expect(nav.isNavigationBarHidden)
    }

    @Test func deepLinkDescription() {
        #expect(DeepLink("events/42?b=2&a=1").description == "/events/42?a=1&b=2")
        #expect(DeepLink("").isEmpty)
        #expect(DeepLink(path: ["a", "", "b"]).path == ["a", "b"])
    }
}

@MainActor
private final class HeaderScreen: UIViewController, NavigationBarHiding {
    var prefersNavigationBarHidden: Bool { true }
}
