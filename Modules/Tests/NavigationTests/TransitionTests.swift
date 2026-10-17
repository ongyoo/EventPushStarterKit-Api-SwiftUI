//
//  TransitionTests.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

@testable import Navigation
import Foundation
import SwiftUI
import Testing
import UIKit

@MainActor
struct TransitionTests {
    private func makeNavigator() -> (Navigator, UIWindow) {
        let navigator = Navigator()
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        window.rootViewController = navigator.navigationController
        window.makeKeyAndVisible()
        navigator.setRoot(UIViewController())
        return (navigator, window)
    }

    @Test func customPushTransitionProvidesAnimatorBothWays() {
        let (navigator, _) = makeNavigator()
        let root = navigator.topViewController!
        let screen = UIViewController()
        navigator.push(screen, transition: .fade, animated: false)
        let nav = navigator.navigationController

        let push = navigator.navigationController(nav, animationControllerFor: .push, from: root, to: screen)
        let pop = navigator.navigationController(nav, animationControllerFor: .pop, from: screen, to: root)
        #expect((push as? TransitionAnimator)?.isPresenting == true)
        #expect((pop as? TransitionAnimator)?.isPresenting == false)

        let plain = UIViewController()
        navigator.push(plain, animated: false)
        #expect(navigator.navigationController(nav, animationControllerFor: .push, from: screen, to: plain) == nil)
    }

    @Test func transitionKindsAndCustomAnimator() {
        #expect(Transition.system.animator(presenting: true) == nil)
        #expect((Transition.slideUp.animator(presenting: true) as? TransitionAnimator) != nil)
        #expect((Transition.scale.animator(presenting: false) as? TransitionAnimator) != nil)
        let custom = Transition.custom { TransitionAnimator(kind: .fade, isPresenting: $0, duration: 1) }
        #expect(custom.animator(presenting: true)?.transitionDuration(using: nil) == 1)

        let zoomed = UIViewController()
        let prepared = Transition.zoom { nil }.prepare(zoomed)
        if case .system = prepared {} else if case .fade = prepared {} else { Issue.record("zoom should map to system or fade") }
    }

    @Test func expandTransitionUsesRegisteredSourceOrFallsBack() {
        let registry = TransitionSourceRegistry.shared
        registry.register("card.1", frame: CGRect(x: 20, y: 200, width: 260, height: 180))
        #expect(registry.frame(for: "card.1") != nil)
        #expect(Transition.expand(sourceID: "card.1").animator(presenting: true) is ExpandAnimator)
        #expect(Transition.expand(sourceID: "missing").animator(presenting: true) is TransitionAnimator)
        registry.remove("card.1")
        #expect(registry.frame(for: "card.1") == nil)
        #expect(TransitionSourceRegistry().frame(for: "x") == nil)
    }

    @Test func registeredViewsAreMeasuredLazilyAndHeldWeakly() {
        let registry = TransitionSourceRegistry()
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 400, height: 800))
        var card: UIView? = UIView(frame: CGRect(x: 10, y: 300, width: 200, height: 100))
        registry.register("card", view: card ?? UIView())
        #expect(registry.frame(for: "card") == nil) // off screen: no window yet

        if let card { window.addSubview(card) }
        #expect(registry.frame(for: "card") == CGRect(x: 10, y: 300, width: 200, height: 100))
        card?.frame.origin.y = 120 // moved (scrolled): measured at transition time
        #expect(registry.frame(for: "card")?.minY == 120)

        card?.removeFromSuperview()
        card = nil
        #expect(registry.frame(for: "card") == nil) // released, not retained
    }

    @Test func swiftUIViewsRegisterThemselvesAsSources() throws {
        let id = "swiftui.card.\(UUID().uuidString)"
        let host = UIHostingController(rootView: Color.red.frame(width: 120, height: 80).transitionSource(id: id))
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        window.rootViewController = host
        window.makeKeyAndVisible()
        host.view.layoutIfNeeded()
        let frame = try #require(TransitionSourceRegistry.shared.frame(for: id))
        #expect(frame.size == CGSize(width: 120, height: 80))
        window.isHidden = true
    }

    @Test func expandAnimatorRunsBothDirections() {
        for presenting in [true, false] {
            let context = FakeTransitionContext()
            let animator = ExpandAnimator(sourceFrame: CGRect(x: 20, y: 200, width: 260, height: 180), isPresenting: presenting, duration: 0)
            #expect(animator.transitionDuration(using: nil) == 0)
            animator.animateTransition(using: context)
            #expect(!context.containerView.subviews.isEmpty)
        }
        let wide = UIView(frame: CGRect(x: 0, y: 0, width: 1000, height: 800))
        #expect(ExpandAnimator.headerFrame(in: wide).width == 480)
        let empty = FakeTransitionContext(hasToView: false)
        ExpandAnimator(sourceFrame: .zero, isPresenting: true).animateTransition(using: empty)
        #expect(empty.completed == true)
    }

    @Test func presentationStylesConfigureController() {
        let sheet = UIViewController()
        PresentationStyle.sheet(detents: [.medium, .large, .height(200)], grabber: true).apply(to: sheet)
        #expect(sheet.modalPresentationStyle == .pageSheet)
        #expect(sheet.sheetPresentationController?.detents.count == 3)

        for (style, expected) in [(PresentationStyle.fullScreen, UIModalPresentationStyle.fullScreen), (.overFullScreen, .overFullScreen), (.formSheet, .formSheet)] {
            let controller = UIViewController()
            style.apply(to: controller)
            #expect(controller.modalPresentationStyle == expected)
        }
    }

    @Test func customModalTransitionKeepsDelegateAlive() {
        let (navigator, _) = makeNavigator()
        let modal = UIViewController()
        navigator.present(modal, style: .fullScreen, transition: .fade, animated: false)
        let delegate = modal.transitioningDelegate
        #expect(delegate != nil)
        #expect(delegate?.animationController?(forPresented: modal, presenting: navigator.navigationController, source: navigator.navigationController) != nil)
        #expect(delegate?.animationController?(forDismissed: modal) != nil)
    }

    @Test func animatorRunsPresentAndDismiss() {
        for kind in [TransitionAnimator.Kind.fade, .slideUp, .scale] {
            for presenting in [true, false] {
                let context = FakeTransitionContext()
                TransitionAnimator(kind: kind, isPresenting: presenting, duration: 0).animateTransition(using: context)
                #expect(context.containerView.subviews.isEmpty == false)
            }
        }
        let empty = FakeTransitionContext(hasToView: false)
        TransitionAnimator(kind: .fade, isPresenting: true).animateTransition(using: empty)
        #expect(empty.completed == false)
    }

    /// Unit tests have no window scene, so UIKit never finishes real modal
    /// animations. The swipe-down path is driven through the presentation
    /// delegate, exactly as UIKit calls it.
    @Test func modalChildFlowIsReleasedOnSwipeDown() throws {
        let (navigator, _) = makeNavigator()
        let parent = Coordinator(navigator: navigator)
        weak var weakChild: Coordinator?
        do {
            var presented: Coordinator?
            navigator.withoutAnimation {
                presented = parent.presentChild(style: .formSheet) { Coordinator(navigator: $0) }
            }
            let child = try #require(presented)
            weakChild = child
            #expect(parent.children.count == 1)
            let presentation = try #require(child.navigator.navigationController.presentationController)
            presentation.delegate?.presentationControllerDidDismiss?(presentation)
            child.dismissFlow(animated: false)
        }
        #expect(parent.children.isEmpty)
        #expect(weakChild == nil)

        let notPresented = Coordinator(navigator: navigator)
        parent.startChild(notPresented)
        notPresented.dismissFlow()
        #expect(parent.children.isEmpty)
    }
}

/// Minimal transition context to run animators synchronously in tests.
private final class FakeTransitionContext: NSObject, UIViewControllerContextTransitioning {
    let containerView = UIView(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
    private let from = UIViewController()
    private let to = UIViewController()
    private let hasToView: Bool
    var completed: Bool?

    init(hasToView: Bool = true) {
        self.hasToView = hasToView
        super.init()
        containerView.addSubview(from.view)
    }

    var isAnimated: Bool { false }
    var isInteractive: Bool { false }
    var transitionWasCancelled: Bool { false }
    var presentationStyle: UIModalPresentationStyle { .fullScreen }
    var targetTransform: CGAffineTransform { .identity }

    func updateInteractiveTransition(_ percentComplete: CGFloat) {}
    func finishInteractiveTransition() {}
    func cancelInteractiveTransition() {}
    func pauseInteractiveTransition() {}
    func completeTransition(_ didComplete: Bool) { completed = didComplete }

    func viewController(forKey key: UITransitionContextViewControllerKey) -> UIViewController? {
        key == .from ? from : to
    }

    func view(forKey key: UITransitionContextViewKey) -> UIView? {
        key == .from ? from.view : (hasToView ? to.view : nil)
    }

    func initialFrame(for vc: UIViewController) -> CGRect { containerView.bounds }
    func finalFrame(for vc: UIViewController) -> CGRect { containerView.bounds }
}
