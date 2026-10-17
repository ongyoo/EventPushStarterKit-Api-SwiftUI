//
//  ExpandTransition.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import UIKit

/// Where tappable views are on screen, by id, so a transition can start from them.
/// SwiftUI views register with `.transitionSource(id:)` (DesignSystem);
/// UIKit views call `register(_:view:)` (preferred) or `register(_:frame:)`.
///
/// Views are held weakly and measured only when a transition starts, so
/// registering costs nothing while the user scrolls.
@MainActor
public final class TransitionSourceRegistry {
    public static let shared = TransitionSourceRegistry()
    private var frames: [String: CGRect] = [:]
    private var views: [String: WeakView] = [:]

    public init() {}

    /// `TransitionSourceRegistry.shared.register("event.42", view: cell)`
    public func register(_ id: String, view: UIView) {
        views[id] = WeakView(view: view)
        frames[id] = nil
        if views.count > 200 { views = views.filter { $0.value.view != nil } }
    }

    /// `TransitionSourceRegistry.shared.register("event.42", frame: cell.convert(cell.bounds, to: nil))`
    public func register(_ id: String, frame: CGRect) {
        frames[id] = frame
        views[id] = nil
    }

    /// Current frame in window coordinates, or `nil` if unknown / off screen.
    public func frame(for id: String) -> CGRect? {
        if let view = views[id]?.view {
            guard view.window != nil else { return nil }
            return view.convert(view.bounds, to: nil)
        }
        return frames[id]
    }

    public func remove(_ id: String) {
        frames[id] = nil
        views[id] = nil
    }

    private struct WeakView {
        weak var view: UIView?
    }
}

/// Hero "expand": a snapshot of the tapped card grows into the destination's
/// header image while the new screen fades in; reversed when going back.
/// Works on iOS 17+ (no dependency on the iOS 18 zoom API).
final class ExpandAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    let sourceFrame: CGRect
    let isPresenting: Bool
    private let duration: TimeInterval

    init(sourceFrame: CGRect, isPresenting: Bool, duration: TimeInterval = 0.5) {
        self.sourceFrame = sourceFrame
        self.isPresenting = isPresenting
        self.duration = duration
    }

    func transitionDuration(using transitionContext: (any UIViewControllerContextTransitioning)?) -> TimeInterval {
        duration
    }

    /// Where the header image sits on the destination (matches the detail layout:
    /// page margin + 4:3 image under the navigation bar).
    static func headerFrame(in view: UIView) -> CGRect {
        let margin: CGFloat = view.bounds.width < 600 ? 16 : 24
        let width = min(view.bounds.width - margin * 2, view.bounds.width >= 900 ? 480 : .greatestFiniteMagnitude)
        return CGRect(x: margin, y: view.safeAreaInsets.top + 16, width: width, height: width * 3 / 4)
    }

    func animateTransition(using context: any UIViewControllerContextTransitioning) {
        let container = context.containerView
        guard let fromView = context.view(forKey: .from), let toView = context.view(forKey: .to) else {
            return context.completeTransition(!context.transitionWasCancelled)
        }
        let source = container.convert(sourceFrame, from: nil)

        if isPresenting {
            if let toController = context.viewController(forKey: .to) {
                toView.frame = context.finalFrame(for: toController)
            }
            container.addSubview(toView)
            toView.layoutIfNeeded()
            let target = container.convert(Self.headerFrame(in: toView), from: toView)
            let snapshot = makeSnapshot(of: fromView, rect: fromView.convert(source, from: container), at: source, in: container)
            toView.alpha = 0

            UIView.animate(withDuration: duration, delay: 0, usingSpringWithDamping: 0.86, initialSpringVelocity: 0) {
                snapshot.frame = target
                snapshot.layer.cornerRadius = 8
            }
            UIView.animate(withDuration: duration * 0.5, delay: duration * 0.45, options: [.curveEaseOut]) {
                toView.alpha = 1
                snapshot.alpha = 0
            } completion: { _ in
                snapshot.removeFromSuperview()
                context.completeTransition(!context.transitionWasCancelled)
            }
        } else {
            container.insertSubview(toView, belowSubview: fromView)
            let start = container.convert(Self.headerFrame(in: fromView), from: fromView)
            let snapshot = makeSnapshot(of: fromView, rect: Self.headerFrame(in: fromView), at: start, in: container)
            UIView.animate(withDuration: duration * 0.25) {
                fromView.alpha = 0
            }
            UIView.animate(withDuration: duration, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0) {
                snapshot.frame = source
                snapshot.layer.cornerRadius = 12
            } completion: { _ in
                UIView.animate(withDuration: 0.15) { snapshot.alpha = 0 } completion: { _ in
                    snapshot.removeFromSuperview()
                    let cancelled = context.transitionWasCancelled
                    if cancelled { fromView.alpha = 1 }
                    context.completeTransition(!cancelled)
                }
            }
        }
    }

    private func makeSnapshot(of view: UIView, rect: CGRect, at frame: CGRect, in container: UIView) -> UIView {
        let snapshot = view.resizableSnapshotView(from: rect, afterScreenUpdates: false, withCapInsets: .zero) ?? UIView()
        snapshot.frame = frame
        snapshot.clipsToBounds = true
        snapshot.layer.cornerRadius = 12
        container.addSubview(snapshot)
        return snapshot
    }
}
