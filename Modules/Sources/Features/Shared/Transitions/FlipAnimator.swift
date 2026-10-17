//
//  FlipAnimator.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import UIKit

/// Example of a hand-written transition plugged in with `.custom`:
///
///     navigator.push(vc, transition: .custom { FlipAnimator(isPresenting: $0) })
///
/// The new screen turns in like a card (3D rotation around the vertical axis).
final class FlipAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    let isPresenting: Bool
    private let duration: TimeInterval

    init(isPresenting: Bool, duration: TimeInterval = 0.55) {
        self.isPresenting = isPresenting
        self.duration = duration
    }

    func transitionDuration(using transitionContext: (any UIViewControllerContextTransitioning)?) -> TimeInterval {
        duration
    }

    func animateTransition(using context: any UIViewControllerContextTransitioning) {
        let container = context.containerView
        guard let fromView = context.view(forKey: .from), let toView = context.view(forKey: .to) else {
            return context.completeTransition(!context.transitionWasCancelled)
        }
        if let toController = context.viewController(forKey: .to) {
            toView.frame = context.finalFrame(for: toController)
        }
        container.addSubview(toView)

        var perspective = CATransform3DIdentity
        perspective.m34 = -1 / 900
        container.layer.sublayerTransform = perspective
        let direction: CGFloat = isPresenting ? 1 : -1
        toView.layer.transform = CATransform3DMakeRotation(direction * -.pi / 2, 0, 1, 0)
        toView.isHidden = true

        // First half: current screen turns away. Second half: new screen turns in.
        UIView.animate(withDuration: duration / 2, delay: 0, options: [.curveEaseIn]) {
            fromView.layer.transform = CATransform3DMakeRotation(direction * .pi / 2, 0, 1, 0)
        } completion: { _ in
            fromView.isHidden = true
            toView.isHidden = false
            UIView.animate(withDuration: self.duration / 2, delay: 0, options: [.curveEaseOut]) {
                toView.layer.transform = CATransform3DIdentity
            } completion: { _ in
                fromView.isHidden = false
                fromView.layer.transform = CATransform3DIdentity
                container.layer.sublayerTransform = CATransform3DIdentity
                context.completeTransition(!context.transitionWasCancelled)
            }
        }
    }
}
