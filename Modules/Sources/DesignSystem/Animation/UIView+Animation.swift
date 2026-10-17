//
//  UIView+Animation.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import UIKit

/// UIKit counterparts of the SwiftUI animation helpers, for Storyboard screens.
/// All of them skip movement when "Reduce Motion" is on.
@MainActor
public extension UIView {
    func fadeIn(duration: TimeInterval = 0.3, delay: TimeInterval = 0) {
        alpha = 0
        isHidden = false
        UIView.animate(withDuration: duration, delay: delay, options: [.curveEaseOut, .allowUserInteraction]) {
            self.alpha = 1
        }
    }

    func fadeOut(duration: TimeInterval = 0.3, completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: duration, animations: { self.alpha = 0 }) { _ in
            self.isHidden = true
            completion?()
        }
    }

    /// Slide up + fade in. Use `delay` for staggered cells.
    func slideIn(from offset: CGFloat = 24, duration: TimeInterval = 0.4, delay: TimeInterval = 0) {
        guard !UIAccessibility.isReduceMotionEnabled else { return fadeIn(duration: duration, delay: delay) }
        alpha = 0
        transform = CGAffineTransform(translationX: 0, y: offset)
        UIView.animate(
            withDuration: duration, delay: delay,
            usingSpringWithDamping: 0.85, initialSpringVelocity: 0,
            options: [.allowUserInteraction]
        ) {
            self.alpha = 1
            self.transform = .identity
        }
    }

    /// Error shake.
    func shake() {
        guard !UIAccessibility.isReduceMotionEnabled else { return }
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        animation.timingFunction = CAMediaTimingFunction(name: .easeOut)
        animation.duration = 0.4
        animation.values = [-10, 10, -6, 6, -3, 3, 0]
        layer.add(animation, forKey: "shake")
    }

    /// One-shot bounce (like / add to cart).
    func pop() {
        guard !UIAccessibility.isReduceMotionEnabled else { return }
        transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.45, initialSpringVelocity: 0.8, options: [.allowUserInteraction]) {
            self.transform = .identity
        }
    }

    /// Repeating soft pulse. Stop with `layer.removeAnimation(forKey: "pulse")`.
    func startPulse() {
        guard !UIAccessibility.isReduceMotionEnabled else { return }
        let animation = CABasicAnimation(keyPath: "transform.scale")
        animation.fromValue = 1
        animation.toValue = 1.06
        animation.duration = 0.8
        animation.autoreverses = true
        animation.repeatCount = .infinity
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        layer.add(animation, forKey: "pulse")
    }
}

@MainActor
public extension UITableView {
    /// Staggered slide-in of visible cells, e.g. after the first load.
    func animateVisibleCells(step: TimeInterval = 0.05) {
        for (index, cell) in visibleCells.enumerated() {
            cell.slideIn(delay: min(Double(index) * step, 0.4))
        }
    }
}
