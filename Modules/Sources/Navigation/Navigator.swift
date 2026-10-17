//
//  Navigator.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import Core
import LiquidGlassKit
import UIKit

/// Thin wrapper around `UINavigationController` used by coordinators.
///
/// Its key job: know when a screen leaves the stack in ANY way
/// (back button, swipe back, `popToRoot`, `setViewControllers`, modal
/// swipe-down) and run the `onPop` / `onDismiss` closure registered for it,
/// so the owning coordinator can finish and be released.
@MainActor
public final class Navigator: NSObject {
    /// Put this in a tab / window / modal.
    public let navigationController: UINavigationController

    private var popHandlers: [PopHandler] = []
    private var animationsEnabled = true
    /// Custom push transitions, by screen. Cleaned when the screen leaves.
    private var pushTransitions: [ObjectIdentifier: Transition] = [:]
    private let analytics: any AnalyticsTracking
    private var lastTrackedScreen: ObjectIdentifier?
    private let backButton: BackButtonStyle
    /// Items whose back title mode this navigator changed (to restore them).
    private var styledBackItems: Set<ObjectIdentifier> = []

    /// Back button look for navigators created without `backButton:`.
    /// Set once at launch, before the first screen:
    ///
    ///     Navigator.defaultBackButton = .belowIOS26(.circle())
    public static var defaultBackButton: BackButtonStyle = .system

    private struct PopHandler {
        weak var viewController: UIViewController?
        let action: () -> Void
    }

    /// Usually `Navigator()`; pass a controller to reuse an existing one.
    /// Screens shown by this navigator are reported to `analytics` as `screen_view`.
    /// - Parameter backButton: look of the back button for the whole stack
    ///   (a screen can override it, see `BackButtonStyling`).
    public init(
        navigationController: UINavigationController = UINavigationController(),
        backButton: BackButtonStyle = Navigator.defaultBackButton,
        analytics: any AnalyticsTracking = Container.shared.analytics()
    ) {
        self.navigationController = navigationController
        self.analytics = analytics
        self.backButton = backButton
        super.init()
        navigationController.delegate = self
        backButton.apply(to: navigationController.navigationBar, traits: navigationController.traitCollection)
        if !backButton.isSystem {
            // Custom indicators are drawn for one appearance: redraw on light/dark change.
            navigationController.registerForTraitChanges([UITraitUserInterfaceStyle.self]) { [weak self] (_: UINavigationController, _) in
                self?.restyleBackButton()
            }
        }
    }

    /// The visible screen of this stack.
    public var topViewController: UIViewController? {
        navigationController.topViewController
    }

    /// Runs `body` with every push/pop/present unanimated.
    /// Used for deep links that build several screens at once.
    public func withoutAnimation(_ body: () -> Void) {
        let previous = animationsEnabled
        animationsEnabled = false
        body()
        animationsEnabled = previous
    }

    // MARK: - Stack

    /// Replace the whole stack with one screen (tab root, after login...).
    public func setRoot(_ viewController: UIViewController, animated: Bool = false) {
        navigationController.setViewControllers([viewController], animated: animated && animationsEnabled)
        runPopHandlersForRemovedScreens()
    }

    /// - Parameters:
    ///   - transition: `.system` (default), `.fade`, `.slideUp`, `.scale`, `.zoom`, `.custom`.
    ///     The same transition is used, reversed, when the screen is popped.
    ///   - onPop: called once when `viewController` leaves the stack.
    public func push(
        _ viewController: UIViewController,
        transition: Transition = .system,
        animated: Bool = true,
        onPop: (() -> Void)? = nil
    ) {
        let transition = transition.prepare(viewController)
        if case .system = transition {} else {
            pushTransitions[ObjectIdentifier(viewController)] = transition
        }
        if let onPop {
            popHandlers.append(PopHandler(viewController: viewController, action: onPop))
        }
        navigationController.pushViewController(viewController, animated: animated && animationsEnabled)
    }

    /// Back one screen. Its `onPop` runs.
    public func pop(animated: Bool = true) {
        navigationController.popViewController(animated: animated && animationsEnabled)
    }

    /// Back to the first screen. `onPop` runs for every removed screen.
    public func popToRoot(animated: Bool = true) {
        navigationController.popToRootViewController(animated: animated && animationsEnabled)
        // didShow only reports the top screen; clean up the ones in between.
        runPopHandlersForRemovedScreens()
    }

    /// Back to `viewController`. `onPop` runs for the screens above it.
    public func pop(to viewController: UIViewController, animated: Bool = true) {
        navigationController.popToViewController(viewController, animated: animated && animationsEnabled)
        runPopHandlersForRemovedScreens()
    }

    // MARK: - Modal

    /// Presents modally. `onDismiss` also fires on interactive swipe-down.
    ///
    ///     navigator.present(vc, style: .sheet(detents: [.medium, .large]))
    ///     navigator.present(vc, style: .fullScreen, transition: .fade)
    public func present(
        _ viewController: UIViewController,
        style: PresentationStyle? = nil,
        transition: Transition = .system,
        animated: Bool = true,
        onDismiss: (() -> Void)? = nil
    ) {
        style?.apply(to: viewController)
        let transition = transition.prepare(viewController)
        if case .system = transition {} else {
            let delegate = ModalTransitionDelegate(transition: transition)
            viewController.transitioningDelegate = delegate
            objc_setAssociatedObject(viewController, &ModalTransitionDelegate.key, delegate, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        if let onDismiss {
            let handler = DismissHandler(action: onDismiss)
            viewController.presentationController?.delegate = handler
            objc_setAssociatedObject(viewController, &DismissHandler.key, handler, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        (navigationController.presentedViewController ?? navigationController)
            .present(viewController, animated: animated && animationsEnabled)
    }

    /// Dismisses the top-most modal and runs its `onDismiss`.
    public func dismiss(animated: Bool = true, completion: (() -> Void)? = nil) {
        guard let presented = navigationController.presentedViewController else {
            completion?()
            return
        }
        let handler = objc_getAssociatedObject(presented, &DismissHandler.key) as? DismissHandler
        navigationController.dismiss(animated: animated && animationsEnabled) {
            handler?.action()
            completion?()
        }
    }

    // MARK: - Private

    private func runPopHandlersForRemovedScreens() {
        let stack = navigationController.viewControllers
        var remaining: [PopHandler] = []
        var toRun: [() -> Void] = []

        for handler in popHandlers {
            if let viewController = handler.viewController, stack.contains(viewController) {
                remaining.append(handler)
            } else {
                toRun.append(handler.action)
            }
        }
        popHandlers = remaining
        let alive = Set(stack.map(ObjectIdentifier.init))
        pushTransitions = pushTransitions.filter { alive.contains($0.key) }
        // Newest first: children finish before their parents.
        toRun.reversed().forEach { $0() }
    }
}

extension Navigator: UINavigationControllerDelegate {
    public func navigationController(
        _ navigationController: UINavigationController,
        animationControllerFor operation: UINavigationController.Operation,
        from fromVC: UIViewController,
        to toVC: UIViewController
    ) -> (any UIViewControllerAnimatedTransitioning)? {
        // Swipe-back in progress: let UIKit run its interactive pop.
        if operation == .pop, let gesture = navigationController.interactivePopGestureRecognizer,
           gesture.state == .began || gesture.state == .changed {
            return nil
        }
        let screen = operation == .push ? toVC : fromVC
        return pushTransitions[ObjectIdentifier(screen)]?.animator(presenting: operation == .push)
    }

    /// Shows or hides the bar for the screen about to appear (see `NavigationBarHiding`)
    /// and styles its back button (see `BackButtonStyle`).
    public func navigationController(
        _ navigationController: UINavigationController,
        willShow viewController: UIViewController,
        animated: Bool
    ) {
        let hidden = (viewController as? NavigationBarHiding)?.prefersNavigationBarHidden ?? false
        if navigationController.isNavigationBarHidden != hidden {
            navigationController.setNavigationBarHidden(hidden, animated: animated)
        }
        styleBackButton(of: viewController, in: navigationController)
        // Glass tab bar: refract the new screen during the transition, follow its scroll view.
        (navigationController.tabBarController as? LiquidGlassTabBarController)?.contentWillChange()
    }

    public func navigationController(
        _ navigationController: UINavigationController,
        didShow viewController: UIViewController,
        animated: Bool
    ) {
        // Covers back button and interactive swipe-back
        // (didShow is not called if the swipe is cancelled).
        runPopHandlersForRemovedScreens()
        trackScreen(viewController)
    }

    /// Redraws the indicators for the new light/dark appearance.
    func restyleBackButton() {
        // The controller's traits are already updated here; its bar's may not be yet.
        backButton.apply(to: navigationController.navigationBar, traits: navigationController.traitCollection)
        if let top = navigationController.topViewController {
            styleBackButton(of: top, in: navigationController)
        }
    }

    private func styleBackButton(of viewController: UIViewController, in navigationController: UINavigationController) {
        let override = (viewController as? BackButtonStyling)?.preferredBackButtonStyle
        if let override, !(override.isSystem && backButton.isSystem) {
            override.apply(to: viewController.navigationItem, in: navigationController.navigationBar, traits: navigationController.traitCollection)
        }
        // UIKit builds the back button from the item of the screen below.
        let stack = navigationController.viewControllers
        guard let index = stack.firstIndex(of: viewController), index > 0 else { return }
        let item = stack[index - 1].navigationItem
        let style = override ?? backButton
        if !style.isSystem {
            item.backButtonDisplayMode = style.titleMode
            styledBackItems.insert(ObjectIdentifier(item))
        } else if styledBackItems.remove(ObjectIdentifier(item)) != nil {
            item.backButtonDisplayMode = .default
        }
    }

    /// One `screen_view` each time a different screen becomes the top one
    /// (push, pop back, first screen of a modal stack).
    private func trackScreen(_ viewController: UIViewController) {
        let id = ObjectIdentifier(viewController)
        guard id != lastTrackedScreen else { return }
        lastTrackedScreen = id
        analytics.track(.screenView(viewController.resolvedAnalyticsScreenName))
    }
}

/// Retained by the presented controller itself (associated object), so it
/// lives exactly as long as the modal. No retain cycle with the navigator.
private final class DismissHandler: NSObject, UIAdaptivePresentationControllerDelegate {
    nonisolated(unsafe) static var key: UInt8 = 0
    let action: () -> Void
    private var didRun = false

    init(action: @escaping () -> Void) {
        self.action = action
    }

    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        guard !didRun else { return }
        didRun = true
        action()
    }
}
