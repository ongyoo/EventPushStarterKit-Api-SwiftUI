//
//  Transition.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import UIKit

/// How a screen animates in (and back out).
///
///     navigator.push(vc, transition: .fade)
///     navigator.present(vc, style: .fullScreen, transition: .slideUp)
///     navigator.push(vc, transition: .zoom { [weak cell] in cell })   // iOS 18 hero zoom
public enum Transition {
    /// Platform default (push slide / modal slide-up).
    case system
    case fade
    /// Comes up from the bottom, like a modal, but inside the navigation stack.
    case slideUp
    /// Grows from 90% with a fade.
    case scale
    /// iOS 18 zoom from a source view (photo grids, cards). Falls back to `.fade`.
    case zoom(source: @MainActor () -> UIView?)
    /// Hero: the view registered under `sourceID` (`.transitionSource(id:)`)
    /// expands into the new screen's header image. Any iOS version.
    case expand(sourceID: String)
    /// Your own animator (`UIViewControllerAnimatedTransitioning`).
    case custom(@MainActor (_ isPresenting: Bool) -> any UIViewControllerAnimatedTransitioning)

    @MainActor
    func animator(presenting: Bool) -> (any UIViewControllerAnimatedTransitioning)? {
        switch self {
        case .system, .zoom: nil
        case .fade: TransitionAnimator(kind: .fade, isPresenting: presenting)
        case let .expand(sourceID):
            if UIAccessibility.isReduceMotionEnabled { TransitionAnimator(kind: .fade, isPresenting: presenting) }
            else if let frame = TransitionSourceRegistry.shared.frame(for: sourceID) { ExpandAnimator(sourceFrame: frame, isPresenting: presenting) }
            else { TransitionAnimator(kind: .fade, isPresenting: presenting) }
        case .slideUp: TransitionAnimator(kind: .slideUp, isPresenting: presenting)
        case .scale: TransitionAnimator(kind: .scale, isPresenting: presenting)
        case let .custom(make): make(presenting)
        }
    }

    /// Applies transitions that UIKit handles itself (zoom).
    @MainActor
    func prepare(_ viewController: UIViewController) -> Transition {
        guard case let .zoom(source) = self else { return self }
        if #available(iOS 18.0, *) {
            viewController.preferredTransition = .zoom { _ in source() }
            return .system
        }
        return .fade
    }
}

/// Sheet heights.
public enum SheetDetent: Sendable, Hashable {
    case medium
    case large
    /// Fixed height in points.
    case height(CGFloat)

    @MainActor
    var detent: UISheetPresentationController.Detent {
        switch self {
        case .medium: .medium()
        case .large: .large()
        case let .height(value): .custom { _ in value }
        }
    }
}

/// How a screen is presented modally.
public enum PresentationStyle: Sendable {
    /// Card sheet: `.sheet(detents: [.medium, .large])`.
    case sheet(detents: [SheetDetent] = [.large], grabber: Bool = true)
    case fullScreen
    /// Keeps the presenting screen visible underneath (dimmed overlays, custom alerts).
    case overFullScreen
    /// Centered card on iPad, sheet on iPhone.
    case formSheet

    @MainActor
    func apply(to viewController: UIViewController) {
        switch self {
        case let .sheet(detents, grabber):
            viewController.modalPresentationStyle = .pageSheet
            if let sheet = viewController.sheetPresentationController {
                sheet.detents = detents.map(\.detent)
                sheet.prefersGrabberVisible = grabber
                sheet.prefersScrollingExpandsWhenScrolledToEdge = true
            }
        case .fullScreen:
            viewController.modalPresentationStyle = .fullScreen
        case .overFullScreen:
            viewController.modalPresentationStyle = .overFullScreen
        case .formSheet:
            viewController.modalPresentationStyle = .formSheet
        }
    }
}

/// Ready-made animator used by `.fade`, `.slideUp`, `.scale`.
/// Respects Reduce Motion (falls back to a fade).
public final class TransitionAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    /// Built-in animations.
    public enum Kind: Sendable { case fade, slideUp, scale }

    public let kind: Kind
    public let isPresenting: Bool
    private let duration: TimeInterval

    /// `TransitionAnimator(kind: .fade, isPresenting: true)`; used by `.fade`, `.slideUp`, `.scale`.
    public init(kind: Kind, isPresenting: Bool, duration: TimeInterval = 0.35) {
        self.kind = UIAccessibility.isReduceMotionEnabled ? .fade : kind
        self.isPresenting = isPresenting
        self.duration = duration
    }

    public func transitionDuration(using transitionContext: (any UIViewControllerContextTransitioning)?) -> TimeInterval {
        duration
    }

    public func animateTransition(using context: any UIViewControllerContextTransitioning) {
        let container = context.containerView
        let fromView = context.view(forKey: .from)
        let toView = context.view(forKey: .to)
        let height = container.bounds.height

        func hide(_ view: UIView) {
            switch kind {
            case .fade: view.alpha = 0
            case .slideUp: view.transform = CGAffineTransform(translationX: 0, y: height)
            case .scale:
                view.alpha = 0
                view.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
            }
        }

        func show(_ view: UIView) {
            view.alpha = 1
            view.transform = .identity
        }

        if isPresenting {
            guard let toView else { return context.completeTransition(false) }
            if let toController = context.viewController(forKey: .to) {
                toView.frame = context.finalFrame(for: toController)
            }
            container.addSubview(toView)
            hide(toView)
            UIView.animate(withDuration: duration, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0, options: [.curveEaseOut]) {
                show(toView)
            } completion: { _ in
                context.completeTransition(!context.transitionWasCancelled)
            }
        } else {
            if let toView, toView.superview == nil {
                container.insertSubview(toView, at: 0)
            }
            UIView.animate(withDuration: duration * 0.8, delay: 0, options: [.curveEaseIn]) {
                fromView.map(hide)
            } completion: { _ in
                let cancelled = context.transitionWasCancelled
                if cancelled { fromView.map(show) }
                context.completeTransition(!cancelled)
            }
        }
    }
}

/// Retained by the presented controller (associated object) so it lives
/// exactly as long as the modal.
final class ModalTransitionDelegate: NSObject, UIViewControllerTransitioningDelegate {
    nonisolated(unsafe) static var key: UInt8 = 0
    private let transition: Transition

    init(transition: Transition) {
        self.transition = transition
    }

    func animationController(
        forPresented presented: UIViewController,
        presenting: UIViewController,
        source: UIViewController
    ) -> (any UIViewControllerAnimatedTransitioning)? {
        transition.animator(presenting: true)
    }

    func animationController(forDismissed dismissed: UIViewController) -> (any UIViewControllerAnimatedTransitioning)? {
        transition.animator(presenting: false)
    }
}
